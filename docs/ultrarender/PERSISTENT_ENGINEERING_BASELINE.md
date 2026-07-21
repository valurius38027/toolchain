# UltraRender Persistent Engineering Baseline

**Recorded:** 2026-07-20  
**Updated:** 2026-07-21  
**Status:** Authoritative recovery and engineering-entry record

## 1. Authoritative toolchain recovery source

The authoritative toolchain recovery source for all subsequent UltraRenderStudio engineering is:

- Repository: `valurius38027/toolchain`
- Branch: `main`
- Immutable SDK release: `ultrarender-sdk-debian13-v2026.07.20.1`
- Supported host: Debian 13 (`trixie`), amd64
- Canonical restore command:

```bash
sudo bash profiles/ultrarender/scripts/restore.sh latest
```

The GitHub Release assets, not temporary Actions artifacts or a transient ChatGPT workspace, are the source of truth.

The release has passed:

1. deterministic package-closure construction;
2. package-file SHA-256 and package-lock verification;
3. installation in a second clean Debian 13 container after removal of external APT sources;
4. exact version and architecture checks for required toolchain packages;
5. GCC and Clang SDK smoke builds;
6. Qt 6 `GuiPrivate` / QRhi integration checks;
7. Lavapipe CPU Vulkan enumeration;
8. remote GitHub Release download and archive checksum verification;
9. full public `restore.sh latest` execution in a fresh Debian 13 container.

A later profile change must bump `profiles/ultrarender/VERSION`; an existing release or tag must never be overwritten.

## 2. Authoritative UltraRenderStudio source

The canonical source repository is:

- Repository: `valurius38027/UltraRenderStudio`
- Branch: `main`
- Remote URL: `https://github.com/valurius38027/UltraRenderStudio.git`
- Remote branch policy: maintain `main` only
- Latest completed engineering phase: `production-bootstrap-v1.1`

Remote feature, development, release, and bundle-vault branches are not part of the maintenance model. Temporary local worktrees may be used for isolation, but completed work is integrated into `main` and the temporary branch is removed. Durable milestones use annotated `phase/*` tags and immutable GitHub Release bundle assets.

`AGENTS.md` in the source repository is the highest-authority operating constraint. `INDEX.md` records the current code reality and next formal milestone.

## 3. Current UltraRenderStudio code reality

The module direction remains:

```text
ur_platform
  -> ur_gfx
  -> ur_text
  -> ur_widgets
  -> ur_dock / ur_nodegraph / ur_viewport
```

Production Bootstrap has closed:

- strict GCC and Clang warning gates;
- Qt-to-platform FIFO events for expose, resize, pointer, focus, and close;
- a private `QWindow` integration bridge without public native handles;
- Vulkan QRhi offscreen rendering and deterministic pixel readback;
- real `QWindow -> QVulkanInstance -> QRhi -> swapchain -> present` rendering;
- resize and swapchain recovery under Xvfb and Mesa Lavapipe;
- two-stage topmost widget hit arbitration;
- stale active/capture cleanup and focus-loss cancellation;
- a real editor frame loop with deterministic finite-frame smoke mode.

Not yet closed:

- minimum text rendering and measurement;
- scoped widget IDs, clipping/scissor, overlay ordering, and basic layout;
- retained editor composition and docking;
- node graph and viewport production integration;
- complete UltraRender engine ABI provenance, capability negotiation, and end-to-end rendering integration;
- production-verified non-Vulkan backends.

This is a production bootstrap, not a claim that the complete editor is production-ready.

## 4. Engineering authority and operating rules

1. Restore and verify the SDK before modifying UltraRenderStudio.
2. Use `valurius38027/UltraRenderStudio` on `main` as the source authority.
3. Read `AGENTS.md`, then `INDEX.md`, then applicable ADRs before implementation.
4. Preserve the dependency boundaries unless an approved design demonstrates a concrete defect.
5. Use test-first development for behavior changes and bug fixes.
6. Keep `UR_WARNINGS_AS_ERRORS=ON`; do not weaken sanitizers or runtime gates to obtain a pass.
7. Window or GPU behavior requires Xvfb/Lavapipe or a real supported platform backend.
8. No phase is complete without fresh GCC, Clang, CTest, runtime, dependency-lint, tag, bundle, checksum, fresh-clone, and `git fsck` evidence.
9. Existing phase tags and Release assets are immutable.
10. Do not begin Dock before minimum text and the Dock prerequisite UI foundation are closed.

## 5. Recovery and engineering entry

After host cleanup:

```bash
git clone https://github.com/valurius38027/toolchain.git
git clone https://github.com/valurius38027/UltraRenderStudio.git
cd toolchain
sudo bash profiles/ultrarender/scripts/restore.sh latest
cd ../UltraRenderStudio
git switch main
git status --short
git log -5 --oneline --decorate
```

Then run the strict GCC and Clang commands documented in the UltraRenderStudio `README.md`. Inspect `AGENTS.md`, `INDEX.md`, the relevant ADRs, and recent commits before writing or executing the next milestone design.

The next formal milestone is **Minimal Text Rendering Closure**. Dock remains blocked until text measurement, scoped IDs, clipping/scissor, overlay ordering, and basic layout consumption are closed.