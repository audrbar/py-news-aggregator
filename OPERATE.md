# Operations Guide

Quick reference for managing and monitoring your py-news-aggregator app on Fly.io.

## Daily Operations

### Check App Status

```bash
fly status
```

Shows the current state of your app, including:

-   App name and hostname
-   Machine status (running/stopped)
-   Region and resource usage
-   Last deployment timestamp

### View Live Logs

```bash
fly logs
```

Streams live logs from your application in real-time (continuously). Useful for monitoring the cron job execution and debugging issues.

**Get logs without continuous streaming:**

```bash
fly logs -n                    # Get buffered logs only (no tail)
fly logs --no-tail             # Same as above
```

**Filter logs by machine:**

```bash
fly logs --machine <machine-id>   # Logs from specific machine
```

**Filter logs by region:**

```bash
fly logs --region fra             # Logs from Frankfurt region
```

### View Cron Job Configuration

```bash
fly ssh console -C "crontab -l"
```

Displays the currently configured cron schedule. Should show:

```
0 5 * * * cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1
```
   # Last 50 lines
fly ssh console -C "cat /tmp/cron-logs/digest.log"          # All logs
This means the job runs daily at 5:00 AM UTC.

### Check Cron Execution Logs

```bash
fly ssh console -C "tail -f /tmp/cron-logs/digest.log"
```

Shows the most recent cron job execution logs. Use `-f` flag to follow logs in real-time, or remove it to just view recent entries:

```bash
fly ssh console -C "tail -n 50 /tmp/cron-logs/digest.log"
```

---

## Testing & Debugging

### Manual Test Run

```bash
fly ssh console -C "/app/.venv/bin/python /app/main.py"
```

Manually triggers the digest pipeline immediately. Useful for:

-   Testing after code changes
-   Verifying email delivery
-   Debugging issues without waiting for cron schedule

**Run with custom parameters:**

```bash
# Get last 48 hours of content, top 15 articles
fly ssh console -C "/app/.venv/bin/python /app/main.py 48 15"
```

### Interactive SSH Session

```bash
fly ssh console
```

Opens an interactive shell inside your container. Once inside, you can:

```bash
# Check environment variables
env | grep POSTGRES

# View cron logs
cat /tmp/cron-logs/digest.log

# Check Python version
python --version

# List installed packages
pip list

# Test database connection
python -c "from app.database.connection import get_connection; print('DB OK')"
```

### Verify Environment Variables

```bash
fly secrets list
```

Lists all configured secrets (environment variables). Values are hidden for security, but you can see which secrets are set.

---

## Deployment & Updates

### Deploy Code Changes

```bash
fly deploy
```

Builds and deploys your latest code changes. The deployment process:

1. Builds new Docker image using Dockerfile.flyio
2. Pushes image to Fly.io registry
3. Creates new machine with updated code
4. Stops old machine after health checks pass

**Force rebuild (ignore cache):**

```bash
fly deploy --no-cache
```

### Update Environment Variables

```bash
fly secrets set OPENAI_API_KEY="new-key-here"
```

Updates a secret and automatically restarts the app to apply changes.

**Update multiple secrets at once:**

```bash
fly secrets set KEY1="value1" KEY2="value2" KEY3="value3"
```

**Remove a secret:**

```bash
fly secrets unset SECRET_NAME
```

### Restart Application

```bash
fly machine restart
```

Restarts your running machine. Useful after configuration changes or if the app becomes unresponsive.

**Restart specific machine:**

```bash
fly machine restart <machine-id>
```

---

## Machine Management

### Scale Resources

**Increase memory:**

```bash
fly scale memory 1024   # 1GB RAM
```

**Decrease memory (cost savings):**

```bash
fly scale memory 256    # 256MB RAM
```

**Add more machines (redundancy):**

```bash
fly scale count 2
```

### Stop/Start Machines

**Stop the app (saves costs):**

```bash
fly machine stop
```

**Start a stopped app:**

```bash
fly machine start
```

**List all machines:**

```bash
fly machine list
```

---

## Monitoring & Troubleshooting

### Open Dashboard

```bash
fly dashboard
```

Opens the Fly.io web dashboard in your browser for visual monitoring:

-   Resource usage graphs
-   Cost estimates
-   Machine health
-   Recent deployments

### Check App Health

```bash
fly checks list
```

Shows health check status if configured (not currently used for cron jobs).

### View Recent Deployments

```bash
fly releases
```

Lists deployment history with timestamps and status.

### Application Metrics

```bash
fly status
```

Shows machine status and basic metrics. For detailed monitoring, use the web dashboard:

```bash
fly dashboard
```

---

## Database Operations

### Connect to Railway Database

From your local machine with Railway credentials from `.env`:

```bash
psql -h shinkansen.proxy.rlwy.net -p 41319 -U postgres -d railway
```

### Check Database from App

```bash
fly ssh console -C "python -c 'from app.database.connection import get_connection; conn = get_connection(); cur = conn.cursor(); cur.execute(\"SELECT COUNT(*) FROM youtube_videos\"); print(f\"Videos: {cur.fetchone()[0]}\")'"
```

---

## Cron Schedule Management

### Change Cron Schedule

Edit [start-cron.sh](start-cron.sh) and modify the cron expression:

```bash
# Examples:
# Every 6 hours:
echo "0 */6 * * * cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1" > /tmp/crontab

# Twice daily (5AM, 5PM UTC):
echo "0 5,17 * * * cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1" > /tmp/crontab

# Monday-Friday only at 8AM UTC:
echo "0 8 * * 1-5 cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1" > /tmp/crontab
```

After editing, deploy the changes:

```bash
fly deploy
```

### Cron Expression Format

```
* * * * *
│ │ │ │ │
│ │ │ │ └── Day of week (0-7, Sun-Sat)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```

---

## Cost Management

### View Current Usage

```bash
fly status
```

Check the machine size and region in the output.

**View billing:**
Visit https://fly.io/dashboard/personal/billing

### Optimize Costs

**Use smallest viable machine:**

```bash
fly scale memory 256
```

**Stop when not needed:**

```bash
fly machine stop
# Start again when needed:
fly machine start
```

**Monitor spending:**

-   Set up billing alerts in Fly.io dashboard
-   Review usage monthly

---

## Useful Links

-   **App Dashboard**: https://fly.io/apps/py-news-aggregator
-   **Monitoring**: https://fly.io/apps/py-news-aggregator/monitoring
-   **Logs**: https://fly.io/apps/py-news-aggregator/logs
-   **Fly.io Docs**: https://fly.io/docs/
-   **Support**: https://community.fly.io/

---

## Emergency Procedures

### App Not Responding

```bash
# 1. Check status
fly status

# 2. View rno-tailgs
fly logs --since 1h

# 3. Restart the app
fly machine restart

# 4. If still issues, redeploy
fly deploy
```

### Email Not Sending

```bash
# 1. Check logs for email errors
fly logs | grep -i email

# 2. Verify email credentials
fly secrets list

# 3. Test manually
fly ssh console -C "/app/.venv/bin/python /app/main.py"

# 4. Update credentials if needed
fly secrets set MY_EMAIL="your@email.com" APP_PASSWORD="your-app-password"
```

### Database Connection Issues

```bash
# 1. Check database secrets
fly secrets list

# 2. Test connection from app
fly ssh console -C "python -c 'from app.database.connection import get_connection; get_connection()'"

# 3. Verify Railway database is running (check Railway dashboard)

# 4. Update database credentials if changed
fly secrets set POSTGRES_HOST="new-host" POSTGRES_PASSWORD="new-password"
```

### Cron Not Running

```bash
# 1. Check if cron process is running
fly ssh console -C "ps aux | grep cron"

# 2. Verify crontab is configured
fly ssh console -C "crontab -l"

# 3. Check cron logs
fly ssh console -C "cat /tmp/cron-logs/digest.log"

# 4. Restart machine
fly machine restart
```

---

## Tips & Best Practices

1. **Monitor regularly**: Check logs weekly to catch issues early
2. **Test before cron**: Always run manual test after code changes
3. **Keep secrets updated**: Rotate API keys periodically
4. **Backup data**: Export important data from Railway database regularly
5. **Document changes**: Update this file when you modify the workflow
6. **Version control**: Commit and push changes before deploying
7. **Check email**: Verify daily digest arrives as expected

---

## Quick Reference

| Task           | Command                                                   |
| -------------- | --------------------------------------------------------- |
| View status    | `fly status`                                              |
| Live logs      | `fly logs`                                                |
| Manual run     | `fly ssh console -C "/app/.venv/bin/python /app/main.py"` |
| View cron logs | `fly ssh console -C "tail -f /tmp/cron-logs/digest.log"`  |
| Deploy changes | `fly deploy`                                              |
| Update secret  | `fly secrets set KEY="value"`                             |
| Restart app    | `fly machine restart`                                     |
| Open dashboard | `fly dashboard`                                           |
| SSH into app   | `fly ssh console`                                         |
| Check crontab  | `fly ssh console -C "crontab -l"`                         |
