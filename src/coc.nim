import httpclient, streams, htmlparser, xmltree, pegs, strutils, sequtils, tables

type
  Ability* = ref object
    str*, con*, pow*, dex*, app*, siz*, int2*, edu*, hp*, mp*, initSan*, idea*, luk*, knowledge*: int

proc getTags*(html, tag: string, attrClass=""): seq[string] =
  var nestCount = 0
  var elem: string
  for i, c in html:
    let max = i + 2 + tag.len
    if html.len <= max:
      break
    if html[i..i+tag.len] == ("<" & tag):
      # class要素が開始タグ内に存在するかの検証
      var startTag = ""
      var pos = i
      while true:
        if html.len <= pos:
          break
        let b = html[pos]
        startTag.add(b)
        if b == '>':
          break
        inc(pos)

      let attrc = "class=\"" & attrClass & "\""
      if (attrClass == "") or (attrc in startTag):
        inc(nestCount)
    if 0 < nestCount and html[i..max] == ("</" & tag & ">"):
      dec(nestCount)
      if nestCount == 0:
        elem.add(html[i..max])
        result.add(elem)
        elem = ""
    if 0 < nestCount:
      elem.add(c)

proc parseAttrValues*(elem: string): seq[int] =
  elem.findAll(peg""" value\=\"\d+\" """)
      .mapIt(it.replace(peg""" [a-zA-Z"=] """, "").parseInt)

proc parseAbility*(html: string): Ability =
  new result
  for elem in html.getTags("tr"):
    if "現在値" in elem:
      let nums = elem.parseAttrValues
      result = Ability(
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
      return

proc parseArts*(html, header: string): Table[string, int] =
  for elem in html.getTags("table"):
    if header in elem:
      for tr in elem.getTags("tr"):
        let sumElem = tr.getTags("td").filterIt("sumTD" in it)
        if 0 < sumElem.len:
          var k = tr.getTags("th")[0][4..^6]
          # 括弧内に任意の文字列を入れられる要素の修正
          if "input" in k:
            k = k.replace(peg"""\(.*""", "")
          let v = sumElem[0].parseAttrValues[0]
          result[k] = v
  
proc parsePcName*(html: string): string =
  for head in html.getTags("div"):
    if "head_breadcrumb" in head:
      result = head.getTags("a")[^1].replace(peg"""\<\/?[^\>]+\>""", "")
      return

proc parsePcLinks*(html: string): seq[string] =
  ## タグページからPCページのURLのリストを取得する。
  for elem in html.getTags("div", attrClass="pc_datas"):
    for elem2 in elem.getTags("div", attrClass="title"):
      for elem3 in elem2.getTags("a"):
        let url = elem3.findAll(peg""" href\=\"[^\"]+\" """)[0]
                       .split("=")[1]
                       .replace("\"", "")
        result.add(url)
  result[2..^1]

proc scrape(format="csv", url: seq[string]): int =
  let headers = ["探索者名", "STR", "CON", "POW", "DEX", "APP", "SIZ", "INT", "EDU", "HP", "MP", "初期SAN", "アイデア", "幸運", "知識"]
  echo headers.join(",")

  let u = "https://charasheet.vampire-blood.net/md735ff4433f26664a3cc8c4e4b6076eb"
  let client = newHttpClient()
  let resp = client.get(u)
  let body = resp.body

  let pcName = body.parsePcName

  let a = body.parseAbility
  let param = [a.str, a.con, a.pow, a.dex, a.app, a.siz, a.int2, a.edu, a.hp, a.mp, a.initSan, a.idea, a.luk, a.knowledge]
  echo pcName & "," & param.join(",")

when isMainModule:
  import cligen
  dispatch(scrape)