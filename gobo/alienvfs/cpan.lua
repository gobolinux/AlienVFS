-- AlienVFS: CPAN backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local glob = require "posix.glob"
local inspect = require "inspect"

local cpan = {
    packlist_dir = nil,
    perldoc_output = {},

    moduleDirs = function(self)
        return nil
    end,

    parse = function(self, cpan_dir)
        local programs = {}
        for _,module in pairs(self:_getModules()) do
            local program = {}
            program.name = module
            program.version = self:_getModuleInfo(module)
            program.module_dir = cpan_dir
            program.filelist = self:_parsePackList(module, cpan_dir)
            table.insert(programs, program)
        end
        return programs
    end,

    populate = function(self, directory, programname)
        -- TODO
        print("CPAN:populate -> dir=" .. directory .. ", program=" .. programname)
        return {}
    end,

    valid = function(self, path)
        -- TODO
        print("CPAN:valid -> path=" .. path)
        return true
    end,

    map = function(self, path)
        -- TODO
        print("CPAN:map -> path=" .. path)
        return path
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
        local module_dir = nil
        for _,line in pairs(self.perldoc_output) do
            if line:find(module .. "$") ~= nil then
                watch = true
            elseif watch == true then
                local istart, iend = line:find('"installed into: ')
                if istart ~= nil then
                    module_dir = line:sub(iend+1, -2)
                else
                    istart, iend = line:find('"VERSION: ')
                    if istart ~= nil then
                        version = line:sub(iend+1, -2)
                    end
                end
            end
            if version ~= nil and module_dir ~= nil then
                break
            end
        end
        return version, module_dir
    end,

    _parsePackList = function(self, module, cpan_dir)
        local filelist = {}
        for _,entry in pairs(glob.glob(cpan_dir, 0)) do
            local packlist = entry .. "/" .. string.gsub(module, "::", "/") .. "/.packlist"
            local f = io.open(packlist)
            if f ~= nil then
                for line in f:lines() do
                    print(line)
                    local path, lower_path = line:sub(cpan_dir:len()+2), nil
                    table.insert(filelist, {path, lower_path})
                end
                f:close()
            end
        end
        return filelist
    end
}

return cpan
