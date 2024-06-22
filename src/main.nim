import std/[httpclient, strformat, htmlparser, xmltree, strutils, tables]
import jester, asyncdispatch
import json
import times

iterator extractWithTag(x: XmlNode, name:string): XmlNode {.closure.}=
  if x.kind == xnElement:
    if(x.len > 0):
      for i in 0..<x.len:
        for sub in extractWithTag(x[i], name):
          yield sub
    if x.attr(name) != "":
      yield x

proc containsClass(classValue: string, lookFor: string): bool=
  for x in classValue.split(" "):
    if(x == lookFor):
      return true
  return false

proc nodeOfClass(n: XmlNode, class: string): seq[XmlNode]=
  result = newSeq[XmlNode]()
  for ele in n.extractWithTag("class"):
    if ele.attr("class").containsClass(class):
      result.add ele
  return result

proc buildMetaPinnedRepo(n: XmlNode): OrderedTableRef[string, string]=
  result = newOrderedTable[string, string]()
  # use the information in `n` to populate the table

  let linkNodes = n.nodeOfClass("Link")
  let full_name = if linkNodes.len > 0: linkNodes[0].attr("href")[1..^1] else: ""
  let repo = if full_name != "": full_name.split("/")[1] else: ""
  let descNodes = n.nodeOfClass("pinned-item-desc")
  let description = if descNodes.len > 0: descNodes[0].innerText.strip() else: ""
  let repo_meta = n.nodeOfClass("pinned-item-meta")

  # Check for language existence
  let languageNodes = n.nodeOfClass("d-inline-block")
  let language = if languageNodes.len > 0: languageNodes[0].innerText.strip() else: ""

  # Check for language color existence
  let languageColorNodes = n.nodeOfClass("repo-language-color")
  let language_color = if languageColorNodes.len > 0: languageColorNodes[0].attr("style").split(":")[1].strip() else: ""

  if full_name != "":
    result["full_name"] = full_name
    result["repo"] = repo
    result["description"] = description
    result["link"] = fmt"https://github.com/{full_name}"
    if repo_meta.len > 0:
      result["stars"] = repo_meta[0].innerText.strip()
    else:
      result["stars"] = "0"
    if repo_meta.len > 1:
      result["forks"] = repo_meta[1].innerText.strip()
    else:
      result["forks"] = "0"
    result["language_color"] = language_color
    result["language"] = language
  return result

type
  CacheEntry = tuple
    timeFetched: DateTime
    html: XmlNode

var cache: Table[string, CacheEntry] = initTable[string, CacheEntry]()

router pinnim:
  get "/@user":
    var user = @"user"
    var client = newHttpClient()
    var g: XmlNode

    if cache.contains(user):
      let entry = cache[user]
      if now() - entry.timeFetched < initDuration(hours=1):
        g = entry.html
    if g.isNil:
      g = parseHtml(client.getContent(fmt"http://github.com/{user}"))
      cache[user] = (timeFetched: now(), html: g)

    var repoInfos = newSeq[OrderedTableRef[string, string]]()
    
    for contentEle in g.nodeOfClass("pinned-item-list-item"):
      repoInfos.add(buildMetaPinnedRepo(contentEle))
    
    let repoInfosJson = newJArray()
    for repoInfo in repoInfos:
      repoInfosJson.add(%*repoInfo) 

    resp($repoInfosJson, "application/json")

proc main() =
  let port      = 7777.Port
  let settings = newSettings(port=port)
  var jester    = initJester(pinnim, settings=settings)
  jester.serve()

when isMainModule:
  main()