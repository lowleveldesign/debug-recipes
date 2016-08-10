
Windows Debugging Configuration
===============================

Kernel Debug output
-------------------

Starting from Vista Microsoft turned off the default kernel debug logging and in order to use it you need to enable it manually. This can be done by modifying: `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Debug Print Filter` key. The `DEFAULT` value is set to 0. Thish is actually a bitmask and Info level is represented by the third bit so setting `DEFAULT` to 8 will enable Info logs on debug output.

Environment variables
---------------------

### \_NT\_SYMBOL\_PATH ###

This variables specify where the windows debuggers will look for symbol files. It may contain multiple locations but they need to be separated with semi colon (;) and are searched from left to right. If you include the string `cache*localsymbolcache` in your symbol path, the specified directory localsymbolcache will be used to store any symbols loaded from any element that appears in your symbol path to the right of this string. This allows you to use a local cache for symbols downloaded from any location, not just those downloaded by a symbol server.

For example, if you set your symbol path with the following .sympath command, the directory c:\mysymbols will be used to store files from both of the \\private shares, but not from \\someshare:

    .sympath \\someshare\that\cachestar\ignores;cache*c:\mysymbols;\\private\binary\symbol\location;\\private\test\build\symbol\share

This can be easily combined with the Microsoft public symbol store by using the following initial setting:

    _NT_SYMBOL_PATH=srv*c:\mysymbols*http://msdl.microsoft.com/download/symbols;cache*c:\mysymbols

#### Symbol server syntax ####

To use a symbol server (`srv*` syntax) symsrv.dll must be installed in the same directory as the debugger and the symbol path must be set in one of the following ways:

    set _NT_SYMBOL_PATH = symsrv*ServerDLL*DownstreamStore*\\Server\Share

    set _NT_SYMBOL_PATH = symsrv*ServerDLL*SymbolServer

    set _NT_SYMBOL_PATH = srv*DownstreamStore*SymbolServer

    set _NT_SYMBOL_PATH = srv*SymbolServer

`srv*` in the last syntax example is a shorthand for `symsrv*symsrv.dll`.

`DownstreamStore` specifies a directory (local or shared) where symbol files will be cached. You may specify multiple directories by separating them with asterisks. If you provide two asterisks `**` then the default location will be used: `<debugger home directory>\sym`. If the `DownstreamStore` is omitted no caching is performed and PDB files are always downloaded directly from the symbol server.

`SymbolServer` is a path to the symbol store. There may be multiple symbol servers defined - asterisk (\*) is used to separate them.

### \_NT\_SOURCE\_PATH ###


Known symbol servers links
--------------------------

    1. Firefox - private
    SRV*c:\websymbols*http://symbols.mozilla.org/firefox

    2. Chrome - private
    SRV*c:\websymbols*http://chromium-browser-symsrv.commondatastorage.googleapis.com

    3. Citrix
    SRV*c:\websymbols*http://ctxsym.citrix.com/symbols

    4. SymbolSource (many OSS projects)
    SRV*c:\websymbols\*http://srv.symbolsource.org/pdb/Public
    SRV*c:\websymbols\*http://srv.symbolsource.org/pdb/MyGet

