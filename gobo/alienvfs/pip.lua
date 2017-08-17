-- AlienVFS: PIP backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local lfs = require "lfs"
local posix = require "posix"
local lunajson = require "lunajson"

local pip = {
    pip_dirs = {},
    programs_table = {},

    parse = function(self, pip_dir)
        local programs = {}
        table.insert(self.pip_dirs, pip_dir)
        for file in lfs.dir(pip_dir) do
            if lfs.attributes(pip_dir.."/"..file, "mode") == "directory" then
                local fname = pip_dir.."/"..file
                if string.find(fname, "egg-info", 1, true) ~= nil then
                    table.insert(programs, self:_parseEgg(fname))
                elseif string.find(fname, "dist-info", 1, true) ~= nil then
                    table.insert(programs, self:_parseDistInfo(fname))
                end
            end
        end
        for _,entry in pairs(programs) do
            -- Local cache
            info = {}
            info.path = entry.path
            info.name = entry.name
            info.version = entry.version
            table.insert(self.programs_table, info)
        end
        return programs
    end,

    contents = function(self, directory, programname)
        local path = directory .. "/" .. programname
        local info = posix.stat(path)
        local programfiles = {}
        if info ~= nil and info.type == "directory" then
            if string.find(programname, "egg-info", 1, true) ~= nil then
                table.insert(programfiles, self:_parseEgg(path))
            elseif string.find(programname, "dist-info", 1, true) ~= nil then
                table.insert(programfiles, self:_parseDistInfo(path))
            end
        end
        for _,entry in pairs(programfiles) do
            -- Local cache
            info = {}
            info.path = path
            info.name = entry.name
            info.version = entry.version
            table.insert(self.programs_table, info)
        end
        return programfiles
    end,

    valid = function(self, path)
        if string.find(path, "egg-info", 1, true) ~= nil or string.find(path, "dist-info", 1, true) ~= nil then
            return true
        else
            for _,info in pairs(self.programs_table) do
                if info.name == posix.basename(path) then
                    return true
                end
            end
        end
        return false
    end,

    _readNameVersion = function(self, f)
        local name = nil
        local version = nil
        for line in f:lines() do
            local name_ = line:find("Name: ")
            local version_ = line:find("Version: ")
            if name_ ~= nil then
                name = self:_getValue(line)
            end
            if version_ ~= nil then
                version = self:_getValue(line)
            end
        end
        return name, version
    end,

    _parseEgg = function(self, egg_dir)
        local this_pip_dir = self:_matchingPipDir(egg_dir)
        local program = {}
        local f = io.open(egg_dir.."/PKG-INFO")
        if f ~= nil then
            program.path = egg_dir
            program.name, program.version = self:_readNameVersion(f)
            f:close()
        end
        f = io.open(egg_dir.."/installed-files.txt")
        if f ~= nil then
            program.filelist = {}
            for line in f:lines() do
                local fname = egg_dir.."/"..line
                local path = posix.realpath(fname)
                if path ~= nil then
                    table.insert(program.filelist, path:sub(this_pip_dir:len()+2))
                end
            end
            f:close()
        end
        program.namespace = this_pip_dir
        return program
    end,

    _getValue = function(self, line)
        return line:sub(line:len()+2 - line:reverse():find(" "))
    end,

    _parseDistInfo = function(self, dist_dir)
        local this_pip_dir = self:_matchingPipDir(dist_dir)
        local program = {}
        local f = io.open(dist_dir.."/metadata.json")
        if f ~= nil then
            local jsonstr = f:read("*all")
            local jsondoc = lunajson.decode(jsonstr)
            program.path = dist_dir
            program.name = jsondoc.name
            program.version = jsondoc.version
            f:close()
        else
            f = io.open(dist_dir.."/METADATA")
            if f ~= nil then
                program.name, program.version = self:_readNameVersion(f)
                f:close()
            end
        end
        f = io.open(dist_dir.."/RECORD")
        if f ~= nil then
            program.filelist = {}
            for line in f:lines() do
                local fname = dist_dir.."/../"..line:sub(1, line:find(",")-1)
                local path = posix.realpath(fname)
                if path ~= nil then
                    table.insert(program.filelist, path:sub(this_pip_dir:len()+2))
                end
            end
            f:close()
        end
        program.namespace = this_pip_dir
        return program
    end,

    _matchingPipDir = function(self, path)
        for _,entry in pairs(self.pip_dirs) do
            local this_pip_dir = posix.realpath(entry)
            if string.find(path, this_pip_dir, 1, true) ~= nil then
                return entry
            end
        end
        return nil
    end
}

return pip
