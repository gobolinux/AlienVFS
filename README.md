# AlienVFS

AlienVFS is a virtual filesystem that mirrors modules installed by
programming language package managers under a centralized directory.
In other words, modules installed through CPAN, LuaRocks, PIP and
friends are exposed under a single mount point. The virtual directory
presents the module name and one or more subdirectories holding the
installed version(s) of that module.

# Supported package managers

AlienVFS has built-in support for a few package managers:

- LuaRocks (Lua)
- CPAN (Perl)
- PIP and PIP3 (Python)
- RubyGems (Ruby)

The virtual filesystem tree automatically updates whenever
a new programming language module is installed or removed
by the package managers.

# Installation

Assuming you want to install from the most recent Git snapshot,
the following two lines are enough to install AlienVFS on a regular
distro:

```
$ git clone https://github.com/gobolinux/AlienVFS.git
$ sudo luarocks build AlienVFS/rockspecs/alienvfs-scm-1.rockspec
```

# Usage

Under a GoboLinux distribution, the main script will be saved under
/System/Aliens/LuaRocks/bin. If that directory is not on your $PATH,
make sure to append it and then invoke the main script passing the
mount point where modules will be shown:

```
$ mkdir -p /Mount/Aliens
$ AlienVFS /Mount/Aliens
```

You can now browse the contents of /Mount/Aliens using regular tools.

```bash
$ ls /Mount/Aliens
CPAN:Authen::SASL     LuaRocks:luafilesystem  PIP:google-api-python-client  PIP:Pygments
CPAN:Digest::HMAC     LuaRocks:luaposix       PIP:htmlmin                   PIP:pyldap
CPAN:Encode::Locale   PIP:agate               PIP:httplib2                  PIP:PyOpenGL
CPAN:Error            PIP:agate-dbf           PIP:idna                      PIP:pyparsing
...

$ ls /Mount/Aliens/PIP:pyldap
2.4.28

$ ls /Mount/Aliens/PIP:pyldap/2.4.28
dsml.py   dsml.pyo  _ldap.so    ldapurl.pyc  ldif.py   ldif.pyo
dsml.pyc  ldap      ldapurl.py  ldapurl.pyo  ldif.pyc  pyldap-2.4.28-py2.7.egg-info
```
