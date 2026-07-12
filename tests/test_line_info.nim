import std/unittest
import nifkit/line_info

suite "NIF line-info":
  test "parses base62 relative positions with filename and comment":
    var pos = 0
    let value = parseLineInfo("@5,3,file.nim#note#", pos, LineInfo())
    check value.column == 5
    check value.line == 3
    check value.filename == "file.nim"
    check value.comment == "note"
    check pos == "@5,3,file.nim#note#".len

  test "round-trips negative relative positions":
    let parent = LineInfo(column: 20, line: 10, filename: "a.nim")
    let value = LineInfo(column: 17, line: 14, filename: "a.nim")
    var pos = 0
    let rendered = renderLineInfo(value, parent)
    check parseLineInfo(rendered, pos, parent) == value
