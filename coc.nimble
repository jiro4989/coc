# Package

version       = "2.1.0"
author        = "jiro4989"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["coc"]
binDir        = "bin"


# Dependencies

requires "nim >= 0.20.0"
requires "cligen >= 0.9.32"

task ci, "Run CI":
  exec "nim -v"
  exec "nimble -v"
  exec "nimble install -Y"
  exec "nimble test -Y"
  exec "nimble build -d:release -Y"
  exec "./bin/coc -Xf json 'https://charasheet.vampire-blood.net/mebb31fcc04f70c0e8c7b272594393e10'"
  #exec "nimble examples"
  #exec "nimble buildjs"
  #exec "./bin/nimjson -h"
  #exec "./bin/nimjson -v"
