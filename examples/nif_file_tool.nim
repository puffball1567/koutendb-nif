## Minimal file tool used by CLI integration demos.

import std/[base64, json, os, strutils]
import koutendb_nif

proc usage() =
  quit "usage: nif_file_tool encode|decode|decode-cli --in=FILE --out=FILE", 2

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
  of "decode-cli":
    let document = parseJson(readFile(input))
    let items = document["items"]
    if items.kind != JArray or items.len != 1:
      raise newException(ValueError, "expected exactly one CLI result")
    let item = items[0]
    if item["codec"].getStr != "bif" or item["encoding"].getStr != "base64":
      raise newException(ValueError, "expected a base64 BIF CLI payload")
    writeFile(output, bifToNif(decode(item["payload"].getStr)))
  else:
    usage()
