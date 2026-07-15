# Qt 6 Debian 13 Offline Toolchain Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, restore-test, and publish a self-contained Debian 13 amd64 Qt 6 development toolchain through GitHub Actions without uploading large files from a developer machine.

**Architecture:** A build job runs in a clean `debian:13` container, resolves the declared package set, downloads the dependency closure, creates a local APT repository, and emits a deterministic `tar.zst`. A second clean Debian 13 job installs only from that archive and runs compiler, Qt, QML, and headless GUI gates. A publish job runs only for explicit release triggers, uploads verified assets to GitHub Release, downloads them again, and checks SHA-256.

**Tech Stack:** GitHub Actions, Debian 13 APT/dpkg, Bash, CMake, Ninja, Qt 6.8.x, GCC, Clang, Xvfb, Zstandard, GitHub CLI.

## Global Constraints

- Target platform is Debian 13 (`trixie`) amd64.
- Private Qt headers are excluded.
- Generated `.deb` files and archives are never committed to Git.
- Normal branch pushes build and restore-test but do not publish a Release.
- Publication requires `workflow_dispatch` with `publish=true` or a tag matching `qt6-debian13-v*`.
- Any dependency, integrity, build, test, headless-startup, upload, or remote-round-trip failure blocks publication.
- Published Release assets are the authoritative recovery artifacts.

---

### Task 1: Package Manifest and Offline Repository Builder

**Files:**
- Create: `manifests/qt6-debian13-packages.txt`
- Create: `scripts/build-offline-repo.sh`
- Create: `scripts/package-release.sh`
- Create: `scripts/lib/common.sh`

**Interfaces:**
- Consumes: newline-delimited package names from `manifests/qt6-debian13-packages.txt`.
- Produces: `out/release-root/repo/Packages.gz`, `out/package-lock.tsv`, `out/build-metadata.json`, and `out/qt6-toolchain-debian13-amd64.tar.zst`.

- [ ] Validate every manifest entry with `apt-cache show` and reject duplicates.
- [ ] Download the complete dependency closure into an isolated APT archive directory with `--no-install-recommends`.
- [ ] Validate every `.deb` using `dpkg-deb --info` and generate a unique `Package/Version/Architecture` lock file.
- [ ] Generate `Packages` and `Packages.gz` with `dpkg-scanpackages`.
- [ ] Package repository, scripts, smoke project, lock file, metadata, and licenses into a deterministic Zstandard archive.
- [ ] Generate archive SHA-256 and verify the archive stream with `zstd --test`.

**Test command:**

```bash
bash -n scripts/lib/common.sh scripts/build-offline-repo.sh scripts/package-release.sh
shellcheck scripts/lib/common.sh scripts/build-offline-repo.sh scripts/package-release.sh
```

Expected: exit code 0 and no ShellCheck errors.

### Task 2: Offline Installer and Smoke-Test Project

**Files:**
- Create: `scripts/install-offline.sh`
- Create: `scripts/verify-installed.sh`
- Create: `smoke/CMakeLists.txt`
- Create: `smoke/src/main.cpp`
- Create: `smoke/src/widget_window.cpp`
- Create: `smoke/src/widget_window.h`
- Create: `smoke/src/smoke_test.cpp`
- Create: `smoke/qml/Main.qml`
- Create: `smoke/qml/Quick3DScene.qml`

**Interfaces:**
- Consumes: extracted release root with `repo/`, `manifests/`, `package-lock.tsv`, and `smoke/`.
- Produces: installed toolchain, GCC and Clang build directories, QtTest XML/text output, QML lint output, and `verification-report.txt`.

- [ ] Configure APT to use only the bundled trusted file repository.
- [ ] Install the declared package set with `--no-install-recommends` and verify locked versions.
- [ ] Configure and build the smoke project with GCC and Clang.
- [ ] Run QtTest and `qmllint`.
- [ ] Run Widgets and QML/Quick 3D startup under Xvfb with Mesa software rendering and bounded timeouts.
- [ ] Record exact Qt, compiler, CMake, Ninja, QML, OpenGL, and test results.

**Test command:**

```bash
cmake -S smoke -B build-gcc -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-gcc
ctest --test-dir build-gcc --output-on-failure
```

Expected: configure/build succeeds and all tests pass.

### Task 3: GitHub Actions Build, Restore, and Publish Pipeline

**Files:**
- Replace: `.github/workflows/release-upload-probe.yml`
- Create: `.github/workflows/qt6-debian13-release.yml`

**Interfaces:**
- Consumes: repository scripts, package manifest, smoke project, release tag or manual inputs.
- Produces: Actions artifact for branch validation and GitHub Release assets for production triggers.

- [ ] Run build and restore jobs in independent `debian:13` containers.
- [ ] Pass the archive only through `actions/upload-artifact` and `actions/download-artifact`.
- [ ] Disable external APT sources before the offline installation test.
- [ ] Gate the publish job on successful restore verification and explicit release trigger.
- [ ] Create or update the selected GitHub Release with archive, checksum, lock, metadata, and verification report.
- [ ] Query Release assets, reject missing or zero-byte assets, download archive and checksum, and verify SHA-256.
- [ ] Pin third-party actions to immutable commit SHAs.

**Validation:** Push to the implementation branch and inspect the resulting workflow run. Expected: build and restore jobs succeed; publish job is skipped.

### Task 4: Documentation and Production Release Gate

**Files:**
- Create: `README.md`
- Create: `docs/RECOVERY.md`
- Modify: `docs/superpowers/specs/2026-07-14-qt6-debian13-release-design.md`

**Interfaces:**
- Consumes: final workflow inputs and generated asset names.
- Produces: operator instructions for build, explicit release, offline restore, verification, and failure recovery.

- [ ] Document branch validation, manual dispatch, tag release, asset layout, checksum verification, and offline installation.
- [ ] Document the `zstd` extraction prerequisite and Debian 13 amd64 boundary.
- [ ] Document that a Release is valid only after remote re-download verification succeeds.
- [ ] Trigger a production release using `qt6-debian13-vYYYY.MM.DD.N`.
- [ ] Confirm the Release remains downloadable independently of the Actions runner.

**Acceptance command:**

```bash
gh release download "$TAG" --repo valurius38027/toolchain --dir verify-download
cd verify-download
sha256sum -c qt6-toolchain-debian13-amd64.tar.zst.sha256
```

Expected: every expected asset exists and checksum verification reports `OK`.
