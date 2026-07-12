# RocheDB NIF Adapter

`rochedb-nif` is the official optional adapter for using NIF text and BIF
payloads with RocheDB. The general-purpose NIF/BIF codec lives in `nifkit`;
this package keeps the RocheDB-facing names, C ABI, and future payload-adapter
integration separate from the reusable codec toolkit.

## Scope

- `nifToBif`: NIF text to BIF bytes
- `bifToNif`: BIF bytes to canonical NIF text
- `validateBif`: BIF validation without semantic interpretation
- RocheDB-named C ABI for `NIF text -> BIF bytes`, `BIF bytes -> NIF text`,
  and BIF validation
- `examples/nif_file_tool.nim` for file-based encode/decode workflows used by
  integration demos

The codec backend is provided by `nifkit`, which is implemented against the
public NIF/BIF specification and has no dependency on Nimony or any compiler
implementation. This package should remain a thin RocheDB adapter over that
toolkit.

This package does not infer RocheDB rings, alter placement, or reinterpret an
existing record's explicit codec.

## Development

For local development, keep `nifkit` next to this repository:

```text
oss/
  nifkit/
  rochedb-nif/
```

`config.nims` automatically adds `../nifkit/src` to the Nim import path, so the
adapter works without repeating `--path:../nifkit/src` in every command. After
`nifkit` is published to Nimble, this will become a normal package dependency.
For the `rochedb-nif v0.1.0` release line, use `nifkit v0.1.0`.

```sh
git clone https://github.com/puffball1567/nifkit
git -C nifkit checkout v0.1.0
git clone https://github.com/puffball1567/rochedb-nif
cd rochedb-nif
nimble verifyCore -y
```

```sh
nimble doctor
nimble test
nimble verifyCore
nimble verifyIntegration
nimble rochedbRoundtrip
nimble matrixDemo
nimble cliRoundtrip
nimble cabiContract
nimble verify
```

`nimble verifyCore` is the CI-safe verification entry point. It runs adapter
tests and the C ABI contract without requiring a RocheDB checkout.

`nimble verifyIntegration` runs RocheDB-backed storage and CLI boundary checks.
It expects the full local OSS workspace layout shown below.

Clang is the recommended C ABI verification compiler. GCC is also supported for
Linux compatibility; replace `clang` with `gcc` in the contract build command.

The package is built with Nim ARC via `config.nims`. The C ABI copies input
bytes into ARC-managed memory and returns explicit output buffers that must be
released with `roche_nif_free`.

Use the adapter to create payload bytes, then store them explicitly. Until the
CLI lands, applications should call the Nim API or C ABI directly:

```sh
roche put --data=data --ring=documents --in=document.bif --codec=bif
```

To inspect a stored BIF record, export its raw bytes and decode them through
`bifToNif` or the C ABI. RocheDB core can safely show base64 or hexadecimal BIF,
but semantic decoding belongs to this adapter.

To verify the full RocheDB round trip against a sibling RocheDB checkout:

```sh
nimble rochedbRoundtrip
```

That demo converts NIF text to BIF through `rochedb-nif`, stores it in RocheDB
with `codec=bif`, reads it back through `getEncoded`, and decodes the retrieved
bytes to NIF again.

The round-trip demo expects the local OSS workspace layout used by RocheDB
development:

```text
oss/
  ceresdb/
  nifkit/
  rochedb-nif/
  sodiumkit/
```

`nimble cliRoundtrip` performs the same boundary check through the RocheDB CLI:
it encodes NIF to BIF, writes the BIF file with `roche put --codec=bif`, reads
it back with `roche get --view=base64`, decodes it, and compares the original
NIF text.

`nimble matrixDemo` stores both NIF text and BIF bytes across multiple RocheDB
rings, then reads them back through explicit codec metadata.

## License and Acknowledgements

`rochedb-nif` is MIT licensed. The adapter depends on `nifkit`, which exists
because Araq and the Nimony/NIF contributors defined and documented the NIF/BIF
foundation. This package keeps RocheDB-specific naming and integration separate
from that general-purpose codec work.

## C ABI

`include/rochedb_nif.h` exposes byte-length APIs for C, C++, Rust, Node native
addons, and FFI consumers. BIF is binary data, so neither input nor output uses
NUL termination. Every successful output buffer must be released with
`roche_nif_free`.

```c
int roche_nif_to_bif(const void *nif_data, size_t nif_len,
                     void **out_bif, size_t *out_len);
int roche_bif_to_nif(const void *bif_data, size_t bif_len,
                     void **out_nif, size_t *out_len);
int roche_validate_bif(const void *bif_data, size_t bif_len);
void roche_nif_free(void *buffer);
const char *roche_nif_last_error(void);
```

All conversion functions return `0` on success and non-zero on failure.
`roche_nif_last_error()` is thread-local. Inputs are byte slices; passing
`NULL` with a non-zero length is an error. Returned buffers may contain NUL
bytes, so callers must use the returned length.
