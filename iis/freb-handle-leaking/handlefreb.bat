   @echo off&SETLOCAL
   :: This will return the date into environment variables
   :: 2002-03-20 : Works on any NT/2K/XP machine independent of regional date settings
   :: 2011-05-04 : Updated to also handle the German language under Windows 7

   FOR /f "tokens=1-4 delims=/-. " %%G IN ('date /t') DO (call :s_fixdate %%G %%H %%I %%J)
   goto :s_print_the_date
   
   :s_fixdate
   if "%1:~0,1%" GTR "9" shift
   FOR /f "skip=1 tokens=2-4 delims=(-)" %%G IN ('echo.^|date') DO (
       Set %%G=%1&set %%H=%2&Set %%I=%3)
   goto :eof

   :s_print_the_date
   Endlocal&(
   Echo.|date|find "JJ">nul
   If errorlevel 1 (
     :: English locale
     SET yy=%yy%&SET mm=%mm%&SET dd=%dd%
   ) Else (
     :: German locale
     SET yy=%JJ%&Set mm=%MM%&SET dd=%TT%
   ))


SET _date=%dd%%mm%%yy%



  SETLOCAL
  For /f "tokens=1-3 delims=1234567890 " %%a in ("%time%") Do set "delims=%%a%%b%%c"
  For /f "tokens=1-4 delims=%delims%" %%G in ("%time%") Do (
    Set _hh=%%G
    Set _min=%%H
    Set _ss=%%I
    Set _ms=%%J
  )
  :: Strip any leading spaces
  Set _hh=%_hh: =%

  :: Ensure the hours have a leading zero
  if 1%_hh% LSS 20 Set _hh=0%_hh%

  ENDLOCAL&Set _time=%_hh%h%_min%min%_ss%

c:\Handle\handle.exe -a -u -accepteula "C:\handle" > c:\handle\%_date%_%_time%.log