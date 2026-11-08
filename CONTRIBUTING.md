# Contributing to Vireo 🦅

First off, thank you for considering contributing to Vireo! This project is built by and for students, and your help in improving the dashboard, refining the math, or optimizing the backend is highly appreciated.

This document outlines the standard process for contributing to the repository. Please read it carefully to ensure a smooth collaboration.

---

## 1. Finding or Creating an Issue

Before writing any code, ensure there is an open issue for your proposed changes. This prevents duplicated effort and ensures the feature aligns with the project's goals.

*   **Browse Existing Issues:** Check the [Issues tab](https://github.com/V3DxNT/vireo/issues) for open tasks. If you find one you want to work on, leave a comment saying "I'd like to work on this!"
*   **Create a New Issue:** If you found a bug or want to request a feature, click **New Issue**. 
    *   Select either the **Bug Report** or **Feature Request** template.
    *   Fill out the template completely so maintainers have all the context they need.

---

## 2. Local Setup & Orchestration

Vireo uses a monorepo architecture bridging Go and Node.js. We use `make` to orchestrate everything so you don't have to memorize a dozen different startup commands.

### Prerequisites
Ensure you have the following installed:
*   **Node.js** (v20+)
*   **Go** (1.22+)
*   **Docker** & **Docker Compose**

### Installation Steps
1. **Fork and Clone:** Fork the repository to your own GitHub account, then clone it to your machine:
   ```bash
   git clone https://github.com/YOUR-USERNAME/vireo.git
   cd vireo
   ```

2. **Environment Variables:** Copy the template file and fill in your local secrets (ask a maintainer for test keys if needed).
   ```bash
   cp .env.example .env
   ```

3. **Start the Database:** Spin up the local MongoDB instance via Docker.
   ```bash
   make db-up
   ```

4. **Install Dependencies:** Install all npm workspace packages (Express, Next.js, and shared types).
   ```bash
   make install
   ```

5. **Boot the Environment:** Start both the Express backend and Next.js frontend concurrently.
   ```bash
   make dev
   ```

*Note: If you are working on the Go scraper, you can test it independently by running `make scrape` in a separate terminal while your API is running.*

---

## 3. Branching Strategy

Never commit directly to the `main` branch. Always create a new branch from `main` using the following naming conventions:

*   **Features:** `feat/your-feature-name` (e.g., `feat/bunk-graphs`)
*   **Bug Fixes:** `fix/your-fix-name` (e.g., `fix/telegram-auth`)
*   **Documentation:** `docs/update-readme`
*   **Refactoring:** `refactor/scraper-loop`

```bash
git checkout -b feat/add-cie-leaderboard
```

---

## 4. Making Changes & Committing

As you write your code, keep the following in mind:
*   **Types First:** If you are changing the shape of the data returned by the API, update `packages/types` first.
*   **Linting:** Run `npm run lint` or `make lint` before committing to ensure your code matches the project's Prettier and ESLint rules.
*   **Signed Commits** : Make sure that all the commits are signed so that it passes the CI checks

When you are ready to commit, write clear, descriptive commit messages:
```bash
git commit -s -m "feat: add CIE leaderboard component to dashboard"
```

---

## 5. Opening a Pull Request (PR)

Push your branch to your forked repository and open a Pull Request against the `main` branch of the original Vireo repository.

*   **Title:** Give your PR a clear, descriptive title.
*   **Description:** Explain what you changed and why. 
*   **Link the Issue:** In the PR description, include the keyword `Fixes #ISSUE_ID` or `Closes #ISSUE_ID` (e.g., `Fixes #12`). This tells GitHub to automatically close the issue when the PR is merged.

---

## 6. The CI Pipeline Checks

Once you open a PR, GitHub Actions will automatically run our Continuous Integration (CI) pipelines. Because this is a polyglot monorepo, we use path filtering:

*   **Node CI (`ci-node.yml`):** If you edited files in `apps/api`, `apps/web`, or `packages/`, this workflow will run. It executes `npm install`, `npm run lint`, and any Jest UI/API tests.
*   **Go CI (`ci-go.yml`):** If you edited files in `apps/scraper`, this workflow will run. It checks Go formatting (`go fmt`), runs the linter (`go vet`), and executes Go tests.

**Important:** Your PR cannot be merged if any CI checks fail. If a check fails, click on the "Details" link in the PR to view the logs, fix the issue locally, and push the update to your branch.

---

## 7. Review and Merge Process

1.  **Code Review:** A maintainer will review your code. They might leave comments asking for minor changes, optimizations, or clarifications.
2.  **Addressing Feedback:** Make the requested changes, commit them to your branch, and push. The PR will automatically update.
3.  **Approval:** Once the maintainer is satisfied and all CI checks are green, they will approve the PR.
4.  **Merge:** A maintainer will merge your branch into `main`! 

🎉 *Congratulations, and thank you for your contribution to Vireo!*