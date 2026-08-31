# Quickshell Project Briefing

This project is a custom Wayland shell written in QML using the Quickshell framework. The entry point is `shell.qml`.

## Directory Structure

```
quickshell/
├── shell.qml                    # Entry point — instantiates all panels per screen
├── panels/                      # One file per edge-spawned panel
│   ├── TopPanel.qml             # Hover-blob preview + expandable dashboard circle
│   ├── BottomPanel.qml          # Stub (visible: false)
│   ├── LeftPanel.qml            # Stub (visible: false)
│   └── RightPanel.qml           # Stub (visible: false)
├── dashboard/                   # Everything inside the expanded dashboard circle
│   ├── DashboardMenu.qml        # Data-driven tab container (Component list + Loader)
│   └── tabs/                    # One file per tab
│       ├── ClockCalendarTab.qml  # Tab 0: dot-clock + calendar
│       └── SystemStatusTab.qml  # Tab 1: CPU/Mem/Temp bars + uptime
└── widgets/                     # Shared, reusable leaf components
    ├── Calendar.qml             # Sliding month calendar
    ├── DotClock.qml             # Stylized dot-ring clock
    ├── CpuMonitor.qml           # CPU usage bar
    ├── MemoryMonitor.qml        # Memory usage bar
    └── TemperatureMonitor.qml   # Temperature bar with color thresholds
```

## Core Components

### 1. Top Panel (`panels/TopPanel.qml`)
- **Dual Mode**: Features a "top-pill" preview (clock/battery) that drops down on hover and a "blow-up" circular dashboard (650x650) triggered by a right-click.
- **Sequential Animations**: Critical for visual polish. Content must fade out (`opacity: 0`) *before* the panel moves or resizes to prevent text from "floating" outside the window boundaries.
- **External Navigation Icons**: When expanded, two small grey icon buttons appear outside the circle at the NW (top-left, 45°) and NE (top-right, 45°) positions. They show the icon of the tab you'd navigate to (e.g., ⏰ for ClockCalendar, 💻 for SystemStatus). NW = previous tab, NE = next tab. Icons subtly brighten on hover.
- **Focus & Interaction**: The window uses the `focusable` property to capture the **Escape** key to hide. Clicks outside the central circle are caught by a full-screen `backgroundDim` to close the dashboard.

### 2. Dashboard Menu (`dashboard/DashboardMenu.qml`)
- **Data-Driven Tab System**: Tabs are declared as a `list<Component>`. To add a tab, append one line to the list. The `Loader` handles instantiation and the modulus-based navigation auto-adapts.
- **Fade Transitions**: Tab switching uses a quick `SequentialAnimation` (fade out 100ms -> swap index -> fade in 100ms) for a snappy "blink" effect.
- **Shared Clock**: A 1-second timer provides `now` to any tab that declares a `property var now`.

### 3. Dashboard Tabs (`dashboard/tabs/`)
- **ClockCalendarTab**: Stylized dot-clock widget and a prominent calendar. Exposes `reset()` to return the calendar to the current month.
- **SystemStatusTab**: System resource monitors (CPU, Memory, Temperature) and uptime. Self-contained with its own uptime process.
- **Adding a Tab**: Create `dashboard/tabs/MyNewTab.qml` as an `Item`, then add `Component { MyNewTab {} }` to the `tabs` list in `DashboardMenu.qml`.

### 4. Widgets (`widgets/`)
- **DotClock**: Accepts a `now` property — the parent controls the timer. Renders hour/minute text surrounded by 60 animated dot indicators for seconds.
- **CpuMonitor, MemoryMonitor, TemperatureMonitor**: Minimalist vertical bars with a fixed **4px thickness**. Layout-agnostic (no `Layout.*` properties on root). Data sourced from `top`, `free`, and `/sys/class/thermal/thermal_zone0/temp` respectively.
- **Calendar**: Stationary header (Month/Year and arrows) with a sliding `ListView` date grid. **250ms** move duration.

### 5. Panel Stubs (`panels/Bottom|Left|Right`)
- Invisible (`visible: false`) PanelWindows anchored to their respective edges. Ready to be implemented with their own content and hover triggers.

## Engineering Standards
- **Validation**: Always verify changes using `qs log`. Check for QML syntax errors and JavaScript `ReferenceError`s.
- **Modern QML**: Use formal parameters in signal handlers (e.g., `onClicked: function(mouse) { ... }`) to avoid deprecation warnings.
- **Anti-Aliasing**: For custom `Shape` elements (like arcs), ensure `layer.enabled: true` and `layer.samples: 4` are set to match the smoothness of native QML rectangles.
- **Imports**: Use `import qs.<path>` for subdirectory imports (e.g., `import qs.widgets`, `import qs.panels`).
