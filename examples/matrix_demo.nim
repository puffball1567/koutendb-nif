## KoutenDB NIF adapter matrix demo.
##
## Stores both NIF text and BIF bytes in KoutenDB, then reads them back with
## explicit codec metadata.

import std/[os, strutils]
import koutendb
import koutendb_nif

type DemoCase = object
  ring: string
  nif: string

const Cases = [
  DemoCase(ring: "artifacts/nif/basic",
           nif: "(record title \"KoutenDB\" kind basic)"),
  DemoCase(ring: "artifacts/nif/line-info",
           nif: "(record@5,3,file.nim title@2,0#field# \"KoutenDB\"@4,0)"),
  DemoCase(ring: "artifacts/nif/symbol",
           nif: "(record :thing.0.module value)")
]

proc argValue(name, defaultValue: string): string =
  let prefix = "--" & name & "="
  for arg in commandLineParams():
    if arg.startsWith(prefix):
      return arg[prefix.len .. ^1]
  defaultValue

when isMainModule:
  let dataDir = argValue("data", "")
  var db = open(dataDir = dataDir)
  try:
    for item in Cases:
      let nifId = db.put(encodedPayload(item.nif, pcNif), ring = item.ring)
      let bif = nifToBif(item.nif)
      let bifId = db.put(encodedPayload(bif, pcBif), ring = item.ring)

      let nifStored = db.getEncoded(nifId)
      let bifStored = db.getEncoded(bifId)
      doAssert nifStored.codec == pcNif
      doAssert nifStored.data == item.nif
      doAssert bifStored.codec == pcBif
      doAssert bifToNif(bifStored.data) == item.nif
      echo "ring=", item.ring, " nifBytes=", nifStored.data.len,
           " bifBytes=", bifStored.data.len
  finally:
    db.close()
