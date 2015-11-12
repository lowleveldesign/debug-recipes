@echo off
powershell -NoProfile -ExecutionPolicy ByPass -File "%~d0%~p0TraceRequest.ps1" -BaseAppUrl "%1" -Password "%2"
