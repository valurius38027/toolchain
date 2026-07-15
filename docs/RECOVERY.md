# Offline Recovery Procedure

## Compatibility boundary

The release targets Debian 13 (`trixie`) on amd64. It is not a generic relocatable Qt SDK and is not supported on Ubuntu, Debian 12, ARM, Windows or macOS.

The target must already have a functioning Debian base system, `apt`, `dpkg`, `tar` and `zstd`. The archive supplies the Qt development stack and its resolved non-recommended dependency closure; it does not replace the operating system base image.

## Integrity model

Before extraction:

```bash
sha256sum -c qt6-toolchain-debian13-amd64.tar.zst.sha256
zstd --test qt6-toolchain-debian13-amd64.tar.zst
```

After extraction, `package-lock.tsv` records, for every bundled package:

1. package name;
2. exact Debian version;
3. architecture;
4. `.deb` filename;
5. SHA-256.

The installer uses an isolated APT source configuration that points only to the bundled `repo/` directory. It then verifies installed versions and architectures against the lock.

## Installation

```bash
tar --zstd -xf qt6-toolchain-debian13-amd64.tar.zst
cd qt6-toolchain-debian13-amd64
sudo bash scripts/install-offline.sh
```

No external repository is consulted by `install-offline.sh`. If the local repository cannot satisfy the dependency graph, installation fails closed.

## Functional verification

```bash
bash scripts/verify-installed.sh
```

The verification process creates fresh GCC and Clang build trees and checks:

- CMake package discovery for all declared Qt components;
- C++20 compilation with GCC and Clang;
- QtTest execution;
- QML static linting;
- Widgets startup under Xvfb;
- QML and Quick 3D startup using Mesa software rendering;
- Qt Creator executable and platform-plugin loading.

A successful run ends with:

```text
VERIFICATION_RESULT=PASS
```

## Release validity

A GitHub Release is authoritative only when its workflow run completed the remote round-trip gate. That gate lists all expected Release assets, rejects missing or zero-byte files, downloads the published archive and checksum from GitHub, and reruns `sha256sum -c`.

An Actions artifact by itself is temporary and is not a durable release.

## Rebuild limitations

The package manifest declares names, while each release freezes versions in `package-lock.tsv`. Debian mirrors may later remove superseded package versions. The workflow must not substitute newer packages while claiming to recreate an older release. Preserve the GitHub Release assets themselves as the immutable recovery payload.
