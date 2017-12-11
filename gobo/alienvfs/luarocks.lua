-- AlienVFS: LuaRocks backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local inspect = require "inspect"

local lua = {
    moduleDirs = function(self)
        return nil
    end,

    parse = function(self, luarocks_dir)
        return self:_parseCommand("luarocks list --porcelain")
    end,

    populate = function(self, directory, programname)
        local program = self:_parseCommand("luarocks list --porcelain " .. programname)
        if #program ~= 0 then
            return program[1]
        end
        return nil
    end,

    valid = function(self, path)
        return path ~= ".tmpluarockstestwritable" and path ~= "manifest.tmp"
    end,

    map = function(self, path, event_type)
        return path
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
            program.module_dir = result[4]
            program.filelist = self:_parseProgram(program)
            table.insert(programs, program)
        end
        f:close()
        return programs
    end,

    _parseProgram = function(self, program)
        local programdir = program.module_dir .. "/" .. program.name .. "/" .. program.version
        local contents = io.popen("find " .. programdir)
        local filelist = {}
        -- Update module_dir
        program.module_dir = programdir
        for fname in contents:lines() do
            local path, lower_path = "/"..fname:sub(program.module_dir:len()+2), nil
            table.insert(filelist, {path, lower_path})
        end
        contents:close()
        return filelist
    end
}

return lua

-- vim: ts=4 sts=4 sw=4 expandtab
