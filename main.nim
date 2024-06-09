import std/[xmltree, strutils, htmlparser, tables]

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


proc buildMetaPinnedRepo(n: XmlNode): TableRef[string, string]=
  result = newTable[string, string]()
  # use the information in `n` to populate the table
  result["full_name"] = "implement"
  result["name"] = "implement"

var repoInfos = newSeq[TableRef[string, string]]()

for contentEle in g.nodeOfClass("pinned-item-list-item-content"):
  for descEle in contentEle.nodeOfClass("pinned-item-desc"):
    repoInfos.add(buildMetaPinnedRepo(descEle))