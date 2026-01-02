# AI News Aggregator

An intelligent, personalized news aggregation system that scrapes AI-related content from multiple sources, processes them using AI agents, and delivers curated daily digests via email. Built with Python, OpenAI GPT-4, PostgreSQL, and deployed as a scheduled cron job.

## Overview

This system automatically:
1. **Scrapes** content from YouTube (transcripts), OpenAI blog (RSS), and Anthropic blog (RSS + full markdown)
2. **Processes** raw content using AI to generate concise digests
3. **Curates** articles using GPT-4 based on user profile preferences
4. **Delivers** personalized email digests with top-ranked articles

The entire pipeline runs daily via a scheduled cron job and maintains a PostgreSQL database for content persistence and deduplication.

## Key Features

- **Multi-Source Scraping**: YouTube videos, OpenAI blog, Anthropic news
- **AI-Powered Processing**: GPT-4o-mini for digest generation, GPT-4.1 for curation
- **Personalized Ranking**: Content ranked based on user profile and interests
- **Duplicate Prevention**: Database tracking prevents reprocessing articles
- **Professional Email Delivery**: HTML emails with responsive design
- **Flexible Deployment**: Supports both local development and production environments
- **Scheduled Automation**: Daily execution with configurable time windows

## Architecture

### Core Components

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Scrapers   │────▶│   Database   │────▶│   Agents    │
│  (Sources)  │     │ (PostgreSQL) │     │ (AI Models) │
└─────────────┘     └──────────────┘     └─────────────┘
      │                                          │
      │                                          ▼
      │                                   ┌──────────────┐
      └──────────────────────────────────▶│  Email       │
                                          │  Service     │
                                          └──────────────┘
```

### Data Models

- **YouTubeVideo**: Video metadata and transcripts
- **OpenAIArticle**: OpenAI blog posts with RSS data
- **AnthropicArticle**: Anthropic content with full markdown
- **Digest**: AI-generated summaries with titles and summaries

### AI Agents

1. **Digest Agent** (`gpt-4o-mini`)
   - Generates concise 2-3 sentence summaries
   - Creates compelling titles (5-10 words)
   - Focuses on actionable insights

2. **Curator Agent** (`gpt-4.1`)
   - Ranks articles based on user profile
   - Assigns relevance scores (0-10)
   - Provides reasoning for rankings
   - Returns top N articles for email digest

## Project Structure

```
py-news-aggregator/
├── app/
│   ├── agent/                 # AI agents for processing
│   │   ├── curator_agent.py   # GPT-4 content curation
│   │   ├── digest_agent.py    # GPT-4o-mini summarization
│   │   └── email_agent.py     # Email content generation
│   ├── database/              # Database layer
│   │   ├── connection.py      # SQLAlchemy connection
│   │   ├── create_tables.py   # Schema initialization
│   │   ├── models.py          # Data models
│   │   └── repository.py      # Database operations
│   ├── profiles/              # User preferences
│   │   └── user_profile.py    # User interests configuration
│   ├── scrapers/              # Content scrapers
│   │   ├── anthropic.py       # Anthropic blog scraper
│   │   ├── openai.py          # OpenAI blog scraper
│   │   └── youtube.py         # YouTube transcript scraper
│   ├── services/              # Business logic
│   │   ├── email.py           # Email sending service
│   │   ├── process_antropic.py
│   │   ├── process_curator.py
│   │   ├── process_digest.py
│   │   ├── process_email.py
│   │   └── process_youtube.py
│   ├── config.py              # Configuration
│   ├── daily_runner.py        # Main pipeline orchestrator
│   └── runner.py              # Scraper orchestrator
├── DEPLOYMENT.md              # Production deployment guide
├── main.py                    # Entry point
├── pyproject.toml             # Dependencies
├── docker-compose.yml         # Local PostgreSQL setup
├── Dockerfile                 # Multi-stage production build
└── render.yaml               # Render.com deployment config
```

## Technology Stack

### Core Technologies
- **Python 3.12**: Modern Python with type hints
- **PostgreSQL 17**: Relational database for content storage
- **SQLAlchemy 2.0**: ORM and database toolkit
- **OpenAI API**: GPT-4.1 and GPT-4o-mini for AI processing

### Key Libraries
- **feedparser**: RSS feed parsing
- **youtube-transcript-api**: YouTube transcript extraction
- **docling**: Markdown content conversion
- **beautifulsoup4**: HTML parsing
- **pydantic**: Data validation and parsing
- **python-dotenv**: Environment management

### Infrastructure
- **Docker**: Containerization (multi-stage builds)
- **Render.com**: Cron job hosting
- **Railway**: PostgreSQL production database
- **uv**: Fast Python package installer

## Setup & Installation

### Prerequisites

- Python 3.12+
- Docker and Docker Compose
- OpenAI API key
- Gmail account with app password (for email delivery)
- (Optional) Webshare proxy credentials for YouTube scraping

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd py-news-aggregator
   ```

2. **Start local PostgreSQL**
   ```bash
   docker-compose up -d
   ```

3. **Configure environment**
   ```bash
   cp app/example.env app/.env.dev
   ```

   Edit `app/.env.dev`:
   ```env
   OPENAI_API_KEY=sk-...
   MY_EMAIL=your-email@gmail.com
   APP_PASSWORD=your-app-password
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=postgres
   POSTGRES_DB=py_news_aggregator
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5432
   PROXY_USERNAME=optional
   PROXY_PASSWORD=optional
   ```

4. **Install dependencies**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   uv sync
   ```

5. **Run the pipeline**
   ```bash
   # Default: 24 hours lookback, top 10 articles
   uv run python -m main

   # Custom: 24 hours lookback, top 5 articles
   uv run python -m main 24 5
   ```

### Docker Development

```bash
# Build development image
docker build --target dev -t py-news-aggregator:dev .

# Run with development environment
docker run --env-file app/.env.dev py-news-aggregator:dev
```

### Docker Production

```bash
# Build production image
docker build --target prod -t py-news-aggregator:prod .

# Run with production environment
docker run -e ENVIRONMENT=prod --env-file app/.env py-news-aggregator:prod
```

## Configuration

### User Profile

Customize content ranking in [`app/profiles/user_profile.py`](app/profiles/user_profile.py):

```python
USER_PROFILE = {
    "name": "Your Name",
    "title": "Your Title",
    "interests": [
        "Large Language Models",
        "RAG systems",
        # Add your interests...
    ],
    "preferences": {
        "prefer_practical": True,
        "prefer_technical_depth": True,
        # Customize preferences...
    },
    "expertise_level": "Advanced",  # Beginner, Intermediate, Advanced
}
```

### YouTube Channels

Edit channels in [`app/config.py`](app/config.py):

```python
YOUTUBE_CHANNELS = [
    "UCawZsQWqfGSbCI5yjkdVkTA",  # Matthew Berman
    # Add more channel IDs...
]
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ENVIRONMENT` | No | `dev` (default) or `prod` |
| `POSTGRES_USER` | Yes | Database username |
| `POSTGRES_PASSWORD` | Yes | Database password |
| `POSTGRES_DB` | Yes | Database name |
| `POSTGRES_HOST` | Yes | Database host |
| `POSTGRES_PORT` | Yes | Database port |
| `OPENAI_API_KEY` | Yes | OpenAI API key |
| `MY_EMAIL` | Yes | Gmail address for sending |
| `APP_PASSWORD` | Yes | Gmail app password |
| `PROXY_USERNAME` | No | Webshare proxy username |
| `PROXY_PASSWORD` | No | Webshare proxy password |

## Deployment

### Production Architecture
- **Application Hosting**: Render.com (scheduled cron job)
- **Database**: Railway (PostgreSQL)
- **Environment**: Separate `.env` and `.env.dev` files

### Deploy to Production

Comprehensive deployment guide available in [DEPLOYMENT.md](DEPLOYMENT.md).

**Quick Start:**
1. Create Railway PostgreSQL database
2. Connect GitHub repo to Render
3. Deploy using `render.yaml` blueprint
4. Set environment variables in Render dashboard (including Railway credentials)
5. Configure `ENVIRONMENT=prod`

The cron job runs daily at 5 AM UTC by default (configurable in `render.yaml`).

## Pipeline Workflow

1. **Scraping** (Hours configurable, default 60h)
   - Fetch YouTube videos from configured channels
   - Parse OpenAI blog RSS feed
   - Parse Anthropic blog RSS feeds (news, research, engineering)
   - Store raw content in database (deduplicates by ID)

2. **Content Processing**
   - Extract full markdown from Anthropic articles
   - Fetch YouTube transcripts (with proxy support)
   - Skip already processed content

3. **AI Digest Generation**
   - Generate summaries for all new content
   - Create compelling titles
   - Store digests with article references

4. **Curation & Ranking**
   - Load user profile preferences
   - Rank digests using GPT-4 based on relevance
   - Select top N articles (default 10)

5. **Email Delivery**
   - Generate HTML email with ranked articles
   - Send via Gmail SMTP
   - Include article titles, summaries, and direct links

## Usage Examples

### Run with default settings (60 hours, top 10)
```bash
uv run python -m main
```

### Run with custom parameters
```bash
# 24 hours lookback, top 5 articles
uv run python -m main 24 5
```

### Check logs
```bash
# Local
uv run python -m main 2>&1 | tee pipeline.log

# Docker
docker logs <container-id>
```

## Development

### Database Management

```bash
# Access local PostgreSQL
docker exec -it py-news-aggregator-db psql -U postgres -d py_news_aggregator

# View tables
\dt

# Query articles
SELECT title, published_at FROM youtube_videos ORDER BY published_at DESC LIMIT 5;
```

### Testing Individual Components

```python
# Test scrapers
from app.scrapers.youtube import YouTubeScraper
scraper = YouTubeScraper()
videos = scraper.get_recent_videos("CHANNEL_ID", hours=24)

# Test digest agent
from app.agent.digest_agent import DigestAgent
agent = DigestAgent()
digest = agent.generate_digest(title, content, "youtube")

# Test curator agent
from app.agent.curator_agent import CuratorAgent
from app.profiles.user_profile import USER_PROFILE
agent = CuratorAgent(USER_PROFILE)
ranked = agent.rank_digests(digests, top_n=5)
```

## Troubleshooting

### Database Connection Issues
- Verify PostgreSQL is running: `docker ps`
- Check connection settings in `.env.dev` or `.env`
- Ensure `ENVIRONMENT` variable is set correctly for production

### YouTube Transcript Errors
- Some videos don't have transcripts enabled
- Use proxy credentials if rate-limited
- Check YouTube channel IDs are correct

### Email Delivery Failures
- Use Gmail app password, not regular password
- Enable "Less secure app access" if needed
- Verify `MY_EMAIL` and `APP_PASSWORD` are set

### OpenAI API Errors
- Check API key is valid
- Verify account has sufficient credits
- Monitor rate limits

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👏 Acknowledgments

This project was inspired by best practices from the following resources:

- [**Dave Ebbelaar**: Build a Complete End-to-End GenAI Project in 3 Hours](https://www.youtube.com/watch?v=E8zpgNPx8jE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions:
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment guide
- Open an issue on GitHub
