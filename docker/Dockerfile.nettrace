FROM mcr.microsoft.com/dotnet/sdk:5.0 AS base

RUN dotnet tool install -g dotnet-trace

ENTRYPOINT ["/root/.dotnet/tools/dotnet-trace", "collect", "-n", "dotnet", "-o", "/work/trace.nettrace", "@/work/input.rsp"]
