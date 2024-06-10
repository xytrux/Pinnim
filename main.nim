import std/httpclient
import strformat
import std/htmlparser
import std/[xmltree, strutils]
import std/tables

var user = "xytrux"
var client = newHttpClient()

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

let g = parseHtml(client.getContent(fmt"http://github.com/{user}"))

proc buildMetaPinnedRepo(n: XmlNode): TableRef[string, string]=
  result = newTable[string, string]()
  # use the information in `n` to populate the table
  let full_name = n.nodeOfClass("Link")[0].attr("href")[1..^1]
  result["full_name"] = full_name
  result["name"] = "TODO"
  result["description"] = "TODO"
  result["link"] = fmt"https://{full_name}"
  result["stars"] = "TODO"
  result["forks"] = "TODO"
  result["language_color"] = "TODO"
  result["language"] = "TODO"
  return result

var repoInfos = newSeq[TableRef[string, string]]()

for contentEle in g.nodeOfClass("pinned-item-list-item-content"):
  repoInfos.add(buildMetaPinnedRepo(contentEle))

for ele in g.extractWithTag("class"):
  if ele.attr("class").containsClass("pinned-item-list-item"):
    echo repoInfos