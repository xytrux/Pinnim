import std/httpclient
import strformat
import std/htmlparser

# TODO: Add a way to parse HTML

var user = "xytrux"

var client = newHttpClient()
try:
  echo client.getContent(fmt"http://github.com/{user}")
finally:
  client.close()