import nimquery

import httpclient, streams, htmlparser, xmltree, pegs, strutils, sequtils

type
  Ability = ref object
    str, con, pow, dex, app, siz, int2, edu, hp, mp, initSan, idea, luk, knowledge: int

proc getTags(html, tag: string): seq[string] =
  var nestCount = 0
  var elem: string
  for i, c in html:
    let max = i + 2 + tag.len
    if html.len <= max:
      break
    if html[i..i+tag.len] == ("<" & tag):
      inc(nestCount)
    if html[i..max] == ("</" & tag & ">"):
      dec(nestCount)
      if nestCount == 0:
        elem.add(html[i..max])
        result.add(elem)
        elem = ""
    if 0 < nestCount:
      elem.add(c)

proc scrape(url: seq[string]): int =
  let u = "https://charasheet.vampire-blood.net/md735ff4433f26664a3cc8c4e4b6076eb"
  let client = newHttpClient()
  let resp = client.get(u)
  let body = resp.body

  for elem in body.getTags("tr"):
    if "現在値" in elem:
      echo elem
      echo "------------"
      let nums = elem.findAll(peg""" value\=\"\d+\" """).mapIt(it.replace(peg""" [a-zA-Z"=] """, "").parseInt)
      var abil = Ability(
        str: nums[0],
        con: nums[1],
        pow: nums[2],
        dex: nums[3],
        app: nums[4],
        siz: nums[5],
        int2: nums[6],
        edu: nums[7],
        hp: nums[8],
        mp: nums[9],
        initSan: nums[10],
        idea: nums[11],
        luk: nums[12],
        knowledge: nums[13])
      echo abil[]

      #let html = elem.newStringStream.parseHtml
      #echo html.querySelectorAll("td")

  when false:
    let html = resp.body.newStringStream.parseHtml
    when false:
      let nodes = html.querySelectorAll("table.pc_making")
      for node in nodes:
        echo node[]
        for node2 in node.querySelectorAll("tbody > tr > th"):
          echo node2[]
    block:
      let nodes = html.querySelectorAll(".sumTD > input")
      for node in nodes:
        echo node.attr("value")
  # if nodes.len < 1:
  #   return
  # for node in nodes:
  #   let nodes2 = node.querySelectorAll("tr")[1..^1]
  #   for node2 in nodes2:
  #     echo node2.querySelector("th").innerText

when isMainModule and false:
  import cligen
  dispatch(scrape)
else:
  discard scrape(@[])