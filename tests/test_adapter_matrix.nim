import std/[strutils, unittest]
import rochedb_nif

type AdapterCase = object
  name: string
  source: string
  expected: string

const Cases = [
  AdapterCase(name: "basic record",
              source: "(record title \"RocheDB\" -5 12u)",
              expected: "(record title \"RocheDB\" -5 12u)"),
  AdapterCase(name: "directives and comments",
              source: "(.nif27)\n(.lang \"json\" (oconstr#metadata# (kv title \"RocheDB\")))",
              expected: "(.nif27)\n(.lang \"json\" (oconstr#metadata# (kv title \"RocheDB\")))"),
  AdapterCase(name: "escaped string",
              source: "(record text \"line\\nquote\\^slash\\|\")",
              expected: "(record text \"line\\nquote\\^slash\\|\")"),
  AdapterCase(name: "line-info",
              source: "(record@5,3,file.nim title@2,0#field# \"RocheDB\"@4,0#literal#)",
              expected: "(record@5,3,file.nim title@2,0#field# \"RocheDB\"@4,0#literal#)")
]

suite "RocheDB NIF adapter matrix":
  test "adapter reports nifkit backend":
    check rochedbNifAdapterInfo().contains("nifkit")
    check codecInfo().contains("NIF/BIF v5")

  for item in Cases:
    test item.name:
      let bif = nifToBif(item.source)
      validateBif(bif)
      check bifToNif(bif) == item.expected

  test "adapter keeps global symbol index visible":
    let doc = parseBif(nifToBif("(record :thing.0.module value)"))
    check doc.index.len == 1
    check doc.index[0].visibility == 1
