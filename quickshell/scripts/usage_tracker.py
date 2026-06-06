#!/usr/bin/env python3
"""Usage tracker for quickshell bar.

Fetches AI provider usage data and outputs normalized JSON lines.
Reads config from ~/.config/quickshell/usage.json.
Supports env var fallbacks for tokens/keys.

Providers: moonshot, copilot, claude, codex, kimi, antigravity
"""

import base64
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

CONFIG_PATH = os.path.expanduser("~/.config/quickshell/usage.json")
REFRESH_INTERVAL = 60  # seconds


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_config() -> dict:
    try:
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"providers": {}}
    except json.JSONDecodeError as e:
        log(f"Invalid JSON in {CONFIG_PATH}: {e}")
        return {"providers": {}}


def http_request(url, method="GET", headers=None, data=None, timeout=15):
    """Make HTTP request and return (status_code, body_bytes)."""
    req_headers = headers or {}
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, method=method, headers=req_headers, data=body)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except urllib.error.URLError as e:
        return 0, str(e).encode()
    except Exception as e:
        return 0, str(e).encode()


def make_rate_window(used_percent: float, window_minutes=None, resets_at_iso=None, reset_desc=None, name=None):
    return {
        "usedPercent": used_percent,
        "remainingPercent": max(0.0, 100.0 - used_percent),
        "windowMinutes": window_minutes,
        "resetsAt": resets_at_iso,
        "resetDescription": reset_desc,
        "name": name,
    }


def parse_iso_timestamp(ts: str) -> str:
    """Return ISO timestamp string or None."""
    if not ts:
        return None
    try:
        # Handle various formats
        ts = ts.replace("Z", "+00:00")
        dt = datetime.fromisoformat(ts)
        return dt.isoformat()
    except Exception:
        return None


def format_reset_description(resets_at_iso: str) -> str:
    """Human-readable time until reset."""
    if not resets_at_iso:
        return None
    try:
        ts = resets_at_iso.replace("Z", "+00:00")
        dt = datetime.fromisoformat(ts)
        now = datetime.now(timezone.utc)
        delta = dt - now
        if delta.total_seconds() <= 0:
            return "now"
        total_min = int(delta.total_seconds() / 60)
        days = total_min // 1440
        hours = (total_min % 1440) // 60
        mins = total_min % 60
        parts = []
        if days > 0:
            parts.append(f"{days}d")
        if hours > 0:
            parts.append(f"{hours}h")
        if mins > 0 and days == 0:
            parts.append(f"{mins}m")
        return "in " + " ".join(parts) if parts else "now"
    except Exception:
        return None


# ─── Provider fetchers ───


def fetch_moonshot(config: dict) -> dict:
    key = config.get("apiKey") or os.environ.get("MOONSHOT_API_KEY")
    if not key:
        return {"error": "No API key (set MOONSHOT_API_KEY or config.apiKey)"}

    code, body = http_request(
        "https://api.moonshot.ai/v1/users/me/balance",
        headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
    )
    if code != 200:
        return {"error": f"HTTP {code}: {body.decode('utf-8', errors='replace')[:200]}"}

    data = json.loads(body)
    bal = data.get("data", {})
    available = bal.get("available_balance", 0)
    cash = bal.get("cash_balance", 0)
    voucher = bal.get("voucher_balance", 0)

    plan_str = f"Balance: ${available:.2f}"
    if cash < 0:
        plan_str += f" · ${abs(cash):.2f} in deficit"

    return {
        "displayName": "Moonshot",
        "primary": None,
        "secondary": None,
        "tertiary": None,
        "credits": {"remaining": available, "currency": "USD"},
        "identity": {"email": None, "plan": plan_str},
        "error": None,
        "updatedAt": now_iso(),
    }


def fetch_copilot(config: dict) -> dict:
    token = config.get("token") or os.environ.get("COPILOT_API_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        return {"error": "No token (set COPILOT_API_TOKEN or GITHUB_TOKEN or config.token)"}

    code, body = http_request(
        "https://api.github.com/copilot_internal/user",
        headers={
            "Authorization": f"token {token}",
            "Accept": "application/json",
            "Editor-Version": "vscode/1.96.2",
            "Editor-Plugin-Version": "copilot-chat/0.26.7",
            "User-Agent": "GitHubCopilotChat/0.26.7",
            "X-Github-Api-Version": "2025-04-01",
        },
    )
    if code != 200:
        return {"error": f"HTTP {code}: {body.decode('utf-8', errors='replace')[:200]}"}

    data = json.loads(body)
    quotas = data.get("quota_snapshots", {})
    plan = data.get("copilot_plan", "unknown")
    reset_date = data.get("quota_reset_date")

    # Extract premium and chat quotas
    premium = quotas.get("premium_interactions")
    chat = quotas.get("chat")

    # Dynamic fallback scan
    if not premium or not chat:
        for k, v in quotas.items():
            if isinstance(v, dict) and "entitlement" in v:
                if not premium and ("premium" in k or "completion" in k or "code" in k):
                    premium = v
                elif not chat and "chat" in k:
                    chat = v
        if not chat and not premium:
            # Use first non-placeholder as fallback
            for k, v in quotas.items():
                if isinstance(v, dict) and v.get("entitlement", 0) > 0:
                    chat = v
                    break

    primary = None
    secondary = None

    if premium:
        used_pct = 100.0 - premium.get("percent_remaining", 0)
        entitlement = premium.get("entitlement", 0)
        remaining = premium.get("remaining", 0)
        primary = make_rate_window(
            used_pct,
            window_minutes=43200,  # ~30 days
            resets_at_iso=parse_iso_timestamp(reset_date + "T00:00:00Z") if reset_date else None,
            reset_desc=f"{remaining}/{entitlement} premium",
        )

    if chat:
        used_pct = 100.0 - chat.get("percent_remaining", 0)
        entitlement = chat.get("entitlement", 0)
        remaining = chat.get("remaining", 0)
        secondary = make_rate_window(
            used_pct,
            window_minutes=43200,
            resets_at_iso=parse_iso_timestamp(reset_date + "T00:00:00Z") if reset_date else None,
            reset_desc=f"{remaining}/{entitlement} chat",
        )

    plan_display = plan.replace("_", " ").title()

    return {
        "displayName": "Copilot",
        "primary": primary,
        "secondary": secondary,
        "tertiary": None,
        "credits": None,
        "identity": {"email": None, "plan": plan_display},
        "error": None,
        "updatedAt": now_iso(),
    }


def fetch_claude(config: dict) -> dict:
    token = config.get("token") or os.environ.get("CLAUDE_API_KEY") or os.environ.get("ANTHROPIC_API_KEY")
    if not token:
        return {"error": "No token (set CLAUDE_API_KEY or ANTHROPIC_API_KEY or config.token)"}

    code, body = http_request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={
            "Authorization": f"Bearer {token}",
            "anthropic-beta": "oauth-2025-04-20",
            "User-Agent": "codexbar/0.1",
        },
    )
    if code != 200:
        return {"error": f"HTTP {code}: {body.decode('utf-8', errors='replace')[:200]}"}

    data = json.loads(body)

    # Dynamic key decoding for windows
    def find_window(*keys):
        for k in keys:
            if k in data:
                return data[k]
        return None

    five_hour = find_window("five_hour", "5h", "session")
    seven_day = find_window("seven_day", "7d", "weekly")
    seven_day_opus = find_window("seven_day_opus", "seven_day_sonnet", "opus", "sonnet")
    seven_day_routines = find_window(
        "seven_day_routines", "seven_day_claude_routines", "claude_routines",
        "routines", "routine", "seven_day_cowork", "cowork"
    )
    extra_usage = data.get("extra_usage")

    primary = None
    secondary = None
    tertiary = None
    credits = None

    if five_hour:
        pct = five_hour.get("utilization", 0)
        resets = parse_iso_timestamp(five_hour.get("resets_at"))
        primary = make_rate_window(pct, window_minutes=300, resets_at_iso=resets)

    if seven_day:
        pct = seven_day.get("utilization", 0)
        resets = parse_iso_timestamp(seven_day.get("resets_at"))
        secondary = make_rate_window(pct, window_minutes=10080, resets_at_iso=resets)

    if seven_day_opus:
        pct = seven_day_opus.get("utilization", 0)
        resets = parse_iso_timestamp(seven_day_opus.get("resets_at"))
        tertiary = make_rate_window(pct, window_minutes=10080, resets_at_iso=resets)

    # Fallback priority
    if not primary:
        for src in [seven_day, seven_day_routines]:
            if src:
                pct = src.get("utilization", 0)
                resets = parse_iso_timestamp(src.get("resets_at"))
                primary = make_rate_window(pct, window_minutes=10080, resets_at_iso=resets)
                break

    if extra_usage and extra_usage.get("is_enabled"):
        used = extra_usage.get("used_credits", 0) / 100.0  # API returns cents
        limit = extra_usage.get("monthly_limit", 0) / 100.0
        credits = {"remaining": limit - used, "currency": extra_usage.get("currency", "USD").upper()}
        # If no rate windows, show spend limit as primary
        if not primary and limit > 0:
            primary = make_rate_window((used / limit) * 100, reset_desc=f"${used:.2f} / ${limit:.2f}")

    return {
        "displayName": "Claude",
        "primary": primary,
        "secondary": secondary,
        "tertiary": tertiary,
        "credits": credits,
        "identity": {"email": None, "plan": "Pro"},
        "error": None,
        "updatedAt": now_iso(),
    }


def fetch_codex(config: dict) -> dict:
    token = config.get("token") or os.environ.get("CODEX_TOKEN") or os.environ.get("OPENAI_API_KEY")
    if not token:
        return {"error": "No token (set CODEX_TOKEN, OPENAI_API_KEY, or config.token)"}

    base_url = config.get("baseUrl", "https://chatgpt.com")
    code, body = http_request(
        f"{base_url}/backend-api/wham/usage",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
    )
    if code != 200:
        return {"error": f"HTTP {code}: {body.decode('utf-8', errors='replace')[:200]}"}

    data = json.loads(body)
    plan = data.get("plan_type", "unknown")
    rate_limit = data.get("rate_limit", {})
    credits_data = data.get("credits", {})

    primary = None
    secondary = None

    pw = rate_limit.get("primary_window")
    if pw:
        resets = datetime.fromtimestamp(pw.get("reset_at", 0), tz=timezone.utc).isoformat() if pw.get("reset_at") else None
        primary = make_rate_window(
            pw.get("used_percent", 0),
            window_minutes=pw.get("limit_window_seconds", 0) // 60,
            resets_at_iso=resets,
        )

    sw = rate_limit.get("secondary_window")
    if sw:
        resets = datetime.fromtimestamp(sw.get("reset_at", 0), tz=timezone.utc).isoformat() if sw.get("reset_at") else None
        secondary = make_rate_window(
            sw.get("used_percent", 0),
            window_minutes=sw.get("limit_window_seconds", 0) // 60,
            resets_at_iso=resets,
        )

    credits = None
    if credits_data.get("has_credits") and not credits_data.get("unlimited"):
        bal = credits_data.get("balance", 0)
        if isinstance(bal, str):
            try:
                bal = float(bal)
            except ValueError:
                bal = 0
        credits = {"remaining": bal, "currency": "USD"}

    plan_display = plan.replace("_", " ").title()

    return {
        "displayName": "Codex",
        "primary": primary,
        "secondary": secondary,
        "tertiary": None,
        "credits": credits,
        "identity": {"email": None, "plan": plan_display},
        "error": None,
        "updatedAt": now_iso(),
    }


def fetch_kimi(config: dict) -> dict:
    token = config.get("token") or os.environ.get("KIMI_AUTH_TOKEN") or os.environ.get("KIMI_MANUAL_COOKIE")
    if not token:
        return {"error": "No token (set KIMI_AUTH_TOKEN or config.token)"}

    # Extract JWT from cookie string or use directly
    jwt = token.strip()
    if "kimi-auth=" in jwt:
        import re
        m = re.search(r"kimi-auth=([^;\s]+)", jwt)
        if m:
            jwt = m.group(1).strip()

    debug = os.environ.get("USAGE_DEBUG", "").lower() in ("1", "true", "yes")
    if debug:
        log(f"[kimi] JWT length: {len(jwt)}, starts with: {jwt[:20]}...")

    # Decode JWT for session headers
    device_id = None
    session_id = None
    traffic_id = None
    jwt_payload = {}
    try:
        parts = jwt.split(".")
        if len(parts) == 3:
            payload = parts[1].replace("-", "+").replace("_", "/")
            pad = 4 - len(payload) % 4
            if pad != 4:
                payload += "=" * pad
            jwt_payload = json.loads(base64.b64decode(payload))
            device_id = jwt_payload.get("device_id")
            session_id = jwt_payload.get("ssid")
            traffic_id = jwt_payload.get("sub")
            if debug:
                log(f"[kimi] JWT payload keys: {list(jwt_payload.keys())}")
    except Exception as e:
        if debug:
            log(f"[kimi] JWT decode error: {e}")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {jwt}",
        "Cookie": f"kimi-auth={jwt}",
        "Origin": "https://www.kimi.com",
        "Referer": "https://www.kimi.com/code/console",
        "Accept": "*/*",
        "Accept-Language": "en-US,en;q=0.9",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        "connect-protocol-version": "1",
        "x-language": "en-US",
        "x-msh-platform": "web",
        "r-timezone": "Europe/Berlin",
    }
    if device_id:
        headers["x-msh-device-id"] = device_id
    if session_id:
        headers["x-msh-session-id"] = session_id
    if traffic_id:
        headers["x-traffic-id"] = traffic_id

    if debug:
        safe_headers = {k: (v[:20] + "..." if "auth" in k.lower() or "token" in k.lower() or "bearer" in v.lower() else v) for k, v in headers.items()}
        log(f"[kimi] Request headers: {json.dumps(safe_headers)}")

    code, body = http_request(
        "https://www.kimi.com/apiv2/kimi.gateway.billing.v1.BillingService/GetUsages",
        method="POST",
        headers=headers,
        data={"scope": ["FEATURE_CODING"]},
    )
    if code != 200:
        body_text = body.decode("utf-8", errors="replace")
        if debug:
            log(f"[kimi] HTTP {code} response: {body_text}")
        return {"error": f"HTTP {code}: {body_text[:400]}"}

    data = json.loads(body)
    usages = data.get("usages", [])
    coding_usage = None
    for u in usages:
        if u.get("scope") == "FEATURE_CODING":
            coding_usage = u
            break
    if not coding_usage:
        coding_usage = usages[0] if usages else {}

    detail = coding_usage.get("detail", {})
    limits = coding_usage.get("limits", [])

    # Weekly quota (primary)
    weekly_limit = int(detail.get("limit", "0") or "0")
    weekly_used = int(detail.get("used", "0") or "0")
    if weekly_used == 0 and weekly_limit > 0:
        weekly_used = weekly_limit - int(detail.get("remaining", "0") or "0")
    weekly_pct = (weekly_used / weekly_limit * 100) if weekly_limit > 0 else 0

    primary = None
    if weekly_limit > 0:
        resets = parse_iso_timestamp(detail.get("resetTime"))
        primary = make_rate_window(
            weekly_pct,
            resets_at_iso=resets,
            reset_desc=f"{weekly_used}/{weekly_limit}",
            name="Weekly",
        )

    # Rate limits — collect all windows from limits array
    secondary = None
    extra_windows = []
    for lim in limits:
        window = lim.get("window", {})
        ld = lim.get("detail", {})
        lim_val = int(ld.get("limit", "0") or "0")
        if lim_val > 0:
            used = int(ld.get("used", "0") or "0")
            if used == 0:
                used = lim_val - int(ld.get("remaining", "0") or "0")
            pct = (used / lim_val * 100)
            dur = window.get("duration", 300)
            unit = window.get("timeUnit", "MINUTE")
            mins = dur if unit == "MINUTE" else dur * 60
            resets = parse_iso_timestamp(ld.get("resetTime"))

            # Build a human-readable name like "5h" or "1d"
            if unit == "MINUTE":
                if dur >= 60:
                    win_name = f"{dur // 60}h"
                else:
                    win_name = f"{dur}m"
            elif unit == "HOUR":
                win_name = f"{dur}h"
            elif unit == "DAY":
                win_name = f"{dur}d"
            else:
                win_name = f"{dur}{unit[0].lower()}"

            w = make_rate_window(
                pct,
                window_minutes=mins,
                resets_at_iso=resets,
                reset_desc=f"{used}/{lim_val}",
                name=win_name,
            )
            if secondary is None:
                secondary = w
            else:
                extra_windows.append(w)

    return {
        "displayName": "Kimi",
        "primary": primary,
        "secondary": secondary,
        "tertiary": None,
        "extraRateWindows": extra_windows,
        "credits": None,
        "identity": {"email": None, "plan": "Coding Plan"},
        "error": None,
        "updatedAt": now_iso(),
    }


# ─── Antigravity ───

_ssl_ctx_no_verify = None

def _get_ssl_ctx_no_verify():
    global _ssl_ctx_no_verify
    if _ssl_ctx_no_verify is None:
        _ssl_ctx_no_verify = ssl.create_default_context()
        _ssl_ctx_no_verify.check_hostname = False
        _ssl_ctx_no_verify.verify_mode = ssl.CERT_NONE
    return _ssl_ctx_no_verify


def _find_language_server_process():
    """Find antigravity/codeium language_server process. Returns (pid, cmdline) or (None, None)."""
    try:
        for entry in os.listdir("/proc"):
            if not entry.isdigit():
                continue
            pid = int(entry)
            try:
                with open(f"/proc/{pid}/cmdline", "rb") as f:
                    cmdline = f.read().replace(b"\x00", b" ").decode("utf-8", errors="replace")
                if "language_server" in cmdline.lower():
                    return pid, cmdline
            except (OSError, PermissionError):
                continue
    except Exception:
        pass
    return None, None


def _extract_csrf_from_cmdline(cmdline: str) -> str:
    import re
    m = re.search(r"--csrf_token[=\s]([^\s]+)", cmdline)
    if m:
        return m.group(1).strip()
    return ""


def _find_listening_ports(pid: int):
    """Find TCP listening ports for a process via /proc/net/tcp."""
    ports = []
    try:
        for tcp_file in [f"/proc/{pid}/net/tcp", f"/proc/{pid}/net/tcp6"]:
            try:
                with open(tcp_file, "r") as f:
                    lines = f.readlines()
                for line in lines[1:]:
                    parts = line.strip().split()
                    if len(parts) < 4:
                        continue
                    local_addr = parts[1]
                    state = parts[3]
                    if state == "0A":  # LISTEN
                        # local_addr format: IP:PORT (hex)
                        port_hex = local_addr.split(":")[-1]
                        port = int(port_hex, 16)
                        if port > 0:
                            ports.append(port)
            except (OSError, ValueError):
                continue
    except Exception:
        pass
    return sorted(set(ports))


def _antigravity_local_probe(config: dict, debug: bool):
    """Try to fetch from local IDE gRPC server."""
    pid, cmdline = _find_language_server_process()
    if not pid:
        return None, "No language_server process found (is Antigravity IDE running?)"

    csrf = config.get("csrfToken") or _extract_csrf_from_cmdline(cmdline)
    if not csrf:
        return None, "Found language_server but could not extract CSRF token"

    ports = _find_listening_ports(pid)
    if not ports:
        return None, "Found language_server but no listening ports"

    if debug:
        log(f"[antigravity] Found language_server pid={pid}, ports={ports}")

    import ssl
    for port in ports:
        url = f"https://127.0.0.1:{port}/exa.language_server_pb.LanguageServerService/GetUserStatus"
        headers = {
            "Content-Type": "application/json",
            "X-Codeium-Csrf-Token": csrf,
            "Connect-Protocol-Version": "1",
        }
        data = {"metadata": {"ideName": "antigravity", "extensionName": "antigravity", "ideVersion": "unknown", "locale": "en"}}
        try:
            body = json.dumps(data).encode("utf-8")
            req = urllib.request.Request(url, method="POST", headers=headers, data=body)
            ctx = _get_ssl_ctx_no_verify()
            with urllib.request.urlopen(req, context=ctx, timeout=5) as resp:
                if resp.status == 200:
                    return json.loads(resp.read().decode("utf-8")), None
        except urllib.error.HTTPError as e:
            if debug:
                log(f"[antigravity] Port {port} HTTP {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}")
            continue
        except Exception as e:
            if debug:
                log(f"[antigravity] Port {port} error: {e}")
            continue

    return None, "Could not connect to any local IDE port"


def _refresh_google_token(refresh_token: str, client_id: str) -> tuple:
    """Refresh Google OAuth access token. Returns (new_access_token, error)."""
    if not refresh_token:
        return None, "No refresh token available"
    if not client_id:
        return None, "No client_id available (needed for refresh)"

    data = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": client_id,
    }).encode("utf-8")

    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data=data,
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            new_token = result.get("access_token")
            if new_token:
                return new_token, None
            return None, f"Refresh response missing access_token: {result}"
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        return None, f"Token refresh failed HTTP {e.code}: {err_body[:300]}"
    except Exception as e:
        return None, f"Token refresh error: {e}"


def _extract_client_id_from_id_token(id_token: str) -> str:
    """Extract azp/aud claim from a Google id_token."""
    try:
        parts = id_token.split(".")
        if len(parts) == 3:
            payload = parts[1].replace("-", "+").replace("_", "/")
            pad = 4 - len(payload) % 4
            if pad != 4:
                payload += "=" * pad
            decoded = json.loads(base64.b64decode(payload))
            return decoded.get("azp") or decoded.get("aud", "")
    except Exception:
        pass
    return ""


def _antigravity_oauth(config: dict, debug: bool):
    """Fallback: Google Cloud OAuth APIs."""
    access_token = config.get("accessToken") or os.environ.get("ANTIGRAVITY_ACCESS_TOKEN")
    refresh_token = config.get("refreshToken") or os.environ.get("ANTIGRAVITY_REFRESH_TOKEN")
    client_id = config.get("clientId") or ""

    # Try to extract client_id from stored id_token if not provided
    if not client_id:
        id_token = config.get("idToken", "")
        client_id = _extract_client_id_from_id_token(id_token)

    if not access_token and not refresh_token:
        return None, "No OAuth tokens (set accessToken+refreshToken or ANTIGRAVITY_ACCESS_TOKEN)"

    base = "https://cloudcode-pa.googleapis.com/v1internal"

    def try_api(token):
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }
        # Try retrieveUserQuota endpoint first
        code, body = http_request(
            f"{base}:retrieveUserQuota",
            method="POST",
            headers=headers,
            data={},
        )
        if code == 200:
            return json.loads(body), None
        # Try fetchAvailableModels
        code2, body2 = http_request(
            f"{base}:fetchAvailableModels",
            method="POST",
            headers=headers,
            data={},
        )
        if code2 == 200:
            return json.loads(body2), None
        return None, (code, body)

    # Try with current access token
    if access_token:
        result, err = try_api(access_token)
        if result:
            return result, None
        # If 401 and we have refresh token, try refreshing
        if isinstance(err, tuple) and err[0] == 401 and refresh_token and client_id:
            if debug:
                log("[antigravity] Access token expired, refreshing...")
            new_token, refresh_err = _refresh_google_token(refresh_token, client_id)
            if refresh_err:
                return None, f"Token refresh failed: {refresh_err}"
            if debug:
                log("[antigravity] Token refreshed successfully")
            # Update config with new token for next cycle
            config["accessToken"] = new_token
            result, err2 = try_api(new_token)
            if result:
                return result, None
            if isinstance(err2, tuple):
                body_text = err2[1].decode("utf-8", errors="replace")[:300]
                return None, f"OAuth API error HTTP {err2[0]} after refresh: {body_text}"
        elif isinstance(err, tuple):
            body_text = err[1].decode("utf-8", errors="replace")[:300]
            return None, f"OAuth API error HTTP {err[0]}: {body_text}"

    # No access token but have refresh token
    if refresh_token and client_id:
        if debug:
            log("[antigravity] No access token, refreshing...")
        new_token, refresh_err = _refresh_google_token(refresh_token, client_id)
        if refresh_err:
            return None, f"Token refresh failed: {refresh_err}"
        config["accessToken"] = new_token
        result, err = try_api(new_token)
        if result:
            return result, None
        if isinstance(err, tuple):
            body_text = err[1].decode("utf-8", errors="replace")[:300]
            return None, f"OAuth API error HTTP {err[0]}: {body_text}"

    return None, "No valid OAuth tokens available"


def fetch_antigravity(config: dict) -> dict:
    debug = os.environ.get("USAGE_DEBUG", "").lower() in ("1", "true", "yes")
    mode = config.get("mode", "auto")

    result = None
    error = None

    if mode in ("auto", "cli"):
        result, error = _antigravity_local_probe(config, debug)
        if result:
            error = None

    if not result and mode in ("auto", "oauth"):
        result, oauth_err = _antigravity_oauth(config, debug)
        if result:
            error = None
        elif error is None:
            error = oauth_err

    if not result:
        return {
            "displayName": "Antigravity",
            "error": error or "Failed to fetch Antigravity usage",
            "updatedAt": now_iso(),
        }

    # Parse local probe response
    user_status = result.get("userStatus", {})
    email = user_status.get("email")
    plan = user_status.get("planStatus", {}).get("planInfo", {}).get("planDisplayName", "")
    tier = user_status.get("userTier", {}).get("name", "")
    configs = user_status.get("cascadeModelConfigData", {}).get("clientModelConfigs", [])

    # Model family mapping
    models = []
    for cfg in configs:
        label = cfg.get("label", "")
        model_id = cfg.get("modelOrAlias", {}).get("model", "")
        quota = cfg.get("quotaInfo", {})
        remaining = quota.get("remainingFraction", 0)
        reset_time = quota.get("resetTime")

        family = "other"
        name_lower = (model_id + " " + label).lower()
        if "claude" in name_lower:
            family = "claude"
        elif "gemini" in name_lower:
            if "flash" in name_lower:
                family = "geminiFlash"
            else:
                family = "geminiPro"

        models.append({
            "label": label,
            "model": model_id,
            "family": family,
            "remainingFraction": remaining,
            "usedPercent": (1 - remaining) * 100,
            "resetTime": reset_time,
        })

    # Pick representatives
    def pick_best(family_name):
        candidates = [m for m in models if m["family"] == family_name]
        if not candidates:
            return None
        # Sort: most constrained first
        candidates.sort(key=lambda m: (m["remainingFraction"], m["label"]))
        return candidates[0]

    claude_model = pick_best("claude")
    gemini_pro = pick_best("geminiPro")
    gemini_flash = pick_best("geminiFlash")

    primary = None
    secondary = None
    tertiary = None

    if claude_model:
        primary = make_rate_window(
            claude_model["usedPercent"],
            reset_desc=f"{claude_model['label']}: {claude_model['remainingFraction'] * 100:.0f}% left",
        )
    if gemini_pro:
        secondary = make_rate_window(
            gemini_pro["usedPercent"],
            reset_desc=f"{gemini_pro['label']}: {gemini_pro['remainingFraction'] * 100:.0f}% left",
        )
    if gemini_flash:
        tertiary = make_rate_window(
            gemini_flash["usedPercent"],
            reset_desc=f"{gemini_flash['label']}: {gemini_flash['remainingFraction'] * 100:.0f}% left",
        )

    # Extra rate windows for all models
    extra_windows = []
    for m in sorted(models, key=lambda x: (x["family"], x["model"], x["label"])):
        extra_windows.append({
            "name": m["label"],
            "usedPercent": m["usedPercent"],
            "remainingPercent": m["remainingFraction"] * 100,
            "resetDescription": f"{m['remainingFraction'] * 100:.0f}% left",
        })

    plan_str = f"{plan} · {tier}" if plan and tier else (plan or tier or "Antigravity")

    return {
        "displayName": "Antigravity",
        "primary": primary,
        "secondary": secondary,
        "tertiary": tertiary,
        "extraRateWindows": extra_windows,
        "credits": None,
        "identity": {"email": email, "plan": plan_str},
        "error": None,
        "updatedAt": now_iso(),
    }


# ─── Main loop ───

FETCHERS = {
    "moonshot": fetch_moonshot,
    "copilot": fetch_copilot,
    "claude": fetch_claude,
    "codex": fetch_codex,
    "kimi": fetch_kimi,
    "antigravity": fetch_antigravity,
}


def fetch_all(config: dict) -> dict:
    providers = config.get("providers", {})
    results = {}
    for name, pc in providers.items():
        if not pc.get("enabled", False):
            continue
        fetcher = FETCHERS.get(name)
        if not fetcher:
            results[name] = {"error": f"Unknown provider: {name}"}
            continue
        try:
            result = fetcher(pc)
            result["provider"] = name
            results[name] = result
        except Exception as e:
            results[name] = {"provider": name, "error": str(e), "updatedAt": now_iso()}
    return results


def enrich_reset_descriptions(results: dict) -> dict:
    """Add human-readable reset descriptions if missing."""
    for name, result in results.items():
        if result.get("error"):
            continue
        for key in ["primary", "secondary", "tertiary"]:
            window = result.get(key)
            if window and window.get("resetsAt") and not window.get("resetDescription"):
                window["resetDescription"] = format_reset_description(window["resetsAt"])
    return results


def main():
    config = load_config()

    # Immediate first fetch
    results = fetch_all(config)
    results = enrich_reset_descriptions(results)
    print(json.dumps(results), flush=True)

    while True:
        time.sleep(REFRESH_INTERVAL)
        # Reload config each cycle to pick up changes
        config = load_config()
        results = fetch_all(config)
        results = enrich_reset_descriptions(results)
        print(json.dumps(results), flush=True)


if __name__ == "__main__":
    main()
