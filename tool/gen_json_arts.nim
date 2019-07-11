## 能力値のオブジェクト定義を生成する

import parsecsv, strformat, tables, strutils

let m = {
  "BattleArts":"戦闘技能",
  "FindArts":"探索技能",
  "ActionArts":"行動技能",
  "NegotiationArts":"交渉技能",
  "KnowledgeArts":"知識技能"
}.toTable

echo "var arts: Table[string, int]"
for genre in ["BattleArts", "FindArts", "ActionArts", "NegotiationArts", "KnowledgeArts"]:
  echo &"""arts = html.parseArts("{m[genre]}")"""
  let varName = genre[0].toLowerAscii & genre[1..^1]
  echo &"""var {varName}: {genre}"""

  var p: CsvParser
  p.open("key.csv")
  p.readHeaderRow
  while p.readRow:
    let row = p.row
    if row[0] == genre:
      echo &"""{varName}.{row[2]} = CValue(name: "{row[1]}", num: arts["{row[1]}"])"""
  echo ""
  p.close
