{ lib
, pkgs
, stdenv
, qtbase
, wrapQtAppsHook
, ...
}:
let
  pname = "multipass";
  version = "1.11.0";
in
stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchFromGitHub {
    owner = "canonical";
    repo = "multipass";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-2d8piIIecoSI3BfOgAVlXl5P2UYDaNlxUgHXWbnSdkg=";
    fetchSubmodules = true;
  };

  preConfigure = ''
    substituteInPlace ./CMakeLists.txt \
      --replace "determine_version(MULTIPASS_VERSION)" "" \
      --replace 'set(MULTIPASS_VERSION ''${MULTIPASS_VERSION})' 'set(MULTIPASS_VERSION "v${version}")'

    substituteInPlace ./src/platform/backends/qemu/linux/qemu_platform_detail_linux.cpp \
      --replace "OVMF.fd" "${pkgs.OVMF.fd}/FV/OVMF.fd" \
      --replace "QEMU_EFI.fd" "${pkgs.OVMF.fd}/FV/QEMU_EFI.fd"
  '';

  postPatch = ''
    # Patch all of the places where Multipass expects the LXD socket to be provided by a snap
    substituteInPlace ./src/network/network_access_manager.cpp \
      --replace "/var/snap/lxd/common/lxd/unix.socket" "/var/lib/lxd/unix.socket"

    substituteInPlace ./src/platform/backends/lxd/lxd_virtual_machine.cpp \
      --replace "/var/snap/lxd/common/lxd/unix.socket" "/var/lib/lxd/unix.socket"

    substituteInPlace ./src/platform/backends/lxd/lxd_request.h \
      --replace "/var/snap/lxd/common/lxd/unix.socket" "/var/lib/lxd/unix.socket"

    substituteInPlace ./tests/CMakeLists.txt \
      --replace "FetchContent_MakeAvailable(googletest)" ""

    cat >> tests/CMakeLists.txt <<'EOF'
      add_library(gtest INTERFACE)
      target_include_directories(gtest INTERFACE ${pkgs.gtest.dev}/include)
      target_link_libraries(gtest INTERFACE ${pkgs.gtest}/lib/libgtest.so ''${CMAKE_THREAD_LIBS_INIT})
      add_dependencies(gtest GMock)

      add_library(gtest_main INTERFACE)
      target_include_directories(gtest_main INTERFACE ${pkgs.gtest.dev}/include)
      target_link_libraries(gtest_main INTERFACE ${pkgs.gtest}/lib/libgtest_main.so gtest)

      add_library(gmock INTERFACE)
      target_include_directories(gmock INTERFACE ${pkgs.gtest.dev}/include)
      target_link_libraries(gmock INTERFACE ${pkgs.gtest}/lib/libgmock.so gtest)

      add_library(gmock_main INTERFACE)
      target_include_directories(gmock_main INTERFACE ${pkgs.gtest.dev}/include)
      target_link_libraries(gmock_main INTERFACE ${pkgs.gtest}/lib/libgmock_main.so gmock gtest_main)
    EOF
  '';

  buildInputs =
    [ qtbase ]
    ++ (with pkgs; [
      gtest
      libapparmor
      libsForQt5.qt5.qtx11extras
      libvirt
      libxml2
      openssl
    ]);

  nativeBuildInputs =
    [ wrapQtAppsHook ]
    ++ (with pkgs; [
      cmake
      git
      pkg-config
      slang
    ]);

  nativeCheckInputs = [ pkgs.gtest ];

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
    description = "Ubuntu VMs on demand for any workstation.";
    homepage = "https://multipass.run";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ jnsgruk ];
    platforms = [ "x86_64-linux" ];
  };
}
