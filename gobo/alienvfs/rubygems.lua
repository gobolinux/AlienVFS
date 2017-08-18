-- AlienVFS: RubyGems backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local rubygems = {
    rubygems_dir = nil,

    parse = function(self, rubygems_dir)
        self.rubygems_dir = rubygems_dir
        local programs = {}
        local gems_path = io.popen("gem environment gempath"):read("*l")
        for _,modinfo in pairs(self:_getModules()) do
            local istart, iend = modinfo:find(" ")
            local program = {}
            program.name = modinfo:sub(1,istart-1)
            program.version = modinfo:sub(iend+1)
            program.filelist = self:_getFileList(program.name, program.version)
            program.namespace = self:_getNamespace(gems_path, program.filelist) or rubygems_dir
            table.insert(programs, program)
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

    _getModules = function(self)
        local modules = {}
        local f = io.popen("gem list --local")
        for line in f:lines() do
            if line:find("[(]") ~= nil then
                local modinfo = string.gsub(line, "[()]", "")
                table.insert(modules, modinfo)
            end
        end
        f:close()
        return modules
    end,

    _getFileList = function(self, name, version)
        local filelist = {}
        local f = io.popen("gem contents " .. name .. " -v " .. version)
        for line in f:lines() do
            table.insert(filelist, {line, nil})
        end
        f:close()
        return filelist
    end,

    _getNamespace = function(self, gems_path, filelist)
        local namespace = nil
        for i,pathinfo in pairs(filelist) do
            local path = pathinfo[1]
            for ns in string.gmatch(gems_path, "[^:]+") do
                local istart, iend = path:find(ns)
                if istart ~= nil then
                    filelist[i][1] = path:sub(iend+2)
                    namespace = ns
                end
            end
        end
        return namespace
    end
}

return rubygems
