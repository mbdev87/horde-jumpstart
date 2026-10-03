# HordeServer, built from the vanilla engine sources staged by scripts/stage-context.sh.
# Derived from Engine/Source/Programs/Horde/HordeServer/Dockerfile, minus the test
# suite and code-coverage tooling so the sandbox comes up quickly.
# Build context must contain (mirroring the engine tree layout):
#   Source/Programs/Shared/...
#   Source/Programs/Horde/...
#   Binaries/DotNET/EpicGames.Perforce.Native/...

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build-env
WORKDIR /app
COPY Source/Programs/Horde/nuget.config ./Source/Programs/Horde/nuget.config
COPY Binaries/DotNET/EpicGames.Perforce.Native/ Binaries/DotNET/EpicGames.Perforce.Native/
COPY Source/Programs/Shared/ ./Source/Programs/Shared/
COPY Source/Programs/Horde/ ./Source/Programs/Horde/
RUN dotnet publish Source/Programs/Horde/HordeServer/HordeServer.csproj -c Release -o out -p:WithHordeStorage=false
RUN rm -rf /app/out/runtimes/osx* && \
    rm -rf /app/out/runtimes/win* && \
    rm -rf /app/out/runtimes/linux-arm* && \
    rm -rf /app/out/runtimes/linux/native/libgrpc_csharp_ext.x86.so

# Full dashboard SPA (Vite/React). HordeServer serves it when <AppDir>/DashboardApp exists.
# Recipe from HordeDashboard/Dockerfile (node 20 + legacy peer deps).
FROM node:20.11.0 AS dashboard-env
WORKDIR /app
COPY Source/Programs/Horde/HordeDashboard ./Dashboard
RUN cd ./Dashboard && npm install --legacy-peer-deps && npm run build

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=""
ENV ASPNETCORE_HTTP_PORTS=""
COPY --from=build-env /app/out .
COPY --from=dashboard-env /app/Dashboard/dist ./DashboardApp
# Docs pages the SPA fetches at /documentation/Docs/... plus images (../Images/...)
# and root README referenced from the docs tree.
COPY Source/Programs/Horde/Docs ./DashboardApp/documentation/Docs
COPY Source/Programs/Horde/Docs/Images ./DashboardApp/documentation/Images
COPY Source/Programs/Horde/README.md ./DashboardApp/documentation/README.md
ENTRYPOINT [ "dotnet", "HordeServer.dll" ]
