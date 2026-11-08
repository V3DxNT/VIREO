# 🎯 Vireo: Project Targets & Roadmap

This document serves as the master checklist and phase tracker for the Vireo project. By breaking the system down into distinct phases and explicitly listing our desired features, we ensure that every milestone delivers a functional, testable outcome without losing sight of the end goal.

---

## 🌟 Core Features Roadmap

Before diving into the technical phases, here is the complete feature set Vireo aims to deliver to the student cohort:

### 1. Automated Proactive Tracking
*   **Headless Extraction:** Silently fetch data from the NMIT Contineo portal multiple times a day without user intervention.
*   **Delta Detection:** Intelligently compare new data against historical data to find exact changes (e.g., "1 class added to Math, marked Present").
*   **Zero-Friction Maintenance:** Automatically rotate sessions and handle rate limits to avoid IP bans.

### 2. Telegram Notification System
*   **Instant Class Alerts:** Push notifications sent immediately when a teacher updates attendance for a specific subject.
*   **Instant CIE Alerts:** Push notifications sent when a new lab or theory score is uploaded to the portal.
*   **Daily Wrap-Up (6:00 PM):** A comprehensive markdown-formatted summary of the day's total attendance and standing sent every evening.

### 3. Predictive Bunk Calculator
*   **Safe Bunk Limits:** Exact mathematical calculation of how many consecutive upcoming classes a student can skip while remaining $\geq 85\%$.
*   **Recovery Path Tracking:** If attendance is $< 85\%$, exact calculation of how many back-to-back classes must be attended to recover.
*   **Visual Bunk Playground:** Interactive web graph allowing students to simulate dropping/attending future classes.

### 4. Advanced Web Dashboard
*   **Single-Password Gatekeeper:** One shared password for the entire cohort; no complex sign-ups, no individual passwords.
*   **Attendance Overview:** Color-coded progress bars (Red/Yellow/Green) highlighting critical subjects.
*   **CIE Leaderboards:** Sortable tables showing top scorers in lab and theory across the section.
*   **Mobile-First Design:** Fully responsive UI built with Tailwind CSS, optimized for viewing on phones during class.

---

## Phase 1: Foundation, Scaffolding & Tooling

**Outcome:** A fully configured local development environment with proper monorepo workspace linking, shared tooling, and database connectivity.

*   \[x\] Initialize Git repository.
*   \[x\] Configure root `package.json` for npm workspaces (`apps/*`, `packages/*`).
*   \[x\] Scaffold `apps/api` (Express/TypeScript).
*   \[x\] Scaffold `apps/web` (Next.js 14 App Router).
*   \[x\] Scaffold `apps/scraper` (Go 1.22 Module).
*   \[x\] Create `packages/config/tsconfig.base.json` for shared strict typing.
*   \[x\] Create `packages/config/eslint-preset.js` and `.prettierrc` for unified code formatting.
*   \[x\] Define shared TypeScript interfaces in `packages/types/index.ts` (e.g., `Student`, `AttendanceLog`, `Subject`).
*   \[x\] Draft the universal `Makefile` to orchestrate local commands (`make dev`, `make db-up`, `make build`).
*   \[x\] Set up local MongoDB using `docker-compose.yml` in the `infra/docker` directory.
*   \[x\] Set up environment variable validation (using `zod` or `joi`) to prevent boot failures if `.env` is missing keys.
*   \[x\] Draft core documentation (`README.md`, `CONTRIBUTING.md`, `architecture.md`).

## Phase 2: The Go Extraction Engine (Network & Scraping)

**Outcome:** A standalone Go binary that can securely request targets, bypass the portal UI headlessly, clean the data, and dispatch a webhook payload.

*   \[ \] Define Go structs for `Target` (Input), `ContineoResponse` (Raw API), and `CleanStudentData` (Output).
*   \[ \] **HTTP Client Setup:** Configure `net/http/cookiejar` to automatically manage `JSESSIONID`.
*   \[ \] **Spoofing:** Implement a random `User-Agent` string selector for the HTTP client.
*   \[ \] **Auth Bypass:** Write the `GET` request to the Contineo login page to parse hidden variables (e.g., `__VIEWSTATE`, `__csrf_token`).
*   \[ \] **Login Sequence:** Write the `POST` request to authenticate using the USN, DOB, and parsed hidden variables.
*   \[ \] **Data Fetching:** Write the `GET` request to extract the dashboard JSON payload from the authenticated session.
*   \[ \] **Data Sanitization:** Map the messy `ContineoResponse` into the strict `CleanStudentData` format, dropping useless metadata.
*   \[ \] **Concurrency Engine:** Initialize a bounded Go channel to feed the worker pool.
*   \[ \] **Worker Pool:** Spawn 3 concurrent goroutines (`sync.WaitGroup`) to process the student targets.
*   \[ \] **Memory Safety:** Implement `sync.Mutex` to safely append each worker's `CleanStudentData` to the master slice.
*   \[ \] **Rate Limiting:** Inject a randomized `time.Sleep` (1.5s - 3s) inside the worker loop to mimic human delay.
*   \[ \] **Webhook Dispatcher:** Serialize the master slice to JSON and send a `POST` request to the Express API.
*   \[ \] **Bridge Security:** Inject the `x-scraper-secret` header into the outgoing webhook request.

## Phase 3: The Express Core & MongoDB Persistence

**Outcome:** A secure backend that can authenticate peers, provision scraping targets, and ingest/store massive JSON payloads safely.

*   \[ \] **Database Connection:** Implement robust Mongoose connection logic with retry mechanisms.
*   \[ \] **Mongoose Schemas:** Define `StudentSchema` (static user info, AES-encrypted DOB).
*   \[ \] **Mongoose Schemas:** Define `LogSchema` (time-series attendance and CIE marks arrays).
*   \[ \] **Gatekeeper Auth:** Create `POST /api/auth/login` to verify the shared password.
*   \[ \] **JWT Issuance:** Generate and attach an `HttpOnly`, `Secure`, `SameSite=Strict` cookie to the auth response.
*   \[ \] **Auth Middleware:** Write middleware to parse and validate the JWT for protected frontend routes.
*   \[ \] **Webhook Auth:** Write middleware checking `req.headers['x-scraper-secret']` against the `.env` file.
*   \[ \] **Target Route:** Create `GET /api/internal/targets` to fetch and decrypt user credentials for the Go scraper.
*   \[ \] **Ingestion Route:** Create `POST /api/internal/ingest` to accept the massive JSON array from Go.
*   \[ \] **Data Persistence:** Write the controller logic to append the new webhook data as a new document in the `Logs` collection.

## Phase 4: The Intelligence Layer (Delta & Bunk Engines)

**Outcome:** The system can mathematically predict safe bunks and proactively detect changes in attendance or marks.

*   \[ \] **Delta Engine - Query:** Fetch the most recent `Log` document for each student before saving the new webhook payload.
*   \[ \] **Delta Engine - Attendance:** Compare `conducted` and `attended` integers. Identify if classes were held and if the student was marked present/absent.
*   \[ \] **Delta Engine - CIE:** Compare `labScore` and `theoryScore` arrays. Identify newly uploaded marks.
*   \[ \] **Bunk Engine - Scenario 1:** Implement $x \leq (A - TC) / T$ to calculate Safe Bunks (Current > 85%).
*   \[ \] **Bunk Engine - Scenario 2:** Implement $y \geq (TC - A) / (1 - T)$ to calculate Recovery Classes (Current < 85%).
*   \[ \] **Unit Testing:** Write Jest test cases for the Bunk Engine to handle edge cases (e.g., 0 classes conducted, division by zero, exactly 85%).

## Phase 5: The Telegram Notification System

**Outcome:** Users receive instant, targeted push notifications on their phones without opening any app.

*   \[ \] Register the Telegram bot via BotFather, secure the token, and add it to `.env`.
*   \[ \] Initialize the `telegraf` package in the Express API instance.
*   \[ \] **Bot Commands:** Implement `/start` to link a user's Telegram Chat ID to their USN in MongoDB.
*   \[ \] **Bot Commands:** Implement `/status` to manually request current attendance on demand.
*   \[ \] **Instant Alerts Integration:** Connect the Telegram service to the Delta Engine. Fire DMs immediately if a state change is detected during ingestion.
*   \[ \] **Alert Formatting:** Design clean, emoji-rich markdown templates for the instant alerts (🚨 vs ✅).
*   \[ \] **Daily Cron Job:** Install and configure `node-cron` in Express.
*   \[ \] **Daily Summary:** Write logic triggering at 6:00 PM IST to query all users, calculate their total daily standing, and dispatch a comprehensive wrap-up DM.

## Phase 6: The Next.js Visual Dashboard

**Outcome:** A beautiful, edge-cached web interface for peers to log in and visualize their academic standing.

*   \[ \] Initialize Tailwind CSS and add `shadcn/ui` base styles (`button`, `card`, `table`, `input`).
*   \[ \] **Next.js Middleware:** Intercept requests to `/dashboard/*`. Redirect to `/auth` if the `HttpOnly` JWT cookie is missing or invalid.
*   \[ \] **Login UI:** Build the minimalist `/auth` page featuring a single password input field and loading state.
*   \[ \] **Layout Shell:** Build the persistent Sidebar and Top Navigation bar for desktop and mobile navigation.
*   \[ \] **API Integration:** Configure `SWR` hooks to fetch data from the Express `/api/students/:usn` routes.
*   \[ \] **Attendance View:** Build the Subject Cards. Use conditional Tailwind classes (Red <75%, Yellow 75-85%, Green >85%) for visual cues.
*   \[ \] **CIE View:** Build the interactive Leaderboard. Implement sorting logic (highest to lowest) for lab and theory scores using shadcn `<Table>`.
*   \[ \] **Bunk Playground:** Integrate `Recharts`. Build the `<LineChart>` projecting future attendance drops based on the Bunk Engine calculations.
*   \[ \] **Responsiveness Check:** Ensure all tables and charts scroll horizontally or stack gracefully on mobile viewports.

## Phase 7: Automation, DevOps & CI/CD

**Outcome:** The system runs permanently on free-tier cloud infrastructure with zero manual intervention, and strictly validates all PRs.

*   \[ \] **Node CI (`ci-node.yml`):** Create GitHub Action with path-filtering for `apps/api`, `apps/web`. Run `npm ci`, `npm run lint`, and Jest tests.
*   \[ \] **Go CI (`ci-go.yml`):** Create GitHub Action with path-filtering for `apps/scraper`. Run `go fmt`, `go vet`, and `go test`.
*   \[ \] **Scraper Cron (`scraper-cron.yml`):** Configure the ephemeral GitHub runner to execute `main.go` on a UTC schedule matching college hours (e.g., 11:15 AM, 1:15 PM, 4:15 PM IST).
*   \[ \] **Dockerization - API:** Write a multi-stage `api.Dockerfile` minimizing the final image size (Alpine Linux).
*   \[ \] **Infrastructure:** Provision the Oracle Always Free ARM instance or Azure VM.
*   \[ \] **Deployment - DB:** Configure MongoDB Atlas M0 cluster and whitelist the VM's IP address.
*   \[ \] **Deployment - API:** Deploy the Dockerized Express app to the VM. Set up reverse proxy (Nginx or Traefik) if required.
*   \[ \] **Deployment - Web:** Connect the Vercel dashboard to the GitHub repository and inject production `.env` variables.
*   \[ \] **Final Audit:** Conduct a full end-to-end integration test (Go -> Express -> MongoDB -> Telegram -> Next.js) in the live production environment.