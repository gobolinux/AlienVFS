-- AlienVFS: LuaRocks backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local inspect = require "inspect"

local lua = {
    parse = function(self, luarocks_dir)
        return self:_parseCommand("luarocks list --porcelain")
    end,

    contents = function(self, directory, programname)
        return self:_parseCommand("luarocks list --porcelain " .. programname)
    end,

    valid = function(self, path)
        return path ~= ".tmpluarockstestwritable" and path ~= "manifest.tmp"
    end,

    _parseCommand = function(self, command)
        local programs = {}
        local f = io.popen(command)
        for line in f:lines() do
            local result = {}
            for column in string.gmatch(line, "[^\t]+") do
                result[#result + 1] = column
            end
            local program = {}
            program.name = result[1]
            program.version = result[2]
            program.namespace = result[4]
            program.filelist = self:_parseProgramVersion(program.namespace .. "/" .. program.name .. "/" .. program.version)
            table.insert(programs, program)
        end
        f:close()
        return programs
    end,

    _parseProgramVersion = function(self, programdir)
        local namespace = programdir:sub(1, programdir:find("/")-1)
        local contents = io.popen("find " .. programdir)
        local filelist = {}
        for fname in contents:lines() do
            local path, lower_path = fname:sub(namespace:len()+2), nil
            table.insert(filelist, {path, lower_path})
        end
        contents:close()
        return filelist
    end
}

return lua
