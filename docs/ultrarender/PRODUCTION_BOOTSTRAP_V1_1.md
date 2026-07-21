# UltraRenderStudio Production Bootstrap v1.1

**Completed:** 2026-07-20  
**Status:** Engineering phase complete; verified Git bundle available  
**Next phase:** Minimal text rendering closure

## Source authority

- Original uploaded baseline: `UltraRenderStudio(1).zip`
- Original archive SHA-256: `32f216017ec73e50cc6b38bc66609cf8d555c0a30eba4a58497831c058520633`
- Local Git feature branch: `feat/production-bootstrap`
- Completion tag: `phase/production-bootstrap-v1.1`
- Completion commit: `782fe87a93416cdcdd90070afb4107b7e51da804`

The uploaded archive did not contain `.git`; a clean local Git history was established before implementation. This record does not claim that a dedicated UltraRenderStudio GitHub source repository exists.

## Delivered production bootstrap

The phase closed the minimum real editor foundation:

1. strict GCC and Clang warning gates, including correct Qt `GuiPrivate` system treatment;
2. backend-neutral platform event FIFO for expose, resize, pointer, focus and close events;
3. real `QWindow -> QVulkanInstance -> QRhi -> swapchain -> present` rendering;
4. resize and swapchain recreation behavior under Xvfb and Mesa Lavapipe;
5. separation between offscreen and window render-device construction;
6. two-stage topmost widget hit arbitration;
7. stale active/capture cleanup and focus-loss cancellation;
8. a real editor frame loop with input draining, button interaction, resize handling and presentation;
9. deterministic `--frames` termination for automated editor smoke testing;
10. architecture and recovery documentation updated to make minimal text rendering the next milestone, not Dock.

## Verification evidence

Fresh final verification passed:

- GCC 14 strict Debug build with ASan/UBSan: 11/11 tests passed;
- Clang 17 strict RelWithDebInfo build: 11/11 tests passed;
- real Xvfb/Lavapipe window present and resize tests passed;
- editor smoke produced the requested finite frame count and exited normally;
- dependency-layer lint passed;
- final worktree was clean.

A 72-byte exit-time leak was isolated with a standalone reproducer to Debian's Vulkan loader process cache. The project still corrected QRhi/Vulkan destruction order and applies a narrowly scoped LSan suppression only to Vulkan window processes.

## Recovery bundle

Authoritative bundle metadata:

- File: `UltraRenderStudio-production-bootstrap-v1.1.bundle`
- Sidecar: `UltraRenderStudio-production-bootstrap-v1.1.bundle.sha256`
- SHA-256: `a27cfd92569c3bb15937cd1edb1ab6f677e2fe446e6b8d44aabd673766fc970e`

The bundle passed:

1. `sha256sum -c`;
2. `git bundle verify`;
3. fresh clone from the bundle;
4. `git fsck --full`;
5. exact tag-to-commit verification.

Recovery procedure:

```bash
sha256sum -c UltraRenderStudio-production-bootstrap-v1.1.bundle.sha256
git clone UltraRenderStudio-production-bootstrap-v1.1.bundle UltraRenderStudio
git -C UltraRenderStudio switch feat/production-bootstrap
git -C UltraRenderStudio fsck --full
```

## Remote-source limitation

An attempt to store the opaque binary bundle as Base64 repository chunks failed integrity verification because the available connector rejected or altered some opaque chunks. That attempt is explicitly marked invalid on the `ultrarenderstudio/bundle-vault` branch and is not a recovery source.

The preferred permanent arrangement remains a dedicated normal UltraRenderStudio Git repository. Until an existing empty repository is supplied, the verified v1.1 bundle and its checksum sidecar are the authoritative source recovery artifacts.
