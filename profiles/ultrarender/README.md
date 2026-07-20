# UltraRender Debian 13 Development SDK

This profile builds and publishes the development environment required by UltraRenderStudio as an immutable GitHub Release. It is separate from the repository's general Qt profile because UltraRenderStudio currently depends on Qt's QRhi private development surface.

## Supported host

- Debian 13 (`trixie`)
- amd64
- root access for package installation
- network access to GitHub for the initial download

The bundle is not supported on Ubuntu, Debian 12, ARM, Windows, or macOS.

## One-command restore

From a checkout of this repository:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest
```

The command resolves the latest published UltraRender SDK release, downloads it into `/var/cache/ultrarender-sdk`, verifies SHA-256, extracts it, installs only from the bundled local APT repository, and runs GCC, Clang, Qt QRhi, Vulkan Lavapipe, GTest, FreeType, HarfBuzz, FlatBuffers, and shader-tool gates.

A successful restore ends with:

```text
VERIFICATION_RESULT=PASS
[ultrarender-sdk] UltraRender SDK <tag> is installed and verified
```

## Rollback and cache control

Install a specific immutable release:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh \
  ultrarender-sdk-debian13-v2026.07.20.1
```

Discard the cached copy and download it again:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest --force
```

Download, verify, and extract without installing:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest --download-only
```

Override the cache location:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest \
  --cache-dir /opt/ultrarender-sdk-cache
```

## Included stack

- GCC, G++, Clang, CMake, Ninja, pkg-config, and Git
- Qt 6 Core, Gui, QPA plugins, private base headers, and QRhi headers
- Vulkan development headers and Mesa Lavapipe CPU Vulkan
- GTest
- FreeType and HarfBuzz
- FlatBuffers library and compiler
- glslang and SPIR-V tools
- Xvfb for headless graphics verification

## Release assets

Each release contains:

```text
ultrarender-dev-sdk-debian13-amd64.tar.zst
ultrarender-dev-sdk-debian13-amd64.tar.zst.sha256
ultrarender-package-lock.tsv
ultrarender-build-metadata.json
ultrarender-verification-report.txt
```

The archive contains a complete local APT repository and a package lock with exact package versions, architectures, filenames, and SHA-256 values. Every bundled `.deb` is checked against that lock before installation. The packages explicitly declared in `packages.txt` must then be installed at their locked versions and architectures. Unused transitive or transitional packages are not forced onto the host, so the SDK does not unnecessarily downgrade the Debian base system.

## Version and publication rules

The version is stored in `profiles/ultrarender/VERSION`. Its format is `YYYY.MM.DD.N`, and the corresponding tag is:

```text
ultrarender-sdk-debian13-v<version>
```

Any change to the profile requires a version bump before it reaches `main`. Existing tags and assets are immutable. The publication workflow refuses to overwrite an existing version.

A release is published only after:

1. the dependency closure is resolved against an empty dpkg state;
2. every bundled package file passes the package-lock integrity check;
3. a second clean Debian 13 container removes external APT sources and installs the required toolchain packages from the bundle alone;
4. required package versions and architectures match the profile lock;
5. GCC and Clang compile and run the SDK smoke target;
6. Lavapipe exposes a CPU Vulkan device;
7. the draft Release assets are uploaded, checked for non-zero size, downloaded back from GitHub, and checksum-verified.

Actions artifacts are temporary transport objects. GitHub Release assets are the authoritative recovery source.
