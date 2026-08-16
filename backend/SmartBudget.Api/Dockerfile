# syntax=docker/dockerfile:1

# --- Build stage ---------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY SmartBudget.Api.csproj ./
RUN dotnet restore "SmartBudget.Api.csproj"

COPY . .
RUN dotnet publish "SmartBudget.Api.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore

# --- Runtime stage ---------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# curl is used by the docker-compose healthcheck to probe GET /health.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_EnableDiagnostics=0

EXPOSE 8080

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "SmartBudget.Api.dll"]
