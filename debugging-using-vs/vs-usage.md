Visual Studio
=============

Keyboard shortcuts
------------------

- **LAlt + Shift + L** - locate an item in the solution explorer (requires resharper :/)
- **Ctrl + F2** - locates the focus on the NavigationBar of the editor and enables you to select classes and their members in the code file
- **Shift + LAlt + F12** - select a word and press this shortcut and you will quick find symbols referencing it
- **Ctrl + LAlt + <down>** - a drop down in the right up corner that shows all opened files
- **Alt + LF12** - show a peek window with the method definition

### Debugging ###

- **Ctrl + LAlt + P** - attach to a process
- **Ctrl + LAlt + M** - Memory 1 window
- **Ctrl + LAlt + D** - Disassembly window

Extensibility
-------------

### Macros

To assign a key to the macro use _Tools->Customize..._ menu.

### Themes ###

You can download themes from <https://studiostyl.es/> and import them into Visual Studio using Tools - Settings - Import Export Settings...

Debugging
---------

Special variables (for use in the immediate and watch windows):

 - **$exception** - shows the last exception that occured in the application

### Disable Attach Security Warning dialog ###

VS2015: `HKEY_CURRENT_USER\Software\Microsoft\VisualStudio\14.0\Debugger`
VS2013: `HKEY_CURRENT_USER\Software\Microsoft\VisualStudio\12.0\Debugger`

Add `REG_DWORD` value of `DisableAttachSecurityWarning = 1`.

### Breakpoints ###

#### Break only if a call stack value is present ####

You can use `System.Diagnostics.StackTrace` in order to create a breakpoint that will fire only if a specific function is present on the callstack. Set a breakpoint's condition to `new System.Diagnostics.StackTrace().ToString().Contains("<your function name>")`.

Command Window
--------------

### Aliases ###

A special command `alias` allows you to create aliases to VS commands, syntax:

    alias <alias> <command>

`alias` with no parameters lists aliases defined already in VS.

### Log command session ###

Using `log -on <filename>` command you are able to log all commands with theirs outputs to the external file. To stop recording use `log -off` command.

### Run external executables from the VS ###

Based on (<http://scottcate.com/tricks/089/>):

    Shell [/commandwindow] [/dir:folder] [/outputwindow] <executable> [/args]

    /commandwindow (or /c) - to display the executable's output in the command window
    /outputwindow (or /o) - to display the executable's output in the output window
    /dir:folder - specifics the working directory

Example:

    Shell /o /c xcopy.exe c:\users\saraf\documents\cmdwinlog.txt c:\users\saraf\pictures

Immediate window
----------------

### Debugging commands ###

**FIXME** (examples)
There are special commands available in native mode (after <http://msdn.microsoft.com/en-us/library/ms171362.aspx>):

**.s** - memory search

    .S [ -A | -D | -Q | -U | -W ] StartAddress [EndAddress | LByteCount] Pattern

**.ln** - list symbols nearest the given address

    .ln address

**.x** - examine symbols

    .X { * | module!symbol }

**.k** - display callstack
**.u** - display disassembly

    U [range]

**.~** - display the status of the thread

    ~{ {. | # | * | ddd} | thread}

There are also some NTSD commands accessible (also in native mode):

**.reload** - reloads all symbol information

   .reload [/d] [/l] [/v] [/w] [-?] [module]

**.sympath** - sets the symbol path

  .sympath [+] [path...]

**.cxr** - resets the register context or displays the context record saved at the specified address (??)

    .cxr [address]

**.exr** - displays the content of the exception record

    .exr [-l] [address]

**.load** - loads the extension DLL

    .load DLL

**.unload** - unload the extension DLL

    .unload DLL

**.unloadall** - unloads all loaded extensions

**.foreach** ???

Issues
------

### Slowly closing tabs ###

Deleting .suo file helps if VS hangs while closing tabs.

Links
-----

- [Powershell cmdlets](http://www.wintellect.com/CS/blogs/jrobbins/archive/2012/03/30/using-nuget-powershell-to-replace-missing-macros-in-dev-11.aspx)
