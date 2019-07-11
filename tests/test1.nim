import unittest

import coc

import tables, strformat

suite "proc getTags":
  test "Empty tag":
    check "<tr></tr>".getTags("tr") == @["<tr></tr>"]
  test "Empty and attrs":
    check """<tr id="tr1" class="testdiv">hogefuga</tr>""".getTags("tr") == @["""<tr id="tr1" class="testdiv">hogefuga</tr>"""]
    check """<tr id="tr1" class="testdiv"><td>1<td></tr>""".getTags("tr") == @["""<tr id="tr1" class="testdiv"><td>1<td></tr>"""]
    check """<tr id="tr1" class="testdiv"><td>1<td></tr> <td></td> <tr id="tr1" class="testdiv"><td>1<td></tr>""".getTags("tr") == @["""<tr id="tr1" class="testdiv"><td>1<td></tr>""", """<tr id="tr1" class="testdiv"><td>1<td></tr>"""]
  test "Multi elements":
    check """<tr>1</tr><tr>2</tr><tr>3</tr>""".getTags("tr") == @["<tr>1</tr>", "<tr>2</tr>", "<tr>3</tr>"]
  test "Multi line":
    check """
    <tr> 1 </tr>
    <tr> 2 </tr>
    <tr> 3 </tr>""".getTags("tr") == @["<tr> 1 </tr>", "<tr> 2 </tr>", "<tr> 3 </tr>"]
  test "Set class attributes":
    check """<div><div class="test">Elem</div></div>""".getTags("div", attrClass="test") == @["""<div class="test">Elem</div>"""]

let p1html = readFile("tests/p1.html")

suite "proc parseAbility":
  test "Parse":
    check p1html.parseAbility == Ability(
      str:       CValue(name: "STR", num: 14),
      con:       CValue(name: "CON", num: 18),
      pow:       CValue(name: "POW", num: 11),
      dex:       CValue(name: "DEX", num: 9),
      app:       CValue(name: "APP", num: 9),
      siz:       CValue(name: "SIZ", num: 13),
      int2:      CValue(name: "INT", num: 14),
      edu:       CValue(name: "EDU", num: 12),
      hp:        CValue(name: "HP", num: 16),
      mp:        CValue(name: "MP", num: 11),
      initSan:   CValue(name: "初期SAN", num: 55),
      idea:      CValue(name: "アイデア", num: 70),
      luk:       CValue(name: "幸運", num: 55),
      knowledge: CValue(name: "知識", num: 60))

block:
  let allianHtml = readFile("tests/allian.html")

  suite "proc parsePageGenre":
    test "page is CoC":
      check p1html.parsePageGenre == "クトゥルフPC作成ツール"
    test "page is アリアンロッド":
      check allianHtml.parsePageGenre == "アリアンロッドギルド作成ツール"

  suite "proc isCoCPcMakingPage":
    test "page is CoC":
      check p1html.isCoCPcMakingPage
    test "page is アリアンロッド":
      check not allianHtml.isCoCPcMakingPage

suite "proc parsePcName":
  test "Parse":
    check p1html.parsePcName == "神田 真（かんだ まこと）"

suite "proc parseArts":
  test "戦闘技能":
    let ret = p1html.parseArts("戦闘技能")
    check ret["回避"] == 38
    check ret["キック"] == 25
    check ret["組み付き"] == 70
    check ret["こぶし（パンチ）"] == 50
    check ret["頭突き"] == 10
    check ret["投擲"] == 25
    check ret["マーシャルアーツ"] == 1
    check ret["拳銃"] == 20
    check ret["サブマシンガン"] == 15
    check ret["ショットガン"] == 30
    check ret["マシンガン"] == 15
    check ret["ライフル"] == 25
  test "探索技能":
    let ret = p1html.parseArts("探索技能")
    # for k in ret.keys:
    #   echo &"""check ret["{k}"] == 1"""
    check ret["応急手当"] == 80
    check ret["鍵開け"] == 1
    check ret["隠す"] == 15
    check ret["隠れる"] == 10
    check ret["聞き耳"] == 64
    check ret["忍び歩き"] == 10
    check ret["写真術"] == 60
    check ret["精神分析"] == 1
    check ret["追跡"] == 10
    check ret["登攀"] == 40
    check ret["図書館"] == 30
    check ret["目星"] == 84
  test "行動技能":
    let ret = p1html.parseArts("行動技能")
    check ret["運転"] == 53
    check ret["機械修理"] == 20
    check ret["重機械操作"] == 1
    check ret["乗馬"] == 5
    check ret["水泳"] == 25
    check ret["製作"] == 5
    check ret["操縦"] == 1
    check ret["跳躍"] == 25
    check ret["電気修理"] == 10
    check ret["ナビゲート"] == 10
    check ret["変装"] == 1
  test "交渉技能":
    let ret = p1html.parseArts("交渉技能")
    check ret["言いくるめ"] == 5
    check ret["信用"] == 60
    check ret["値切り"] == 5
    check ret["説得"] == 15
    check ret["母国語"] == 60
  test "知識技能":
    let ret = p1html.parseArts("知識技能")
    check ret["医学"] == 5
    check ret["オカルト"] == 5
    check ret["化学"] == 1
    check ret["クトゥルフ神話"] == 0
    check ret["芸術"] == 5
    check ret["経理"] == 10
    check ret["考古学"] == 1
    check ret["コンピューター"] == 4
    check ret["心理学"] == 5
    check ret["人類学"] == 1
    check ret["生物学"] == 1
    check ret["地質学"] == 1
    check ret["電子工学"] == 1
    check ret["天文学"] == 1
    check ret["博物学"] == 10
    check ret["物理学"] == 1
    check ret["法律"] == 5
    check ret["薬学"] == 1
    check ret["歴史"] == 70

let listHtml = readFile("tests/list1.html")

suite "proc parsePcUrls":
  test "Parse":
   check listHtml.parsePcUrls == @[
     "https://charasheet.vampire-blood.net/md735ff4433f26664a3cc8c4e4b6076eb",
     "https://charasheet.vampire-blood.net/m3c43564fef578aec972f0c8302fdd84a",
     "https://charasheet.vampire-blood.net/me8756567322569dc7ba24620ecbde76e",
     "https://charasheet.vampire-blood.net/md0b578e35b9772be5d90d3cb1a73118e",
     "https://charasheet.vampire-blood.net/mb001af1a4d0f547fd9392976df18615a",
     "https://charasheet.vampire-blood.net/m4df7d6cb4439ac774c29e7c2dcf7cd2f",
     "https://charasheet.vampire-blood.net/m1d2d6e28548626b6580488bea972ed9b",
   ]

suite "proc parsePcTag":
  test "Parse":
   check p1html.parsePcTag == @["jiro"]

suite "proc isListPageUrl":
  test "Normal url":
   check "https://charasheet.vampire-blood.net/list.html?tag=jiro".isListPageUrl
   check "https://charasheet.vampire-blood.net/list.html?tag=".isListPageUrl
   check "https://charasheet.vampire-blood.net/list.html?tag=あ".isListPageUrl
   check "https://charasheet.vampire-blood.net/list_coc.html?tag=あ".isListPageUrl
  test "Not list url":
   check not "https://charasheet.vampire-blood.net/md735ff4433f26664a3cc8c4e4b6076eb".isListPageUrl

suite "proc hasListItem":
  test "true":
    check listhtml.hasListItem
  test "false":
    let html = "tests/list_out.html".readFile
    check not html.hasListItem
