-- AlienVFS: CPAN backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local glob = require "posix.glob"

local cpan = {
    cpan_dir = nil,
    packlist_dir = nil,
    perldoc_output = {},

    parse = function(self, cpan_dir)
        self.cpan_dir = cpan_dir
        local programs = {}
        for _,module in pairs(self:_getModules()) do
            local program = {}
            program.name = module
            program.version = self:_getModuleInfo(module)
            program.namespace = self.cpan_dir
            program.filelist = self:_parsePackList(module)
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
        local f = io.popen("perldoc -t perllocal")
        for line in f:lines() do
            self.perldoc_output[#self.perldoc_output + 1] = line
            if line:find("Module") ~= nil then
                local name = string.gsub(line, '^.*" ', '')
                table.insert(modules, name)
            end
        end
        f:close()
        return modules
    end,

    _getModuleInfo = function(self, module)
        local watch = false
        local version = nil
        local namespace = nil
        for _,line in pairs(self.perldoc_output) do
            if line:find(module .. "$") ~= nil then
                watch = true
            elseif watch == true then
                local istart, iend = line:find('"installed into: ')
                if istart ~= nil then
                    namespace = line:sub(iend+1, -2)
                else
                    istart, iend = line:find('"VERSION: ')
                    if istart ~= nil then
                        version = line:sub(iend+1, -2)
                    end
                end
            end
            if version ~= nil and namespace ~= nil then
                break
            end
        end
        return version, namespace
    end,

    _packListDir = function(self, module)
        if self.packlist_dir == nil then
            local arch = io.popen("uname -m"):read("*l")
            for _,dir in pairs(glob.glob(self.cpan_dir .. "/lib/perl*/" .. arch .. "*/auto")) do
                self.packlist_dir = dir
            end
        end
        return self.packlist_dir
    end,

    _parsePackList = function(self, module)
        local filelist = {}
        local packlist = self:_packListDir() .. "/" .. string.gsub(module, "::", "/") .. "/.packlist"
        local f = io.open(packlist)
        if f ~= nil then
            for line in f:lines() do
                table.insert(filelist, line:sub(self.cpan_dir:len()+2))
            end
            f:close()
        end
        return filelist
    end
}

return cpan
