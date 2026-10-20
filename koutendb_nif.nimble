version       = "0.1.1"
author        = "KoutenDB contributors"
description   = "Official NIF/BIF payload adapter for KoutenDB"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.2.0"
# The development checkout uses nifkit v0.4.1; see README.md.

task test, "Run the KoutenDB NIF/BIF adapter test suite":
  exec "nim c --nimcache:nimcache/test_nif_encoder -r tests/test_nif_encoder.nim"
  exec "nim c --nimcache:nimcache/test_bif_decoder -r tests/test_bif_decoder.nim"
  exec "nim c --nimcache:nimcache/test_line_info -r tests/test_line_info.nim"
  exec "nim c --nimcache:nimcache/test_adapter_matrix -r tests/test_adapter_matrix.nim"

task integrationTest, "Run KoutenDB-backed adapter integration tests":
  exec "nim c --nimcache:nimcache/test_koutendb_integration --path:../ceresdb/src --path:../sodiumkit/src -r tests/test_koutendb_integration.nim"

task doctor, "Verify the sibling nifkit setup":
  exec "nim c --nimcache:nimcache/doctor -r tests/test_nif_encoder.nim"

task koutendbRoundtrip, "Verify KoutenDB stores and returns nifkit-produced BIF payloads":
  exec "nim c --nimcache:nimcache/koutendb_roundtrip --path:../ceresdb/src --path:../sodiumkit/src -r examples/koutendb_roundtrip_demo.nim"

task cliRoundtrip, "Verify KoutenDB CLI stores and returns koutendb-nif BIF payloads":
  exec "bash examples/cli_roundtrip_demo.sh"

task matrixDemo, "Run the KoutenDB NIF adapter matrix demo":
  exec "nim c --nimcache:nimcache/matrix_demo --path:../ceresdb/src --path:../sodiumkit/src -r examples/matrix_demo.nim"

task cabiContract, "Build and run the KoutenDB NIF C ABI contract":
  for source in ["src/koutendb_nif_capi.nim", "src/rochedb_nif_capi.nim"]:
    when defined(windows):
      exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:nimcache/koutendb-nif-capi -o:koutendb_nif.dll " & source
      exec "clang -std=c11 -Wall -Wextra -DKOUTENDB_NIF_DYNAMIC_LOAD -Iinclude examples/cabi_contract.c -o koutendb_nif_cabi_contract.exe"
      exec "koutendb_nif_cabi_contract.exe"
    elif defined(macosx):
      exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:/tmp/koutendb-nif-capi -o:/tmp/libkoutendb_nif.dylib " & source
      exec "clang -std=c11 -Wall -Wextra -Iinclude examples/cabi_contract.c /tmp/libkoutendb_nif.dylib -o /tmp/koutendb_nif_cabi_contract"
      exec "DYLD_LIBRARY_PATH=/tmp /tmp/koutendb_nif_cabi_contract"
    else:
      exec "nim c --app:lib -d:release --hints:off --warnings:off --nimcache:/tmp/koutendb-nif-capi -o:/tmp/libkoutendb_nif.so " & source
      exec "clang -std=c11 -Wall -Wextra -Iinclude examples/cabi_contract.c -L/tmp -lkoutendb_nif -Wl,-rpath,/tmp -o /tmp/koutendb_nif_cabi_contract"
      exec "/tmp/koutendb_nif_cabi_contract"

task verifyCore, "Run CI-safe adapter verification":
  exec "nimble test -y"
  exec "nimble cabiContract -y"

task verifyIntegration, "Run KoutenDB-backed adapter verification":
  exec "nimble integrationTest -y"
  exec "nimble koutendbRoundtrip -y"
  exec "nimble matrixDemo -y"
  exec "nimble cliRoundtrip -y"

task verify, "Run the full KoutenDB NIF adapter verification suite":
  exec "nimble verifyCore -y"
  exec "nimble verifyIntegration -y"
