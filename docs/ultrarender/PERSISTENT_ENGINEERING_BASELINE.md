# UltraRender Persistent Engineering Baseline

**Recorded:** 2026-07-20  
**Status:** Authoritative recovery and engineering-entry record

## 1. Authoritative toolchain recovery source

The authoritative recovery source for all subsequent UltraRenderStudio engineering is:

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

## 2. Current UltraRenderStudio code reality

The last known implementation state is:

```text
ur_platform
  -> ur_gfx
  -> ur_text
  -> ur_widgets
  -> dock / nodegraph / viewport
```

Implemented baseline:

- offscreen Vulkan rectangle rendering;
- a minimal immediate-mode `button()` state machine;
- a tested `DrawList -> ur_gfx -> Vulkan -> pixel readback` path;
- a thin UltraRender C ABI session wrapper.

Not yet closed:

- presentation of the editor window to a real surface;
- production event/input routing;
- retained editor composition and docking closure;
- node graph and viewport production integration;
- end-to-end editor-to-renderer interaction.

This is an engineering baseline, not a claim that the editor is production-ready.

## 3. Engineering authority and operating rules

1. Restore and verify the SDK before modifying UltraRenderStudio.
2. Use the actual source checkout with valid `.git` metadata as the code authority.
3. `AGENT.md` or `AGENTS.md`, when present in the UltraRenderStudio repository, is the highest-authority repository constraint document.
4. `INDEX.md` is only a maintained code-reality index; it must not replace agent constraints, architecture specifications, or implementation plans.
5. Do not infer the source repository from the toolchain repository. The UltraRenderStudio source checkout or canonical remote must be identified explicitly before implementation.
6. Preserve the existing layer boundaries unless a reviewed design demonstrates a concrete defect.
7. Formal engineering begins by reproducing the current build/tests and recording the exact baseline before feature work.
8. No implementation phase is complete without fresh build, test, and runtime evidence.

## 4. Immediate entry condition

Before the first production implementation task, identify the canonical UltraRenderStudio source repository or provide the latest workspace/archive. Then perform:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git log -5 --oneline --decorate
sudo bash /path/to/toolchain/profiles/ultrarender/scripts/restore.sh latest
```

After source and toolchain verification, inspect repository authority documents, architecture, current tests, and recent commits before writing the first production-stage design.
