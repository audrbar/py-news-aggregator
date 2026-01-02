# Deployment Guide

Complete guide for deploying the AI News Aggregator to production using Fly.io or Railway.

## Table of Contents

-   [Fly.io Deployment (Recommended)](#flyio-deployment-recommended)
-   [Railway Deployment (Database Option)](#railway-deployment-database-option)
-   [Environment Variables](#environment-variables-reference)
-   [Troubleshooting](#troubleshooting)
-   [Maintenance & Monitoring](#maintenance--monitoring)

---

## Fly.io Deployment (Recommended)

Complete deployment with built-in PostgreSQL and cron scheduling.

### Quick Start (15 minutes)

#### Prerequisites

-   Install Fly.io CLI: `curl -L https://fly.io/install.sh | sh` (or `brew install flyctl`)
-   Create account: `fly auth signup` (or `fly auth login`)

#### Step 1: Install Fly CLI

```bash
# macOS/Linux
curl -L https://fly.io/install.sh | sh

# Or using Homebrew (macOS)
brew install flyctl
```

#### Step 2: Login to Fly.io

```bash
fly auth login
```

#### Step 3: Create Fly.io App

```bash
cd /path/to/py-news-aggregator

# Launch the app (follow prompts)
fly launch --no-deploy

# When prompted:
# - Choose app name (or use auto-generated)
# - Select region (e.g., iad for Washington DC, or closest to you)
# - PostgreSQL? Select YES
# - Deploy now? Select NO (we need to set env variables first)
```

#### Step 4: Set Environment Variables

```bash
# Set your OpenAI API key
fly secrets set OPENAI_API_KEY="sk-your-key-here"

# Set email credentials
fly secrets set MY_EMAIL="your.email@gmail.com"
fly secrets set APP_PASSWORD="your-16-char-app-password"

# PostgreSQL credentials (auto-set if you created Fly Postgres)
# If using external database, set these:
# fly secrets set POSTGRES_HOST="your-db-host"
# fly secrets set POSTGRES_USER="postgres"
# fly secrets set POSTGRES_PASSWORD="your-password"
# fly secrets set POSTGRES_DB="py_news_aggregator"
# fly secrets set POSTGRES_PORT="5432"
```

#### Step 5: Deploy

```bash
fly deploy
```

#### Step 6: Verify

```bash
# Check status
fly status

# View logs
fly logs

# SSH into the machine
fly ssh console

# Inside the container, check cron:
crontab -l
```

---

### Architecture on Fly.io

**What's Different:**

-   Fly.io runs a **persistent machine** (not serverless)
-   Cron runs **inside the container** using standard Linux cron
-   Database: Fly Postgres (recommended) or external database
-   Runs 24/7 with minimal resource usage (~$3-5/month)

**Daily Schedule:**

-   Cron job runs at **5:00 AM UTC** daily
-   Customizable in `start-cron.sh`

---

### Fly.io Configuration

#### Fly.toml Explanation

```toml
app = 'py-news-aggregator'          # Your app name
primary_region = 'iad'               # Region (iad=DC, lhr=London, etc.)

[build]
  dockerfile = "Dockerfile.flyio"    # Uses cron-enabled Dockerfile

[env]
  PYTHONUNBUFFERED = "1"
  ENVIRONMENT = "prod"

[[vm]]
  size = "shared-cpu-1x"             # Smallest machine (sufficient)
  memory = "512mb"                   # 512MB RAM
```

#### Customizing Cron Schedule

Edit `start-cron.sh` to change schedule:

```bash
# Current: Daily at 5:00 AM UTC
echo "0 5 * * * cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1" > /tmp/crontab

# Examples:
# Every 6 hours: "0 */6 * * * cd /app..."
# Twice daily (5AM, 5PM): "0 5,17 * * * cd /app..."
# Monday-Friday only: "0 5 * * 1-5 cd /app..."
```

---

### PostgreSQL on Fly.io

#### Option 1: Fly Postgres (Recommended)

```bash
# During fly launch, select YES for PostgreSQL
# Or create separately:
fly postgres create

# Attach to your app:
fly postgres attach <postgres-app-name>
```

This automatically sets `DATABASE_URL` environment variable.

#### Option 2: External Database (Railway, Supabase, etc.)

```bash
# Manually set connection details:
fly secrets set POSTGRES_HOST="your-host"
fly secrets set POSTGRES_USER="postgres"
fly secrets set POSTGRES_PASSWORD="your-password"
fly secrets set POSTGRES_DB="py_news_aggregator"
fly secrets set POSTGRES_PORT="5432"
```

---

### Fly.io Commands Reference

#### Deployment

```bash
# Deploy changes
fly deploy

# Deploy specific Dockerfile
fly deploy --dockerfile Dockerfile.flyio

# Force rebuild
fly deploy --no-cache
```

#### Monitoring

```bash
# View logs (live)
fly logs

# Check status
fly status

# View metrics
fly dashboard
```

#### Machine Management

```bash
# SSH into machine
fly ssh console

# Inside machine:
# - Check cron logs: tail -f /tmp/cron-logs/digest.log
# - View crontab: crontab -l
# - Test script manually: python main.py

# Restart machine
fly machine restart

# Stop machine
fly machine stop

# Start machine
fly machine start
```

#### Database Management

```bash
# Connect to Fly Postgres
fly postgres connect -a <postgres-app-name>

# Inside psql:
\dt                    # List tables
SELECT * FROM youtube_videos LIMIT 5;
```

#### Secrets (Environment Variables)

```bash
# List secrets
fly secrets list

# Set secret
fly secrets set KEY=value

# Remove secret
fly secrets unset KEY
```

---

### Fly.io Cost Estimate

**Fly.io Free Tier (Hobby Plan):**

-   3 shared-cpu-1x machines (256MB RAM each): FREE
-   3GB persistent storage: FREE
-   160GB transfer: FREE

**Your App Usage:**

-   1 machine (shared-cpu-1x, 512MB): **~$3-4/month**
-   Postgres database (1GB storage): **~$1-2/month**
-   **Total: ~$4-6/month**

To reduce costs:

```bash
# Use smaller machine
fly scale memory 256

# Stop when not needed (manual)
fly machine stop
```

---

### Updating on Fly.io

#### Deploy Code Changes

```bash
git pull origin main
fly deploy
```

#### Update Environment Variables

```bash
fly secrets set OPENAI_API_KEY="new-key"
```

#### Change Cron Schedule

1. Edit `start-cron.sh`
2. Deploy: `fly deploy`
3. Machine will use new schedule on next restart

---

### Scaling on Fly.io

#### Increase Memory

```bash
fly scale memory 1024  # 1GB RAM
```

#### Add More Machines (for redundancy)

```bash
fly scale count 2
```

#### Change Region

```bash
fly regions add lhr  # Add London region
fly regions remove iad  # Remove DC region
```

---

## Railway Deployment (Database Option)

Use Railway as an external PostgreSQL database for Fly.io or as a standalone option.

### Quick Start (10 minutes)

##### Step 1: Setup Railway Database

1. Go to https://railway.app
2. Sign up and create a new project
3. Add PostgreSQL database to your project
4. Copy connection details (user, password, host, port, database name)
5. Keep these credentials - you'll need them for Fly.io

#### Step 2: Connect to Fly.io

Use the Railway credentials with Fly.io:

```bash
fly secrets set POSTGRES_HOST="your-railway-host.railway.app"
fly secrets set POSTGRES_USER="postgres"
fly secrets set POSTGRES_PASSWORD="your-railway-password"
fly secrets set POSTGRES_DB="railway"
fly secrets set POSTGRES_PORT="5432"
```

---

### Railway Database Management

**View tables in Railway:**

1. Go to Railway dashboard
2. Select your PostgreSQL service
3. Use the built-in database viewer or connect via CLI

**Check data:**

```sql
-- View recent videos
SELECT title, published_at FROM youtube_videos
ORDER BY published_at DESC LIMIT 5;

-- View digests
SELECT title, article_type FROM digests
ORDER BY created_at DESC LIMIT 10;

-- Count articles by type
SELECT article_type, COUNT(*) FROM digests
GROUP BY article_type;
```

**Cost:**

-   Railway: $5/month for PostgreSQL with 512MB RAM, 8GB storage, shared CPU

---

## Environment Variables Reference

| Variable            | Required | Description                        | Where to Get            |
| ------------------- | -------- | ---------------------------------- | ----------------------- |
| `ENVIRONMENT`       | Yes      | Set to `prod` for production       | Auto-set in fly.toml    |
| `POSTGRES_USER`     | Yes      | Database username                  | Fly Postgres or Railway |
| `POSTGRES_PASSWORD` | Yes      | Database password                  | Fly Postgres or Railway |
| `POSTGRES_DB`       | Yes      | Database name                      | Fly Postgres or Railway |
| `POSTGRES_HOST`     | Yes      | Database host                      | Fly Postgres or Railway |
| `POSTGRES_PORT`     | Yes      | Database port                      | Fly Postgres or Railway |
| `OPENAI_API_KEY`    | Yes      | OpenAI API key for LLM             | OpenAI website          |
| `MY_EMAIL`          | Yes      | Gmail address for sending          | Your Gmail              |
| `APP_PASSWORD`      | Yes      | Gmail app password                 | Gmail settings          |
| `PROXY_USERNAME`    | No       | Webshare proxy username (optional) | Webshare.io             |
| `PROXY_PASSWORD`    | No       | Webshare proxy password (optional) | Webshare.io             |

### How to Get Gmail App Password

1. Go to your Google Account settings
2. Navigate to Security
3. Enable 2-Step Verification (if not enabled)
4. Go to "App passwords"
5. Generate a new app password for "Mail"
6. Use this 16-character password (not your regular Gmail password)

---

## Troubleshooting

### Fly.io Specific Issues

#### Check Cron is Running

```bash
fly ssh console
ps aux | grep cron
crontab -l
```

#### View Cron Logs

```bash
fly ssh console
tail -f /tmp/cron-logs/digest.log
```

#### Test Job Manually

```bash
fly ssh console
cd /app
python main.py
```

### Database Connection Issues

**Fly.io:**

```bash
# Verify environment variables
fly ssh console
env | grep POSTGRES
```

**General:**

-   Verify all `POSTGRES_*` environment variables are set correctly
-   Check database is running (Fly or Railway dashboard)
-   Verify `ENVIRONMENT=prod` is set
-   Ensure database allows external connections
-   Test connection locally first using the same credentials

### Email Not Sending

**Fly.io:**

```bash
# Check email credentials
fly secrets list

# Test manually
fly ssh console
python -c "import os; print(os.getenv('MY_EMAIL'))"
```

**General:**

-   Verify `MY_EMAIL` and `APP_PASSWORD` are correct
-   Check Gmail app password is valid (not regular password)
-   Enable "Less secure app access" if needed (Gmail settings)
-   Review email service logs for errors
-   Verify Gmail SMTP is not blocked by your account settings

### Build Failures

-   Check Dockerfile syntax
-   Verify all dependencies in `pyproject.toml`
-   Review build logs for specific errors
-   Ensure all required files are committed to Git
-   Check if there are any version conflicts

### YouTube Transcript Errors

-   Some videos don't have transcripts enabled
-   Use proxy credentials (`PROXY_USERNAME`, `PROXY_PASSWORD`) if rate-limited
-   Check YouTube channel IDs are correct in `app/config.py`

### Local Development Database Issues

-   Run `docker-compose up -d` to start PostgreSQL
-   Verify `app/.env.dev` has correct local settings
-   Check port 5432 is not in use by another PostgreSQL instance
-   Stop local PostgreSQL: `sudo -u postgres /Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data stop`

---

## Maintenance & Monitoring

### Local Development

For local development, use docker-compose to run PostgreSQL:

```bash
docker-compose up -d
```

This starts PostgreSQL locally on `localhost:5432`.

**Environment Configuration:**

-   Development uses `app/.env.dev` (local Docker database)
-   Production uses `app/.env` (Fly or Railway database)
-   The app defaults to `dev` environment unless `ENVIRONMENT=prod` is set

**To run locally:**

```bash
uv run python -m main
```

### Monitoring

**Fly.io:**

```bash
# View running status
fly status
fly dashboard  # Opens web dashboard

# Manual job trigger
fly ssh console
python main.py
```

**Railway:**

-   Check connection count, storage usage, and query performance in dashboard

### Backup Database

**Fly Postgres:**

```bash
fly postgres connect -a <postgres-app-name>
pg_dump py_news_aggregator > backup.sql
```

**Railway:**
Use Railway's built-in backup feature or connect via psql

---

## What Gets Created

When deployed, you'll have:

**Fly.io Setup:**

-   **Fly.io Machine**: Application with cron (~$3-5/month)

    -   Runs daily at 5 AM UTC
    -   Executes full pipeline automatically
    -   Sends email digest after completion

-   **Fly PostgreSQL** or **Railway PostgreSQL**: Production database (~$1-5/month)
    -   Tables: `youtube_videos`, `openai_articles`, `anthropic_articles`, `digests`
    -   Persistent storage for all scraped content

**Local Setup:**

-   **Local Docker PostgreSQL**: Development database (free)
    -   For local testing and development
    -   Isolated from production data

---

## Cost Comparison

| Platform            | Application | Database            | Total/Month |
| ------------------- | ----------- | ------------------- | ----------- |
| Fly.io (All-in-one) | $3-4        | $1-2 (Fly Postgres) | **$4-6**    |
| Fly.io + Railway    | $3-4        | $5 (Railway)        | **$8-9**    |

**Recommendation:** Use Fly.io with built-in Fly Postgres for best value.

---

## Performance Optimization

-   Monitor OpenAI API usage and costs
-   Adjust `hours` parameter to reduce content volume if needed
-   Optimize database queries if response time increases
-   Consider caching frequently accessed data
-   Review and clean old data periodically

---

## Support & Resources

-   **Fly.io Documentation**: https://fly.io/docs/
-   **Fly.io Community**: https://community.fly.io/
-   **Fly.io Status**: https://status.fly.io/
-   **Railway Documentation**: https://docs.railway.app
-   **OpenAI API Docs**: https://platform.openai.com/docs
-   **Project Issues**: Check GitHub repository issues

---

## Security Best Practices

1. **Never commit `.env` files** to Git (already in `.gitignore`)
2. **Use app passwords** for Gmail, not your main password
3. **Rotate API keys** periodically
4. **Monitor usage** to detect unusual activity
5. **Keep dependencies updated** for security patches
6. **Use strong passwords** for databases
7. **Limit database access** to only necessary IPs if possible

---

## Next Steps

After successful deployment:

1. ✅ Customize user profile in `app/profiles/user_profile.py`
2. ✅ Add/remove YouTube channels in `app/config.py`
3. ✅ Adjust cron schedule in `start-cron.sh` if needed
4. ✅ Monitor logs for first few runs
5. ✅ Fine-tune content sources based on preferences
6. ✅ Set up monitoring/alerts for failures

Enjoy your automated AI news digests! 🚀
