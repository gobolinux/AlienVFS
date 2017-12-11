-- AlienVFS: directory definitions
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local glob = require "posix.glob"

local function scan_dirs(pattern)
    local dirs = {}
    local matches = glob.glob(pattern, 0)
    if matches then
        for _, dirname in pairs(matches) do
            table.insert(dirs, dirname)
        end
        return table.unpack(dirs)
    end
end

local config = {
    pip_directories = function(self)
        return {
            "/System/Aliens/PIP",
            scan_dirs("/System/Aliens/PIP/lib/python2*/site-packages"),
            scan_dirs("/usr/lib64/python2*/site-packages"),
            scan_dirs("/usr/lib/python2*/site-packages")
        }
    end,

    pip3_directories = function(self)
        return {
            scan_dirs("/System/Aliens/PIP/lib/python3*/site-packages"),
            scan_dirs("/usr/lib64/python3*/site-packages"),
            scan_dirs("/usr/lib/python3*/site-packages")
        }
    end,

    luarocks_directories = function(self)
        return {
            scan_dirs("/System/Aliens/LuaRocks/lib/luarocks/rocks*"),
            scan_dirs("/usr/lib64/lua/5.*/luarocks/rocks*"),
            scan_dirs("/usr/lib/lua/5.*/luarocks/rocks*")
        }
    end,

    cpan_directories = function(self)
        local arch = io.popen("uname -m"):read("*l")
        return {
            scan_dirs("/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto"),
            scan_dirs("/usr/lib64/perl*/" .. arch .. "*/auto"),
            scan_dirs("/usr/lib/perl*/" .. arch .. "*/auto")
        }
    end,

    cpan_inotify_directories = function(self)
        local arch = io.popen("uname -m"):read("*l")
        return {
            self:cpan_directories(),
            scan_dirs("/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto/*"),
            scan_dirs("/usr/lib64/perl*/" .. arch .. "*/auto/*"),
            scan_dirs("/usr/lib/perl*/" .. arch .. "*/auto/*")
        }
    end
}

return config
