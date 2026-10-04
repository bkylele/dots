{
  lib,
  pkgs,
  theme,
}:
let
  # Preserve the existing activity and panel IDs, without desktop-file history.
  activity = "3fca704a-42c6-410d-a957-83c07af8f755";
  panels = [
    {
      id = 37;
      screen = 0;
      firstApplet = 38;
      desktop = 35;
    }
    {
      id = 59;
      screen = 1;
      firstApplet = 60;
      desktop = 36;
    }
  ];
  panelSettings =
    panel:
    let
      prefix = "Containments][${toString panel.id}";
      applets = [
        "kickoff"
        "pager"
        "icontasks"
        "systemtray"
        "digitalclock"
        "showdesktop"
      ];
    in
    {
      "Containments][${toString panel.desktop}" = {
        activityId = activity;
        formfactor = 0;
        lastScreen = panel.screen;
        location = 0;
        plugin = "org.kde.plasma.folder";
        wallpaperplugin = "org.kde.image";
      };
      "${prefix}" = {
        formfactor = 2;
        lastScreen = panel.screen;
        location = 4; # Bottom edge.
        plugin = "org.kde.panel";
      };
      "Containments][${toString panel.desktop}][Wallpaper][org.kde.image][General".Image =
        "${theme}/share/wallpapers/Windows7/";
      "${prefix}][General".AppletOrder = lib.concatStringsSep ";" (
        lib.genList (i: toString (panel.firstApplet + i)) (builtins.length applets)
      );
      "${prefix}][Applets][${toString panel.firstApplet}][Configuration][General" = {
        icon = "distributor-logo-window-7";
        systemFavorites = "suspend\\,hibernate\\,reboot\\,shutdown";
      };
    }
    // lib.listToAttrs (
      lib.imap0 (i: applet: {
        name = "${prefix}][Applets][${toString (panel.firstApplet + i)}";
        value.plugin = "org.kde.plasma.${applet}";
      }) applets
    );
in
{
  # Se7enAero assets are captured in plasma-theme.tar.xz and installed by Nix.
  kdeglobals = {
    KDE = {
      AnimationDurationFactor = 0.5;
      LookAndFeelPackage = "Se7enAero";
      DefaultLightLookAndFeel = "Se7enAero";
      widgetStyle = "fusion";
      contrast = 0;
      frameContrast = "0.2";
    };
    General = {
      ColorScheme = "Win7OS";
      DeviceLedsAccentColored = true;
      XftAntialias = true;
      XftHintStyle = "hintnone";
      XftSubPixel = "rgb";
      TerminalApplication = "kitty";
      TerminalService = "kitty.desktop";
    };
    Icons.Theme = "Win11";
    "KFileDialog Settings" = {
      "Show hidden files" = true;
      "Sort directories first" = true;
      "View Style" = "DetailTree";
    };
  };
  kcminputrc = {
    Keyboard.RepeatDelay = 250;
    Mouse = {
      cursorTheme = "Breeze_Light";
      cursorSize = 24;
    };
    "Libinput][1118][2479][Microsoft Surface 045E:09AF Touchpad" = {
      NaturalScroll = true;
      PointerAcceleration = "1.0";
      PointerAccelerationProfile = 1;
    };
  };
  kcmfonts.General.forceFontDPI = 0;
  kwinrc = {
    Input.TabletMode = "auto";
    Desktops = {
      Number = 9;
      Rows = 3;
    };
    "Effect-overview" = {
      BorderActivate = 9;
      GridBorderActivate = 7;
      GridTouchBorderActivate = 0;
    };
    Plugins = {
      diminactiveEnabled = true;
      touchpointsEnabled = true;
      wobblywindowsEnabled = true;
    };
    TouchEdges.Bottom = "ApplicationLauncher";
    Wayland = {
      InputMethod = "${pkgs.maliit-keyboard}/share/applications/com.github.maliit.keyboard.desktop";
      VirtualKeyboardMode = 1; # Show for touch/pen input, not ordinary mouse clicks.
    };
    Xwayland.Scale = 1;
    "org.kde.kdecoration2" = {
      library = "org.kde.kwin.aurorae";
      theme = "__aurorae__svg__Se7enAero";
      NoPlugin = false;
    };
  };
  kwinrulesrc.General.rules = "";
  ksmserverrc.General.loginMode = "emptySession";
  "plasma-localerc".Formats.LANG = "en_US.UTF-8";
  plasmarc.Theme.name = "Se7enAeroStyle";
  ksplashrc.KSplash = {
    Engine = "KSplashQML";
    Theme = "Se7enAero";
  };
  kactivitymanagerdrc = {
    activities.${activity} = "Default";
    main.currentActivity = activity;
  };

  # Only shortcut overrides; KDE supplies unchanged defaults on startup.
  kglobalshortcutsrc = {
    "KDE Keyboard Layout Switcher" = {
      "Switch to Last-Used Keyboard Layout" = "none,Meta+Alt+L,Switch to Last-Used Keyboard Layout";
      "Switch to Next Keyboard Layout" = "none,Meta+Alt+K,Switch to Next Keyboard Layout";
    };
    kaccess."Toggle Screen Reader On and Off" = "none,Meta+Alt+S,Toggle Screen Reader On and Off";
    ksmserver."Lock Session" = "none,Screensaver\\tMeta+L,Lock Session";
    kwin = {
      "Activate Window Demanding Attention" = "none,Meta+Ctrl+A,Activate Window Demanding Attention";
      "Cycle Overview Opposite" = "Meta+O,none,Cycle through Grid View and Overview";
      "Edit Tiles" = "none,Meta+T,Toggle Tiles Editor";
      "Kill Window" = "none,Meta+Ctrl+Esc,Kill Window";
      "Switch One Desktop Down" = "Meta+J,Meta+Ctrl+Down,Switch One Desktop Down";
      "Switch One Desktop Up" = "Meta+K,Meta+Ctrl+Up,Switch One Desktop Up";
      "Switch One Desktop to the Left" = "Meta+H,Meta+Ctrl+Left,Switch One Desktop to the Left";
      "Switch One Desktop to the Right" = "Meta+L,Meta+Ctrl+Right,Switch One Desktop to the Right";
      "Window Close" = "Meta+Q,Alt+F4,Close Window";
      "Window Maximize" = "Meta+F,Meta+PgUp,Maximize Window";
      "Window Custom Quick Tile Bottom" = "Meta+Shift+J,none,Custom Quick Tile Window to the Bottom";
      "Window Custom Quick Tile Left" = "Meta+Shift+H,none,Custom Quick Tile Window to the Left";
      "Window Custom Quick Tile Right" = "Meta+Shift+L,none,Custom Quick Tile Window to the Right";
      "Window Custom Quick Tile Top" = "Meta+Shift+K,none,Custom Quick Tile Window to the Top";
      "Window One Screen to the Left" = "Meta+Alt+Shift+H,none,Move Window One Screen to the Left";
      "Window One Screen to the Right" = "Meta+Alt+Shift+L,none,Move Window One Screen to the Right";
    };
    org_kde_powerdevil.powerProfile = "Battery,Battery\\tMeta+B,Switch Power Profile";
    plasmashell = {
      "activate application launcher" = "Alt+F1,Meta\\tAlt+F1,Activate Application Launcher";
      "manage activities" = "none,Meta+Q,Show Activity Switcher";
      "next activity" = "Meta+A,none,Walk through activities";
      "previous activity" = "Meta+Shift+A,none,Walk through activities (Reverse)";
    };
    "services][firefox.desktop"._launch = "Meta+B";
    "services][kitty.desktop"._launch = "Meta+T";
    "services][org.kde.dolphin.desktop"._launch = "none";
    "services][org.kde.krunner.desktop" = {
      _launch = "Meta+P";
      RunClipboard = "none";
    };
    "services][org.kde.kscreen.desktop".ShowOSD = "none";
    "services][org.kde.plasma.emojier.desktop"._launch = "none";
    "services][systemsettings.desktop"._launch = "none";
    "services][org.kde.spectacle.desktop" = {
      _launch = "none";
      ActiveWindowScreenShot = "none";
      CurrentMonitorScreenShot = "none";
      FullScreenScreenShot = "none";
      OpenWithoutScreenshot = "none";
      RecordRegion = "Meta+Shift+R";
      RecordScreen = "none";
      RecordWindow = "none";
      RectangularRegionScreenShot = "Meta+Shift+S";
      WindowUnderCursorScreenShot = "none";
    };
  };

  "plasma-org.kde.plasma.desktop-appletsrc" = lib.foldl' lib.recursiveUpdate {
    "ActionPlugins][0" = {
      "MiddleButton;NoModifier" = "org.kde.paste";
      "RightButton;NoModifier" = "org.kde.contextmenu";
    };
    "ActionPlugins][1"."RightButton;NoModifier" = "org.kde.contextmenu";
  } (map panelSettings panels);
  plasmashellrc = lib.foldl' lib.recursiveUpdate { } (
    map (panel: {
      "PlasmaViews][Panel ${toString panel.id}" = {
        floating = 1;
        panelVisibility = 1;
        shell = "org.kde.plasma.desktop";
      };
      "PlasmaViews][Panel ${toString panel.id}][Defaults".thickness = 48;
    }) panels
  );

  dolphinrc = {
    "KFileDialog Settings" = {
      "Places Icons Auto-resize" = false;
      "Places Icons Static Size" = 22;
    };
    MainWindow.MenuBar = "Disabled";
  };
  katerc = {
    General = {
      "Days Meta Infos" = 30;
      "Save Meta Infos" = true;
      "Show Full Path in Title" = false;
      "Show Menu Bar" = true;
      "Show Status Bar" = true;
      "Show Tab Bar" = true;
      "Show Url Nav Bar" = true;
    };
    filetree = {
      listMode = false;
      shadingEnabled = true;
      showToolbar = true;
      sortRole = 0;
    };
    lspclient = {
      AutoHover = true;
      AutoImport = true;
      FormatOnSave = false;
      InlayHints = false;
      SemanticHighlighting = true;
    };
  };
  spectaclerc = {
    ImageSave.translatedScreenshotsFolder = "Screenshots";
    VideoSave.translatedScreencastsFolder = "Screencasts";
  };
}
