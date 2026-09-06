import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.panels
import qs.runner

ShellRoot {
    Scope {
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
