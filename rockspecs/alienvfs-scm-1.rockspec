package = "AlienVFS"
version = "scm-1"
source = {
   url = "git+https://github.com/gobolinux/AlienVFS"
}
description = {
   detailed = [[
AlienVFS is a virtual filesystem that mirrors modules installed by
programming language package managers under a centralized directory.
]],
   homepage = "https://github.com/gobolinux/AlienVFS",
   license = "GNU GPL v2"
}
dependencies = {
   "flu",
   "luaposix",
   "lunajson"
}
build = {
   type = "builtin",
   modules = {
      ["gobo.alienvfs.pip"] = "gobo/alienvfs/pip.lua"
   },
   install = {
      bin = {
         "AlienVFS"
      }
   }
}
