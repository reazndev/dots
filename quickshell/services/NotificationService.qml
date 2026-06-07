pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "DesktopIcons.js" as DesktopIcons

Item {
    id: root

    // Expose the tracked notifications list and server instance
    property alias trackedNotifications: server.trackedNotifications
    property alias server: server
    readonly property int unreadCount: trackedNotifications.values.length
    property var activeTransientNotification: null
    readonly property var latestNotification: activeTransientNotification !== null ? activeTransientNotification : (unreadCount > 0 ? trackedNotifications.values[unreadCount - 1] : null)
    property string presentationMode: "none" // none, sticky, transient
    property int transientDuration: 5000

    signal layoutModeRequested(string label)

    Timer {
        id: transientTimer
        interval: root.transientDuration
        repeat: false
        onTriggered: {
            root.presentationMode = root.unreadCount > 0 ? "sticky" : "none";
            root.activeTransientNotification = null;
        }
    }

    function appIconSource(notification) {
        if (!notification)
            return "";

        var notificationText = [
            notification.appName || "",
            notification.summary || "",
            notification.body || "",
            notification.appIcon || "",
            notification.desktopEntry || ""
        ].join(" ").toLowerCase();

        // Content-specific icons must win over the app that delivered the notification
        // e.g. Codex messages sent through Ghostty should not use the Ghostty icon.
        if (notificationText.indexOf("codex") !== -1)
            return "file:///home/reazn/.config/icons/png/codex.png";
        if (notificationText.indexOf("color picker") !== -1)
            return "file:///home/reazn/.config/icons/png/hyprpicker.png";

        // 1. Try custom notification image/avatar (e.g. sender avatar)
        if (notification.image) {
            var img = String(notification.image);
            if (img.indexOf("/") === 0 || img.indexOf("file://") === 0 || img.indexOf("qrc:/") === 0)
                return img;
        }

        // Helper to resolve an icon name with aliases and fallbacks
        var resolveIcon = function (name) {
            if (!name)
                return "";

            var key = String(name).toLowerCase().trim();
            var resolved = "";

            // Custom local png icon mapping
            var customPngMap = {
                "vesktop": "discord.png",
                "discord": "discord.png",
                "discord-client": "discord.png",
                "element": "element2.png",
                "element-desktop": "element2.png",
                "element-desktop-nightly": "element2.png",
                "element desktop": "element2.png",
                "ghostty": "ghostty.png",
                "com.mitchellh.ghostty": "ghostty.png",
                "helium": "helium.png",
                "helium-browser": "helium.png",
                "helium browser": "helium.png",
                "spotify": "spotify.png",
                "spotify-launcher": "spotify.png",
                "vleer": "vleer.png",
                "zed": "zed.png",
                "zeditor": "zed.png",
                "zed preview": "zed.png",
                "dev.zed.zed-preview": "zed.png",
                "github": "github.png",
                "github-desktop": "github.png",
                "codex": "codex.png",
                "color picker": "hyprpicker.png",
                "colorpicker": "hyprpicker.png",
                "hyprpicker": "hyprpicker.png",
                "hyprshot": "hyprshot.png",
                "screenshot": "hyprshot.png",
                "accessories-screenshot": "hyprshot.png",
                "localsend": "localsend.png",
                "protonvpn": "protonvpn.png",
                "proton vpn": "protonvpn.png",
                "proton-vpn": "protonvpn.png",
                "proton.vpn.app.gtk": "protonvpn.png",
                "cachy": "cachy.png",
                "cachyos": "cachy.png",
                "cachyos-hello": "cachy.png",
                "cachyos hello": "cachy.png",
                "arch": "arch.png",
                "console": "console.png",
                "terminal": "console.png",
                "alacritty": "console.png",
                "kitty": "console.png",
                "fish": "fish.png",
                "claude": "claude.png",
                "claude-code": "cc.png",
                "claude code": "cc.png"
            };

            var cleanedKey = key.replace(/\s+desktop$/g, "").replace(/\s+client$/g, "").replace(/\s+\d+$/g, "").replace(/[\s\-_]+/g, "");

            var customFile = customPngMap[key] || customPngMap[cleanedKey];
            if (!customFile) {
                for (var customKey in customPngMap) {
                    if (key.indexOf(customKey) !== -1 || cleanedKey.indexOf(customKey) !== -1) {
                        customFile = customPngMap[customKey];
                        break;
                    }
                }
            }

            if (customFile) {
                return "file:///home/reazn/.config/icons/png/" + customFile;
            }

            // A. Check the auto-generated desktop file icon mapping
            var desktopIcon = DesktopIcons.getIcon(key);
            if (desktopIcon) {
                resolved = Quickshell.iconPath(desktopIcon, true);
                if (resolved)
                    return resolved;
            }

            // Try standard cleaned key in desktop file icon mapping
            var cleanedKey = key.replace(/\s+desktop$/g, "").replace(/\s+client$/g, "").replace(/\s+\d+$/g, "") // remove trailing numbers
            .replace(/[\s\-_]+/g, ""); // strip spaces/hyphens

            var cleanedDesktopIcon = DesktopIcons.getIcon(cleanedKey);
            if (cleanedDesktopIcon) {
                resolved = Quickshell.iconPath(cleanedDesktopIcon, true);
                if (resolved)
                    return resolved;
            }

            // B. Common manual icon/appName aliases as a backup
            var aliases = {
                "vesktop": "discord",
                "element desktop": "element",
                "element": "element",
                "hyprshot": "accessories-screenshot",
                "screenshot": "accessories-screenshot",
                "discord-client": "discord",
                "discord": "discord"
            };

            // Try explicit alias first
            if (aliases[key]) {
                resolved = Quickshell.iconPath(aliases[key], true);
                if (resolved)
                    return resolved;
            }

            if (aliases[cleanedKey]) {
                resolved = Quickshell.iconPath(aliases[cleanedKey], true);
                if (resolved)
                    return resolved;
            }

            // C. Try the name directly
            resolved = Quickshell.iconPath(key, true);
            if (resolved)
                return resolved;

            // Try cleaned key directly
            resolved = Quickshell.iconPath(cleanedKey, true);
            if (resolved)
                return resolved;

            // D. Generic fallback categories for common key prefixes/suffixes
            if (key.indexOf("shot") !== -1 || key.indexOf("screen") !== -1) {
                resolved = Quickshell.iconPath("accessories-screenshot", true) || Quickshell.iconPath("camera-photo", true);
                if (resolved)
                    return resolved;
            }

            return "";
        };

        // 2. Try the app icon specified by the app
        if (notification.appIcon) {
            var icon = String(notification.appIcon);
            if (icon.indexOf("/") === 0 || icon.indexOf("file://") === 0 || icon.indexOf("qrc:/") === 0)
                return icon;

            var resolvedAppIcon = resolveIcon(icon);
            if (resolvedAppIcon)
                return resolvedAppIcon;
        }

        // 3. Try the desktop entry name specified by the notification (e.g. desktop-entry hint)
        if (notification.desktopEntry) {
            var resolvedDesktopEntry = resolveIcon(notification.desktopEntry);
            if (resolvedDesktopEntry)
                return resolvedDesktopEntry;
        }

        // 4. Try resolving the application name
        if (notification.appName) {
            var resolvedAppName = resolveIcon(notification.appName);
            if (resolvedAppName)
                return resolvedAppName;
        }

        return "";
    }

    function appLabel(notification) {
        if (!notification || !notification.appName)
            return "Notification";
        return notification.appName;
    }

    function isLayoutModeNotification(notification) {
        if (!notification)
            return false;

        return (notification.summary || "").toLowerCase().trim() === "ultrawide layout";
    }

    function layoutModeLabel(notification) {
        if (!isLayoutModeNotification(notification))
            return "";

        var body = (notification.body || "").toLowerCase();
        if (body.indexOf("2560x1440") !== -1)
            return "narrow";
        if (body.indexOf("enabled") !== -1)
            return "mid";
        if (body.indexOf("disabled") !== -1)
            return "wide";

        return "layout";
    }

    function shouldTrack(notification) {
        if (!notification)
            return false;

        var app = (notification.appName || "").toLowerCase();
        var summary = (notification.summary || "").toLowerCase();
        var body = (notification.body || "").toLowerCase();

        // Layout mode changes get a compact transient island only.
        if (isLayoutModeNotification(notification))
            return false;

        // 1. Screenshot check
        if (app.indexOf("hyprshot") !== -1 || app.indexOf("screenshot") !== -1 ||
            summary.indexOf("screenshot") !== -1 || body.indexOf("screenshot") !== -1) {
            return false;
        }

        // 2. Ghostty check
        if (app.indexOf("ghostty") !== -1) {
            return false;
        }

        // 3. Claude Code check
        if (app.indexOf("claude") !== -1 || summary.indexOf("claude") !== -1) {
            return false;
        }

        return true;
    }

    function receiveNotification(notification) {
        if (!notification)
            return;

        if (isLayoutModeNotification(notification)) {
            notification.tracked = false;
            transientTimer.stop();
            root.presentationMode = "none";
            root.activeTransientNotification = null;
            root.layoutModeRequested(layoutModeLabel(notification));
            return;
        }

        var tracked = shouldTrack(notification);
        if (tracked) {
            notification.tracked = true;
        } else {
            notification.tracked = false;
        }

        root.activeTransientNotification = notification;

        if (!tracked) {
            root.presentationMode = "transient";
            transientTimer.restart();
        } else if (IslandManager.activeIsland && IslandManager.activeIsland.type !== "notification") {
            root.presentationMode = "transient";
            transientTimer.restart();
        } else {
            root.presentationMode = "sticky";
            transientTimer.stop();
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            console.log("New notification received: " + n.summary + " | " + n.body);
            root.receiveNotification(n);
        }
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() {
            if (server.trackedNotifications.values.length === 0) {
                root.presentationMode = "none";
                transientTimer.stop();
            }
        }
    }
}
