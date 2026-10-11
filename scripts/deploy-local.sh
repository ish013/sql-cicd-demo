#!/usr/bin/env bash
# Simulates the CI/CD pipeline locally:
#   1. Build the SQL project -> DACPAC
#   2. Deploy the DACPAC to the local Dockerized SQL Server (stand-in for Azure SQL)
#   3. Verify the schema landed
#
# Prereqs: Docker, .NET 8 SDK, sqlpackage (installed automatically via dotnet tool if missing)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="localhost,1433"
USER="sa"
PASSWORD="DemoPass123!"
DB_NAME="DemoDb"

echo "== Step 1/3: Build SQL project (generate DACPAC) =="
dotnet build "$ROOT_DIR/SqlProject/SqlProject.sqlproj" --configuration Release --output "$ROOT_DIR/build"
DACPAC_PATH="$ROOT_DIR/build/SqlProject.dacpac"
echo "DACPAC generated at: $DACPAC_PATH"

echo ""
echo "== Step 2/3: Deploy DACPAC to SQL Server (local stand-in for Azure SQL) =="
if ! command -v sqlpackage &> /dev/null; then
  echo "sqlpackage not found, installing as a local dotnet tool..."
  dotnet tool install -g microsoft.sqlpackage
  export PATH="$PATH:$HOME/.dotnet/tools"
fi

sqlpackage /Action:Publish \
  /SourceFile:"$DACPAC_PATH" \
  /TargetServerName:"$SERVER" \
  /TargetDatabaseName:"$DB_NAME" \
  /TargetUser:"$USER" \
  /TargetPassword:"$PASSWORD" \
  /TargetEncryptConnection:False

echo ""
echo "== Step 3/3: Verify schema changes =="
docker exec -i sql-cicd-demo /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U "$USER" -P "$PASSWORD" -d "$DB_NAME" \
  -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' ORDER BY TABLE_NAME;"

echo ""
echo "Done. $DB_NAME now has the latest schema from SqlProject."
