
## Tracing with trcapi and syelogd (Detours)

This folder contains compiled binaries from the [Detours repository](https://github.com/microsoft/Detours). Detours contains a **traceapi** sample that we can use to trace [many WinAPI methods](https://github.com/microsoft/Detours/blob/main/samples/traceapi/_win32.cpp). Once we inject a DLL into a process, it will start logging the detoured API calls to the syelogd service.

Here are the steps required to collect the WinAPI trace in a test.exe process:

1. Start syelogd.exe in command prompt. If you expect a high number of events, consider disabling the standard output and log to a file, for example:

```
syelogd64.exe /q winapi.out
```

2. Inject the trcapi32 or trcapi64 DLL into the target process (TODO:instructions how to do it)

An example trace output looks as follows:

```
20230921133135854 11204 50.60: trcapi64: 000 +GetEnvironmentVariableW(PSModuleAutoLoadingPreference,ac1a38e7d0,80)
20230921133135854 11204 50.60: trcapi64: 000 -GetEnvironmentVariableW(,àÈR,) -> 0
20230921133135854 11204 50.60: trcapi64: 000 +GetConsoleScreenBufferInfo(4c4,ac1a38e270)
20230921133135854 11204 50.60: trcapi64: 000 -GetConsoleScreenBufferInfo(,) -> 1
20230921133135854 11204 50.60: trcapi64: 000 +GetEnvironmentVariableW(COLUMNS,ac1a38d990,80)
20230921133135854 11204 50.60: trcapi64: 000 -GetEnvironmentVariableW(,120,) -> 3
20230921133135854 11204 50.60: trcapi64: 000 +GetEnvironmentVariableW(COLUMNS,ac1a38df80,80)
20230921133135854 11204 50.60: trcapi64: 000 -GetEnvironmentVariableW(,120,) -> 3
20230921133135854 11204 50.60: trcapi64: 000 +GetEnvironmentVariableW(COLUMNS,ac1a38da50,80)
20230921133135854 11204 50.60: trcapi64: 000 -GetEnvironmentVariableW(,120,) -> 3
20230921133135854 11204 50.60: trcapi64: 000 +RaiseException(e0434352,1,5,ac1a38df08)
20230921133135854 11204 50.60: trcapi64: 000 -RaiseException(,,,) ->
20230921133135854 11204 50.60: trcapi64: 000 +RaiseException(e0434352,1,5,ac1a38b998)
20230921133135854 11204 50.60: trcapi64: 000 -RaiseException(,,,) ->
20230921133135854 11204 50.60: trcapi64: 000 +SetEnvironmentVariableW(COLUMNS,120)
20230921133135854 11204 50.60: trcapi64: 000 -SetEnvironmentVariableW(,) -> 1
20230921133135854 11204 50.60: trcapi64: 000 +GetEnvironmentVariableW(PSModuleAutoLoadingPreference,ac1a38d6c0,80)
20230921133135854 11204 50.60: trcapi64: 000 -GetEnvironmentVariableW(,àÈR,) -> 0
```
