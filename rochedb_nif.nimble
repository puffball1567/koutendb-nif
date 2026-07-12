version       = "0.1.0"
author        = "RocheDB contributors"
description   = "Official NIF/BIF payload adapter for RocheDB"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.2.0"
# Add `requires "nifkit >= 0.1.0"` after nifkit is published to Nimble.

task test, "Run the RocheDB NIF/BIF adapter test suite":
  exec "nim c --nimcache:nimcache/test_nif_encoder -r tests/test_nif_encoder.nim"
  exec "nim c --nimcache:nimcache/test_bif_decoder -r tests/test_bif_decoder.nim"
  exec "nim c --nimcache:nimcache/test_line_info -r tests/test_line_info.nim"
  exec "nim c --nimcache:nimcache/test_adapter_matrix -r tests/test_adapter_matrix.nim"

task integrationTest, "Run RocheDB-backed adapter integration tests":
  exec "nim c --nimcache:nimcache/test_rochedb_integration --path:../ceresdb/src --path:../sodiumkit/src -r tests/test_rochedb_integration.nim"

task doctor, "Verify the sibling nifkit setup":
  exec "nim c --nimcache:nimcache/doctor -r tests/test_nif_encoder.nim"

task rochedbRoundtrip, "Verify RocheDB stores and returns nifkit-produced BIF payloads":
  exec "nim c --nimcache:nimcache/rochedb_roundtrip --path:../ceresdb/src --path:../sodiumkit/src -r examples/rochedb_roundtrip_demo.nim"

task cliRoundtrip, "Verify RocheDB CLI stores and returns rochedb-nif BIF payloads":
  exec "bash examples/cli_roundtrip_demo.sh"

task matrixDemo, "Run the RocheDB NIF adapter matrix demo":
  exec "nim c --nimcache:nimcache/matrix_demo --path:../ceresdb/src --path:../sodiumkit/src -r examples/matrix_demo.nim"

task cabiContract, "Build and run the RocheDB NIF C ABI contract":
  when defined(windows):
    exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:nimcache/rochedb-nif-capi -o:rochedb_nif.dll src/rochedb_nif_capi.nim"
    exec "clang -std=c11 -Wall -Wextra -DROCHEDB_NIF_DYNAMIC_LOAD -Iinclude examples/cabi_contract.c -o rochedb_nif_cabi_contract.exe"
    exec "rochedb_nif_cabi_contract.exe"
  elif defined(macosx):
    exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:/tmp/rochedb-nif-capi -o:/tmp/librochedb_nif.dylib src/rochedb_nif_capi.nim"
    exec "clang -std=c11 -Wall -Wextra -Iinclude examples/cabi_contract.c /tmp/librochedb_nif.dylib -o /tmp/rochedb_nif_cabi_contract"
    exec "DYLD_LIBRARY_PATH=/tmp /tmp/rochedb_nif_cabi_contract"
  else:
    exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:/tmp/rochedb-nif-capi -o:/tmp/librochedb_nif.so src/rochedb_nif_capi.nim"
    exec "clang -std=c11 -Wall -Wextra -Iinclude examples/cabi_contract.c -L/tmp -lrochedb_nif -Wl,-rpath,/tmp -o /tmp/rochedb_nif_cabi_contract"
    exec "/tmp/rochedb_nif_cabi_contract"

task verifyCore, "Run CI-safe adapter verification":
  exec "nimble test -y"
  exec "nimble cabiContract -y"

task verifyIntegration, "Run RocheDB-backed adapter verification":
  exec "nimble integrationTest -y"
  exec "nimble rochedbRoundtrip -y"
  exec "nimble matrixDemo -y"
  exec "nimble cliRoundtrip -y"

task verify, "Run the full RocheDB NIF adapter verification suite":
  exec "nimble verifyCore -y"
  exec "nimble verifyIntegration -y"
