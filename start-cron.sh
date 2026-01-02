#!/bin/bash
# Start script for running daily digest as cron job on Fly.io

set -e

echo "Starting AI News Aggregator cron service on Fly.io"
echo "Current time: $(date)"

# Create cron log directory
mkdir -p /tmp/cron-logs

# Create crontab entry
# Runs daily at 5:00 AM UTC
echo "0 5 * * * cd /app && /app/.venv/bin/python main.py >> /tmp/cron-logs/digest.log 2>&1" > /tmp/crontab

# Install crontab
crontab /tmp/crontab

echo "Cron schedule installed:"
crontab -l

# Start cron in foreground (this keeps the container running)
echo "Starting cron daemon..."
cron -f
