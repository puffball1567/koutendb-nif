import std/[strutils, unittest]
import koutendb_nif
import rochedb_nif

type AdapterCase = object
  name: string
  source: string
  expected: string

const Cases = [
  AdapterCase(name: "current NIF numeric and string syntax",
              source: "(record 0xFF 0o377 0b1111_1111 1_000 1_2.5E+0_1 \"key: #value\")",
              expected: "(record 255 255 255 1000 125.0 \"key\\3A \\23value\")"),
  AdapterCase(name: "basic record",
              source: "(record title \"KoutenDB\" -5 12u)",
              expected: "(record title \"KoutenDB\" -5 12u)"),
  AdapterCase(name: "directives and comments",
              source: "(.nif27)\n(.lang \"json\" (oconstr#metadata# (kv title \"KoutenDB\")))",
              expected: "(.nif27)\n(.lang \"json\" (oconstr#metadata# (kv title \"KoutenDB\")))"),
  AdapterCase(name: "escaped string",
              source: "(record text \"line\\nquote\\^slash\\|\")",
              expected: "(record text \"line\\nquote\\^slash\\|\")"),
  AdapterCase(name: "line-info",
              source: "(record@5,3,file.nim title@2,0#field# \"KoutenDB\"@4,0#literal#)",
              expected: "(record@5,3,file.nim title@2,0#field# \"KoutenDB\"@4,0#literal#)")
]

suite "KoutenDB NIF adapter matrix":
  test "adapter reports nifkit backend":
    check koutendbNifAdapterInfo().contains("nifkit")
    check codecInfo().contains("NIF/BIF v5")

  test "legacy adapter import remains compatible":
    check rochedbNifAdapterInfo() == "rochedb-nif: RocheDB adapter over nifkit"
    let bif = rochedb_nif.nifToBif("(record 0xFF)")
    check koutendb_nif.bifToNif(bif) == "(record 255)"

  for item in Cases:
    test item.name:
      let bif = nifToBif(item.source)
      validateBif(bif)
      check bifToNif(bif) == item.expected

  test "adapter keeps global symbol index visible":
    let doc = parseBif(nifToBif("(record :thing.0.module value)"))
    check doc.index.len == 1
    check doc.index[0].visibility == 1
