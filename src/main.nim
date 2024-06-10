import std/[httpclient, strformat, htmlparser, xmltree, strutils, tables]
import jester, asyncdispatch
import json

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

  let full_name = n.nodeOfClass("Link")[0].attr("href")[1..^1]
  let repo = full_name.split("/")[1]
  let description = n.nodeOfClass("pinned-item-desc")[0].innerText.strip()
  let repo_meta = n.nodeOfClass("pinned-item-meta")
  let language = n.nodeOfClass("d-inline-block")[0].innerText.strip()
  let language_color = n.nodeOfClass("repo-language-color")[0].attr("style").split(":")[1].strip()

  result["full_name"] = full_name
  result["repo"] = repo.join("")
  result["description"] = description
  result["link"] = fmt"https://github.com/{full_name}"
  if len(repo_meta) < 1:
    result["stars"] = "0"
  else:
    result["stars"] = repo_meta[0].innerText.strip()
  if len(repo_meta) < 2:
    result["forks"] = "0"
  else:
    result["forks"] = repo_meta[1].innerText.strip()
  result["language_color"] = language_color
  result["language"] = language
  return result

router pinnim:
  get "/@user":
    var user = @"user"
    var client = newHttpClient()
    let g = parseHtml(client.getContent(fmt"http://github.com/{user}"))

    var repoInfos = newSeq[OrderedTableRef[string, string]]()
    
    # index out of bounds, the container is empty HERE
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