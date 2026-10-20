## Compatibility import for consumers of the original RocheDB adapter.
import koutendb_nif
export koutendb_nif

proc rochedbNifAdapterInfo*(): string =
  "rochedb-nif: RocheDB adapter over nifkit"
