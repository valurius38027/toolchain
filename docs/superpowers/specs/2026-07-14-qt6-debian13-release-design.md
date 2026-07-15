# Qt 6 Debian 13 Offline Toolchain Release Design

Date: 2026-07-14
Status: Approved direction; implementation pending
Target repository: `valurius38027/toolchain`

## 1. Objective

Build and publish a reproducible Debian 13 amd64 Qt 6 development toolchain entirely inside GitHub Actions. No large artifact is uploaded from a ChatGPT container or developer workstation.

The release must contain enough material to install and validate the toolchain on a clean Debian 13 amd64 host without network access after download.

## 2. Target environment

- Base system: Debian 13 (`trixie`), amd64
- Qt: Debian 13 repository version, recorded at build time
- Build systems: CMake and Ninja
- Compilers and analysis: GCC, Clang, clangd, clang-tidy, clazy, ccache
- Debugging and coverage: GDB, LLDB, Valgrind, gcovr, lcov
- Qt components:
  - Core, GUI, Widgets
  - QML, Qt Quick, Qt Quick Controls
  - Qt Quick 3D and Shader Tools
  - SVG and image format plugins
  - Multimedia
  - WebSockets and WebChannel
  - WebEngine Widgets and Qt PDF
  - Wayland, XCB, EGL, OpenGL and Vulkan runtime support
  - Qt Test, Designer, Linguist, Assistant and Qt Creator

Private Qt headers are excluded from the default package set unless a later release explicitly enables them.

## 3. Build architecture

The workflow runs on `ubuntu-latest` only as the GitHub Actions host. All package resolution, installation and packaging happen inside a pinned `debian:13` container.

The workflow has three logical stages.

### 3.1 Build stage

1. Start a clean Debian 13 amd64 container.
2. Install only bootstrap utilities needed for package acquisition and packaging.
3. Resolve the declared toolchain package manifest with APT.
4. Download the complete dependency closure as `.deb` files.
5. Generate a local APT repository index with `dpkg-scanpackages`.
6. Record:
   - exact package names and versions;
   - package origin and architecture;
   - Qt, compiler, CMake and Ninja versions;
   - build timestamp and Git commit SHA.
7. Add offline installation, environment activation and verification scripts.
8. Add a minimal Qt smoke-test project covering Widgets, QML/Quick, Quick 3D and Qt Test.
9. Create a deterministic `tar.zst` release archive.
10. Generate SHA-256 checksums and a machine-readable metadata manifest.

### 3.2 Restore-test stage

A second clean Debian 13 container must verify the archive rather than trusting the build container.

1. Extract the release archive.
2. Disable external APT sources for the test.
3. Install the toolchain only from the bundled local APT repository.
4. Verify package integrity and dependency closure.
5. Configure and build the smoke project with GCC.
6. Configure and build the smoke project with Clang.
7. Run Qt Test.
8. Run `qmllint`.
9. Run Widgets and QML applications under Xvfb.
10. Record all version and test output in `verification-report.txt`.

Any failure blocks release publication.

### 3.3 Publish stage

After restore verification succeeds:

1. Create or update a GitHub Release for the selected tag.
2. Upload:
   - the offline toolchain archive;
   - archive SHA-256 file;
   - package manifest;
   - build metadata;
   - verification report.
3. Query the GitHub Release API and confirm all expected assets exist with non-zero sizes.
4. Download the published checksum and archive back to the workflow runner.
5. Verify the downloaded archive against the published checksum.

Only after this remote round-trip validation is the release considered published.

## 4. Workflow triggers and versioning

The workflow supports:

- manual `workflow_dispatch` for controlled production releases;
- tag pushes matching `qt6-debian13-v*`.

The initial production tag format is:

`qt6-debian13-vYYYY.MM.DD.N`

where `N` is the release revision for that date.

Normal branch pushes run manifest validation and lightweight syntax checks but do not publish a Release.

## 5. Repository layout

```text
.github/workflows/
  qt6-debian13-release.yml
manifests/
  qt6-debian13-packages.txt
scripts/
  build-offline-repo.sh
  install-offline.sh
  verify-installed.sh
  package-release.sh
smoke/
  CMakeLists.txt
  src/
  qml/
docs/superpowers/specs/
  2026-07-14-qt6-debian13-release-design.md
README.md
```

Generated archives and `.deb` files are never committed to Git. They exist only in workflow storage and GitHub Release assets.

## 6. Reproducibility model

The release is reproducible at the package-version level, not guaranteed byte-for-byte across arbitrary future dates.

Each release freezes the exact package versions resolved during that run. Subsequent rebuilds use the release metadata and package manifest, but Debian mirrors may remove superseded package versions. Therefore, the published GitHub Release asset is the authoritative immutable recovery artifact.

The workflow must never silently substitute a newer package version while claiming to rebuild an older release.

## 7. Security and supply-chain controls

- Use official Debian repositories only.
- Pin GitHub Actions by immutable commit SHA where practical.
- Use the repository-scoped `GITHUB_TOKEN` with `contents: write` only in the publish job.
- Do not embed credentials in archives or repository files.
- Validate `.deb` metadata and run `dpkg-deb --info` over every downloaded package.
- Produce SHA-256 checksums for every published asset.
- Preserve build logs and verification reports as workflow artifacts.

## 8. Failure handling

The workflow fails closed on:

- unresolved dependencies;
- missing or duplicate package identities;
- package architecture mismatch;
- corrupt `.deb` files;
- smoke-project build failure;
- test, QML lint or headless startup failure;
- archive checksum mismatch;
- missing Release assets;
- failed remote re-download verification.

A failed run must not overwrite or delete an existing successful Release.

## 9. Acceptance criteria

The implementation is complete only when a real GitHub Actions run demonstrates all of the following:

1. Debian 13 resolves and downloads the full toolchain dependency closure.
2. The workflow produces a self-contained offline archive.
3. A second clean Debian 13 environment installs solely from the archive.
4. GCC and Clang builds pass.
5. Qt Test, `qmllint`, Widgets headless startup and QML/Quick startup pass.
6. GitHub Release is created with all required assets.
7. The archive is re-downloaded from the Release and its SHA-256 matches.
8. The Release remains downloadable independently of the original Actions runner.

## 10. Explicit non-goals

- Cross-compiling Windows or macOS Qt toolchains.
- Bundling proprietary Qt commercial components.
- Guaranteeing physical-GPU performance testing on GitHub-hosted runners.
- Preserving a mutable container filesystem snapshot as the primary distribution format.
