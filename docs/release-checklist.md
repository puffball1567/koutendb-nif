# Release Checklist

This checklist is for publishing a koutendb-nif release.

## Local Verification

Run the CI-safe verification suite before tagging:

```sh
nimble verifyCore -y
```

The core suite covers:

- KoutenDB-facing NIF text to BIF binary encoding
- KoutenDB-facing BIF binary to canonical NIF text decoding
- BIF validation
- adapter matrix fixtures
- line-info fixtures
- KoutenDB-named C ABI contract behavior

Run the KoutenDB-backed integration suite when the full local workspace is
available:

```sh
nimble verifyIntegration -y
```

That suite expects:

```text
oss/
  ceresdb/
  nifkit/
  koutendb-nif/
  sodiumkit/
```

## CI Verification

Pushes and pull requests run `nimble verifyCore -y` on:

- `ubuntu-latest`
- `macos-latest`
- `windows-latest`

The CI workflow also checks out `nifkit` from the same GitHub owner into the
`nifkit/` subdirectory at `v0.1.0` because koutendb-nif remains a thin adapter
until nifkit is published as a normal Nimble dependency.

## Dependency Boundary

`koutendb-nif` may depend on `nifkit` and may test against KoutenDB integration
boundaries. The general-purpose NIF/BIF codec must stay in `nifkit`; this
repository should keep KoutenDB naming, adapter docs, C ABI naming, and
KoutenDB-specific integration tests.

## Versioning

Update `version` in `koutendb_nif.nimble`, then create a matching Git tag:

```sh
git status --short
git tag -a v0.1.0 -m "koutendb-nif v0.1.0"
git push origin main:main
git push origin refs/tags/v0.1.0:refs/tags/v0.1.0
```
