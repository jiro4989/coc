import httpclient, streams, htmlparser, xmltree, pegs, strutils, sequtils, tables, marshal
from os import sleep

type
  Ability* = ref object
    str*, con*, pow*, dex*, app*, siz*, int2*, edu*, hp*, mp*, initSan*, idea*, luk*, knowledge*: int

proc getTags*(html, tag: string, attrClass=""): seq[string] =
  ## HTMLのタグ要素をタグを含めて取得
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
  ## HTMLからvalue属性の値を取得
  elem.findAll(peg""" value\=\"\d+\" """)
      .mapIt(it.replace(peg""" [a-zA-Z"=] """, "").parseInt)

proc parseAbility*(html: string): Ability =
  ## 探索者の能力値を取得
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
  ## XX技能の表から能力値を取得
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
  
proc parsePageGenre*(html: string): string =
  ## ページの分類（クトゥルフ神話PCの作成ページかどうかを判定するために）を取得
  for head in html.getTags("ul", attrClass="breadcrumb"):
    for a in head.getTags("a"):
      if "作成ツール" in a:
        result = a.replace(" ", "")
                  .replace("\t", "")
                  .replace("\n", "")
                  .replace(peg"""\<\/?[^\>]+\>""", "")
                  .strip
        return

proc isCoCPcMakingPage*(html: string): bool =
  let genre = html.parsePageGenre
  result = genre == "クトゥルフPC作成ツール"

proc parsePcName*(html: string): string =
  ## 探索者名を取得
  for head in html.getTags("div"):
    if "head_breadcrumb" in head:
      result = head.getTags("a")[^1].replace(peg"""\<\/?[^\>]+\>""", "")
      return

proc parsePcUrls*(html: string): seq[string] =
  ## タグページからPCページのURLのリストを取得する。
  for elem in html.getTags("div", attrClass="pc_datas"):
    for elem2 in elem.getTags("div", attrClass="title"):
      for elem3 in elem2.getTags("a"):
        let url = elem3.findAll(peg""" href\=\"[^\"]+\" """)[0]
                       .split("=")[1]
                       .replace("\"", "")
        result.add(url)
  result[2..^1]

proc parsePcTag*(html: string): seq[string] =
  for elem in html.getTags("a", attrClass="label label-default"):
    let text = elem.replace(peg"""\<\/?a[^\>]*\>""", "")
                   .replace(peg"""\<\/?span[^\>]*\>""", "")
                   .strip
    result.add(text)

proc isListPageUrl*(url: string): bool =
  ## URLがリストページのものかを調べる。
  ## URLは一応
  let lastUrlPath = url.split("/")[^1]
  result = 0 < ["list.html?tag=", "list_coc.html?tag="].filterIt(lastUrlPath.startsWith(it)).len

proc scrape(format="csv", recursive=false, urls: seq[string]): int =
  ## キャラクター保管所から探索者の能力値をスクレイピングしてきて、
  ## 任意のフォーマットで出力する。
  ## 出力する項目を指定しなければ、以下のデータで出力する。
  ##
  ## 1. 全部のせ 探索者の能力値、技能全てを出力する
  ## 2. 能力値のみ出力
  ## 3. 戦闘技能のみ出力
  ## 4. 探索技能のみ出力
  ## 5. 行動技能のみ出力
  ## 6. 交渉技能のみ出力
  ## 7. 知識技能のみ出力
  let abilHeaders = ["STR", "CON", "POW", "DEX", "APP", "SIZ", "INT", "EDU", "HP", "MP", "初期SAN", "アイデア", "幸運", "知識", ]
  let btlHeaders = [ "回避", "キック", "組み付き", "こぶし（パンチ）", "頭突き", "投擲", "マーシャルアーツ", "拳銃", "サブマシンガン", "ショットガン", "マシンガン", "ライフル", ]
  let findHeaders = ["応急手当", "鍵開け", "隠す", "隠れる", "聞き耳", "忍び歩き", "写真術", "精神分析", "追跡", "登攀", "図書館", "目星", ]
  let actHeaders = ["運転", "機械修理", "重機械操作", "乗馬", "水泳", "製作", "操縦", "跳躍", "電気修理", "ナビゲート", "変装", ]
  let negoHeaders = ["言いくるめ", "信用", "値切り", "説得", "母国語", ]
  let intHeaders = [ "医学", "オカルト", "化学", "クトゥルフ神話", "芸術", "経理", "考古学", "コンピューター", "心理学", "人類学", "生物学", "地質学", "電子工学", "天文学", "博物学", "物理学", "法律", "薬学", "歴史", ]
  var headers = @["探索者名"]
  headers.add(abilHeaders)
  headers.add(btlHeaders)
  headers.add(findHeaders)
  headers.add(actHeaders)
  headers.add(negoHeaders)
  headers.add(intHeaders)
  case format
  of "csv":
    echo headers.join(",")
  
  let client = newHttpClient()

  # リストページから探索者のページのURLを取得し、それを後続のスクレイピング対象
  # ページとする。
  var nUrls = urls # 引数でvar指定するとエラーになるため暫定対応
  var pcUrls: seq[string]
  for url in urls:
    # リストページのURLのときはスクレイピングしてページを取得
    if url.isListPageUrl:
      let links = client.get(url).body.parsePcUrls
      pcUrls.add(links)
      continue
    # それ以外はそのまま追加
    pcUrls.add(url)
  nUrls = pcUrls
  
  template addArts(genre: string) =
    block:
      let arts = html.parseArts(genre)
      for k in headers:
        if arts.hasKey(k):
          param.add(arts[k])

  proc parts(html, genre: string): string =
    "\"" & genre & "\":" & $html.parseArts(genre)

  # 探索者のページから能力値を取得して出力する。
  var jsonList: seq[string]
  for url in nUrls:
    let html = client.get(url).body

    # 取得先のURLはクトゥルフ神話のシート以外が混ざっている可能性があるため
    # 取得先URLの一部を判定してクトゥルフ神話以外を除外する。
    if not html.isCoCPcMakingPage:
      continue

    let pcName = html.parsePcName
    let a = html.parseAbility
    case format
    of "csv":
      var param = @[a.str, a.con, a.pow, a.dex, a.app, a.siz, a.int2, a.edu, a.hp, a.mp, a.initSan, a.idea, a.luk, a.knowledge]
      addArts("戦闘技能")
      addArts("探索技能")
      addArts("行動技能")
      addArts("交渉技能")
      addArts("知識技能")
      echo pcName & "," & param.join(",")
    of "json":
      let abil = {"STR":a.str, "CON":a.con, "POW":a.pow, "DEX":a.dex,
                  "APP":a.app, "SIZ":a.siz, "INT":a.int2, "EDU":a.edu,
                  "HP":a.hp, "MP":a.mp, "初期SAN":a.initSan, "アイデア":a.idea,
                  "幸運":a.luk, "知識":a.knowledge}.toTable
      #var data = {"能力値": abil}.toTable
      var pcParam: seq[string]
      pcParam.add("\"" & "能力値" & "\":" & $abil)
      pcParam.add(parts(html, "戦闘技能"))
      pcParam.add(parts(html, "探索技能"))
      pcParam.add(parts(html, "行動技能"))
      pcParam.add(parts(html, "交渉技能"))
      pcParam.add(parts(html, "知識技能"))
      let tags = html.parsePcTag
      jsonList.add("{\"name\":" & $$pcName & ", \"tags\":" & $$tags & ", \"url\":" & $$url & ", \"params\":{" & pcParam.join(",") & "}}")
      
      # echo "\"" & "知識技能" & "\"", ":", html.parseArts(" & ")
      # echo "}"
      #jsonData.add(pcName, data)
    sleep(1)
  case format
  of "json":
    echo "[\n", jsonList.join(",\n"), "\n]"

when isMainModule:
  import cligen
  dispatch(scrape)