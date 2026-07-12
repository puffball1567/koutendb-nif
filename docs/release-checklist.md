# Release Checklist

This checklist is for publishing a rochedb-nif release.

## Local Verification

Run the CI-safe verification suite before tagging:

```sh
nimble verifyCore -y
```

The core suite covers:

- RocheDB-facing NIF text to BIF binary encoding
- RocheDB-facing BIF binary to canonical NIF text decoding
- BIF validation
- adapter matrix fixtures
- line-info fixtures
- RocheDB-named C ABI contract behavior

Run the RocheDB-backed integration suite when the full local workspace is
available:

```sh
nimble verifyIntegration -y
```

That suite expects:

```text
oss/
  ceresdb/
  nifkit/
  rochedb-nif/
  sodiumkit/
```

## CI Verification

Pushes and pull requests run `nimble verifyCore -y` on:

- `ubuntu-latest`
- `macos-latest`
- `windows-latest`

The CI workflow also checks out `nifkit` from the same GitHub owner into the
`nifkit/` subdirectory at `v0.1.0` because rochedb-nif remains a thin adapter
until nifkit is published as a normal Nimble dependency.

## Dependency Boundary

`rochedb-nif` may depend on `nifkit` and may test against RocheDB integration
boundaries. The general-purpose NIF/BIF codec must stay in `nifkit`; this
repository should keep RocheDB naming, adapter docs, C ABI naming, and
RocheDB-specific integration tests.

## Versioning

Update `version` in `rochedb_nif.nimble`, then create a matching Git tag:

```sh
git status --short
git tag -a v0.1.0 -m "rochedb-nif v0.1.0"
git push origin main:main
git push origin refs/tags/v0.1.0:refs/tags/v0.1.0
```
