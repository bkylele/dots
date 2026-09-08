import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.notifications
import qs.panels
import qs.runner

ShellRoot {
    Scope {
        NotificationServer {
            id: notificationServer
            keepOnReload: true
            persistenceSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: true
            bodyImagesSupported: true
            actionsSupported: true
            actionIconsSupported: true
            imageSupported: true
            inlineReplySupported: true

            onNotification: function(notification) {
                notification.tracked = true
            }
        }

        NotificationPopup {
            // Change to top-left, bottom-right, or bottom-left as desired.
            location: "top-right"
            screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
            notificationModel: notificationServer.trackedNotifications
        }

        // --- App Runner IPC (singleton, not per-screen) ---
        // RunnerState decides which screen the runner appears on; the per-screen
        // AppRunner instances just follow it.
        IpcHandler {
            target: "runner"

            function toggle(): void {
                RunnerState.toggle()
            }

            function hide(): void {
                RunnerState.hide()
            }
        }

        Variants {
            model: Quickshell.screens;
            AppRunner { }
        }
        Variants {
            model: Quickshell.screens;
            TopPanel { }
        }
        Variants {
            model: Quickshell.screens;
            BottomPanel { }
        }
        Variants {
            model: Quickshell.screens;
            LeftPanel { }
        }
        Variants {
            model: Quickshell.screens;
            RightPanel { }
        }
    }
}
