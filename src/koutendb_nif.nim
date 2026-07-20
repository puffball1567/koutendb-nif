## KoutenDB adapter surface for NIF/BIF payload conversion.
##
## The codec implementation lives in nifkit. This package keeps the KoutenDB
## naming, docs, and future payload-adapter integration separate from the
## general-purpose NIF/BIF toolkit.

import nifkit

export nifkit

proc koutendbNifAdapterInfo*(): string =
  "koutendb-nif: KoutenDB adapter over nifkit"
