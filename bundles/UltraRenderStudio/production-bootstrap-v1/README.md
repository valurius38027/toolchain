# UltraRenderStudio Production Bootstrap v1

This directory is the persistent binary recovery vault for the completed UltraRenderStudio Production Bootstrap phase.

- Source phase tag: `phase/production-bootstrap-v1`
- Source commit: `45d9df06be6abf841729fb2399f7d8ef94a8c53d`
- Bundle: `UltraRenderStudio-production-bootstrap-v1.bundle`
- SHA-256: `7462e9e9012beabe22a89cefff2f84cbb113de1fea93ceb91c42d47d2e96710d`
- Sidecar: `UltraRenderStudio-production-bootstrap-v1.bundle.sha256`

Verification performed before upload:

1. `sha256sum -c`
2. `git bundle verify`
3. fresh `git clone` from the bundle
4. `git fsck --full`
5. verification that `phase/production-bootstrap-v1` resolves to the completion commit

Restore:

```bash
sha256sum -c UltraRenderStudio-production-bootstrap-v1.bundle.sha256
git clone UltraRenderStudio-production-bootstrap-v1.bundle UltraRenderStudio
git -C UltraRenderStudio switch feat/production-bootstrap
```
