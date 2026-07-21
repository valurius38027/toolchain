# UltraRenderStudio Production Bootstrap v1

This directory is the persistent binary recovery vault for the completed UltraRenderStudio Production Bootstrap phase.

- Source phase tag: `phase/production-bootstrap-v1`
- Source commit: `45d9df06be6abf841729fb2399f7d8ef94a8c53d`
- Reconstructed bundle: `UltraRenderStudio-production-bootstrap-v1.bundle`
- SHA-256: `7462e9e9012beabe22a89cefff2f84cbb113de1fea93ceb91c42d47d2e96710d`
- Sidecar: `UltraRenderStudio-production-bootstrap-v1.bundle.sha256`
- Storage representation: nine ordered Base64 chunks under `encoded/`

The GitHub connector cannot write raw binary repository files directly, so the complete Git bundle is stored losslessly as ordered Base64 chunks. `restore.sh` concatenates the chunks, decodes the binary bundle, verifies SHA-256, and runs `git bundle verify`.

## Restore from the vault

From a checkout of the `ultrarenderstudio/bundle-vault` branch:

```bash
bash bundles/UltraRenderStudio/production-bootstrap-v1/restore.sh

git clone \
  bundles/UltraRenderStudio/production-bootstrap-v1/UltraRenderStudio-production-bootstrap-v1.bundle \
  UltraRenderStudio

git -C UltraRenderStudio switch feat/production-bootstrap
git -C UltraRenderStudio fsck --full
```

A successful reconstruction prints:

```text
UltraRenderStudio-production-bootstrap-v1.bundle: OK
VAULT_BUNDLE_RESULT=PASS
```

## Verification contract

The local source bundle was verified before upload with:

1. `sha256sum -c`;
2. `git bundle verify`;
3. a fresh `git clone` from the bundle;
4. `git fsck --full`;
5. confirmation that `phase/production-bootstrap-v1` resolves to source commit `45d9df06be6abf841729fb2399f7d8ef94a8c53d`.

The vault branch also runs `.github/workflows/verify-ultrarenderstudio-bundle-vault.yml`. It reconstructs the bundle exclusively from the remote chunks, repeats the integrity and fresh-clone checks, and writes `VERIFIED.txt` only after all gates pass.
