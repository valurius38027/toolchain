# Debian 13 Qt 6 Offline Toolchain

This repository builds and publishes a Debian 13 (`trixie`) amd64 Qt 6 C++ development environment entirely through GitHub Actions. Large package archives never pass through a ChatGPT container or developer workstation.

## Included development stack

- Qt 6 Core, GUI, Widgets, QML, Quick and Quick Controls
- Qt Quick 3D, Quick 3D Physics and Shader Tools
- SVG, image formats, Multimedia, WebSockets and WebChannel
- WebEngine Widgets and Qt PDF
- Wayland, XCB, OpenGL, Vulkan and software-rendering support
- Qt Creator, Designer, Linguist and Assistant
- GCC, Clang, clangd, clang-tidy, Clazy, CMake, Ninja and ccache
- GDB, LLDB, Valgrind, cppcheck, gcovr and lcov

Private Qt development headers are intentionally excluded.

## CI/CD behavior

Every push affecting the manifest, scripts, smoke project, documentation or release workflow runs:

1. package resolution and offline APT repository construction in `debian:13`;
2. deterministic `tar.zst` packaging;
3. extraction in a second clean `debian:13` container;
4. installation using only the bundled `file:` APT repository;
5. GCC and Clang builds, QtTest, `qmllint`, Widgets startup and QML/Quick 3D startup.

Branch validation uploads a temporary Actions artifact but does not create a Release. The implementation branch is expected to pass this full validation before it is merged.

Production publication is allowed only when:

- a tag matching `qt6-debian13-v*` is pushed; or
- the workflow is manually dispatched with `publish=true` and a valid release tag.

The publish job uploads the archive, checksum, package lock, build metadata and verification report to GitHub Release. It then queries the remote asset list, downloads the archive and checksum again, and verifies SHA-256. A release is not considered valid before this round trip succeeds.

## Release assets

- `qt6-toolchain-debian13-amd64.tar.zst`
- `qt6-toolchain-debian13-amd64.tar.zst.sha256`
- `package-lock.tsv`
- `build-metadata.json`
- `verification-report.txt`

## Offline restore

A target machine must be Debian 13 amd64 and must have `tar` and `zstd` available to extract the archive.

```bash
sha256sum -c qt6-toolchain-debian13-amd64.tar.zst.sha256
tar --zstd -xf qt6-toolchain-debian13-amd64.tar.zst
cd qt6-toolchain-debian13-amd64
sudo bash scripts/install-offline.sh
bash scripts/verify-installed.sh
```

See `docs/RECOVERY.md` for the package-lock and failure-recovery model.
