-- AlienVFS: CPAN backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local glob = require "posix.glob"
local inspect = require "inspect"

local cpan = {
    cpan_dir = nil,
    packlists = {},
    perldoc_output = {},

    moduleDirs = function(self)
        return nil
    end,

    parse = function(self, cpan_dir)
        if self.cpan_dir == nil then self.cpan_dir = cpan_dir end
        local programs = {}
        self.perldoc_output = self:_runPerlDoc()
        for _,module in pairs(self:_getModules(cpan_dir)) do
            if module._packlist ~= nil then
                table.insert(programs, module)
                if self.packlists[module._packlist] == nil then
                    self.packlists[module._packlist] = module
                end
            end
        end
        return programs
    end,

    populate = function(self, directory, programname)
        -- Lazy inotify:create handling
        local filelist = {}
        for _,module in pairs(self:_getModules(directory)) do
            if module._packlist ~= nil and self.packlists[module._packlist] == nil then
                self.packlists[module._packlist] = module
                return module
            end
        end
        return nil
    end,

    valid = function(self, path)
        -- This function is called to test if a newly created path is a new module
        return true
    end,

    map = function(self, path, event_type)
        -- Given a path, returns the corresponding AlienVFS module name
        local module = self.packlists[path]
        if module ~= nil then
            return module.name
        end

        -- Update the packlists and try again
        local old_packlist = { table.unpack(self.packlists) }
        self:parse(self.cpan_dir)
        for key,value in pairs(self.packlists) do
            if old_packlist[key] == nil and string.find(key, path, 1, true) ~= nil then
                -- Obtain a reference to the module name and then remove the new entry
                -- from packlists. We do so in order to keep the logic of populate() simple.
                module, self.packlists[key] = self.packlists[key], nil
                return module.name
            end
        end
        return nil
    end,

    _getModules = function(self, cpan_dir)
        -- Get last path element
        local modules, last_element = {}, nil
        for name in string.gmatch(cpan_dir, "[^/]+") do
            last_element = name
        end

        -- We only support Perl modules that ship a .packlist file. All other modules are ignored.
        local f = io.popen("find " .. cpan_dir .. " -name \"*.packlist\"")
        for packlist in f:lines() do
            local parts, module = {}, {}
            local module_dir = string.gsub(packlist, "/.packlist", "")
            for name in string.gmatch(module_dir, "[^/]+") do
                table.insert(parts, name)
            end

            -- Populate the module table
            module._packlist = packlist
            module.module_dir = module_dir
            if parts[#parts-1] ~= last_element then
                module.name = parts[#parts-1] .. "::" .. parts[#parts]
            else
                module.name = parts[#parts]
            end
            module.version = self:_getModuleVersion(module.name)
            module.filelist = self:_parsePackList(cpan_dir, packlist)
            if module.filelist ~= nil then
                table.insert(modules, module)
            end
        end
        f:close()
        return modules
    end,

    _getModuleVersion = function(self, module_name)
        local watch, version = false, nil
        for _,line in pairs(self.perldoc_output) do
            if line:find(module_name .. "$") ~= nil then
                watch = true
            elseif watch == true then
                local istart, iend = line:find('"VERSION: ')
                if istart ~= nil then
                    return line:sub(iend+1, -2)
                end
            end
        end
        print("Failed to get version of module " .. module_name)
        return nil
    end,

    _runPerlDoc = function(self)
        local f, data = io.popen("perldoc -t perllocal"), {}
        for line in f:lines() do data[#data + 1] = line end
        f:close()
        return data
    end,

    _parsePackList = function(self, cpan_dir, packlist)
        local f = io.open(packlist)
        if f ~= nil then
            local filelist = {}
            for line in f:lines() do
                local common = self:_commonPrefix(line, cpan_dir)
                local path, lower_path = line:sub(common:len()+1), line
                table.insert(filelist, {path, lower_path})
            end
            f:close()
            return filelist
        end
        return nil
    end,

    _commonPrefix = function(self, path, basedir)
        local common = ""
        for i=1, #path do
            if path:sub(i,i) ~= basedir:sub(i,i) then
                break
            end
            common = common .. path:sub(i,i)
        end
        return common
    end,
}

return cpan
