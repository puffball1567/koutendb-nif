# Codec Backend Contract

`rochedb-nif` exposes RocheDB-facing NIF/BIF conversion through a stable public
surface:

```nim
nifToBif(nifText)
bifToNif(bifBytes)
validateBif(bifBytes)
codecInfo()
```

The current backend is `nifkit`. `rochedb-nif` must stay a thin adapter: it
keeps RocheDB naming, C ABI compatibility, and future payload-adapter
integration while `nifkit` owns the general-purpose codec implementation.

Local development keeps that dependency explicit but low-friction. Until
`nifkit` is published as a Nimble package, `rochedb-nif/config.nims` adds
`../nifkit/src` to the Nim import path. A fresh checkout should therefore use
this layout. For `rochedb-nif v0.1.0`, use `nifkit v0.1.0`.

```text
oss/
  nifkit/
  rochedb-nif/
```

Run `nimble doctor` in `rochedb-nif` to verify that the sibling codec toolkit is
available. Run `nimble rochedbRoundtrip` to verify that a `nifkit`-produced BIF
payload can be stored in RocheDB with `codec=bif` and decoded after retrieval.

CI runs `nimble verifyCore -y` on Linux, macOS, and Windows. That entry point
checks the adapter API and RocheDB-named C ABI without requiring RocheDB core.
RocheDB-backed storage and CLI checks live in `nimble verifyIntegration -y` and
are intended for the full local OSS workspace.

Codec fixtures and property tests live in `nifkit`. `rochedb-nif` should keep
adapter-level tests that prove the RocheDB-facing names still route to the
same codec behavior.

If an official standalone NIF/BIF library is published later, an
`official_backend` may replace `nifkit` behind the same boundary. The public API
and RocheDB integration must remain unchanged.

The implementation rejects unsupported BIF versions and malformed containers
with recoverable errors. It must never terminate the host process for malformed
payload bytes.

Memory safety contract:

- The package is built with Nim ARC via `config.nims`.
- Codec internals are owned by `nifkit`.
- C ABI entry points copy input bytes before parsing.
- C ABI success outputs are allocated with Nim `alloc` and must be released
  with `roche_nif_free`.
- C ABI failure paths reset output pointers to `nil` and lengths to `0`.
- zero-length inputs and zero-length outputs are represented explicitly:
  `NULL` is valid only when the corresponding length is `0`.
- returned BIF/NIF buffers are byte slices and may contain NUL bytes; callers
  must use the returned length, not C string termination.
- Malformed BIF count, offset, nesting-depth, and trailing-data cases are
  covered by tests so hostile payloads are rejected before unsafe allocation or
  ambiguous decoding.
