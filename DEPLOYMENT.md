# Deployment Guide

Complete guide for deploying the AI News Aggregator to production using Render.com and Railway.

## Table of Contents

- [Quick Start (10 minutes)](#quick-start-10-minutes)
- [Detailed Step-by-Step Guide](#detailed-step-by-step-guide)
- [Environment Variables](#environment-variables-reference)
- [Troubleshooting](#troubleshooting)
- [Maintenance & Monitoring](#maintenance--monitoring)

---

## Quick Start (10 minutes)

### Step 1: Setup Railway Database
1. Go to https://railway.app
2. Sign up and create a new project
3. Add PostgreSQL database to your project
4. Copy connection details (user, password, host, port, database name)
5. Keep these credentials - you'll need them for Render

### Step 2: Create Render Account
1. Go to https://render.com
2. Sign up (free account works)
3. Verify email

### Step 3: Deploy from GitHub
1. In Render dashboard: **New** → **Blueprint**
2. Connect GitHub (if not connected)
3. Select repository: `py-news-aggregator`
4. Select your branch (e.g., `main` or `master`)
5. Click **Apply** (Render reads `render.yaml` automatically)

### Step 4: Set Environment Variables
After the cron job is created, go to `daily-digest-job` → **Environment** tab:

```env
ENVIRONMENT=prod
POSTGRES_USER=your_railway_user
POSTGRES_PASSWORD=your_railway_password
POSTGRES_DB=railway
POSTGRES_HOST=your_railway_host.railway.app
POSTGRES_PORT=5432
OPENAI_API_KEY=sk-...
MY_EMAIL=your.email@gmail.com
APP_PASSWORD=your_16_char_app_password
```

**Important**: Use your Railway database credentials from Step 1!

### Step 5: Test
1. Go to `daily-digest-job` → **Logs**
2. Click **Manual Deploy** to test immediately
3. Check your email inbox
4. Verify in Railway dashboard that tables were created

---

## Detailed Step-by-Step Guide

### Architecture Overview

- **Application Hosting**: Render.com (cron job for scheduled execution)
- **Production Database**: Railway.app (PostgreSQL)
- **Development Database**: Local Docker PostgreSQL

### Prerequisites

- Render.com account (sign up at https://render.com)
- Railway.app account with PostgreSQL database (sign up at https://railway.app)
- GitHub account with this repository
- OpenAI API key
- Gmail account with app password (for email sending)

### 1. Create Render Account

1. Go to https://render.com
2. Sign up for a free account (or log in if you already have one)
3. Verify your email address

### 2. Connect GitHub Repository

1. In Render dashboard, click "New" → "Blueprint"
2. Connect your GitHub account if not already connected
3. Select the repository: `py-news-aggregator`
4. Select your main branch
5. Render will detect `render.yaml` automatically

### 3. Setup Railway Database (One-time)

1. Go to https://railway.app and create an account
2. Create a new project → Add PostgreSQL database
3. Copy the database connection details:
   - `POSTGRES_USER`
   - `POSTGRES_PASSWORD`
   - `POSTGRES_DB`
   - `POSTGRES_HOST`
   - `POSTGRES_PORT`
4. Keep these credentials - you'll need them for Render

### 4. Review Blueprint Configuration

Render will read `render.yaml` and show you:
- **Cron Job**: `daily-digest-job` (runs daily at 5 AM UTC)
- **Note**: Database is on Railway, not managed by Render

Click "Apply" to create the cron job service.

### 5. Set Environment Variables in Render

After the cron job is created, you need to set environment variables:

1. Go to the `daily-digest-job` service in Render dashboard
2. Navigate to "Environment" tab
3. Add the following variables:

```env
ENVIRONMENT=prod
POSTGRES_USER=your_railway_user
POSTGRES_PASSWORD=your_railway_password
POSTGRES_DB=your_railway_db_name
POSTGRES_HOST=your_railway_host
POSTGRES_PORT=your_railway_port
OPENAI_API_KEY=your_openai_api_key_here
MY_EMAIL=your_email@gmail.com
APP_PASSWORD=your_gmail_app_password_here
```

**Important**: 
- Use your Railway database credentials for all `POSTGRES_*` variables
- `ENVIRONMENT=prod` tells the app to use production configuration

### 6. Initialize Database

The database tables will be created automatically when the cron job runs for the first time (via `app.database.create_tables` in the Dockerfile).

To manually trigger table creation:

1. Go to the cron job service in Render
2. Click "Manual Deploy" → "Deploy latest commit"
3. Check logs to verify tables were created successfully

### 7. Verify Deployment

1. Check the cron job logs in Render dashboard
2. Look for successful database connection and execution messages
3. Verify email was sent (check your inbox)
4. Check Railway dashboard to confirm database tables were created

### 8. Adjust Schedule (Optional)

To change when the daily digest runs:

1. Edit `render.yaml`:
   ```yaml
   schedule: "0 8 * * *"  # 8 AM UTC instead of 5 AM
   ```
2. Push changes to GitHub
3. Render will automatically update

**Cron Schedule Format**: `minute hour day month weekday`
- `0 0 * * *` = Daily at midnight UTC
- `0 5 * * *` = Daily at 5 AM UTC
- `0 8 * * *` = Daily at 8 AM UTC
- `0 0 * * 1` = Every Monday at midnight UTC

---

## Environment Variables Reference

| Variable | Required | Description | Where to Get |
|----------|----------|-------------|-------------|
| `ENVIRONMENT` | Yes | Set to `prod` for production | Render dashboard |
| `POSTGRES_USER` | Yes | Database username | Railway dashboard |
| `POSTGRES_PASSWORD` | Yes | Database password | Railway dashboard |
| `POSTGRES_DB` | Yes | Database name | Railway dashboard |
| `POSTGRES_HOST` | Yes | Database host | Railway dashboard |
| `POSTGRES_PORT` | Yes | Database port | Railway dashboard |
| `OPENAI_API_KEY` | Yes | OpenAI API key for LLM | OpenAI website |
| `MY_EMAIL` | Yes | Gmail address for sending | Your Gmail |
| `APP_PASSWORD` | Yes | Gmail app password | Gmail settings |
| `PROXY_USERNAME` | No | Webshare proxy username (optional) | Webshare.io |
| `PROXY_PASSWORD` | No | Webshare proxy password (optional) | Webshare.io |

### How to Get Gmail App Password

1. Go to your Google Account settings
2. Navigate to Security
3. Enable 2-Step Verification (if not enabled)
4. Go to "App passwords"
5. Generate a new app password for "Mail"
6. Use this 16-character password (not your regular Gmail password)

---

## Troubleshooting

### Database Connection Issues

- Verify all `POSTGRES_*` environment variables are set correctly in Render
- Check Railway database is running (check Railway dashboard)
- Verify `ENVIRONMENT=prod` is set in Render
- Ensure Railway database allows external connections (should be default)
- Check Railway database connection details haven't changed
- Test connection locally first using the same credentials

### Cron Job Not Running

- Check cron job logs in Render dashboard
- Verify schedule syntax in `render.yaml`
- Ensure Docker build succeeded
- Check if manual deploy works
- Verify the cron job is not suspended (free tier limitation)

### Email Not Sending

- Verify `MY_EMAIL` and `APP_PASSWORD` are correct
- Check Gmail app password is valid (not regular password)
- Enable "Less secure app access" if needed (Gmail settings)
- Review email service logs for errors
- Verify Gmail SMTP is not blocked by your account settings

### Build Failures

- Check Dockerfile syntax
- Verify all dependencies in `pyproject.toml`
- Review build logs for specific errors
- Ensure all required files are committed to Git
- Check if there are any version conflicts

### YouTube Transcript Errors

- Some videos don't have transcripts enabled
- Use proxy credentials (`PROXY_USERNAME`, `PROXY_PASSWORD`) if rate-limited
- Check YouTube channel IDs are correct in `app/config.py`

### Local Development Database Issues

- Run `docker-compose up -d` to start PostgreSQL
- Verify `app/.env.dev` has correct local settings
- Check port 5432 is not in use by another PostgreSQL instance
- Stop local PostgreSQL: `sudo -u postgres /Library/PostgreSQL/16/bin/pg_ctl -D /Library/PostgreSQL/16/data stop`

---

## Maintenance & Monitoring

### Local Development

For local development, use docker-compose to run PostgreSQL:

```bash
docker-compose up -d
```

This starts PostgreSQL locally on `localhost:5432`.

**Environment Configuration:**
- Development uses `app/.env.dev` (local Docker database)
- Production uses `app/.env` (Railway database)
- The app defaults to `dev` environment unless `ENVIRONMENT=prod` is set

**To run locally:**
```bash
uv run python -m main
```

### Updating the Deployment

1. Make changes to code
2. Commit and push to GitHub
3. Render automatically rebuilds and redeploys
4. For cron jobs, changes take effect on next scheduled run

### Monitoring

- **Render Logs**: View in Render dashboard under the cron job service
- **Railway Database**: Check connection count, storage usage, and query performance
- **Cron Job History**: Monitor execution history and success rate in Render
- **Email Delivery**: Check if emails are being sent successfully

### Database Management

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

### Cost Considerations

**Current Pricing:**
- **Render**: Free tier available for cron jobs with limited execution time
- **Railway**: $5/month for PostgreSQL with 512MB RAM, 8GB storage, shared CPU

**Production Recommendations:**
- Railway Starter plan provides good performance for small-medium workloads
- Monitor database usage in Railway dashboard
- Consider Render paid plans for more frequent cron execution if needed
- Set up usage alerts to avoid unexpected charges

### Performance Optimization

- Monitor OpenAI API usage and costs
- Adjust `hours` parameter to reduce content volume if needed
- Optimize database queries if response time increases
- Consider caching frequently accessed data
- Review and clean old data periodically

---

## What Gets Created

When deployed, you'll have:

- **Railway PostgreSQL**: Production database (~$5/month)
  - Tables: `youtube_videos`, `openai_articles`, `anthropic_articles`, `digests`
  - Persistent storage for all scraped content
  
- **Render Cron Job**: Scheduled execution (free tier)
  - Runs daily at 5 AM UTC
  - Executes full pipeline automatically
  - Sends email digest after completion

- **Local Docker PostgreSQL**: Development database (free)
  - For local testing and development
  - Isolated from production data

---

## Support & Resources

- **Render Documentation**: https://render.com/docs
- **Railway Documentation**: https://docs.railway.app
- **OpenAI API Docs**: https://platform.openai.com/docs
- **Project Issues**: Check GitHub repository issues
- **Render Support**: Available in Render dashboard
- **Railway Support**: Community Discord and support tickets

---

## Security Best Practices

1. **Never commit `.env` files** to Git (already in `.gitignore`)
2. **Use app passwords** for Gmail, not your main password
3. **Rotate API keys** periodically
4. **Monitor usage** to detect unusual activity
5. **Keep dependencies updated** for security patches
6. **Use strong passwords** for Railway database
7. **Limit database access** to only necessary IPs if possible

---

## Next Steps

After successful deployment:

1. ✅ Customize user profile in `app/profiles/user_profile.py`
2. ✅ Add/remove YouTube channels in `app/config.py`
3. ✅ Adjust cron schedule in `render.yaml` if needed
4. ✅ Monitor logs for first few runs
5. ✅ Fine-tune content sources based on preferences
6. ✅ Set up monitoring/alerts for failures

Enjoy your automated AI news digests! 🚀
