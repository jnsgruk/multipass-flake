{
  lib,
  pkgs,
  stdenv,
  qtbase,
  wrapQtAppsHook,
  ...
}: let
  pname = "multipass";
  version = "1.11.0";
in
  stdenv.mkDerivation {
    name = "${pname}-${version}";

    src = pkgs.fetchFromGitHub {
      owner = "canonical";
      repo = "multipass";
      rev = "refs/tags/v${version}";
      sha256 = "sha256-m9Oh3izZswgBQnAEbD9ZB3x6T2akuYR34ARivar4A5Q=";
      fetchSubmodules = true;
      leaveDotGit = true;
    };

    preConfigure = ''
      substituteInPlace ./CMakeLists.txt \
        --replace "determine_version(MULTIPASS_VERSION)" "" \
        --replace "set(MULTIPASS_VERSION ''${MULTIPASS_VERSION})" "set(MULTIPASS_VERSION v${version})"

      substituteInPlace ./src/platform/backends/qemu/linux/qemu_platform_detail_linux.cpp \
        --replace "OVMF.fd" "${pkgs.OVMF.fd}/FV/OVMF.fd"
    '';

    buildInputs =
      [qtbase]
      ++ (with pkgs; [
        libapparmor
        libsForQt5.qt5.qtx11extras
        libvirt
        libxml2
        openssl
      ]);

    nativeBuildInputs =
      (with pkgs; [
        cmake
        git
        pkg-config
        slang
      ])
      ++ [wrapQtAppsHook];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DMULTIPASS_ENABLE_TESTS=off"
    ];

    postInstall = ''
      wrapProgram $out/bin/multipassd --prefix PATH : ${lib.makeBinPath (with pkgs; [
        dnsmasq
        iproute2
        iptables
        OVMF.fd
        qemu
        qemu-utils
        xterm
      ])}

    '';

    meta = with lib; {
      description = "Multipass orchestrates virtual Ubuntu instances";
      homepage = https://multipass.run;
      license = licenses.gpl3;
      maintainers = with maintainers; [jnsgruk];
      platforms = with platforms; linux;
    };
  }
