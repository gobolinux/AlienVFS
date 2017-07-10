-- AlienVFS: PIP backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local lfs = require "lfs"
local posix = require "posix"
local lunajson = require "lunajson"

local pip = {
    pip_dir = nil,

    parse = function(self, pip_dir)
        local programs = {}
        self.pip_dir = pip_dir
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
        return programs
    end,

    contents = function(self, directory, programname)
        -- TODO
        return {}
    end,

    valid = function(self, path)
        -- TODO
        return true
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
        local program = {}
        local f = io.open(egg_dir.."/PKG-INFO")
        if f ~= nil then
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
                    table.insert(program.filelist, path:sub(self.pip_dir:len()+2))
                end
            end
            f:close()
        end
        program.namespace = self.pip_dir
        return program
    end,

    _getValue = function(self, line)
        return line:sub(line:len()+2 - line:reverse():find(" "))
    end,

    _parseDistInfo = function(self, dist_dir)
        local program = {}
        local f = io.open(dist_dir.."/metadata.json")
        if f ~= nil then
            local jsonstr = f:read("*all")
            local jsondoc = lunajson.decode(jsonstr)
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
                    table.insert(program.filelist, path:sub(self.pip_dir:len()+2))
                end
            end
            f:close()
        end
        program.namespace = self.pip_dir
        return program
    end
}

return pip
