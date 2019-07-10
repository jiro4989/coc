import httpclient, streams, htmlparser, xmltree, pegs, strutils, sequtils, tables

type
  Ability* = ref object
    str*, con*, pow*, dex*, app*, siz*, int2*, edu*, hp*, mp*, initSan*, idea*, luk*, knowledge*: int

proc getTags*(html, tag: string): seq[string] =
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

proc scrape(url: seq[string]): int =
  let u = "https://charasheet.vampire-blood.net/md735ff4433f26664a3cc8c4e4b6076eb"
  let client = newHttpClient()
  let resp = client.get(u)
  let body = resp.body

  let ability = body.parseAbility
  echo ability[]

when isMainModule and false:
  import cligen
  dispatch(scrape)
else:
  discard scrape(@[])