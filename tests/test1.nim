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

let p1html = readFile("tests/p1.html")

suite "proc parseAbility":
  test "Parse":
    check p1html.parseAbility[] == Ability(str: 14, con: 18, pow: 11, dex: 9,
                                         app: 9, siz: 13, int2: 14, edu: 12, 
                                         hp: 16, mp: 11, initSan: 55, idea: 70,
                                         luk: 55, knowledge: 60)[]

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
