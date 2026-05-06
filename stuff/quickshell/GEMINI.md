# Quickshell Project Briefing

This project is a custom Wayland shell written in QML using the Quickshell framework. The entry point is `shell.qml`.

## Core Components

### 1. Dashboard (`Dash.qml`)
- **Dual Mode**: Features a "top-pill" preview (clock/battery) that drops down on hover and a "blow-up" circular dashboard (650x650) triggered by a right-click.
- **Sequential Animations**: Critical for visual polish. Content must fade out (`opacity: 0`) *before* the panel moves or resizes to prevent text from "floating" outside the window boundaries. 
- **Integrated Navigation**: The far left and right edges (80px) of the expanded circle act as invisible buttons for cycling through tabs. They show a subtle grey overlay (`#15000000`) and arrows only on hover.
- **Focus & Interaction**: The window uses the `focusable` property to capture the **Escape** key to hide. Clicks outside the central circle are caught by a full-screen `backgroundDim` to close the dashboard.

### 2. Dashboard Menu (`DashMenu.qml`)
- **Tab System**: Cyclical navigation between multiple views.
    - **Tab 0**: Stylized dot-clock and a prominent calendar.
    - **Tab 1**: System resource monitors and uptime.
- **Fade Transitions**: Tab switching uses a quick `SequentialAnimation` (fade out 100ms -> swap index -> fade in 100ms) for a snappy "blink" effect.

### 3. Resource Monitors (`CPU.qml`, `Memory.qml`, `Temperature.qml`)
- **Design**: Minimalist vertical bars with a fixed **4px thickness**.
- **Data Sources (NixOS Optimized)**:
    - **CPU**: Parsed from `top`.
    - **Memory**: Parsed from `free`.
    - **Temperature**: Sourced directly from `/sys/class/thermal/thermal_zone0/temp`.
    - **Uptime**: Sourced from `/proc/uptime` and formatted into "Xh Ym".

### 4. Calendar (`Calendar.qml`)
- **Layout**: Features a stationary header (Month/Year and arrows) while only the date grid slides horizontally.
- **Animations**: Grid transitions use a `ListView` with a **250ms** move duration.
- **Interactivity**: Clicking "Month Year" resets to the current month. The grid automatically resets when the dashboard is hidden.

## Engineering Standards
- **Validation**: Always verify changes using `qs log`. Check for QML syntax errors and JavaScript `ReferenceError`s.
- **Modern QML**: Use formal parameters in signal handlers (e.g., `onClicked: function(mouse) { ... }`) to avoid deprecation warnings.
- **Anti-Aliasing**: For custom `Shape` elements (like arcs), ensure `layer.enabled: true` and `layer.samples: 4` are set to match the smoothness of native QML rectangles.
