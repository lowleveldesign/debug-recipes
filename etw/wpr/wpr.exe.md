

### Get information on running profiles ###

To find active WPR recording you can run `wpr -status [profiles][collectors [details]]`:

    PS wpr> wpr -status profiles

    Microsoft Windows Performance Recorder Version 6.2.9200
    Copyright (c) 2012 Microsoft Corporation. All rights reserved.

    WPR recording is in progress...

    Time since start        : 00:00:13
    Dropped event           : 0
    Logging mode            : Memory

    Recording system activity using the following set of profiles:

    Profile                 : DiskIO.Verbose.Memory, CPU.Verbose.Memory, FileIO.Verbose.Memory

Tracing
-------

### Profiling using predefined profiles ###

To start profiling with CPU,FileIO and DiskIO profile run:

    wpr -start CPU -start FileIO -start DiskIO

To save the results run:

    wpr -stop C:\temp\result.etl

To completely turn off wpr logging run: `wpr -cancel`.

### Profiling using custom profiles

Start tracing:

    wpr.exe -start GeneralProfile -start Audio -start circular-audio-glitches.wprp!MediaProfile -filemode

Stop tracing and save the results to a file (say, my-wpr-glitches.etl:)

    wpr.exe -stop my-wpr-glitches.etl

(Optional) if you want to cancel tracing:

    wpr.exe -cancel

(Optional) if you want to see whether tracing is currently active:

    wpr.exe -status

### Profiling a system boot ###

To collect general profile traces use:

    wpr -start generalprofile -onoffscenario boot -numiterations 1

All options are displayed after executing: `wpr -help start`.

