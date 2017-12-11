-- AlienVFS: PIP backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local lfs = require "lfs"
local posix = require "posix"
local lunajson = require "lunajson"

local pip = {
    pip_dirs = {},
    programs_table = {},

    moduleDirs = function(self)
        return nil
    end,

    parse = function(self, pip_dir)
        local programs = {}
        table.insert(self.pip_dirs, pip_dir)
        for file in lfs.dir(pip_dir) do
            if lfs.attributes(pip_dir.."/"..file, "mode") == "directory" then
                local fname = pip_dir.."/"..file
                if string.find(fname, "egg-info", 1, true) ~= nil then
                    local info = self:_parseEgg(fname)
                    if info.name ~= nil then
                        table.insert(programs, info)
                        table.insert(self.programs_table, info)
                    end
                elseif string.find(fname, "dist-info", 1, true) ~= nil then
                    local info = self:_parseDistInfo(fname)
                    if info.name ~= nil then
                        table.insert(programs, info)
                        table.insert(self.programs_table, info)
                    end
                end
            end
        end
        return programs
    end,

    populate = function(self, directory, programname)
        local path = directory .. "/" .. programname
        local info = posix.stat(path)
        local programfiles = {}
        if info ~= nil and info.type == "directory" then
            if string.find(programname, "egg-info", 1, true) ~= nil then
                local egginfo = self:_parseEgg(path)
                if egginfo.name ~= nil then
                    table.insert(programfiles, egginfo)
                end
            elseif string.find(programname, "dist-info", 1, true) ~= nil then
                local distinfo = self:_parseDistInfo(path)
                if distinfo.name ~= nil then
                    table.insert(programfiles, distinfo)
                end
            end
        end
        module = {}
        for _,entry in pairs(programfiles) do
            -- Local cache
            module.path = path
            module.name = entry.name
            module.version = entry.version
            table.insert(self.programs_table, module)
        end
        if #module == 0 then
            module = nil
        end
        return module
    end,

    valid = function(self, path)
        return string.find(path, "egg-info", 1, true) ~= nil or string.find(path, "dist-info", 1, true) ~= nil
    end,

    map = function(self, path, event_type)
        if event_type == "DELETE" then
           for _,info in pairs(self.programs_table) do
                if info.name == posix.basename(path) or posix.basename(info.path) == posix.basename(path) then
                    return info.name .. "/" .. info.version
                end
            end
        elseif event_type == "CREATE" then
            return path
        end
        return nil
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

    _getValue = function(self, line)
        return line:sub(line:len()+2 - line:reverse():find(" "))
    end,

    _parseEgg = function(self, egg_dir)
        local this_pip_dir = self:_matchingPipDir(egg_dir)
        if this_pip_dir == nil then return {} end

        local program = {}
        local f = io.open(egg_dir.."/PKG-INFO")
        if f ~= nil then
            program.name, program.version = self:_readNameVersion(f)
            f:close()
        end
        if program.name == nil then return {} end

        f = io.open(egg_dir.."/installed-files.txt")
        if f ~= nil then
            program.filelist = {}
            for line in f:lines() do
                local fname = egg_dir.."/"..line
                local path, lower_path = self:_getPath(fname, this_pip_dir)
                if path ~= nil then
                    table.insert(program.filelist, {path, lower_path})
                end
            end
            f:close()
        end
        program.path = egg_dir
        program.module_dir = this_pip_dir
        return program
    end,

    _parseDistInfo = function(self, dist_dir)
        local this_pip_dir = self:_matchingPipDir(dist_dir)
        if this_pip_dir == nil then return {} end

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
        if program.name == nil then return {} end

        f = io.open(dist_dir.."/RECORD")
        if f ~= nil then
            program.filelist = {}
            for line in f:lines() do
                local fname = dist_dir.."/../"..line:sub(1, line:find(",")-1)
                local path, lower_path = self:_getPath(fname, this_pip_dir)
                if path ~= nil then
                    table.insert(program.filelist, {path, lower_path})
                end
            end
            f:close()
        end
        program.path = dist_dir
        program.module_dir = this_pip_dir
        return program
    end,

    _getPath = function(self, fname, basedir)
        local path = posix.realpath(fname)
        if path ~= nil then
            if string.find(path, basedir, 1, true) ~= nil then
                return path:sub(basedir:len()+2), nil
            end
            local common = ""
            for i=1, #path do
                if path:sub(i,i) ~= basedir:sub(i,i) then
                    break
                end
                common = common .. path:sub(i,i)
            end
            return path:sub(common:len()+1), fname
        end
        return nil, nil
    end,

    _matchingPipDir = function(self, path)
        for _,entry in pairs(self.pip_dirs) do
            local this_pip_dir = posix.realpath(entry)
            if this_pip_dir ~= nil and string.find(path, this_pip_dir, 1, true) ~= nil then
                return entry
            end
        end
        return nil
    end
}

return pip

-- vim: ts=4 sts=4 sw=4 expandtab
