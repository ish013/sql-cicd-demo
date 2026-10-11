# SQL CI/CD Demo (GitHub Actions → DACPAC → Azure SQL)

This is a minimal, runnable example of the pipeline:

```
Developer updates SQL table
        |
Push changes to GitHub
        |
GitHub Actions builds SQL project
        |
Generate DACPAC
        |
Deploy DACPAC to Azure SQL Database
        |
Verify schema changes in Azure
```

It has two ways to demo it:

- **Part A — Run it fully locally** (no Azure account needed): builds the DACPAC and
  deploys it to a SQL Server running in Docker on your machine. Good for showing the
  client the mechanics without cloud setup.
- **Part B — Run it for real on GitHub Actions against Azure SQL**: push this repo to
  GitHub and watch the same pipeline deploy to an actual Azure SQL Database.

---

## Project layout

```
SqlProject/
  SqlProject.sqlproj         <- SQL Server Database Project (SDK-style)
  dbo/Tables/Customers.sql   <- sample table
  dbo/Tables/Orders.sql      <- sample table with a foreign key
.github/workflows/deploy.yml <- the GitHub Actions pipeline
docker-compose.yml           <- local SQL Server, stands in for Azure SQL
scripts/deploy-local.sh      <- builds the DACPAC and deploys it locally
```

---

## Part A: Run the whole pipeline locally

**Prerequisites:**
- [Docker](https://www.docker.com/products/docker-desktop/) running
- [.NET 8 SDK](https://dotnet.microsoft.com/download)

**Steps:**

```bash
# 1. Start a local SQL Server (stand-in for Azure SQL)
docker compose up -d

# wait ~15 seconds for SQL Server to finish starting, then:

# 2. Build the project into a DACPAC and deploy it
./scripts/deploy-local.sh
```

You'll see the script:
1. `dotnet build` the `.sqlproj` → produces `build/SqlProject.dacpac`
2. Use `sqlpackage` to publish that DACPAC to the running SQL Server (creating the
   `DemoDb` database and the `Customers`/`Orders` tables if they don't exist yet)
3. Query `INFORMATION_SCHEMA.TABLES` to verify the tables landed

**To show a schema change flowing through the pipeline:**
1. Edit `SqlProject/dbo/Tables/Customers.sql` — e.g. add a new column like
   `[Phone] NVARCHAR (20) NULL`.
2. Re-run `./scripts/deploy-local.sh`.
3. `sqlpackage` will diff the DACPAC against the live database and apply only the
   change (adds the column, nothing else) — this is the key thing to point out to the
   client: it's a schema *diff* deploy, not a destructive drop/recreate.

To tear down: `docker compose down -v`

---

## Part B: Run it for real with GitHub Actions + Azure SQL

1. Push this folder to a new GitHub repo.
2. In Azure, create (or reuse) an Azure SQL Database and get its ADO.NET connection
   string (Azure Portal → your SQL DB → Connection strings).
3. In your GitHub repo: **Settings → Secrets and variables → Actions → New repository
   secret**, name it `AZURE_SQL_CONNECTION_STRING`, and paste the connection string
   (with the real password filled in).
4. Push a commit that touches anything under `SqlProject/` (or trigger manually via
   **Actions → Build and Deploy SQL Database → Run workflow**).
5. Watch the **Actions** tab: build → DACPAC artifact uploaded → deploy step publishes
   to Azure SQL → verify step prints the query to confirm.

---

## Talking points for the client demo

- **Schema as code**: every table/column is a `.sql` file in source control, reviewable
  in pull requests like application code.
- **DACPAC = a portable schema snapshot**: built once in CI, deployable to any target
  (dev, staging, Azure SQL prod) without re-running raw scripts by hand.
- **Diff-based deploys**: `sqlpackage` compares the DACPAC to the target database and
  generates only the delta — no manual change scripts, no drift between environments.
- **Everything is auditable**: the GitHub Actions run log is a permanent record of what
  was deployed, when, and from which commit.
