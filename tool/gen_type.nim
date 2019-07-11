## 能力値のオブジェクト定義を生成する

import parsecsv, strformat

for genre in ["BattleArts", "FindArts", "ActionArts", "NegotiationArts", "KnowledgeArts"]:
  echo &"  {genre}* = object"

  var p: CsvParser
  p.open("key.csv")
  p.readHeaderRow
  while p.readRow:
    let row = p.row
    if row[0] == genre:
      echo &"""    {row[2]}*: CValues    ## {row[1]}"""
  echo ""
  p.close
