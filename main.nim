import std/[httpclient, strformat, htmlparser, xmltree, strutils, tables]

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
  let repo = full_name.split("/")[1]
  let description = n.nodeOfClass("pinned-item-desc")[0].innerText.strip()
  let repo_meta = n.nodeOfClass("pinned-item-meta")
  let language = n.nodeOfClass("d-inline-block")[0].innerText.strip()
  let language_color = n.nodeOfClass("repo-language-color")[0].attr("style").split(":")[1].strip()

  result["full_name"] = full_name
  result["repo"] = repo.join("")
  result["description"] = description
  result["link"] = fmt"https://github.com/{full_name}"
  result["stars"] = repo_meta[0].innerText.strip()
  if len(repo_meta) < 2:
    result["forks"] = "0"
  result["language_color"] = language_color
  result["language"] = language
  return result

var repoInfos = newSeq[TableRef[string, string]]()

for contentEle in g.nodeOfClass("pinned-item-list-item-content"):
  repoInfos.add(buildMetaPinnedRepo(contentEle))
  
echo repoInfos