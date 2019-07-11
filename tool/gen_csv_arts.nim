## CSV用のHTMLパースコードの生成

import parsecsv, strformat, tables

let m = {
  "BattleArts":"戦闘技能",
  "FindArts":"探索技能",
  "ActionArts":"行動技能",
  "NegotiationArts":"交渉技能",
  "KnowledgeArts":"知識技能"
}.toTable

for genre in ["BattleArts", "FindArts", "ActionArts", "NegotiationArts", "KnowledgeArts"]:
  echo "block:"
  echo &"""  let arts = html.parseArts("{m[genre]}")"""
  var p: CsvParser
  p.open("key.csv")
  p.readHeaderRow
  while p.readRow:
    let row = p.row
    if row[0] == genre:
      echo &"""  param.add(arts["{row[1]}"])    ## {row[1]}"""
  echo ""
  p.close
