# Persistent UltraRender SDK Release Design

## Goal

Provide a durable, reproducible Debian 13 amd64 development environment for UltraRenderStudio that can be restored after host cleanup with one repository command, without re-resolving Qt, Vulkan, compiler, testing, font, FlatBuffers, or shader-tool dependencies by hand.

## Scope

The profile is intentionally separate from the repository's general Qt 6 toolchain. The general profile continues to exclude Qt private headers. The UltraRender profile includes `qt6-base-private-dev` because the current Studio source uses QRhi.

The supported target is Debian 13 (`trixie`) amd64. The archive is not a relocatable cross-distribution SDK and is not supported on Ubuntu, Debian 12, ARM, Windows, or macOS.

## Repository Layout

```text
profiles/ultrarender/
├── VERSION
├── README.md
├── packages.txt
├── scripts/
│   ├── build-offline-repo.sh
│   ├── install-offline.sh
│   ├── package-release.sh
│   ├── restore.sh
│   ├── verify-installed.sh
│   └── lib/common.sh
└── smoke/
    ├── CMakeLists.txt
    └── main.cpp

.github/workflows/ultrarender-debian13-release.yml
```

## Package and Integrity Model

The build job resolves the package graph against an empty dpkg status database. This is required because resolving against the GitHub runner's installed state omits dependencies that exist on the runner but may be absent or older on the restored host.

The bundle contains:

- a flat local APT repository with the complete non-recommended dependency closure;
- `Packages` and `Packages.gz` indexes;
- the requested package manifest;
- a package lock recording package name, exact version, architecture, filename, and SHA-256;
- installation and verification scripts;
- a CMake smoke project;
- deterministic build metadata.

The archive is produced with sorted entries, fixed ownership, and `SOURCE_DATE_EPOCH` derived from the source commit. A SHA-256 file is generated and checked before upload.

## Required Development Stack

The profile includes:

- GCC, G++, Clang, CMake, Ninja, pkg-config, and Git;
- Qt 6 Core and Gui development files;
- Qt 6 private base headers and QPA plugins;
- Vulkan loader headers, Mesa Lavapipe, and `vulkaninfo`;
- GTest;
- FreeType and HarfBuzz development files;
- FlatBuffers library and compiler;
- glslang and SPIR-V tools;
- Xvfb and X authentication utilities.

## Verification Gates

A second clean Debian 13 container downloads the generated build artifact, verifies its checksum, removes external APT sources and cached indexes, and installs only through the bundled `file:` repository.

Verification must prove:

1. package versions and architectures exactly match the package lock;
2. Qt 6 Core, Gui, and `Qt6::GuiPrivate` are discoverable by CMake;
3. `<rhi/qrhi.h>` compiles through the private Qt target;
4. Vulkan headers and loader are discoverable;
5. GTest, FreeType, HarfBuzz, and FlatBuffers are discoverable;
6. the smoke target builds with GCC and Clang;
7. Lavapipe enumerates a CPU Vulkan device under Xvfb;
8. the verification report ends with `VERIFICATION_RESULT=PASS`.

## Persistent Release Model

The authoritative artifacts live in a GitHub Release, not an Actions artifact. Actions artifacts are temporary and are used only to transfer files between jobs.

The version is stored in `profiles/ultrarender/VERSION` using `YYYY.MM.DD.N`. The release tag is:

```text
ultrarender-sdk-debian13-v<version>
```

The release contains:

```text
ultrarender-dev-sdk-debian13-amd64.tar.zst
ultrarender-dev-sdk-debian13-amd64.tar.zst.sha256
ultrarender-package-lock.tsv
ultrarender-build-metadata.json
ultrarender-verification-report.txt
```

A main-branch change affecting the UltraRender profile triggers validation and publication. If the release tag already exists while profile content changed, publication fails and requires a version bump. This prevents silently replacing immutable assets.

The publish job creates a draft release, uploads all assets, checks every remote asset is non-empty, downloads the archive and checksum back from GitHub, verifies SHA-256, and only then publishes the release. Any failure deletes the draft release.

## Restore Interface

From a checkout of the toolchain repository:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest
```

The script accepts `latest` or an explicit release tag. It downloads into a versioned cache, verifies the checksum, extracts the bundle, installs through the local APT repository, and runs the verification gates. Existing verified downloads are reused. `--force` discards the cached copy and repeats the operation.

The script prefers GitHub CLI and falls back to the public GitHub REST API through `curl`. It fails closed if the tag, assets, checksum, platform, architecture, package lock, or verification result is invalid.

## Failure and Recovery Rules

- Missing dependencies fail package construction.
- Missing or duplicate manifest entries fail linting.
- A partial offline dependency graph fails the clean-container restore job.
- Any compiler, CMake, QRhi, Vulkan, package-lock, or checksum failure blocks publication.
- Existing release tags are immutable and cannot be overwritten.
- Operators recover by selecting a known release tag; rebuilding an old version from current Debian mirrors is not considered equivalent to downloading the original release assets.
