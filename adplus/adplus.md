ADPLUS
------

**ADPLUS MUST BE RUN IN ITS OWN DIRECTORY!** as it can't find the debugger otherwise and fails with a message:

    Spawning Test.exe
    !!! ERROR !!!
    The system cannot find the file specified
       at System.Diagnostics.Process.StartWithShellExecuteEx(ProcessStartInfo startInfo)
       at System.Diagnostics.Process.Start(ProcessStartInfo startInfo)
       at ADPlus.AdplusApl.TryAttachSelectedProcesses()
       at ADPlus.AdplusApl.TryRun()
    !!!ERROR - ADPlus failed to run

### Command line options

#### Hang mode

#### Crash mode

    adplus -p 7628 -crash -o c:\dumps -FullOnFirst

Attach to a running process with dump on first and Ctrl+C causing no action, but a break to the debugger:

    C:>adplus.exe -crash -p 7532 -fullonfirst -o d:\diag\dumps -CTCV
    Starting ADPlus
    ********************************************************
    *                                                      *
    * ADPLus Flash V 7.01.002 02/27/2009                   *
    *                                                      *
    *   For ADPlus documentation see ADPlus.doc            *
    *   New command line options:                          *
    *     -pmn <procname> - process monitor                *
    *        waits for a process to start                  *
    *     -po <procname> - optional process                *
    *        won't fail if this process isn't running      *
    *     -mss <LocalCachePath>                            *
    *        Sets Microsoft's symbol server                *
    *     -r <quantity> <interval in seconds>              *
    *        Runs -hang multiple times                     *
    *                                                      *
    *   ADPlusManager - an additional tool to facilitate   *
    *   the use of ADPlus in distributed environments like *
    *   computer clusters.                                 *
    *   Learn about ADPlusManager in ADPlus.doc            *
    *                                                      *
    ********************************************************

    Attaching to 7532 - w3wp in Crash mode 06/29/2012 11:50:07
    Logs and memory dumps will be placed in d:\diag\dumps\20120629_115007_Crash_Mode

Launch a new proces

    adplus -c first-chance-only-specific-exception.adplus.config -o c:\dumps -sc TSService.exe

#### Common options

##### Output directory
To set the output directory for dump files you need to use the **-o** option: `-o c:\dumps`

### Configuration file

All commands in configuration needs to be constructed from keywords and seperated by semicolons (;).

The Adplus behviours can be configured via a config file. To **load a config file** into the adplus you need to use the `-c <config_file_path>` switch. The format of this file is quite well explained in the adplus documentation.

The configuration file is case insensitive and the xml version header is not required. Example:

    adplus -c adplus-clr.config -o c:\dumps -sc test.exe

By default first chance CLR exceptions are not logged by adplus. You need to use a configuration file to change this bahaviour.

#### Diagnosing specific managed exceptions ####

We can configure filtering CLR exceptions using one of the configuration files from the `adplus-configs` directory. Then to collect dumps and logs for an exe application use:

    adplus -c first-chance-null-reference-exception.adplus.config -o c:\dumps -sc Thrower.exe

To attach to an already running process use:

    adplus -c first-chance-null-reference-exception.adplus.config -o c:\dumps -p <process-id>

