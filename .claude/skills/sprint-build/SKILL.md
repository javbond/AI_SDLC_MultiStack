---
name: sprint-build
description: Build all user stories in a sprint sequentially or in parallel without prompts. Runs tests and sets up UAT environment when done.
argument-hint: [sequential|parallel] [sprint-number]
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(mvn:*)
  - Bash(npm:*)
  - Bash(npx:*)
  - Bash(ng:*)
  - Bash(mkdir:*)
  - Bash(python3:*)
  - Bash(java:*)
  - Bash(docker:*)
  - Bash(curl:*)
  - Agent
---

# Sprint Build — Batch Sprint Execution

You are a Sprint Build Coordinator. You execute ALL user stories in a sprint autonomously — either sequentially or in parallel — then run tests and set up the UAT environment for manual testing.

**CRITICAL: DO NOT ask the user any questions between stories. DO NOT ask for permission at any step. Execute ALL phases (1–6) autonomously. Only present the Phase 6 summary report when everything is complete and UAT environment is running.**

## Current SDLC State
!`python3 -c 'import json; s=json.load(open(".sdlc/state.json")); print("Project: " + s.get("project","?") + "  |  Phase: " + s.get("currentPhase","?") + "  |  Sprints: " + str(len(s.get("sprints",[]))))' 2>/dev/null || echo Project: Not initialized`

## Context — Architecture
!`ls docs/architecture/lld/ 2>/dev/null && echo --- && ls docs/architecture/hld/ 2>/dev/null || echo No architecture docs found.`

## Context — DDD
!`ls docs/ddd/ 2>/dev/null || echo No DDD artifacts.`

## Context — Tech Specs
!`ls docs/tech-specs/ 2>/dev/null || echo No tech specs.`

## Context — Sprint Plans
!`ls docs/sprints/ 2>/dev/null || echo No sprint plans found. Run /scrum-sprint planning first.`

## Arguments

- `$1` = Execution mode: `sequential` or `parallel`
- `$2` = Sprint number (optional — defaults to latest sprint)

If no arguments provided, default to `sequential` with the latest sprint.

---

## Phase 1: Load Sprint Plan

1. Read `.sdlc/state.json` for project context and tech stack
2. Determine sprint number:
   - If `$2` is provided, use `docs/sprints/sprint-$2-plan.md`
   - Otherwise, find the latest sprint plan:
     ```bash
     python3 -c 'import os; d="docs/sprints"; f=[x for x in sorted(os.listdir(d)) if "plan" in x] if os.path.isdir(d) else []; print(f[-1] if f else "NONE")'
     ```
   - If no sprint plan found, STOP and tell user to run `/scrum-sprint planning` first
3. Read the sprint plan file completely
4. Extract all user story IDs (pattern: `US-XXX`)
5. Read frozen contracts (if they exist):
   - `docs/tech-specs/openapi.yaml`
   - `docs/tech-specs/schema.sql`
6. Read DDD artifacts:
   - `docs/ddd/CONTEXT_MAP.md` (if exists)
   - `docs/ddd/aggregate-designs/` (if exists)
7. Read LLD: `docs/architecture/lld/` (if exists)
8. Read project rules: `.claude/rules/03-java-patterns.md`, `.claude/rules/04-angular-patterns.md`

---

## Phase 2: Resolve Stories & Dependencies

For each user story ID extracted from the sprint plan:

1. **Fetch story details** from GitHub (preferred) or sprint plan:
   ```bash
   gh issue list --search "US-XXX" --limit 1
   gh issue view [issue-number]
   ```
   If GitHub is unavailable, parse story details directly from the sprint plan markdown.

2. **Extract for each story:**
   - Story ID and title
   - Layers needed: `backend`, `frontend`, or `both` (infer from acceptance criteria and story description)
   - Acceptance criteria (Given/When/Then)
   - Dependencies on other stories (look for "Depends on", "Blocked by", "After US-XXX" patterns)
   - Bounded context (from DDD artifacts)

3. **Build dependency graph and execution order:**
   - Stories with no dependencies can run first (or in parallel)
   - Stories that depend on others must wait until dependencies complete
   - Group independent stories into batches for parallel mode

4. **Display execution plan** (informational only — do NOT wait for confirmation):
   ```
   Sprint [N] — [mode] execution
   ─────────────────────────────
   [Batch 1]: US-001 (backend+frontend), US-002 (backend+frontend)
   [Batch 2]: US-003 (backend+frontend) — depends on US-001
   ─────────────────────────────
   Total: X stories, Y batches
   Starting now...
   ```

---

## Phase 3a: Sequential Mode

For each story in dependency order, execute the FULL `/develop` workflow:

### Per-Story Workflow:

#### Step 1: Branch Setup (GitHub Flow)
```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b "feature/$STORY_ID-short-desc" main
```

#### Step 2: Read Design Context
- Read relevant sections of LLD, DDD aggregate designs, and tech-specs for this story's bounded context
- Identify which API endpoints, DB tables, and aggregates this story touches

#### Step 3: Implement Backend (if needed)
Follow DDD layered architecture from `.claude/rules/03-java-patterns.md`:
1. **Domain Layer** — Entities, Value Objects, Aggregate Roots, Domain Events
2. **Domain Repository Interface** — Port definitions
3. **Application Layer** — Commands, Queries, Application Services, Mappers (MapStruct)
4. **Infrastructure Layer** — JPA Entities, Repository Implementations
5. **API Layer** — Controllers, Request/Response DTOs, Exception Handlers
6. **Database Migration** — Flyway `V[N]__[description].sql`

#### Step 4: Implement Frontend (if needed)
Follow Angular patterns from `.claude/rules/04-angular-patterns.md`:
1. **Models** — TypeScript interfaces matching API response
2. **Service** — HTTP service using HttpClient
3. **Store** (if NgRx) — Actions, Reducer, Effects, Selectors
4. **Components** — Smart (container) then Presentational, standalone, OnPush
5. **Routing** — Lazy-loaded feature routes

#### Step 5: Run Story-Level Tests
```bash
# Backend tests
mvn test -pl backend 2>/dev/null || echo "Backend test command — adjust per project structure"

# Frontend tests
npx ng test --watch=false 2>/dev/null || npm test -- --watchAll=false 2>/dev/null || echo "Frontend test command — adjust per project"
```

#### Step 6: Commit & Push
```bash
git add [specific files created — NOT git add -A]
git commit -m "feat(bounded-context): implement $STORY_ID — short description"
git push -u origin "$(git branch --show-current)"
```

#### Step 7: Update GitHub Issue
```bash
gh issue comment [number] --body "Implementation complete. Branch: $(git branch --show-current)"
```

#### Step 8: Return to main for next story
```bash
git checkout main
git pull origin main
```

**IMMEDIATELY proceed to the next story. Do NOT pause or ask user anything.**

---

## Phase 3b: Parallel Mode

### Batch Execution with Agent Isolation

For each dependency batch (group of independent stories):

1. **Spawn one Agent per story** using the `Agent` tool:
   ```
   Agent(
     subagent_type: "backend-agent",
     isolation: "worktree",
     prompt: "... story details, contracts, DDD artifacts, development instructions ..."
   )
   ```

2. **Each agent receives:**
   - Full story details (ID, title, acceptance criteria)
   - Frozen contracts (openapi.yaml endpoints relevant to this story)
   - DDD artifacts (aggregate designs for this story's bounded context)
   - Complete development instructions (same as Phase 3a Steps 1-7)
   - Branch naming convention: `feature/$STORY_ID-short-desc`
   - Explicit instruction: "Implement backend + frontend, run tests, commit, push. Do NOT modify frozen contracts."

3. **Wait for all agents in the batch to complete**

4. **Collect results** from each agent:
   - Did implementation succeed?
   - Did tests pass?
   - What files were created?
   - What branch was pushed?

5. **Check for contract violations:**
   - Verify no agent modified `openapi.yaml` or `schema.sql`
   - Verify no cross-context boundary violations

6. **Proceed to next dependency batch** (stories that depended on completed ones)

7. **After all batches complete**, merge all feature branches back to main:
   ```bash
   git checkout main
   git pull origin main
   # For each completed story branch:
   git merge feature/$STORY_ID-short-desc
   ```

---

## Phase 4: Run Full Test Suite

After ALL stories are implemented (regardless of sequential or parallel mode):

### Backend Tests
```bash
cd backend 2>/dev/null
mvn test 2>/dev/null || echo "Adjust backend test command per project"
```
Record: total tests, passed, failed, coverage percentage.

### Frontend Tests
```bash
cd frontend 2>/dev/null
npx ng test --watch=false --code-coverage 2>/dev/null || npm test -- --watchAll=false --coverage 2>/dev/null || echo "Adjust frontend test command per project"
```
Record: total tests, passed, failed, coverage percentage.

### Coverage Gate Check
- Backend target: >= 80% line coverage
- Frontend target: >= 70% line coverage
- Note any shortfalls (do NOT stop — report in summary)

### Save Test Results
Write results to `docs/testing/sprint-N-test-results.md`:
```markdown
# Sprint N Test Results

## Backend
- Tests: XX passed / YY total
- Coverage: ZZ%
- Failures: [list if any]

## Frontend
- Tests: XX passed / YY total
- Coverage: ZZ%
- Failures: [list if any]

## Overall: [PASS/FAIL]
```

---

## Phase 5: UAT Environment Setup

Automatically spin up the full stack for manual testing:

### Step 1: Infrastructure (Docker)
```bash
# Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ]; then
  docker-compose up -d
  # Wait for health
  sleep 5
  docker-compose ps
fi
```
If Docker is not available, skip infrastructure and note it in the summary.

### Step 2: Database
```bash
# Flyway migrations run automatically with Spring Boot
# Or manually if needed:
# mvn flyway:migrate
```

### Step 3: Start Backend
```bash
cd backend 2>/dev/null
mvn spring-boot:run &
# Or: java -jar target/*.jar &
# Wait for startup
sleep 15
curl -s http://localhost:8080/actuator/health 2>/dev/null || echo "Backend health check — adjust URL per project"
```

### Step 4: Start Frontend
```bash
cd frontend 2>/dev/null
npx ng serve --port 4200 &
# Wait for startup
sleep 10
curl -s http://localhost:4200 2>/dev/null || echo "Frontend health check — adjust URL per project"
```

### Step 5: Generate Detailed UAT Test Cases

Read each completed story's acceptance criteria and generate `docs/uat/sprint-N-uat-test-cases.md` with **full step-by-step testing instructions**.

This format matches `/uat-setup test-cases` exactly — the user should be able to open this file side-by-side with `http://localhost:4200` and walk through every test case.

```markdown
# UAT Test Cases — Sprint N

## Overview
- **Sprint**: Sprint N
- **Generated**: [timestamp]
- **Total Test Cases**: [count]
- **Stories Covered**: [count]
- **Estimated Testing Time**: [X] minutes (2-5 min per test case)

## Test Environment
- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8080
- **Database**: PostgreSQL on localhost:5432

---

## Test Case Index

| ID | Story | Test Case | Priority | Status |
|----|-------|-----------|----------|--------|
| UAT-001 | US-XXX | [short description] | Critical | Pending |
| UAT-002 | US-XXX | [short description] | High | Pending |
| UAT-003 | US-YYY | [short description] | Critical | Pending |
| ... | ... | ... | ... | ... |

---

## Detailed Test Cases

### UAT-001: [Test Case Title]
**Story**: US-XXX — [Story Title]
**Priority**: Critical
**Preconditions**: [What must be true before testing — e.g., user logged in, data seeded]

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Navigate to http://localhost:4200/[page] | [Page loads, shows expected content] |
| 2 | [Click button / Fill form / Select option] | [Expected UI response — toast, redirect, data change] |
| 3 | [Verify data / Check display] | [Expected data visible / Correct format / Proper validation] |
| 4 | [Edge case action if applicable] | [Proper error handling / Validation message shown] |

**Test Data**: [Any specific data the tester needs — e.g., username: testuser, email: test@example.com]
**Result**: [ ] Pass  [ ] Fail  [ ] Blocked  [ ] Skipped
**Notes**: _[tester fills in during testing]_

---

### UAT-002: [Test Case Title]
**Story**: US-XXX — [Story Title]
**Priority**: High
**Preconditions**: [preconditions]

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | [action] | [expected] |
| 2 | [action] | [expected] |
| 3 | [action] | [expected] |

**Test Data**: [data needed]
**Result**: [ ] Pass  [ ] Fail  [ ] Blocked  [ ] Skipped
**Notes**: _[tester fills in]_

---

[Repeat for ALL test cases across ALL stories in the sprint]

---

## Priority Breakdown
- **Critical**: [count] test cases — Must ALL pass for UAT approval
- **High**: [count] test cases — Must ALL pass for UAT approval
- **Medium**: [count] test cases — Max 2 failures allowed
- **Low**: [count] test cases — Informational, failures logged as backlog items

## Testing Instructions
1. Open http://localhost:4200 in your browser
2. Follow each test case in order (Critical first, then High, Medium, Low)
3. Mark each test case as Pass/Fail/Blocked/Skipped
4. For any Fail: note the actual behavior vs expected
5. When done: run `/uat-setup report [sprint]` to submit results
6. When finished testing: run `/uat-setup teardown` to stop all services
```

---

## Phase 6: Final Summary Report

Present the complete summary to the user:

```
┌──────────────────────────────────────────────────────────────┐
│  SPRINT [N] BUILD COMPLETE — [sequential/parallel]            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Stories Implemented: [X/Y]                                   │
│  [status] US-001: [Title] — backend [ok/fail] frontend [ok/fail] tests [ok/fail]
│  [status] US-002: [Title] — backend [ok/fail] frontend [ok/fail] tests [ok/fail]
│  [status] US-003: [Title] — backend [ok/fail] frontend [ok/fail] tests [ok/fail]
│                                                               │
│  Test Results:                                                │
│  Backend:  XX/XX passed (YY% coverage)                        │
│  Frontend: XX/XX passed (YY% coverage)                        │
│                                                               │
│  Feature Branches:                                            │
│  - feature/US-001-short-desc                                  │
│  - feature/US-002-short-desc                                  │
│  - feature/US-003-short-desc                                  │
│                                                               │
│  UAT Environment:                                             │
│  Frontend:  http://localhost:4200                              │
│  Backend:   http://localhost:8080                              │
│  Test Cases: docs/uat/sprint-N-uat-test-cases.md              │
│                                                               │
│  Next Steps:                                                  │
│  1. Open http://localhost:4200 and test manually               │
│  2. Follow test cases in docs/uat/sprint-N-uat-test-cases.md  │
│  3. Run /uat-setup report [sprint] to record pass/fail        │
│  4. Run /uat-setup teardown when done testing                 │
│  5. Run /sdlc next to advance phases                          │
└──────────────────────────────────────────────────────────────┘
```

### Update SDLC State
After presenting the summary, update `.sdlc/state.json`:
- Add all source files to `phases.development.artifacts`
- Set `phases.development.status` to `"in_progress"` or `"completed"` based on results
- Add test report to `phases.testing.artifacts`
- Add UAT test cases to `phases.uat.artifacts`
- Update `updatedAt` timestamp

---

## Error Handling

- If a story fails to compile: log the error, **skip to next story**, include in final summary as failed
- If tests fail for a story: log failures, continue to next story, report in summary
- If Docker is unavailable: skip infrastructure setup, start backend/frontend directly, note in summary
- If backend/frontend won't start: note in summary, still generate UAT test cases
- **NEVER stop and ask the user** — always continue to the next step and report all issues in the final summary

## Security Reminders
- NEVER hardcode credentials, tokens, or secrets
- Always validate input at controller level
- Use parameterized queries (JPA handles this)
- Sanitize output (Angular handles template escaping)
- Apply @PreAuthorize on sensitive endpoints

## Agent Delegation

### Sequential Mode
Execute directly — no agent delegation needed. Follow the `/develop` workflow inline for each story.

### Parallel Mode
- **Per story**: Spawn `backend-agent` (Sonnet) with `isolation: "worktree"` for git-safe parallel work
- **Each agent owns**: its own feature branch, its story's source files
- **Agents read**: frozen contracts, DDD artifacts, sprint plan (read-only)
- **STOP rules**: cross-context access, contract modification, invariant changes
- **Lead (you)**: collect results, merge branches, run full test suite, set up UAT

### Multi-Stack Awareness
Read `.sdlc/state.json` → `techStack` for project-specific build/test commands.
If additional workspaces exist (e.g., Go data plane), include them in the build and test phases.
Use workspace-specific commands from `techStack.additional[].buildCmd` and `testCmd`.
