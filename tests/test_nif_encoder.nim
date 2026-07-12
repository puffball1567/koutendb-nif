import std/[unittest, strutils]
import ../src/rochedb_nif

suite "NIF to BIF v5 encoder":
  test "reports adapter information":
    check rochedbNifAdapterInfo().contains("nifkit")

  test "encodes a basic compound and round-trips through the decoder":
    let source = "(record title \"RocheDB\" -5 12u)"
    check bifToNif(nifToBif(source)) == source

  test "encodes wide signed integers and a large pooled string":
    let longText = repeat("x", 300)
    let source = "(record -34359738368 \"" & longText & "\")"
    check bifToNif(nifToBif(source)) == source

  test "builds a global symbol index":
    let document = parseBif(nifToBif("(record :thing.0.module x)"))
    check document.index.len == 1
    check document.index[0].visibility == 1

  test "rejects standalone comments because comments are suffixes":
    let source = "(.nif27)\n(.lang \"json\" (oconstr #metadata# (kv title \"RocheDB\")))"
    expect BifError:
      discard nifToBif(source)

  test "preserves suffix comments on tag heads":
    let source = "(.nif27)\n(.lang \"json\" (oconstr#metadata# (kv title \"RocheDB\")))"
    check bifToNif(nifToBif(source)) == source

  test "preserves common line-info positions and filenames through BIF":
    let source = "(record@5,3,file.nim title@2,0 \"RocheDB\"@4,0)"
    check bifToNif(nifToBif(source)) == source

  test "preserves negative relative line-info deltas through BIF":
    let source = "(record@5,3,file.nim title@~2,1)"
    check bifToNif(nifToBif(source)) == source

  test "preserves line-info comments through wide BIF line-info":
    let source = "(record@5,3,file.nim title@2,0#field# \"RocheDB\"@4,0#literal#)"
    check bifToNif(nifToBif(source)) == source
