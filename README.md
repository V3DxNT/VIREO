<div align="center">

# 🦅 Vireo

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=20&pause=1000&color=10B981&center=true&vCenter=true&width=600&lines=Automated+Attendance+Tracking.;Predict+Your+Bunks.;Instant+Telegram+Alerts.;Zero+Compute+Waste.)](https://git.io/typing-svg)

A centralized, automated Contineo portal wrapper and analytics dashboard featuring real-time Telegram notifications, predictive bunk calculators, and a custom microservices architecture.

[![Go Version](https://img.shields.io/badge/Go-1.22%2B-00ADD8?style=flat-square&logo=go)](https://go.dev)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?style=flat-square&logo=next.js)](https://nextjs.org/)
[![Express.js](https://img.shields.io/badge/Express-4.x-333333?style=flat-square&logo=express)](https://expressjs.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=flat-square&logo=mongodb)](https://mongodb.com/)
[![Telegram](https://img.shields.io/badge/Telegram-Bot-2CA5E0?style=flat-square&logo=telegram)](https://core.telegram.org/bots)

</div>

---

## ✨ What is Vireo?

**Vireo** transforms the legacy NMIT Contineo portal into a proactive, high-performance developer platform. Instead of manually logging into the college portal multiple times a day to check for updated CIE marks or attendance percentages, Vireo entirely automates the extraction, analysis, and notification pipeline.

Whether you are trying to calculate if you can safely bunk the next lecture, waiting for your lab internals to drop, or simply wanting a daily summary of your academic standing, Vireo delivers it directly to your Telegram inbox and visualizes it on a beautiful, edge-cached web dashboard.

---

## ⚡ Why Vireo?

Legacy college portals are reactive. You only know your attendance dropped if you actively remember to log in and check. 

### The Problem: Reactive Tracking & High Friction

- **Manual Polling:** Repeatedly logging in with USN, DOB, and CAPTCHAs just to see if a teacher updated a single subject.
- **Blind Bunking:** Guessing how many classes you can miss before dropping below the 85% threshold, often resulting in miscalculations.
- **Fragmented Data:** Tracking CIE lab scores, theory marks, and assignment grades across different, clunky UI tabs.
- **Rate Limits:** Traditional scraping bots get IP-banned rapidly due to inefficient browser-automation overhead.

### The Solution: Proactive, Automated Intelligence

Vireo flips the model from reactive polling to proactive push notifications using a lightweight, anti-ban architecture:

| Challenge | Without Vireo | With Vireo |
| :--- | :--- | :--- |
| **Attendance Updates** | Manual daily logins to check percentages | Instant Telegram DM the moment a teacher logs attendance |
| **CIE Marks Tracking** | Refreshing the portal during exam season | Automated push notification when a new score is uploaded |
| **Bunk Planning** | Manual math on a calculator | Real-time predictive charts showing exact safe-to-bunk limits |
| **Data Access** | Slow, session-timeout prone UI | Instant access via a cached, beautiful Next.js Recharts dashboard |
| **Security** | Sharing portal passwords with friends | Single-password JWT gatekeeper for trusted peers |

---

## 🛠️ Core Features

Vireo delivers a complete suite of academic tracking tools. For deep-dive technical documentation on how these features are built under the hood, check out our `docs/` folder.

| Feature | Description | Technical Guide |
| :--- | :--- | :--- |
| **Delta Engine** | Instantly detects granular changes in class conduct and attendance states by comparing time-series data. | [Architecture →](docs/architecture.md) |
| **Bunk Calculator** | Advanced algebraic forecasting to predict safe bunks, visualize recovery paths, and calculate thresholds. | [Bunk Math →](docs/bunk-math.md) |
| **Go Extractor** | High-performance `net/http` scraper bypassing firewalls via User-Agent rotation and organic delays. | [API Guide →](docs/api-guide.md) |
| **Telegram Integration** | Triggers instant class-specific alerts and dispatches comprehensive daily academic summaries at 6:00 PM. | [Targets Config →](docs/targets-config.md) |
| **Single-Password Auth** | Frictionless JWT `HttpOnly` security model, keeping the dashboard exclusive to trusted peers without complex logins. | [Architecture →](docs/architecture.md) |
| **Recharts Dashboard** | A responsive Next.js interface providing visual representations of attendance trends and CIE leaderboards. | [API Guide →](docs/api-guide.md) |

---

## 🏗️ System Architecture & Data Flow

Vireo operates on a strict **Producer-Consumer microservices model** using an npm workspaces monorepo. It splits the heavy network extraction (Go) from the business logic and UI (Node.js/Next.js) to achieve zero compute waste on free-tier servers.

> **Read the Full Architectural Blueprint:** For a complete breakdown of the monorepo folder structure, the Go-to-Express webhook bridge, and the GitHub Actions cron execution cycle, please read [**`docs/architecture.md`**](docs/architecture.md).

---

## 🚀 Quick Start & Installation

Vireo is designed for a "zero-friction" developer experience. The entire polyglot monorepo can be booted locally using a single `Makefile` command.

### 1. Prerequisites
Ensure you have the following installed on your system:
- **Node.js** (v20+)
- **Go** (1.22+)
- **Docker** & **Docker Compose** (for the local MongoDB instance)
- **Make** (Pre-installed on macOS/Linux environments)

### 2. Environment Setup

Clone the repository and set up your secure environment variables:

```bash
git clone https://github.com/V3DxNT/vireo.git
cd vireo

# Copy the environment template
cp .env.example .env
```

Ensure your `.env` contains your Telegram Bot Token, Database URI, and the shared Webhook Secret required for the Go-to-Express bridge:
```env
# .env
API_WEBHOOK_SECRET=super_secure_random_string
GROUP_DASHBOARD_SECRET=nmit_peers_2026
TELEGRAM_BOT_TOKEN=your_bot_token_here
MONGO_URI=mongodb://localhost:27017/vireo
```

### 3. Bootstrap & Run

Use the `Makefile` at the root of the project to install all workspace dependencies, spin up the local database container, and launch the development servers concurrently.

```bash
# Start the MongoDB Docker container in the background
make db-up

# Install all workspace dependencies (Express, Next.js, Shared Types)
make install

# Boot the Express API and Next.js Frontend simultaneously
make dev
```

### 4. Trigger the Scraper (Local Testing)

Because the GitHub Actions cron job only runs in production, you must manually trigger the Go scraper to test the data ingestion bridge during local development:

```bash
make scrape
```

---

## ☁️ Deployment Strategy

Vireo is architected to run permanently on free-tier infrastructure.

- **Frontend (`apps/web`):** Deployed globally via **Vercel**.
- **Backend (`apps/api`):** Containerized via Docker and deployed to an **Oracle Always Free** ARM instance or **Azure VM**.
- **Database:** Hosted securely on **MongoDB Atlas** (M0 Free Cluster).
- **Scraper Engine (`apps/scraper`):** Executed serverlessly via **GitHub Actions** scheduled workflows, completely offloading the heavy extraction compute costs.

---

<div align="center">

Built with ❤️ by [**vedx.dev**](https://vedx.dev) · GitHub [**@V3DxNT**](https://github.com/V3DxNT)

</div>