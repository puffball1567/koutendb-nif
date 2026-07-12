## RocheDB integration demo for the rochedb-nif adapter.
##
## This verifies the intended ownership boundary:
## - rochedb-nif/nifkit converts NIF text to BIF bytes.
## - RocheDB stores and returns the bytes with explicit codec metadata.
## - rochedb-nif/nifkit decodes the retrieved BIF bytes back to NIF text.

import std/[os, strutils]
import rochedb
import rochedb_nif

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
    let nifText = "(record title \"RocheDB\" kind adapter)"
    let bifBytes = nifToBif(nifText)
    let id = db.put(encodedPayload(bifBytes, pcBif), ring = "artifacts/nif")

    let stored = db.getEncoded(id)
    doAssert stored.codec == pcBif
    doAssert stored.data == bifBytes
    doAssert bifToNif(stored.data) == nifText

    echo "rochedb-nif RocheDB roundtrip passed codec=",
         stored.codec.payloadCodecName, " bytes=", stored.data.len
  finally:
    db.close()

  if dataDir.len > 0:
    var reopened = open(dataDir = dataDir)
    try:
      let page = reopened.listByRing("artifacts/nif", limit = 1)
      doAssert page.items.len == 1
      doAssert page.items[0].codec == pcBif
      doAssert bifToNif(page.items[0].payload) == "(record title \"RocheDB\" kind adapter)"
      echo "rochedb-nif persisted RocheDB roundtrip passed"
    finally:
      reopened.close()
