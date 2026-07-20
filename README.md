# Debian 13 Qt 6 Offline Toolchain

This repository builds and publishes Debian 13 (`trixie`) amd64 C++ development environments entirely through GitHub Actions. Large package archives never need to pass through a ChatGPT container or developer workstation.

## General Qt 6 profile

The general profile includes:

- Qt 6 Core, GUI, Widgets, QML, Quick and Quick Controls
- Qt Quick 3D, Quick 3D Physics and Shader Tools
- SVG, image formats, Multimedia, WebSockets and WebChannel
- WebEngine Widgets and Qt PDF
- Wayland, XCB, OpenGL, Vulkan and software-rendering support
- Qt Creator, Designer, Linguist and Assistant
- GCC, Clang, clangd, clang-tidy, Clazy, CMake, Ninja and ccache
- GDB, LLDB, Valgrind, cppcheck, gcovr and lcov

Private Qt development headers are intentionally excluded from the general profile.

### General-profile CI/CD behavior

Every push affecting the manifest, scripts, smoke project, documentation or release workflow runs:

1. package resolution and offline APT repository construction in `debian:13`;
2. deterministic `tar.zst` packaging;
3. extraction in a second clean `debian:13` container;
4. installation using only the bundled `file:` APT repository;
5. GCC and Clang builds, QtTest, `qmllint`, Widgets startup and QML/Quick 3D startup.

Branch validation uploads a temporary Actions artifact but does not create a Release.

General-profile production publication uses tags matching `qt6-debian13-v*` or an explicit manual publish operation. A release is valid only after the published archive and checksum have been downloaded from GitHub and verified again.

### General-profile offline restore

```bash
sha256sum -c qt6-toolchain-debian13-amd64.tar.zst.sha256
tar --zstd -xf qt6-toolchain-debian13-amd64.tar.zst
cd qt6-toolchain-debian13-amd64
sudo bash scripts/install-offline.sh
bash scripts/verify-installed.sh
```

See `docs/RECOVERY.md` for the general package-lock and failure-recovery model.

## UltraRender development profile

UltraRenderStudio requires Qt's QRhi development surface, so it has a separate profile under `profiles/ultrarender`. This profile includes Qt private base headers, Vulkan/Lavapipe, GTest, FreeType, HarfBuzz, FlatBuffers, and the shader toolchain without changing the general profile's dependency policy.

Restore the latest persistent SDK Release after a host reset:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest
```

Install a known version for deterministic rollback:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh \
  ultrarender-sdk-debian13-v2026.07.20.1
```

The UltraRender workflow resolves dependencies against an empty dpkg state, restores in a second clean Debian 13 container with external APT sources removed, compiles the smoke target with GCC and Clang, enumerates a Lavapipe CPU Vulkan device, and performs a remote Release round-trip checksum gate.

See `profiles/ultrarender/README.md` for cache, rollback, versioning, and publication details.
