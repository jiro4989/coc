import unittest

import coc

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