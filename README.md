# AlienVFS

AlienVFS is a virtual filesystem that mirrors modules installed by
programming language package managers under a centralized directory.

# Example

```bash
] ls /Mount/AlienVFS
CPAN:Authen::SASL     LuaRocks:luafilesystem  PIP:google-api-python-client  PIP:Pygments
CPAN:Digest::HMAC     LuaRocks:luaposix       PIP:htmlmin                   PIP:pyldap
CPAN:Encode::Locale   PIP:agate               PIP:httplib2                  PIP:PyOpenGL
CPAN:Error            PIP:agate-dbf           PIP:idna                      PIP:pyparsing
...

] ls /Mount/AlienVFS/PIP:pyldap
2.4.28

] ls /Mount/AlienVFS/PIP:pyldap/2.4.28 
dsml.py   dsml.pyo  _ldap.so    ldapurl.pyc  ldif.py   ldif.pyo
dsml.pyc  ldap      ldapurl.py  ldapurl.pyo  ldif.pyc  pyldap-2.4.28-py2.7.egg-info
```
