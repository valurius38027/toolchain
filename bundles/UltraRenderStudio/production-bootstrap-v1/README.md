# UltraRenderStudio Bundle Vault — Invalid Attempt

```text
REMOTE_VAULT_STATUS=INVALID
DO_NOT_RESTORE_FROM_THIS_DIRECTORY
```

This directory records a failed experiment to transport a binary Git bundle through repository text-file writes. It is retained only as an auditable failure record.

The remote verification workflow correctly failed closed:

- several opaque Base64 chunks changed or were rejected during connector transport;
- `base64 --decode` and per-chunk SHA-256 checks detected the corruption;
- `VERIFIED.txt` records `VERIFIED_RESULT=FAIL`;
- no bundle reconstructed from this directory is authoritative.

Do not run `restore.sh`, do not clone a reconstructed file from this directory, and do not treat its old v1 checksum as a valid remote backup.

## Authoritative completed phase

The corrected completed phase is:

- Tag: `phase/production-bootstrap-v1.1`
- Commit: `c4b92fd0a290380bb6a5c0be4cf2b762b589cea8`
- Bundle filename: `UltraRenderStudio-production-bootstrap-v1.1.bundle`
- Bundle SHA-256: `84a0a83e5458810f1afd1f95b429476fe2db6e95e4fb9dfdb11618b7326d7cd2`

The v1.1 bundle was verified locally with:

1. `sha256sum -c`;
2. `git bundle verify`;
3. a fresh clone from the bundle;
4. `git fsck --full`;
5. confirmation that `phase/production-bootstrap-v1.1` resolves to commit `c4b92fd0a290380bb6a5c0be4cf2b762b589cea8`.

A dedicated normal Git remote for UltraRenderStudio remains the preferred durable source repository. Until one is supplied or created, the verified v1.1 bundle and its sidecar are the authoritative recovery artifacts from this engineering session.
