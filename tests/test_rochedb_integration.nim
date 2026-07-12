import std/[os, tempfiles, unittest]
import rochedb
import rochedb_nif

const
  NifText = "(record@5,3,file.nim title@2,0#field# \"RocheDB\"@4,0)"
  UpdatedNifText = "(record title \"Updated\" kind adapter)"

type StorageCase = object
  ring: string
  source: string
  codec: PayloadCodec

suite "RocheDB integration":
  test "stores nifkit-produced BIF bytes with explicit codec metadata":
    var db = open()
    try:
      let bif = nifToBif(NifText)
      let id = db.put(encodedPayload(bif, pcBif), ring = "artifacts/nif")
      let stored = db.getEncoded(id)
      check stored.codec == pcBif
      check stored.data == bif
      check bifToNif(stored.data) == NifText
    finally:
      db.close()

  test "persists and reopens BIF payloads without changing bytes":
    let dir = createTempDir("rochedb-nif", "persist")
    try:
      let bif = nifToBif(NifText)
      var id: RocheId
      block:
        var db = open(dataDir = dir)
        try:
          id = db.put(encodedPayload(bif, pcBif), ring = "artifacts/nif")
        finally:
          db.close()

      var reopened = open(dataDir = dir)
      try:
        let stored = reopened.getEncoded(id)
        check stored.codec == pcBif
        check stored.data == bif
        check bifToNif(stored.data) == NifText

        let page = reopened.listByRing("artifacts/nif", limit = 4)
        check page.items.len == 1
        check page.items[0].codec == pcBif
        check page.items[0].payload == bif
      finally:
        reopened.close()
    finally:
      removeDir(dir)

  test "transaction commit preserves BIF codec metadata":
    var db = open()
    try:
      let bif = nifToBif(NifText)
      var id: RocheId
      db.transaction(proc(tx: RocheTx) =
        id = tx.put(encodedPayload(bif, pcBif), ring = "artifacts/nif")
      )
      let stored = db.getEncoded(id)
      check stored.codec == pcBif
      check bifToNif(stored.data) == NifText
    finally:
      db.close()

  test "update replaces BIF bytes and keeps BIF codec metadata":
    var db = open()
    try:
      let id = db.put(encodedPayload(nifToBif(NifText), pcBif),
                     ring = "artifacts/nif")
      let updated = nifToBif(UpdatedNifText)
      db.update(id, encodedPayload(updated, pcBif))
      let stored = db.getEncoded(id)
      check stored.codec == pcBif
      check stored.data == updated
      check bifToNif(stored.data) == UpdatedNifText
    finally:
      db.close()

  test "ring payload profile can default writes to BIF":
    var db = open()
    try:
      db.configureRingPayloadProfile("artifacts/nif",
        RingPayloadProfile(defaultCodec: pcBif, charset: "UTF-8",
                           formatVersion: "5"))
      let bif = nifToBif(NifText)
      let id = db.putUsingRingProfile(bif, ring = "artifacts/nif")
      let stored = db.getEncoded(id)
      check stored.codec == pcBif
      check stored.data == bif
      check bifToNif(stored.data) == NifText
    finally:
      db.close()

  test "JSON projection stays disabled for BIF payloads":
    var db = open()
    try:
      let id = db.put(encodedPayload(nifToBif(NifText), pcBif),
                     ring = "artifacts/nif")
      let fields = prepareSelection("{ title }")
      expect ValueError:
        discard db.query(id, fields)
    finally:
      db.close()

  test "storage matrix preserves explicit NIF and BIF codecs across rings":
    let cases = [
      StorageCase(ring: "matrix/nif/basic",
                  source: "(record title \"RocheDB\" kind nif)",
                  codec: pcNif),
      StorageCase(ring: "matrix/bif/basic",
                  source: "(record title \"RocheDB\" kind bif)",
                  codec: pcBif),
      StorageCase(ring: "matrix/bif/line-info",
                  source: "(record@5,3,file.nim title@2,0 \"RocheDB\"@4,0)",
                  codec: pcBif)
    ]
    var db = open()
    try:
      for item in cases:
        let bytes =
          if item.codec == pcBif: nifToBif(item.source)
          else: item.source
        let id = db.put(encodedPayload(bytes, item.codec), ring = item.ring)
        let stored = db.getEncoded(id)
        check stored.codec == item.codec
        check stored.data == bytes
        if item.codec == pcBif:
          check bifToNif(stored.data) == item.source
      for item in cases:
        let page = db.listByRing(item.ring, limit = 10)
        check page.items.len == 1
        check page.items[0].codec == item.codec
    finally:
      db.close()
