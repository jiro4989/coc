import httpclient, streams, htmlparser, xmltree, pegs, strutils, sequtils, tables, marshal, logging
from os import sleep
from strformat import `&`

type
  Pc* = ref object
    id*: string
    name*: string
    tags*: seq[string]
    url*: string
    param*: Param
  Param* = ref object
    ability*: Ability
    battleArts*: BattleArts
    findArts*: FindArts
    actionArts*: ActionArts
    negotiationArts*: NegotiationArts
    knowledgeArts*: KnowledgeArts
  CValue* = object
    name*: string
    num*: int
  Ability* = ref object
    str*: CValue    ## STR
    con*: CValue    ## CON
    pow*: CValue    ## POW
    dex*: CValue    ## DEX
    app*: CValue    ## APP
    siz*: CValue    ## SIZ
    int2*: CValue    ## INT
    edu*: CValue    ## EDU
    hp*: CValue    ## HP
    mp*: CValue    ## MP
    initSan*: CValue    ## 初期SAN
    idea*: CValue    ## アイデア
    luk*: CValue    ## 幸運
    knowledge*: CValue    ## 知識
  BattleArts* = ref object
    avoidance*: CValue    ## 回避
    kick*: CValue    ## キック
    hold*: CValue    ## 組み付き
    punch*: CValue    ## こぶし（パンチ）
    headThrust*: CValue    ## 頭突き
    throwing*: CValue    ## 投擲
    martialArts*: CValue    ## マーシャルアーツ
    handGun*: CValue    ## 拳銃
    submachineGun*: CValue    ## サブマシンガン
    shotGun*: CValue    ## ショットガン
    machineGun*: CValue    ## マシンガン
    rifle*: CValue    ## ライフル
  FindArts* = ref object
    firstAid*: CValue    ## 応急手当
    lockPicking*: CValue    ## 鍵開け
    hide*: CValue    ## 隠す
    disappear*: CValue    ## 隠れる
    ear*: CValue    ## 聞き耳
    quietStep*: CValue    ## 忍び歩き
    photography*: CValue    ## 写真術
    psychoAnalysis*: CValue    ## 精神分析
    tracking*: CValue    ## 追跡
    climbing*: CValue    ## 登攀
    library*: CValue    ## 図書館
    aim*: CValue    ## 目星
  ActionArts* = ref object
    driving*: CValue    ## 運転
    repairingMachine*: CValue    ## 機械修理
    operatingHeavyMachine*: CValue    ## 重機械操作
    ridingHorse*: CValue    ## 乗馬
    swimming*: CValue    ## 水泳
    creating*: CValue    ## 製作
    control*: CValue    ## 操縦
    jumping*: CValue    ## 跳躍
    repairingElectric*: CValue    ## 電気修理
    navigate*: CValue    ## ナビゲート
    disguise*: CValue    ## 変装
  NegotiationArts* = ref object
    winOver*: CValue    ## 言いくるめ
    credit*: CValue    ## 信用
    haggle*: CValue    ## 値切り
    argue*: CValue    ## 説得
    nativeLanguage*: CValue    ## 母国語
  KnowledgeArts* = ref object
    medicine*: CValue    ## 医学
    occult*: CValue    ## オカルト
    chemistry*: CValue    ## 化学
    cthulhuMythology*: CValue    ## クトゥルフ神話
    art*: CValue    ## 芸術
    accounting*: CValue    ## 経理
    archeology*: CValue    ## 考古学
    computer*: CValue    ## コンピューター
    psychology*: CValue    ## 心理学
    anthropology*: CValue    ## 人類学
    biology*: CValue    ## 生物学
    geology*: CValue    ## 地質学
    electronicEngineering*: CValue    ## 電子工学
    astronomy*: CValue    ## 天文学
    naturalHistory*: CValue    ## 博物学
    physics*: CValue    ## 物理学
    law*: CValue    ## 法律
    pharmacy*: CValue    ## 薬学
    history*: CValue    ## 歴史

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
        str:       CValue(name: "STR", num: nums[0]),
        con:       CValue(name: "CON", num: nums[1]),
        pow:       CValue(name: "POW", num: nums[2]),
        dex:       CValue(name: "DEX", num: nums[3]),
        app:       CValue(name: "APP", num: nums[4]),
        siz:       CValue(name: "SIZ", num: nums[5]),
        int2:      CValue(name: "INT", num: nums[6]),
        edu:       CValue(name: "EDU", num: nums[7]),
        hp:        CValue(name: "HP", num: nums[8]),
        mp:        CValue(name: "MP", num: nums[9]),
        initSan:   CValue(name: "初期SAN", num: nums[10]),
        idea:      CValue(name: "アイデア", num: nums[11]),
        luk:       CValue(name: "幸運", num: nums[12]),
        knowledge: CValue(name: "知識", num: nums[13]))
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

proc hasListItem*(html: string): bool =
  result = true
  for elem in html.getTags("div", attrClass="maincontent"):
    for elem2 in elem.getTags("h3"):
      if "リスト項目がありません" in elem2:
        return false

proc addPcPageUrlResursive(urls: var seq[string], client: HttpClient, url: string, waitTime: int) =
  ## urlにリストページのURLを指定すると、次のリストページを順に辿っていき、
  ## ページがなくなるまで探索者のページURLを取得して追加する。
  for i in 1..100:
    let nextUrl = url & "&order=&page=" & $i
    debug &"Next list url is {nextUrl}"
    let html = client.get(nextUrl).body
    sleep(waitTime)
    if html.hasListItem:
      urls.add(html.parsePcUrls)
      continue
    return

proc scrape(format="csv", recursive=false, debug=false, waitTime=1000, oneLine=false, urls: seq[string]): int =
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
  if debug:
    addHandler(newConsoleLogger(lvlAll, useStderr=true))
  debug &"main start:"

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
  of "json":
    if not oneLine:
      echo "["
  
  let client = newHttpClient()

  # リストページから探索者のページのURLを取得し、それを後続のスクレイピング対象
  # ページとする。
  var nUrls = urls # 引数でvar指定するとエラーになるため暫定対応
  var pcUrls: seq[string]
  for url in urls:
    # リストページのURLのときはスクレイピングしてページを取得
    if url.isListPageUrl:
      debug &"{url} is a list url."
      pcUrls.addPcPageUrlResursive(client, url, waitTime)
      continue
    # それ以外はそのまま追加
    debug &"{url} is a pc url."
    pcUrls.add(url)
  nUrls = pcUrls
  
  when false:
    template addArts(genre: string) =
      block:
        let arts = html.parseArts(genre)
        for k in headers:
          if arts.hasKey(k):
            param.add(arts[k])

  proc parts(html, genre: string): string =
    "\"" & genre & "\":" & $html.parseArts(genre)

  # 探索者のページから能力値を取得して出力する。
  for i, url in nUrls:
    debug &"Scraping start: [{i+1}/{nUrls.len}] i = {i}, url = {url}"

    let html = client.get(url).body

    # 取得先のURLはクトゥルフ神話のシート以外が混ざっている可能性があるため
    # 取得先URLの一部を判定してクトゥルフ神話以外を除外する。
    if not html.isCoCPcMakingPage:
      debug &"{url} is not Coc url."
      continue

    let pcName = html.parsePcName
    let a = html.parseAbility
    case format
    of "csv":
      when false:
        var param = @[a.str, a.con, a.pow, a.dex, a.app, a.siz, a.int2, a.edu, a.hp, a.mp, a.initSan, a.idea, a.luk, a.knowledge]
        addArts("戦闘技能")
        addArts("探索技能")
        addArts("行動技能")
        addArts("交渉技能")
        addArts("知識技能")
        echo pcName & "," & param.join(",")
    of "json":
      let id = url.split("/")[^1]
      let tags = html.parsePcTag

      var arts: Table[string, int]
      arts = html.parseArts("戦闘技能")
      var battleArts = new BattleArts
      battleArts.avoidance = CValue(name: "回避", num: arts["回避"])
      battleArts.kick = CValue(name: "キック", num: arts["キック"])
      battleArts.hold = CValue(name: "組み付き", num: arts["組み付き"])
      battleArts.punch = CValue(name: "こぶし（パンチ）", num: arts["こぶし（パンチ）"])
      battleArts.headThrust = CValue(name: "頭突き", num: arts["頭突き"])
      battleArts.throwing = CValue(name: "投擲", num: arts["投擲"])
      battleArts.martialArts = CValue(name: "マーシャルアーツ", num: arts["マーシャルアーツ"])
      battleArts.handGun = CValue(name: "拳銃", num: arts["拳銃"])
      battleArts.submachineGun = CValue(name: "サブマシンガン", num: arts["サブマシンガン"])
      battleArts.shotGun = CValue(name: "ショットガン", num: arts["ショットガン"])
      battleArts.machineGun = CValue(name: "マシンガン", num: arts["マシンガン"])
      battleArts.rifle = CValue(name: "ライフル", num: arts["ライフル"])
      
      arts = html.parseArts("探索技能")
      var findArts = new FindArts
      findArts.firstAid = CValue(name: "応急手当", num: arts["応急手当"])
      findArts.lockPicking = CValue(name: "鍵開け", num: arts["鍵開け"])
      findArts.hide = CValue(name: "隠す", num: arts["隠す"])
      findArts.disappear = CValue(name: "隠れる", num: arts["隠れる"])
      findArts.ear = CValue(name: "聞き耳", num: arts["聞き耳"])
      findArts.quietStep = CValue(name: "忍び歩き", num: arts["忍び歩き"])
      findArts.photography = CValue(name: "写真術", num: arts["写真術"])
      findArts.psychoAnalysis = CValue(name: "精神分析", num: arts["精神分析"])
      findArts.tracking = CValue(name: "追跡", num: arts["追跡"])
      findArts.climbing = CValue(name: "登攀", num: arts["登攀"])
      findArts.library = CValue(name: "図書館", num: arts["図書館"])
      findArts.aim = CValue(name: "目星", num: arts["目星"])
      
      arts = html.parseArts("行動技能")
      var actionArts = new ActionArts
      actionArts.driving = CValue(name: "運転", num: arts["運転"])
      actionArts.repairingMachine = CValue(name: "機械修理", num: arts["機械修理"])
      actionArts.operatingHeavyMachine = CValue(name: "重機械操作", num: arts["重機械操作"])
      actionArts.ridingHorse = CValue(name: "乗馬", num: arts["乗馬"])
      actionArts.swimming = CValue(name: "水泳", num: arts["水泳"])
      actionArts.creating = CValue(name: "製作", num: arts["製作"])
      actionArts.control = CValue(name: "操縦", num: arts["操縦"])
      actionArts.jumping = CValue(name: "跳躍", num: arts["跳躍"])
      actionArts.repairingElectric = CValue(name: "電気修理", num: arts["電気修理"])
      actionArts.navigate = CValue(name: "ナビゲート", num: arts["ナビゲート"])
      actionArts.disguise = CValue(name: "変装", num: arts["変装"])
      
      arts = html.parseArts("交渉技能")
      var negotiationArts = new NegotiationArts
      negotiationArts.winOver = CValue(name: "言いくるめ", num: arts["言いくるめ"])
      negotiationArts.credit = CValue(name: "信用", num: arts["信用"])
      negotiationArts.haggle = CValue(name: "値切り", num: arts["値切り"])
      negotiationArts.argue = CValue(name: "説得", num: arts["説得"])
      negotiationArts.nativeLanguage = CValue(name: "母国語", num: arts["母国語"])
      
      arts = html.parseArts("知識技能")
      var knowledgeArts = new KnowledgeArts
      knowledgeArts.medicine = CValue(name: "医学", num: arts["医学"])
      knowledgeArts.occult = CValue(name: "オカルト", num: arts["オカルト"])
      knowledgeArts.chemistry = CValue(name: "化学", num: arts["化学"])
      knowledgeArts.cthulhuMythology = CValue(name: "クトゥルフ神話", num: arts["クトゥルフ神話"])
      knowledgeArts.art = CValue(name: "芸術", num: arts["芸術"])
      knowledgeArts.accounting = CValue(name: "経理", num: arts["経理"])
      knowledgeArts.archeology = CValue(name: "考古学", num: arts["考古学"])
      knowledgeArts.computer = CValue(name: "コンピューター", num: arts["コンピューター"])
      knowledgeArts.psychology = CValue(name: "心理学", num: arts["心理学"])
      knowledgeArts.anthropology = CValue(name: "人類学", num: arts["人類学"])
      knowledgeArts.biology = CValue(name: "生物学", num: arts["生物学"])
      knowledgeArts.geology = CValue(name: "地質学", num: arts["地質学"])
      knowledgeArts.electronicEngineering = CValue(name: "電子工学", num: arts["電子工学"])
      knowledgeArts.astronomy = CValue(name: "天文学", num: arts["天文学"])
      knowledgeArts.naturalHistory = CValue(name: "博物学", num: arts["博物学"])
      knowledgeArts.physics = CValue(name: "物理学", num: arts["物理学"])
      knowledgeArts.law = CValue(name: "法律", num: arts["法律"])
      knowledgeArts.pharmacy = CValue(name: "薬学", num: arts["薬学"])
      knowledgeArts.history = CValue(name: "歴史", num: arts["歴史"])
      
      let pc = Pc(id: id, name: pcName, tags: tags, url: url,
                  param: Param(ability: a,
                               battleArts: battleArts,
                               findArts: findArts,
                               actionArts: actionArts,
                               negotiationArts: negotiationArts,
                               knowledgeArts: knowledgeArts))

      var data = $$pc
      # 1行ずつデータを出力するが、最後のデータのときはカンマ区切りが不要
      if i != nUrls.len - 1 and not oneLine:
        data.add(",")
      echo data
    sleep(waitTime)
    debug &"Scraping end:"
  case format
  of "json":
    if not oneLine:
      echo "]"
  debug &"main end:"

when isMainModule:
  import cligen
  dispatch(scrape, short={"debug":'X', "oneLine":'l', "waitTime":'t'})