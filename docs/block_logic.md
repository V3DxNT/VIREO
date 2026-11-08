# 🦅 Vireo: Deep System Architecture & Technical Blueprint

This document serves as the exhaustive technical specification and architectural master plan for the Vireo platform. It details the design philosophies, technology choices, exact data structures, mathematical algorithms, and infrastructure configurations required to maintain, scale, and contribute to the project.

---

## Table of Contents

1.  [System Overview & Problem Statement](#1-system-overview--problem-statement)
2.  [High-Level Architecture & Interaction Flow](#2-high-level-architecture--interaction-flow)
3.  [Frontend Architecture (Next.js 14 App Router)](#3-frontend-architecture-nextjs-14-app-router)
4.  [Backend Architecture (Express.js Core)](#4-backend-architecture-expressjs-core)
5.  [The Bunk Calculator (Mathematical Proofs)](#5-the-bunk-calculator-mathematical-proofs)
6.  [Data Extraction Engine (Go Concurrency)](#6-data-extraction-engine-go-concurrency)
7.  [Database Design & Mongoose Schemas](#7-database-design--mongoose-schemas)
8.  [Security, Auth & Webhooks](#8-security-auth--webhooks)
9.  [DevOps, Docker, & Kubernetes (K8s)](#9-devops-docker--kubernetes-k8s)
10. [Continuous Integration & Delivery (CI/CD)](#10-continuous-integration--delivery-cicd)

---

## 1. System Overview & Problem Statement

### 1.1 The Problem: Legacy Portal Limitations
The NMIT Contineo portal is built on legacy infrastructure. It presents several friction points for students:
*   **Session Instability:** The portal aggressively logs users out, requiring constant re-entry of the USN, Date of Birth (DOB), and CAPTCHA.
*   **Data Fragmentation:** Viewing attendance, internal lab marks, and theory marks requires navigating through multiple slow-loading HTML tables.
*   **Reactive Model:** Students only discover a drop in attendance or a new CIE mark if they actively log in. There are no push notifications.
*   **Rate Limits:** Standard web scrapers using Puppeteer or Selenium are easily flagged and IP-banned due to headless browser overhead and static request patterns.

### 1.2 The Vireo Solution
Vireo abstracts the legacy portal into a **Proactive Microservices Platform**. 
*   **Proactive Notification:** It polls the college servers silently in the background and pushes state changes (deltas) via Telegram.
*   **Decoupled Compute:** It separates heavy network extraction (Go) from data presentation and business logic (TypeScript/Node).
*   **Zero Compute Waste:** It executes the extraction loops on ephemeral GitHub Actions runners, preserving the Oracle/Azure API servers' memory purely for database reads and UI rendering.

---

## 2. High-Level Architecture & Interaction Flow

Vireo operates strictly on a **Producer-Consumer** model via Webhooks.

### 2.1 Component Interaction Graph
```mermaid
graph TD
    %% Environments
    subgraph GitHub Actions [Ephemeral Runners - UTC Scheduled]
        GO[Go Extraction Engine]
    end

    subgraph Cloud Server [Oracle/Azure VM]
        API[Express.js API]
        CRON[Node-Cron Scheduler]
    end
    
    subgraph Vercel [Edge Network]
        WEB[Next.js App Router]
    end

    subgraph Database [MongoDB Atlas M0]
        DB[(Vireo Clusters)]
    end

    subgraph External [Third-Party APIs]
        TG[Telegram Bot API]
        NMIT[Contineo Portal]
    end

    %% Flow
    WEB <-->|REST / JWT Cookies| API
    GO -->|1. GET /targets| API
    GO <-->|2. Raw HTTP Scrape| NMIT
    GO -->|3. POST /ingest (Webhook)| API
    API <-->|Mongoose Queries| DB
    API -->|Delta Alerts| TG
    CRON -->|6 PM Summaries| TG
```

### 2.2 The 11:15 AM Webhook Cycle (Step-by-Step)
1.  **Initialization:** At 11:15 AM IST, GitHub Actions boots an Ubuntu container and executes `go run main.go`.
2.  **Target Provisioning:** Go sends a `GET` request with an `x-scraper-secret` header to the Express API. Express queries MongoDB, decrypts the stored DOBs, and returns an array of `[{ usn, dob }]`.
3.  **Concurrent Extraction:** Go initializes a worker pool of 3 Goroutines. Each worker:
    *   Spoofs a random `User-Agent`.
    *   POSTs to the Contineo login endpoint to capture the `JSESSIONID`.
    *   GETs the target's dashboard JSON.
    *   Cleans the JSON and locks a Mutex to append it to a master slice.
4.  **Handoff:** Go sends a single `POST` request containing the master JSON slice to Express. The Go process terminates, and GitHub destroys the runner.
5.  **Delta Processing:** Express compares the new slice against the previous MongoDB state. If differences exist, Telegram API calls are dispatched. Database records are overwritten with the new state.

---

## 3. Frontend Architecture (Next.js 14 App Router)

The frontend is an edge-cached Next.js 14 application focusing purely on data visualization. 

### 3.1 Tech Stack & Directory Structure
*   **Framework:** Next.js 14 (App Router)
*   **Styling:** Tailwind CSS + `shadcn/ui`
*   **State / Fetching:** SWR (Stale-While-Revalidate)
*   **Charts:** Recharts

```text
apps/web/
├── app/
│   ├── (auth)/
│   │   └── page.tsx            # Single-password Gatekeeper UI
│   ├── (dashboard)/
│   │   ├── layout.tsx          # Sidebar and Top Nav
│   │   ├── attendance/page.tsx # Progress bars and subject lists
│   │   ├── cie/page.tsx        # Leaderboards and tables
│   │   └── bunk/page.tsx       # Bunk prediction playground
│   ├── api/                    # Next.js API Routes (BFF pattern if needed)
│   └── globals.css             # Tailwind directives
├── components/
│   ├── ui/                     # shadcn primitives (button, card, dialog)
│   └── shared/                 # DeltaToast, SubjectRow, BunkChart
├── lib/
│   └── utils.ts                # Tailwind merge (cn) utilities
└── middleware.ts               # JWT route protection logic
```

### 3.2 Visual Components Deep-Dive
*   **`SubjectRow.tsx`:** Displays `SubjectName`, `Attended/Conducted`. Uses conditional Tailwind classes based on attendance logic: 
    *   `< 75%`: `text-red-500 bg-red-100`
    *   `75% - 85%`: `text-yellow-500 bg-yellow-100`
    *   `> 85%`: `text-green-500 bg-green-100`
*   **`BunkChart.tsx`:** A Recharts `<LineChart>`. It plots a dynamic projection line calculating percentage drops if the user were to miss the next 10 consecutive classes. 
*   **`CieLeaderboard.tsx`:** Sorts the cohort's CIE data dynamically. Uses shadcn's `<Table>` primitive for clean row rendering.

---

## 4. Backend Architecture (Express.js Core)

The API is the monolith core. It houses 100% of the business logic, mathematical engines, and database connections.

### 4.1 Directory Structure
```text
apps/api/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.ts     # JWT issuance
│   │   ├── webhook.controller.ts  # Ingestion logic
│   │   └── student.controller.ts  # Data fetching for UI
│   ├── engines/
│   │   ├── delta.engine.ts        # Compares Old vs New state
│   │   └── bunk.engine.ts         # Algebraic calculators
│   ├── models/
│   │   ├── Student.model.ts       # Mongoose schemas
│   │   └── Log.model.ts
│   ├── routes/
│   │   ├── public.routes.ts       # Validates JWT
│   │   └── internal.routes.ts     # Validates x-scraper-secret
│   ├── services/
│   │   └── telegram.service.ts    # telegraf wrapper
│   └── index.ts                   # Express app initialization
```

### 4.2 The Delta Engine Algorithm
The Delta Engine ensures we only send Telegram notifications when a true change occurs, ignoring duplicate webhooks.

```typescript
// Pseudo-code representation of the Delta Engine logic
async function processDeltas(newPayload: StudentPayload[]) {
  for (const student of newPayload) {
    const previousState = await LogModel.findOne({ usn: student.usn }).sort({ createdAt: -1 });
    
    if (!previousState) continue; // First scrape, no delta possible

    student.attendance.forEach(newSub => {
      const oldSub = previousState.attendance.find(s => s.subjectCode === newSub.subjectCode);
      
      if (oldSub) {
        if (newSub.conducted > oldSub.conducted) {
          // Class happened! Did they attend?
          const attendedDiff = newSub.attended - oldSub.attended;
          if (attendedDiff === 0) {
            TelegramService.sendAlert(student.chatId, `🚨 Absent in ${newSub.subjectCode}`);
          } else {
            TelegramService.sendAlert(student.chatId, `✅ Present in ${newSub.subjectCode}`);
          }
        }
      }
    });
  }
}
```

---

## 5. The Bunk Calculator (Mathematical Proofs)

The Bunk Engine uses algebraic forecasting isolated within `src/engines/bunk.engine.ts`. 

Let variables be:
*   $C$ = Total Classes Conducted
*   $A$ = Total Classes Attended
*   $T$ = Target Percentage (usually 0.85 for 85%)

### 5.1 Scenario 1: Safe Bunks (Current > 85%)
How many future classes can a student miss consecutively without dropping below the target $T$?
If a student misses $x$ classes, $A$ remains constant, but $C$ increases to $C + x$.
$$ \frac{A}{C + x} \geq T $$
Solving for $x$:
$$ A \geq T(C + x) $$
$$ A \geq TC + Tx $$
$$ x \leq \frac{A - TC}{T} $$
**Implementation Logic:** `Math.floor((A - (T * C)) / T)`

### 5.2 Scenario 2: Recovery Classes (Current < 85%)
How many future consecutive classes must a student attend to reach target $T$?
If a student attends $y$ classes, both $A$ and $C$ increase by $y$.
$$ \frac{A + y}{C + y} \geq T $$
Solving for $y$:
$$ A + y \geq T(C + y) $$
$$ A + y \geq TC + Ty $$
$$ y - Ty \geq TC - A $$
$$ y(1 - T) \geq TC - A $$
$$ y \geq \frac{TC - A}{1 - T} $$
**Implementation Logic:** `Math.ceil(((T * C) - A) / (1 - T))`

---

## 6. Data Extraction Engine (Go Concurrency)

The Go microservice uses native `net/http` to achieve headless extraction.

### 6.1 Bounded Worker Pool Pattern
To prevent IP bans from the college, we restrict concurrency using Channels and a `sync.WaitGroup`.

```go
package main

import (
    "sync"
    "time"
)

// The global mutex to protect the master array
var mu sync.Mutex
var masterPayload []CleanStudentData

func worker(targets <-chan Target, wg *sync.WaitGroup) {
    defer wg.Done()
    for t := range targets {
        // 1. Spoof Client (CookieJar + User-Agent)
        client := getSpoofedClient()
        
        // 2. Execute Login & Extract
        rawData := extractData(client, t.USN, t.DOB)
        
        // 3. Clean Data
        cleanData := sanitize(rawData)
        
        // 4. Safe Append
        mu.Lock()
        masterPayload = append(masterPayload, cleanData)
        mu.Unlock()
        
        // 5. Anti-Ban Delay
        time.Sleep(2 * time.Second)
    }
}
```

### 6.2 Data Struct Mapping
Go filters out unneeded portal metadata before it hits the network bridge.
```go
// Messy input from portal
type ContineoResponse struct {
    ViewData    string `json:"__VIEWSTATE"`
    HiddenToken string `json:"csrf_token"`
    StudentName string `json:"st_name"`
    Attendance  []struct {
        SubjectName string `json:"sub_name"`
        SubCode     string `json:"sub_code"`
        TotalHours  int    `json:"tot_hrs"`
        PresentHrs  int    `json:"pres_hrs"`
    } `json:"att_data"`
}

// Clean output to Express API
type CleanStudentData struct {
    USN        string       `json:"usn"`
    Attendance []CleanSub   `json:"attendance"`
}
type CleanSub struct {
    SubjectCode string `json:"subjectCode"`
    Conducted   int    `json:"conducted"`
    Attended    int    `json:"attended"`
}
```

---

## 7. Database Design & Mongoose Schemas

### 7.1 The Student Collection
Stores immutable user data and encrypted DOBs.
```typescript
const StudentSchema = new Schema({
  usn: { type: String, required: true, unique: true, index: true },
  name: { type: String, required: true },
  encryptedDob: { type: String, required: true }, // AES-256 encrypted
  chatId: { type: String, default: null },        // Telegram link
  semester: { type: Number, required: true },
  section: { type: String, required: true }
}, { timestamps: true });
```

### 7.2 The Time-Series Log Collection
This collection grows every time Go fires a webhook. It is strictly time-series for graphing.
```typescript
const LogSchema = new Schema({
  usn: { type: String, required: true, index: true },
  timestamp: { type: Date, default: Date.now, index: true },
  attendance: [{
    subjectCode: String,
    conducted: Number,
    attended: Number
  }],
  cie: [{
    subjectCode: String,
    labScore: Number,
    theoryScore: Number,
    maxScore: Number
  }]
});
// Compound index for rapid historical queries
LogSchema.index({ usn: 1, timestamp: -1 }); 
```

---

## 8. Security, Auth & Webhooks

### 8.1 The Next.js Gatekeeper (Frontend)
*   User enters password: `nmit_vireo_2026`
*   Express API returns an `HttpOnly` JWT cookie.
*   The payload of the JWT contains: `{ role: "peer", iat: 171500000, exp: 171700000 }`.
*   Next.js Middleware validates this cookie. JavaScript cannot read it, preventing XSS attacks.

### 8.2 The Go-to-Express Webhook Bridge
Because the `/api/internal/ingest` route writes directly to the database, it must be impenetrable from the public internet.
*   We use a static pre-shared key (PSK) defined in `.env` as `API_WEBHOOK_SECRET`.
*   Go attaches this to the header: `x-scraper-secret: <PSK>`.
*   Express Middleware immediately rejects any request lacking this exact header with `401 Unauthorized`.

---

## 9. DevOps, Docker, & Kubernetes (K8s)

### 9.1 Multi-Stage API Dockerfile
Optimized for the smallest possible image size on free-tier cloud providers.
```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build --workspace=apps/api

# Stage 2: Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/apps/api/package*.json ./
RUN npm ci --only=production
EXPOSE 5000
CMD ["node", "dist/index.js"]
```

### 9.2 Kubernetes Ingress Routing
How traffic is split in a production K8s cluster:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vireo-ingress
spec:
  rules:
  - host: vireo.yourdomain.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: express-service
            port:
              number: 5000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nextjs-service
            port:
              number: 3000
```

---

## 10. Continuous Integration & Delivery (CI/CD)

The monorepo utilizes path-filtered GitHub actions to prevent unnecessary builds.

### 10.1 The Node.js CI Pipeline (`.github/workflows/ci-node.yml`)
Triggers only on changes to `apps/api/`, `apps/web/`, or `packages/`.
*   **Checkout & Setup:** Node v20.
*   **Install:** `npm ci`.
*   **Lint:** `npm run lint` (Checks Prettier/ESLint rules).
*   **Test:** Executes Jest suite against the Bunk Engine mathematical formulas to ensure edge cases (divide by zero) do not crash the app.
*   **Build:** Runs `npm run build` on Next.js to catch strict TypeScript typing errors before merge.

### 10.2 The Go CI Pipeline (`.github/workflows/ci-go.yml`)
Triggers only on changes to `apps/scraper/`.
*   **Checkout & Setup:** Go 1.22.
*   **Format:** `go fmt ./...` (Fails if unformatted).
*   **Vet:** `go vet ./...` (Static analysis for concurrency bugs / data races).
*   **Test:** `go test -v ./...` (Mocks HTTP server to test struct mapping).