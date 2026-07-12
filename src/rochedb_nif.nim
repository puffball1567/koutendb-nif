## RocheDB adapter surface for NIF/BIF payload conversion.
##
## The codec implementation lives in nifkit. This package keeps the RocheDB
## naming, docs, and future payload-adapter integration separate from the
## general-purpose NIF/BIF toolkit.

import nifkit

export nifkit

proc rochedbNifAdapterInfo*(): string =
  "rochedb-nif: RocheDB adapter over nifkit"
