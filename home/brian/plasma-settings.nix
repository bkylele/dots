{
  lib,
  pkgs,
  theme,
}:
let
  # Preserve the existing activity and panel IDs, without desktop-file history.
  # Qt 6 QFont::toString() form of Segoe UI Regular, as ATP's wizard writes it.
  effects = enabled: ids: lib.genAttrs (map (id: "${id}Enabled") ids) (_: enabled);
  segoe = size: "Segoe UI,${toString size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular";
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
  # AeroThemePlasma appearance. These mirror ATP's authui7 defaults and the
  # settings its first-run wizard writes, so restoring these files each login
  # keeps the theme instead of reverting it. kdeglobals also receives the Aero
  # color scheme's groups in plasma-config.nix.
  kdeglobals = {
    KDE = {
      AnimationDurationFactor = 0.5;
      LookAndFeelPackage = "authui7";
      DefaultLightLookAndFeel = "authui7";
      widgetStyle = "kvantum";
      contrast = 0;
      frameContrast = "0.2";
    };
    General = {
      ColorScheme = "Aero";
      AccentColor = "0,0,0,0";
      accentColorFromWallpaper = false;
      DeviceLedsAccentColored = true;
      XftAntialias = true;
      XftHintStyle = "hintnone";
      XftSubPixel = "rgb";
      TerminalApplication = "kitty";
      TerminalService = "kitty.desktop";
      font = segoe 9;
      menuFont = segoe 9;
      toolBarFont = segoe 9;
      smallestReadableFont = segoe 8;
    };
    # Merged into the color scheme's [WM] group by plasma-config.nix.
    WM.activeFont = segoe 9;
    Icons.Theme = "Windows 7 Aero";
    Sounds.Theme = "Windows 7";
    "KFileDialog Settings" = {
      "Show hidden files" = true;
      "Sort directories first" = true;
      "View Style" = "DetailTree";
    };
  };
  "Kvantum/kvantum.kvconfig".General.theme = "Windows7Aero";
  # Skip ATP's first-run wizard: everything it applies is declared here.
  aerothemeplasmarc.OOTB.wizardRun = true;
  kcminputrc = {
    Keyboard.RepeatDelay = 250;
    Mouse = {
      cursorTheme = "aero-drop";
      cursorSize = 32;
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
    # Equal outer and inner gaps for windows placed in KWin's custom tiles.
    Tiling.padding = 8;
    "Effect-overview" = {
      BorderActivate = 9;
      GridBorderActivate = 7;
      GridTouchBorderActivate = 0;
    };
    # AeroShell effects replace their stock KWin counterparts (as ATP's wizard does).
    Plugins = {
      diminactiveEnabled = true;
      touchpointsEnabled = true;
      wobblywindowsEnabled = true;
    }
    // effects true [
      "aeroglassblur"
      "aeroglide"
      "aeroshell-thumbnails"
      "dimscreenaero"
      "fadingpopupsaero"
      "launchfeedback"
      "minimizeall"
      "slide" # Virtual desktop switch animation.
      "smodglow"
      "smodpeekeffect"
      "smodpeekscript"
      "smodsnap"
      "squashaero"
    ]
    // effects false [
      "blur"
      "contrast"
      "dialogparent"
      "fade"
      "fadingpopups"
      "login"
      "logout"
      "maximize"
      "scale"
      "slidingnotifications"
      "slidingpopups"
      "squash"
      "windowaperture"
    ];
    TouchEdges.Bottom = "ApplicationLauncher";
    Wayland = {
      InputMethod = "${pkgs.maliit-keyboard}/share/applications/com.github.maliit.keyboard.desktop";
      VirtualKeyboardMode = 1; # Show for touch/pen input, not ordinary mouse clicks.
    };
    Xwayland.Scale = 1;
    TabBox = {
      ShowDesktopMode = 1;
      LayoutName = "thumbnail_aero";
    };
    TabBoxAlternative = {
      ShowDesktopMode = 1;
      LayoutName = "flip3d";
    };
    "org.kde.kdecoration2" = {
      library = "org.smod.smod";
      theme = "SMOD";
      ButtonsOnLeft = "M";
      ButtonsOnRight = "H_IAX";
      NoPlugin = false;
    };
  };
  # ATP's default window rules (aeroshell.rules): keep the UAC prompt unminimizable.
  kwinrulesrc = {
    "1" = {
      Description = "POLKIT_RULES";
      clientmachine = "localhost";
      minimizerule = 2;
      wmclass = "(polkit-kde-authentication-agent-1)|(polkit-kde-manager)|(org.kde.polkit-kde-authentication-agent-1)";
      wmclassmatch = 3;
    };
    "2" = {
      Description = "LINVER_RULES";
      clientmachine = "localhost";
      minimizerule = 2;
      wmclass = "linver";
      wmclassmatch = 1;
    };
    General = {
      count = 2;
      rules = "1,2";
    };
  };
  ksmserverrc.General = {
    loginMode = "emptySession";
    confirmLogout = false;
  };
  "plasma-localerc".Formats.LANG = "en_US.UTF-8";
  plasmarc.Theme.name = "Seven-Black";
  ksplashrc.KSplash = {
    Engine = "KSplashQML";
    Theme = "authui7";
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
        "Cycle Overview Opposite"             = "Meta+O,none,Cycle through Grid View and Overview";
        "Edit Tiles"                          = "none,Meta+T,Toggle Tiles Editor";
        "Kill Window"                         = "none,Meta+Ctrl+Esc,Kill Window";
        "Window Close"                        = "Meta+Q,Alt+F4,Close Window";
        "Window One Screen to the Left"       = "Meta+Alt+Shift+H,none,Move Window One Screen to the Left";
        "Window One Screen to the Right"      = "Meta+Alt+Shift+L,none,Move Window One Screen to the Right";
        "Switch One Desktop Down"             = "Meta+J,Meta+Ctrl+Down,Switch One Desktop Down";
        "Switch One Desktop Up"               = "Meta+K,Meta+Ctrl+Up,Switch One Desktop Up";
        "Switch One Desktop to the Left"      = "Meta+H,Meta+Ctrl+Left,Switch One Desktop to the Left";
        "Switch One Desktop to the Right"     = "Meta+L,Meta+Ctrl+Right,Switch One Desktop to the Right";
        "Window One Desktop Down"             = "Meta+Shift+J,Meta+Ctrl+Shift+Down,Window One Desktop Down";
        "Window One Desktop Up"               = "Meta+Shift+K,Meta+Ctrl+Shift+Up,Window One Desktop Up";
        "Window One Desktop to the Left"      = "Meta+Shift+H,Meta+Ctrl+Shift+Left,Window One Desktop to the Left";
        "Window One Desktop to the Right"     = "Meta+Shift+L,Meta+Ctrl+Shift+Right,Window One Desktop to the Right";
        "Window Maximize"                     = "Meta+F,Meta+PgUp,Maximize Window";
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

  # Layout for the stock Plasma session only; AeroShell keeps its own
  # plasma-io.gitgud.wackyideas.desktop-appletsrc, created from ATP's layout.
  "plasma-org.kde.plasma.desktop-appletsrc" = lib.foldl' lib.recursiveUpdate {
    "ActionPlugins][0" = {
      "MiddleButton;NoModifier" = "org.kde.paste";
      "RightButton;NoModifier" = "org.kde.contextmenu";
    };
    "ActionPlugins][1"."RightButton;NoModifier" = "org.kde.contextmenu";
  } (map panelSettings panels);
  # plasmashellrc is not managed: it is shared with AeroShell, which stores its
  # taskbar geometry there, and rewriting it each login would reset that panel.

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
