-- AlienVFS: directory definitions
-- Written by Lucas C. Villa Real <lucasvr@gobolinux.org>
-- Released under the GNU GPL version 2

local glob = require "posix.glob"

local function scan_dirs(patterns)
    local dirs = {}
    for _, pattern in pairs(patterns) do
        local matches = glob.glob(pattern, 0)
        if matches then
            for _, dirname in pairs(matches) do
                table.insert(dirs, dirname)
            end
        end
    end
    return dirs
end

local config = {
    pip_directories = function(self)
        return scan_dirs({
            "/System/Aliens/PIP",
            "/System/Aliens/PIP/lib/python2*/site-packages",
            "/Programs/Python/2.*/lib/python2*/site-packages",
            "/usr/lib64/python2*/site-packages",
            "/usr/lib/python2*/site-packages"
        })
    end,

    pip3_directories = function(self)
        return scan_dirs({
            "/System/Aliens/PIP/lib/python3*/site-packages",
            "/Programs/Python/3.*/lib/python3*/site-packages",
            "/usr/lib64/python3*/site-packages",
            "/usr/lib/python3*/site-packages"
        })
    end,

    luarocks_directories = function(self)
        return scan_dirs({
            "/System/Aliens/LuaRocks/lib/luarocks/rocks*",
            "/usr/lib64/lua/5.*/luarocks/rocks*",
            "/usr/lib/lua/5.*/luarocks/rocks*"
        })
    end,

    cpan_directories = function(self)
        local arch = io.popen("uname -m"):read("*l")
        return scan_dirs({
            "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto",
            "/usr/lib64/perl*/" .. arch .. "*/auto",
            "/usr/lib/perl*/" .. arch .. "*/auto"
        })
    end,

    cpan_inotify_directories = function(self)
        local arch = io.popen("uname -m"):read("*l")
        local regular_dirs = self:cpan_directories()
        local inotify_dirs = scan_dirs({
            "/System/Aliens/CPAN/lib/perl*/" .. arch .. "*/auto/*",
            "/usr/lib64/perl*/" .. arch .. "*/auto/*",
            "/usr/lib/perl*/" .. arch .. "*/auto/*"
        })
        for _, dir in pairs(regular_dirs) do
            table.insert(inotify_dirs, dir)
        end
        return inotify_dirs
    end
}

return config

-- vim: ts=4 sts=4 sw=4 expandtab
