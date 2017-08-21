-- AlienVFS: RubyGems backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local stat = require "posix.sys.stat"

local rubygems = {
    programs_list = {},

    moduleDirs = function(self)
        local module_dirs = {}
        local gems_path = io.popen("gem environment gempath"):read("*l")
        for moddir in string.gmatch(gems_path, "[^:]+") do
            moddir = moddir .. "/gems"
            if stat.lstat(moddir) ~= nil then
                table.insert(module_dirs, moddir)
            end
        end
        return module_dirs
    end,

    parse = function(self, rubygems_dir)
        local programs = {}
        for _,modinfo in pairs(self:_getModules(rubygems_dir)) do
            local nameversion, moddir = modinfo[1], modinfo[2]
            local istart, iend = nameversion:find(" ")

            local program = {}
            program.name = nameversion:sub(1,istart-1)
            program.version = nameversion:sub(iend+1)
            program.filelist = self:_getFileList(moddir, program.name, program.version)
            program.namespace = moddir .. "/" .. program.name .. "-" .. program.version .. "/"

            self.programs_list[program.name .. "-" .. program.version] = program
            table.insert(programs, program)
        end
        return programs
    end,

    populate = function(self, directory, programname)
        local istart, iend = 1, programname:find("-")
        while iend ~= nil do
            local name = programname:sub(istart, iend-1)
            local version = programname:sub(iend+1)
            local moddir = self:_getInstallDir(name, version)
            if moddir ~= nil then
                local filelist = self:_getFileList(moddir, name, version)
                if #filelist > 0 then
                    local program = {}
                    program.name = name
                    program.version = version
                    program.filelist = filelist
                    program.namespace = self:_getInstallDir(name, version) .. "/" .. name .. "-" .. version .. "/"

                    self.programs_list[program.name .. "-" .. program.version] = program
                    return {program}
                end
            end
            iend = programname:find("-", iend+1)
        end
        return {}
    end,

    valid = function(self, path)
        return true
    end,

    map = function(self, path)
        local program = self.programs_list[path]
        if program == nil then
            return nil
        end
        return program.name .. "/" .. program.version
    end,

    _getInstallDir = function(self, name, version)
        local f = io.popen("gem list --local --details " .. name .. " -v " .. version .. " | grep 'Installed at:'")
        for line in f:lines() do
            local istart, iend = line:find(": ")
            return string.sub(line, iend+1) .. "/gems"
        end
        return nil
    end,

    _getModules = function(self, moddir)
        local modules = {}
        local modinfo = {}
        local f = io.popen("gem list --local --details | grep '^[a-zA-Z].*)$\\|Installed at:'")
        for line in f:lines() do
            if line:find("[(]") ~= nil then
                -- module name and version
                modinfo[1] = string.gsub(line, "[()]", "")
            else
                -- installation path
                local istart, iend = line:find(": ")
                modinfo[2] = string.sub(line, iend+1) .. "/gems"
                if modinfo[2]:find(moddir) == 1 then
                    table.insert(modules, modinfo)
                end
                modinfo = {}
            end
        end
        f:close()
        return modules
    end,

    _getFileList = function(self, moddir, name, version)
        local filelist = {}
        local prefix = name .. "-" .. version .. "/"
        local f = io.popen("gem contents " .. name .. " -v " .. version)
        for line in f:lines() do
            local path = line:sub(moddir:len()+prefix:len()+2)
            table.insert(filelist, {path, nil})
        end
        f:close()
        return filelist
    end,
}

return rubygems
