{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  wayland,
  libxkbcommon,
  libei,
}:

stdenv.mkDerivation {
  pname = "hypr-kdeconnect-fix";
  version = "0.1.0-unstable-2026-09-06";

  src = fetchFromGitHub {
    owner = "gfhdhytghd";
    repo = "hypr-kdeconnect-fix";
    rev = "0bc47e676ae2d6964cec4020be9966bbe85985e6";
    hash = "sha256-s8hWpEIyWpwW9w8t80Byqp+8jG0ChddtbDB7eJ/7ebA=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    wayland
    libxkbcommon
    libei
  ];

  doCheck = true;

  meta = {
    description = "RemoteDesktop portal bridge for KDE Connect on Wayland";
    homepage = "https://github.com/gfhdhytghd/hypr-kdeconnect-fix";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
