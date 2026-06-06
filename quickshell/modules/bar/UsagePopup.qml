import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"

Rectangle {
    id: root
    anchors.fill: parent
    color: Theme.bg
    border.color: Theme.border
    border.width: Theme.borderWidth
    radius: Theme.radius

    function usageColor(pct) {
        if (pct >= 90) return Theme.red;
        if (pct >= 70) return Theme.yellow;
        return Theme.green;
    }

    function formatWindow(w) {
        if (!w) return "";
        var pct = Math.round(w.usedPercent);
        var desc = w.resetDescription || "";
        return pct + "%" + (desc ? " · " + desc : "");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "AI Usage"
                font.pixelSize: Theme.fontSizeLarge
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: UsageTrackingService.isLoading ? "Loading..." : ""
                role: "fgDim"
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // Provider list
        Repeater {
            model: UsageTrackingService.providerNames

            ColumnLayout {
                id: providerCol
                Layout.fillWidth: true
                spacing: 6
                required property var modelData
                required property int index

                // Provider header
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: {
                            var d = UsageTrackingService.usageData[providerCol.modelData];
                            return d ? d.displayName || providerCol.modelData : providerCol.modelData;
                        }
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: {
                            var d = UsageTrackingService.usageData[providerCol.modelData];
                            if (!d || !d.identity) return "";
                            return d.identity.plan || "";
                        }
                        role: "fgDim"
                        font.pixelSize: 11
                    }
                }

                // Error display
                StyledText {
                    Layout.fillWidth: true
                    text: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.error ? d.error : "";
                    }
                    role: "red"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && !!d.error;
                    }
                }

                // Primary window
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.primary !== null && d.primary !== undefined && !d.error;
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.primary && d.primary.name ? d.primary.name : "Rate";
                            }
                            role: "fgDim"
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.primary ? root.formatWindow(d.primary) : "";
                            }
                            font.pixelSize: 11
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.primary ? root.usageColor(d.primary.usedPercent) : Theme.fg;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

                        Rectangle {
                            width: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                var pct = d && d.primary ? d.primary.usedPercent / 100 : 0;
                                return parent.width * Math.min(pct, 1);
                            }
                            height: parent.height
                            radius: parent.radius
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.primary ? root.usageColor(d.primary.usedPercent) : Theme.green;
                            }
                        }
                    }
                }

                // Secondary window
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.secondary !== null && d.secondary !== undefined && !d.error;
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.secondary && d.secondary.name ? d.secondary.name : "Weekly";
                            }
                            role: "fgDim"
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.secondary ? root.formatWindow(d.secondary) : "";
                            }
                            font.pixelSize: 11
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.secondary ? root.usageColor(d.secondary.usedPercent) : Theme.fg;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

                        Rectangle {
                            width: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                var pct = d && d.secondary ? d.secondary.usedPercent / 100 : 0;
                                return parent.width * Math.min(pct, 1);
                            }
                            height: parent.height
                            radius: parent.radius
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.secondary ? root.usageColor(d.secondary.usedPercent) : Theme.green;
                            }
                        }
                    }
                }

                // Tertiary window (Claude opus/sonnet)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.tertiary !== null && d.tertiary !== undefined && !d.error;
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.tertiary && d.tertiary.name ? d.tertiary.name : "Opus";
                            }
                            role: "fgDim"
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.tertiary ? root.formatWindow(d.tertiary) : "";
                            }
                            font.pixelSize: 11
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.tertiary ? root.usageColor(d.tertiary.usedPercent) : Theme.fg;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)

                        Rectangle {
                            width: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                var pct = d && d.tertiary ? d.tertiary.usedPercent / 100 : 0;
                                return parent.width * Math.min(pct, 1);
                            }
                            height: parent.height
                            radius: parent.radius
                            color: {
                                var d = UsageTrackingService.usageData[providerCol.modelData];
                                return d && d.tertiary ? root.usageColor(d.tertiary.usedPercent) : Theme.green;
                            }
                        }
                    }
                }

                // Credits / balance
                RowLayout {
                    Layout.fillWidth: true
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.credits !== null && d.credits !== undefined && !d.error;
                    }

                    StyledText {
                        text: "Balance"
                        role: "fgDim"
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: {
                            var d = UsageTrackingService.usageData[providerCol.modelData];
                            if (!d || !d.credits) return "";
                            var c = d.credits;
                            var sym = c.currency === "USD" ? "$" : c.currency + " ";
                            return sym + c.remaining.toFixed(2);
                        }
                        font.pixelSize: 11
                        color: {
                            var d = UsageTrackingService.usageData[providerCol.modelData];
                            if (!d || !d.credits) return Theme.fg;
                            return d.credits.remaining < 5 ? Theme.red : Theme.green;
                        }
                    }
                }

                // Extra rate windows (Antigravity model quotas)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: {
                        var d = UsageTrackingService.usageData[providerCol.modelData];
                        return d && d.extraRateWindows && d.extraRateWindows.length > 0 && !d.error;
                    }

                    StyledText {
                        text: "Models"
                        role: "fgDim"
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: {
                            var d = UsageTrackingService.usageData[providerCol.modelData];
                            return d && d.extraRateWindows ? d.extraRateWindows : [];
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            required property var modelData

                            StyledText {
                                text: modelData.name || ""
                                role: "fgDim"
                                font.pixelSize: 10
                            }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: {
                                    var pct = Math.round(modelData.usedPercent || 0);
                                    var desc = modelData.resetDescription || "";
                                    return pct + "%" + (desc ? " · " + desc : "");
                                }
                                font.pixelSize: 10
                                color: root.usageColor(modelData.usedPercent || 0)
                            }
                        }
                    }
                }

                // Divider between providers
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                    visible: providerCol.index < UsageTrackingService.providerNames.length - 1
                }
            }
        }

        // Empty state
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "No providers configured"
            role: "fgDim"
            visible: UsageTrackingService.providerNames.length === 0 && !UsageTrackingService.isLoading
        }

        Item { Layout.fillHeight: true }
    }
}
