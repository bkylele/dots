import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    Scope {
        Variants {
            model: Quickshell.screens;
            Dash { }
        }
    }
}
