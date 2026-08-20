import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.panels
import qs.runner

ShellRoot {
    Scope {
        // --- App Runner IPC (singleton, not per-screen) ---
        IpcHandler {
            target: "runner"

            function toggle() {
                for (var i = 0; i < runnerVariants.instances.length; i++) {
                    runnerVariants.instances[i].toggle()
                }
            }
        }

        Variants {
            id: runnerVariants
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
