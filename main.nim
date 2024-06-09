import std/httpclient
import strformat
import std/htmlparser
import std/[xmltree, strutils]
import std/tables

var user = "xytrux"

var client = newHttpClient()

iterator extractWithTag(x: XmlNode, name:string): XmlNode {.closure.}=
  if(x.len > 0):
    for i in 0..<x.len:
      for sub in extractWithTag(x[i], name):
        yield sub
  if x.kind() == xnElement and x.attr(name) != "":
    yield x

proc containsClass(classValue: string, lookFor: string): bool=
  for x in classValue.split(" "):
    if(x == lookFor):
      return true
  return false

# TODO: collect everything into a map.

let g = parseHtml(client.getContent(fmt"http://github.com/{user}"))
for ele in g.extractWithTag("class"):
  if ele.attr("class").containsClass("pinned-item-list-item"):
    echo "found a pinned repo"