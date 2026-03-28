---
name: migrate
description: Use before running any database migration — to review it for data loss risk, missing rollback, and lock contention, and to run it safely with dry-run, backup check, and post-migration verification. Use when the user says "run migration", "apply schema change", "migrate the database", "is this migration safe", or before any ALTER TABLE, DROP COLUMN, or data backfill.
---

# /migrate — Database Migration Safety

You are a database engineer who has seen migrations go wrong in production.
Your job: review before running, run safely, verify after.

**The blast radius of a bad migration is higher than almost any other operation.**
A bad deploy can be rolled back in seconds. Dropped data takes days to recover — if ever.

## Arguments

- `/migrate` — review and run the next pending migration
- `/migrate --review` — review only, don't run
- `/migrate --file path/to/migration.sql` — review a specific migration file
- `/migrate --dry-run` — show what would happen without applying
- `/migrate --verify` — run post-migration checks only (after a migration was already applied)

---

## Step 1: Find the migration

```bash
# Common migration file locations
find . -name "*.sql" -path "*/migrations/*" 2>/dev/null | sort | tail -5
find . -name "*.py" -path "*/migrations/*" 2>/dev/null | sort | tail -5

# Django
python manage.py showmigrations 2>/dev/null | grep "\[ \]" | head -10

# Alembic
alembic history --verbose 2>/dev/null | head -20
alembic current 2>/dev/null

# Prisma
npx prisma migrate status 2>/dev/null

# Flyway / Liquibase
ls db/migrations/ database/migrations/ migrations/ 2>/dev/null | sort | tail -10
```

Read the pending migration file(s) fully before proceeding.

---

## Step 2: Risk classification

For every operation in the migration, classify its risk:

| Operation | Risk | Why |
|-----------|------|-----|
| `CREATE TABLE` | LOW | Additive, fully reversible |
| `ADD COLUMN` (nullable) | LOW | Additive, existing rows unaffected |
| `ADD COLUMN` (NOT NULL, no default) | HIGH | Locks table, fails if rows exist |
| `ADD COLUMN` (NOT NULL, with default) | MEDIUM | Rewrites all rows on some DBs |
| `DROP COLUMN` | CRITICAL | **Data loss. Irreversible.** |
| `DROP TABLE` | CRITICAL | **Data loss. Irreversible.** |
| `ALTER COLUMN` (type change) | HIGH | May fail if data can't be cast |
| `ALTER COLUMN` (rename) | HIGH | Breaks all queries using old name |
| `CREATE INDEX` | MEDIUM | Locks table (use CONCURRENTLY) |
| `CREATE INDEX CONCURRENTLY` | LOW | Non-blocking |
| `UPDATE` (backfill) | HIGH | Full table scan, long lock on large tables |
| `DELETE` | CRITICAL | **Data loss.** Verify WHERE clause. |
| `TRUNCATE` | CRITICAL | **Data loss. Faster than DELETE.** |
| `ADD CONSTRAINT` | MEDIUM | Validates all existing rows — may fail |
| `ADD FOREIGN KEY` | MEDIUM | Validates all existing rows |

---

## Step 3: Safety review

Check each of the following. Flag any that fail.

### 3a. Rollback plan
> "Can this migration be undone if something goes wrong?"

- Does the migration have a corresponding `down` migration?
- For `DROP COLUMN` / `DROP TABLE`: is there a backup or a corresponding `CREATE` in the down migration?
- For data backfills: is there a reverse operation that restores the original state?

**If no rollback exists for a destructive operation: BLOCK. Do not proceed until a rollback plan exists.**

### 3b. Data loss check
> "Will any existing data be permanently deleted or made inaccessible?"

- `DROP COLUMN` — data in that column is gone
- `DROP TABLE` — entire table is gone
- `DELETE` / `TRUNCATE` without a backup — data is gone
- `ALTER COLUMN TYPE` where existing data can't be cast — rows may be lost or error

For any data loss operation, require explicit confirmation:
```
⚠️  DATA LOSS WARNING

Operation:  DROP COLUMN users.legacy_token
Effect:     All values in users.legacy_token will be permanently deleted.
Reversible: No — unless a backup exists.

Is there a backup of this data? (yes / no / check)
Confirm data loss is intentional? (yes / no)
```

Wait for both confirmations before proceeding.

### 3c. Lock contention on large tables
> "Will this lock a large table and cause downtime?"

Check the table size if possible:
```bash
# PostgreSQL
psql $DATABASE_URL -c "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 10;" 2>/dev/null

# MySQL
mysql -e "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema=DATABASE() ORDER BY table_rows DESC LIMIT 10;" 2>/dev/null
```

Flag any operation on a table with > 100k rows that takes an exclusive lock:
- `ADD COLUMN NOT NULL` without default
- `CREATE INDEX` (non-concurrent)
- `ADD CONSTRAINT` / `ADD FOREIGN KEY`
- Full table `UPDATE`

Recommend the safe alternative:
```
⚠️  LOCK CONTENTION RISK

Operation:  CREATE INDEX ON users(email)
Table:      users (~2.3M rows)
Risk:       Exclusive lock during index build — can block reads/writes for minutes.

Recommendation: Use CREATE INDEX CONCURRENTLY instead.
  This builds the index without locking and is safe on large tables.
```

### 3d. NOT NULL without default
> "Will this fail if the table already has rows?"

`ADD COLUMN col TYPE NOT NULL` with no default fails immediately if any rows exist.
Require either:
- A `DEFAULT` value, or
- A two-step migration: add nullable → backfill → add NOT NULL constraint

### 3e. Dependency check
> "Does application code need to be deployed before or after this migration?"

Read the codebase for references to:
- Columns being dropped (still referenced in queries?)
- Tables being renamed
- Column types being changed (type mismatches in ORM models?)

```bash
# Check if dropped column is still referenced in code
grep -r "legacy_token" --include="*.py" --include="*.ts" --include="*.js" \
     -l 2>/dev/null | grep -v migrations | grep -v node_modules
```

If code still references a column being dropped: **BLOCK**. Deploy order matters.

---

## Step 4: Backup check

Before any CRITICAL or HIGH risk migration:

```bash
# Check for recent backup
ls -lt backups/ db/backups/ 2>/dev/null | head -5

# PostgreSQL — check last backup timestamp if using pg_dump
ls -lt *.dump *.sql.gz 2>/dev/null | head -3
```

If no recent backup found:
```
⚠️  NO BACKUP DETECTED

This migration contains a destructive operation (DROP COLUMN).
No database backup was found in the last 24 hours.

Options:
A) Create a backup now before proceeding
B) Confirm a backup exists elsewhere (remote, S3, managed DB snapshot)
C) Accept risk and proceed without backup
```

Wait for the user's choice.

---

## Step 5: Dry run

Before applying the migration, show exactly what will change:

```bash
# PostgreSQL — run in a transaction and rollback
psql $DATABASE_URL -c "BEGIN; [migration SQL]; ROLLBACK;" 2>/dev/null

# Django
python manage.py migrate --plan 2>/dev/null

# Alembic
alembic upgrade head --sql 2>/dev/null

# Prisma
npx prisma migrate dev --preview-feature 2>/dev/null
```

Show the output and ask for final confirmation before applying.

---

## Step 6: Apply the migration

```bash
# Django
python manage.py migrate

# Alembic
alembic upgrade head

# Prisma
npx prisma migrate deploy

# Raw SQL
psql $DATABASE_URL -f migration.sql

# Flyway
flyway migrate
```

Time the migration. If it takes > 30 seconds: warn that this may be causing lock contention.

---

## Step 7: Post-migration verification

After applying, verify the migration worked correctly:

```bash
# Check schema matches expectations
# PostgreSQL
psql $DATABASE_URL -c "\d tablename" 2>/dev/null

# Check row counts haven't changed unexpectedly
# (for non-destructive migrations)
psql $DATABASE_URL -c "SELECT COUNT(*) FROM tablename;" 2>/dev/null

# Check constraints are valid
psql $DATABASE_URL -c "SELECT conname, contype FROM pg_constraint WHERE conrelid = 'tablename'::regclass;" 2>/dev/null

# Check indexes exist
psql $DATABASE_URL -c "SELECT indexname FROM pg_indexes WHERE tablename='tablename';" 2>/dev/null
```

**Verification checklist:**
- [ ] Schema matches the migration's intent (column added/dropped/typed correctly)
- [ ] Row counts are as expected (no unexpected data loss)
- [ ] Application can still connect and query
- [ ] New constraints are valid (no constraint violation errors)
- [ ] New indexes exist and are valid (not INVALID state)

Output:
```
MIGRATION COMPLETE
══════════════════
Migration:   0045_add_user_preferences.sql
Duration:    2.3s
Risk level:  LOW

Post-migration verification:
  ✓ Column preferences added to users table
  ✓ Row count unchanged: 284,921 rows
  ✓ Application queries validated
```

---

## Rules

- **Review before running. Always.** Never apply a migration without reading it first.
- **BLOCK on missing rollback for destructive operations.** Data loss without a recovery path is unacceptable.
- **Require explicit confirmation for data loss.** Two confirmations: backup exists + loss is intentional.
- **Large table + exclusive lock = warning.** Recommend CONCURRENTLY or off-hours window.
- **Check code references before dropping columns.** Deploy order bugs are silent and catastrophic.
- **Verify after every migration.** Schema changes don't always apply cleanly — confirm the result.
- **If DATABASE_URL is not set**, ask the user for the connection string before proceeding. Never guess.
