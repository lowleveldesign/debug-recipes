DIM objShell
set objShell = wscript.createObject("wscript.shell")

iReturn = objShell.Run("CMD /C c:\handle\handlefreb.bat" & chr(34), , True)