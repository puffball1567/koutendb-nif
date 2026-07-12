## Minimal file tool used by CLI integration demos.

import std/[os, strutils]
import rochedb_nif

proc usage() =
  quit "usage: nif_file_tool encode|decode --in=FILE --out=FILE", 2

proc argValue(name: string): string =
  let prefix = "--" & name & "="
  for arg in commandLineParams():
    if arg.startsWith(prefix):
      return arg[prefix.len .. ^1]
  ""

when isMainModule:
  let args = commandLineParams()
  if args.len == 0:
    usage()
  let input = argValue("in")
  let output = argValue("out")
  if input.len == 0 or output.len == 0:
    usage()

  case args[0]
  of "encode":
    writeFile(output, nifToBif(readFile(input)))
  of "decode":
    writeFile(output, bifToNif(readFile(input)))
  else:
    usage()
