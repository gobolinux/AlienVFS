-- AlienVFS: LuaRocks backend
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local lua = {
    parse = function(self, luarocks_dir)
        local programs = {}
        local f = io.popen("luarocks list --porcelain")
        for line in f:lines() do
            local result = {}
            for column in string.gmatch(line, "[^\t]+") do
                result[#result + 1] = column
            end

            local program = {}
            program.name = result[1]
            program.version = result[2]
            program.filelist = {}
            program.namespace = result[4]

            local contents = io.popen("find " .. program.namespace .. "/" .. program.name .. "/" .. program.version)
            for path in contents:lines() do
                table.insert(program.filelist, path:sub(program.namespace:len()+2))
            end
            table.insert(programs, program)
        end
        return programs
    end
}

return lua
