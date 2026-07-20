# Persistent UltraRender SDK Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a self-contained UltraRender development profile that builds, restore-tests, publishes, downloads, installs, and verifies a durable Debian 13 amd64 SDK.

**Architecture:** Profile-specific manifests, scripts, and smoke sources live under `profiles/ultrarender` and do not alter the general Qt profile. A GitHub Actions pipeline resolves the complete package closure against an empty dpkg state, restores it in a second clean container with no external APT sources, and publishes immutable Release assets only after remote round-trip verification.

**Tech Stack:** Bash, Debian 13 APT/dpkg, GitHub Actions, GitHub CLI, CMake, Ninja, GCC, Clang, Qt 6 GuiPrivate/QRhi, Vulkan/Lavapipe, GTest, FreeType, HarfBuzz, FlatBuffers, Zstandard.

## Global Constraints

- Target platform is Debian 13 (`trixie`) amd64.
- UltraRender is a separate profile; the general Qt profile continues to exclude Qt private headers.
- Package resolution uses an empty dpkg status database.
- External APT sources are removed before restore verification.
- Every bundled `.deb` is integrity-checked, while required manifest packages are version- and architecture-checked without forcing unused transitive packages onto the base OS.
- Release assets are immutable and must not be overwritten.
- The release version is read from `profiles/ultrarender/VERSION` and must match `YYYY.MM.DD.N`.
- Publication requires all build, restore, compiler, QRhi, Vulkan, package-lock, required-package, and remote checksum gates to pass.

---

### Task 1: Profile Manifest and Common Utilities

**Files:**
- Create: `profiles/ultrarender/VERSION`
- Create: `profiles/ultrarender/packages.txt`
- Create: `profiles/ultrarender/scripts/lib/common.sh`

**Interfaces:**
- Consumes: Debian package names and the version file.
- Produces: `manifest_packages`, `profile_root`, `repo_root`, `require_command`, `require_root`, `fail`, `log`, and SHA-256 helpers used by every profile script.

- [ ] Add version `2026.07.20.1` and the exact package manifest from the approved design.
- [ ] Add common Bash helpers with the log prefix `[ultrarender-sdk]`.
- [ ] Validate Bash syntax and reject duplicate manifest entries.

### Task 2: Deterministic Offline Repository and Archive

**Files:**
- Create: `profiles/ultrarender/scripts/build-offline-repo.sh`
- Create: `profiles/ultrarender/scripts/package-release.sh`

**Interfaces:**
- Consumes: `packages.txt`, `VERSION`, `GITHUB_SHA`, and `SOURCE_DATE_EPOCH`.
- Produces: `out/ultrarender/release-root/repo`, `ultrarender-package-lock.tsv`, `ultrarender-build-metadata.json`, archive, and checksum.

- [ ] Resolve the complete dependency graph with `Dir::State::status` pointing to an empty file.
- [ ] Validate each `.deb`, architecture, package identity, and SHA-256.
- [ ] Generate the local APT indexes.
- [ ] Assemble a deterministic `tar.zst` containing the repository, scripts, smoke project, manifest, lock, metadata, and profile documentation.
- [ ] Verify the archive stream and checksum.

### Task 3: Offline Installer, Restore Command, and Smoke Gate

**Files:**
- Create: `profiles/ultrarender/scripts/install-offline.sh`
- Create: `profiles/ultrarender/scripts/verify-installed.sh`
- Create: `profiles/ultrarender/scripts/restore.sh`
- Create: `profiles/ultrarender/smoke/CMakeLists.txt`
- Create: `profiles/ultrarender/smoke/main.cpp`

**Interfaces:**
- Consumes: extracted release bundle or a GitHub Release tag.
- Produces: bundle-integrity verification, exact required-package installation, GCC/Clang smoke builds, Vulkan report, and `VERIFICATION_RESULT=PASS`.

- [ ] Install only from the extracted `file:` APT repository, verify every bundled package file against the lock, and verify every manifest package at its locked version and architecture.
- [ ] Do not require unused transitive or transitional packages to be installed merely because their `.deb` files are present in the complete offline closure.
- [ ] Compile a C++20 target against Qt6 Core, Gui, GuiPrivate, Vulkan, GTest, FreeType, HarfBuzz, and FlatBuffers.
- [ ] Build the target independently with GCC and Clang.
- [ ] Enumerate Lavapipe through `vulkaninfo` under Xvfb.
- [ ] Implement cached `latest` or explicit-tag download using `gh`, with a `curl` API fallback.
- [ ] Verify SHA-256 before extraction and run install plus verification automatically.

### Task 4: Build, Restore, and Persistent Release Workflow

**Files:**
- Create: `.github/workflows/ultrarender-debian13-release.yml`

**Interfaces:**
- Consumes: all UltraRender profile files and `VERSION`.
- Produces: temporary build/verification artifacts and a permanent GitHub Release.

- [ ] Lint scripts and validate manifest/version format.
- [ ] Build the archive in `debian:13` and upload it as a temporary artifact.
- [ ] Restore in a second clean `debian:13` container after removing external APT sources.
- [ ] Upload the verification report.
- [ ] On main, reject an existing version tag and require a version bump.
- [ ] Create a draft Release, upload five required assets, check remote sizes, download the archive and checksum back, verify SHA-256, and publish.

### Task 5: Operator Documentation and End-to-End Validation

**Files:**
- Create: `profiles/ultrarender/README.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: final asset names and restore command.
- Produces: operator instructions for build, release, cached restore, explicit rollback, and failure recovery.

- [ ] Document the one-command restore path and explicit version rollback.
- [ ] Document compatibility limits and immutability rules.
- [ ] Open a PR and require the branch validation workflow to pass.
- [ ] Merge the approved branch, observe the main workflow publish the first Release, and verify its remote assets.
