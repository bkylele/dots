import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.panels

ShellRoot {
    Scope {
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
