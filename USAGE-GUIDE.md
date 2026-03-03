# AI-Native SDLC Factory (Multi-Stack) — Usage Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start — From Scratch](#quick-start--from-scratch)
3. [Step-by-Step: Scaffold WITH Existing Documents](#step-by-step-scaffold-with-existing-documents)
4. [Step-by-Step: Scaffold WITHOUT Documents](#step-by-step-scaffold-without-documents)
5. [How Imported Documents Are Processed](#how-imported-documents-are-processed)
6. [Complete Phase-by-Phase Walkthrough](#complete-phase-by-phase-walkthrough)
7. [Multi-Stack Workspaces](#multi-stack-workspaces)
8. [Multi-Agent Architecture](#multi-agent-architecture)
9. [Agent Teams — Parallel Execution](#agent-teams--parallel-execution)
10. [Complete Skill Reference](#complete-skill-reference)
11. [Quality Gates](#quality-gates)
12. [Tips & Best Practices](#tips--best-practices)
13. [File Reference](#file-reference)

---

## Prerequisites

Before using the SDLC Factory, ensure you have:

| Tool | Required? | Install |
|------|-----------|---------|
| **Claude Code CLI** | Yes | `npm install -g @anthropic-ai/claude-code` |
| **Python 3.x** | Yes | Required for document analysis and state management |
| **Git 2.x+** | Yes | Configured with your credentials |
| **GitHub CLI** (`gh`) | Yes | `brew install gh` then `gh auth login` |
| **tmux** | Recommended | `brew install tmux` — for Agent Teams split-pane view |
| **Node.js 18+** | If Angular/React | For frontend stacks |
| **Java 17+ & Maven 3.9+** | If Spring Boot | For Java backend stack |
| **Go 1.21+** | If Go workspace | For Go workspace development |
| **PyPDF2** | Optional | `pip3 install PyPDF2` — for importing PDF documents |

---

## Quick Start — From Scratch

### The 5-Command Flow

```bash
# 1. Clone the kit
git clone <kit-repo-url> ai-sdlc-factory-multistack
cd ai-sdlc-factory-multistack

# 2. Scaffold a new project (interactive)
bash create-project.sh my-app ~/projects

# 3. Navigate to your project
cd ~/projects/my-app

# 4. Launch the SDLC Factory
bash scripts/start-sdlc.sh

# 5. Inside Claude Code — initialize
/sdlc init my-app
```

That's it. The scaffold is interactive — it will ask you questions, analyze any documents you provide, and set up everything.

The rest of this guide covers each step in detail with real examples.

---

## Step-by-Step: Scaffold WITH Existing Documents

This is the **recommended flow** when you have existing project documentation (product vision, PRD, architecture guide, implementation guide, tech specs, etc.).

### Scenario: Building a SASE Security Platform

You have an existing "SASE Master Implementation Guide" (a .docx file) that covers product vision, architecture, tech specs, and implementation details for a hybrid platform: Angular admin UI + Spring Boot control plane + Go data plane agent + Envoy edge proxy.

### Step 1: Run the Scaffold

```bash
bash create-project.sh sase-platform ~/projects
```

### Step 2: The Interactive Flow

```
┌──────────────────────────────────────────────────────────┐
│    AI-NATIVE SDLC FACTORY — Multi-Stack Scaffold         │
└──────────────────────────────────────────────────────────┘

  Project: sase-platform

Step 1/5: Do you have any existing project documents?
  (product vision, PRD, requirements, architecture guide, tech specs, etc.)
  These will be analyzed to auto-detect tech stack, phases, and project scope.

  Do you have existing documents? (y/n): y
  Enter file paths one per line (blank line when done):
  > ~/Documents/SASE-Master-Implementation-Guide.docx
  Added: SASE-Master-Implementation-Guide.docx
  > ~/Documents/product-requirements.pdf
  Added: product-requirements.pdf
  >

  Analyzing 2 document(s)...
    Extracting: SASE-Master-Implementation-Guide.docx
    Analyzed: SASE-Master-Implementation-Guide.docx
    Extracting: product-requirements.pdf
    Analyzed: product-requirements.pdf

  ┌─ Document Analysis Results ──────────────────────────────┐
  │  Tech detected:
  │    Frontend:  Angular 17+
  │    Backend:   Spring Boot 3.x
  │    Databases: PostgreSQL, Redis
  │    Messaging: Kafka
  │    Infra:     Envoy, ClickHouse, Keycloak, Kubernetes
  │
  │  Phase coverage:
  │    ✅ ideation (confidence: high)
  │    ⚠️  requirements (confidence: medium)
  │    ✅ architecture (confidence: high)
  │    ✅ techSpecs (confidence: high)
  │    ⏳ backlog (not covered)
  └──────────────────────────────────────────────────────────┘
```

**What happened**: The kit extracted text from your documents and analyzed them using keyword matching to detect:
- **Tech stack** (frameworks, languages, databases, messaging, infrastructure)
- **Phase coverage** (which SDLC phases the documents already address)
- **Workspaces** (distinct system components that need separate directories)

### Step 3: Confirm Detected Tech Stack

```
Step 2/5: Tech Stack Configuration
  Based on your documents, confirm or change:

  Frontend: Angular 17+ [correct? y/n]: y
  Frontend: Angular
  Backend: Spring Boot 3.x [correct? y/n]: y
  Backend: Spring Boot
  Databases: PostgreSQL,Redis [correct? y/n]: y
  Databases: PostgreSQL,Redis
  Messaging: Kafka [correct? y/n]: y
  Messaging: Kafka
```

The kit **detected** all tech from your documents and asks you to confirm. If something was wrong, type `n` and you'll get the manual selection menu.

### Step 4: Configure Additional Workspaces

```
Step 3/5: Additional Tech Stack Workspaces
  Workspaces detected from documents:
    1. Data Plane (Go) -> workspaces/go-data-plane/
    2. Edge Proxy (Envoy) -> workspaces/envoy-edge/
  Keep these? (y/n): y
  Add additional workspace? (y/n): n
```

If your documents mentioned distinct system components (like Go data plane agents, Envoy proxies, Rust workers), the kit detects them and suggests workspace directories. You can also add more manually.

### Step 5: Project Generation

```
Step 4/5: Creating project...

  Copying kit files...
  Kit files copied
  Created: workspaces/go-data-plane/
  Created: workspaces/envoy-edge/
  Processing imported documents...
    Extracted: SASE-Master-Implementation-Guide.docx
    Extracted: product-requirements.pdf
  Initializing state...
  Project: sase-platform

Step 5/5: Finalizing...
  06-tech-stack-context.md generated
  Git initialized (main)
  Agent teams enabled
  Initial commit created

┌──────────────────────────────────────────────────────────┐
│                   Project Ready!                          │
├──────────────────────────────────────────────────────────┤
│  Project:  sase-platform                                 │
│  Location: /Users/you/projects/sase-platform             │
│  Kit:      v2.0.0 (MultiStack)                           │
│  Stack:    Angular / Spring Boot / Go Data Plane /       │
│            Envoy Edge Proxy                              │
│  Imported: 2 document(s) (as reference)                  │
│  Start:    Phase: ideation                               │
│                                                          │
│  Note: Imported docs are used as REFERENCE.              │
│  /sdlc init will review them, ask questions to           │
│  ensure completeness, and generate standard docs.        │
│                                                          │
│  Next Steps:                                             │
│  1. cd /Users/you/projects/sase-platform                 │
│  2. Review: docs/ and .claude/rules/06-tech-stack-context│
│  3. bash scripts/start-sdlc.sh                           │
│  4. /sdlc init sase-platform                             │
└──────────────────────────────────────────────────────────┘
```

### What the Scaffold Created

```
sase-platform/
├── .claude/
│   ├── agents/                 # 11 multi-stack-aware agents
│   ├── skills/                 # 10 SDLC skills
│   ├── rules/
│   │   ├── 01-general.md
│   │   ├── 02-quality-gates.md
│   │   ├── 03-java-patterns.md     # Present (Spring Boot selected)
│   │   ├── 04-angular-patterns.md  # Present (Angular selected)
│   │   ├── 05-security.md
│   │   └── 06-tech-stack-context.md # AUTO-GENERATED — all stacks
│   ├── hooks/
│   └── settings.local.json
├── .sdlc/
│   └── state.json              # Extended with techStack + importedDocs
├── docs/
│   ├── tech-refs/              # Your imported documents live here
│   │   ├── SASE-Master-Implementation-Guide.docx (original)
│   │   ├── SASE-Master-Implementation-Guide-extracted.md (extracted text)
│   │   ├── product-requirements.pdf (original)
│   │   └── product-requirements-extracted.md (extracted text)
│   ├── tech-specs/
│   │   └── shared-schemas/     # Cross-workspace contracts (gRPC, OpenAPI)
│   ├── ideation/
│   ├── prd/
│   ├── architecture/
│   └── ...
├── workspaces/
│   ├── go-data-plane/          # Go workspace (empty, ready for code)
│   └── envoy-edge/             # Envoy workspace (empty, ready for config)
├── scripts/
├── CLAUDE.md
├── USAGE-GUIDE.md
└── kit.json
```

### Step 6: Review the Generated Tech Context

Before launching Claude Code, review the auto-generated tech context rule:

```bash
cat .claude/rules/06-tech-stack-context.md
```

This file is the **single source of truth** for all agents. It lists:
- Primary stacks (Angular, Spring Boot) with build/test commands
- Additional workspaces (Go Data Plane, Envoy Edge) with their commands
- Databases, messaging, infrastructure
- Reference doc locations
- Cross-workspace integration points

### Step 7: Launch and Initialize

```bash
cd ~/projects/sase-platform

# Launch SDLC Factory with Agent Teams (tmux split-pane)
bash scripts/start-sdlc.sh

# Inside Claude Code:
/sdlc init sase-platform
```

The `/sdlc init` command will process your imported documents — see [How Imported Documents Are Processed](#how-imported-documents-are-processed) for details.

---

## Step-by-Step: Scaffold WITHOUT Documents

This flow is for when you're starting completely from scratch with no existing documentation.

### Scenario: Building a Task Management App

```bash
bash create-project.sh taskflow ~/projects
```

### The Interactive Flow

```
┌──────────────────────────────────────────────────────────┐
│    AI-NATIVE SDLC FACTORY — Multi-Stack Scaffold         │
└──────────────────────────────────────────────────────────┘

  Project: taskflow

Step 1/5: Do you have any existing project documents?
  Do you have existing documents? (y/n): n

Step 2/5: Tech Stack Configuration
  Select Primary Frontend:
    [1] Angular 17+  [2] React 18+  [3] Vue 3+  [4] Svelte 5+  [5] None  [6] Other
  > 1
  Frontend: Angular
  Select Primary Backend:
    [1] Spring Boot  [2] Express  [3] NestJS  [4] Go  [5] Rust
    [6] Django  [7] FastAPI  [8] None  [9] Other
  > 1
  Backend: Spring Boot
  Databases (comma-separated): [1] PostgreSQL [2] MySQL [3] MongoDB [4] Redis
  > 1,4
  Databases: PostgreSQL,Redis
  Messaging: [1] Kafka [2] RabbitMQ [3] None
  > 1
  Messaging: Kafka

Step 3/5: Additional Tech Stack Workspaces
  Add additional workspace? (y/n): n

Step 4/5: Creating project...
  Copying kit files...
  Kit files copied
  Initializing state...
  Project: taskflow

Step 5/5: Finalizing...
  06-tech-stack-context.md generated
  Git initialized (main)
  Agent teams enabled
  Initial commit created

┌──────────────────────────────────────────────────────────┐
│                   Project Ready!                          │
├──────────────────────────────────────────────────────────┤
│  Project:  taskflow                                      │
│  Location: /Users/you/projects/taskflow                  │
│  Kit:      v2.0.0 (MultiStack)                           │
│  Stack:    Angular / Spring Boot                         │
│  Start:    Phase: ideation                               │
│                                                          │
│  Next Steps:                                             │
│  1. cd /Users/you/projects/taskflow                      │
│  2. bash scripts/start-sdlc.sh                           │
│  3. /sdlc init taskflow                                  │
└──────────────────────────────────────────────────────────┘
```

With no documents imported, `/sdlc init` starts you at Phase 1 (Ideation) — everything is fresh and you go through each phase sequentially.

### Adding a Workspace Later

If you later decide to add a Go microservice workspace, you can:

1. Edit `.sdlc/state.json` → add entry to `techStack.additional[]`
2. Create the workspace directory: `mkdir -p workspaces/go-service`
3. Regenerate the tech context: `bash scripts/generate-tech-context.sh`

---

## How Imported Documents Are Processed

This is one of the most important concepts in the Multi-Stack kit. Understanding this flow explains how the kit intelligently handles your existing documentation.

### The Golden Rule

> **Imported documents are REFERENCE material, not comprehensive/final.**
> The kit never treats them as complete or authoritative. It uses them as a starting point, then asks questions to ensure completeness and generates standard-format SDLC documents.

### What Happens at Scaffold Time (`create-project.sh`)

1. **Copy**: Original files copied to `docs/tech-refs/` (preserved as-is)
2. **Extract**: Text extracted to markdown (`.docx` → `.md`, `.pdf` → `.md`)
3. **Analyze**: Python keyword matching detects tech stack, phases, workspaces
4. **Track**: `state.json → importedDocs` records what was imported and when
5. **Auto-Advance**: Phases with imported coverage are set to `in_progress` (NEVER `completed`)

### What Happens at Init Time (`/sdlc init`)

When you run `/sdlc init` and imported documents exist, the SDLC orchestrator performs a **3-step process** for each imported phase:

#### Step 1: Read & Analyze
- Read the extracted `.md` version of the imported document
- Identify which sections map to which SDLC phase/document
- A single imported document (like the SASE guide) may span MULTIPLE phases

#### Step 2: Generate Standard Docs (Reference-Based)
- Create the kit's standard-format documents by incorporating relevant sections from the import
- **Critically**: Use `AskUserQuestion` to:
  - Clarify gaps (e.g., "Your imported doc mentions 3 personas but doesn't define user journeys. Should I create them based on the personas?")
  - Confirm accuracy (e.g., "The doc says target audience is enterprise IT teams. Is this still correct?")
  - Solicit missing details (e.g., "What are your top 3 success metrics / KPIs?")
- Mark sections as `<!-- IMPORTED: from SASE guide -->` or `<!-- TODO: needs filling -->`
- Adhere to the kit's required formats and sections for each document

#### Step 3: Gap Analysis & Phase Status
- Check generated docs against quality gate criteria
- Suggest additions/updates
- Phase remains `in_progress` — it is NEVER auto-completed from imports

### Example: What `/sdlc init` Might Show

```
/sdlc init sase-platform

Processing imported documents...

📄 Ideation (from SASE-Master-Implementation-Guide-extracted.md)
  → Reading document...
  → Found: executive summary, architecture overview, tech stack decisions
  → Generating docs/ideation/product-vision.md (standard format)...
  → Incorporated: vision context, problem space, technology rationale
  → ASKING QUESTIONS to ensure completeness:
    Q: "Your doc describes the SASE architecture but doesn't state
        a clear product vision. What is the ONE-sentence vision
        for this product?"
    Q: "Who is the primary target audience? The doc mentions
        enterprise IT teams — is that correct?"
    Q: "What are the top 3 problems this product solves?"
  → Phase 1 (Ideation) → in_progress (needs your answers + review)

📄 Requirements (from product-requirements-extracted.md)
  → Reading document...
  → Found: 3 personas, 12 functional requirements
  → Missing: NFRs, success metrics, acceptance criteria
  → Generating docs/prd/prd.md (standard format)...
  → ASKING QUESTIONS:
    Q: "What are your non-functional requirements?
        (latency targets, availability SLA, throughput needs)"
    Q: "What success metrics will you track?"
  → Phase 2 (Requirements) → in_progress (gaps in NFRs, metrics)

📄 Architecture (from SASE-Master-Implementation-Guide-extracted.md)
  → Found: HLD sections, technology decisions, deployment model
  → Will use as REFERENCE when /hld is invoked
  → Phase 4 (Design) → in_progress

Summary:
  Phase 1 (Ideation):      🔶 in_progress — generated, needs answers
  Phase 2 (Requirements):   🔶 in_progress — generated, has gaps
  Phase 3 (Project Setup):  ⏳ pending
  Phase 4 (Design):         🔶 in_progress — reference available

  Starting at: Phase 1 (Ideation)
  Recommendation: Review docs/ideation/product-vision.md, answer
  the questions above, then run /sdlc next
```

### How Skills Handle Existing Docs

Each skill follows the **Reference-First Approach**:

| Skill | Without Imported Doc | With Imported Doc |
|-------|---------------------|-------------------|
| `/ideate` | Full interactive discovery (8 questions) | Reads imported doc → fills gaps → asks targeted questions |
| `/enterprise-prd` | Generates PRD from scratch | Reads imported PRD → identifies missing sections → fills gaps |
| `/hld` | Designs architecture from scratch | Reads imported architecture doc as reference → builds on it |
| `/lld` | Generates from HLD | Uses imported tech specs as reference → generates complete LLD |
| `/develop` | Implements from contracts | Also reads `docs/tech-refs/` for workspace conventions |

The key: skills **never skip work** because an import exists. They use the import as a starting point and ensure the final output meets the kit's quality standards.

---

## Complete Phase-by-Phase Walkthrough

This walkthrough covers all 9 phases from start to finish. It shows both the **with-documents** and **without-documents** paths.

### Phase 1: Ideation

```
/ideate sase-platform cybersecurity
```

**Without imported docs**: The Research Agent (Opus) runs in interactive mode:
1. Asks you 8 structured questions (domain, problem, users, scale, competitors, constraints)
2. Researches based on your answers (web search for market data, competitors)
3. Presents 3 product direction options with visual previews
4. You choose a direction
5. Agent generates `docs/ideation/product-vision.md`

**With imported docs**: The Research Agent reads `docs/tech-refs/*-extracted.md` first:
1. Identifies what's already there (vision context, problem statements, etc.)
2. Asks **targeted questions** about gaps (e.g., "The doc doesn't mention target market size — what scale do you envision?")
3. Supplements with web research on market/competitors
4. Generates `docs/ideation/product-vision.md` with imported content woven in

**Output**: `docs/ideation/product-vision.md` — contains vision statement, problem statements, target audience, value proposition, competitive analysis, market sizing.

**Advance**:
```
/sdlc next
```
Gate check: product-vision.md exists with "Vision" and "Problem" sections.

### Phase 2: Requirements

```
/enterprise-prd sase-platform cybersecurity
```

The Product Agent (Opus) generates a comprehensive PRD:

**Without imported docs**: Full PRD generation from product vision. Agent may use `AskUserQuestion` to validate capability breakdown and epic priorities.

**With imported docs**: Reads imported requirements → identifies gaps (NFRs, success metrics, acceptance criteria) → asks questions to fill them → generates complete PRD in standard format.

**Output**: `docs/prd/prd.md` — executive summary, personas (3+), functional requirements (FR-XXX), non-functional requirements (NFR-XXX), success metrics, epic list, story list.

Then generate backlog and roadmap (can run in parallel):

```
/agile-backlog sase-platform 4
/roadmap sase-platform
```

**Output**: `docs/prd/backlog.md`, `docs/prd/roadmap.md`, GitHub issues with labels.

```
/sdlc next
```

### Phase 3: Project Setup

```
/github-project-setup sase-api your-github-username
```

The DevOps Agent (Haiku) creates:
- GitHub repo with issue templates, CI/CD workflows
- Labels (epic, user-story, bug, etc.)
- Branch protection rules
- GitHub Project board
- GitHub milestones from roadmap

```
/sdlc next
```

### Phase 4: Design

This is the most complex phase — it involves 4 skills with dependency ordering.

#### Step 4a: High-Level Design (must be first)

```
/hld sase-platform
```

**With imported architecture docs**: The Architect Agent reads `docs/tech-refs/` for existing architecture context and builds on it, ensuring the HLD covers ALL configured tech stacks (Angular, Spring Boot, Go Data Plane, Envoy Edge).

**Output**: `docs/architecture/hld/system-architecture.md` — architecture style, system context diagram, component architecture, technology decisions (for ALL stacks), deployment architecture, ADRs.

The HLD includes **both ASCII and Mermaid diagrams** so they render in terminal and GitHub.

#### Step 4b: DDD + LLD (can run in parallel after HLD)

These both read the HLD and write to different directories, so they can run simultaneously:

```
/ddd-architect sase-management
/lld sase-platform
```

**DDD Output** (`docs/ddd/`): Context map, bounded contexts, aggregate designs, domain events, saga designs.

**LLD Output** (`docs/architecture/lld/`): Class diagrams, sequence diagrams, API contracts, database schema, package structure — **for ALL configured stacks** (Java package structure for Spring Boot, Go package structure for data plane, etc.).

#### Step 4c: Tech Specs (needs both DDD + LLD)

```
/tech-specs sase-platform "spring-boot angular go envoy"
```

**Output** (`docs/tech-specs/`):
- `openapi.yaml` — **FROZEN** API contract
- `schema.sql` — **FROZEN** database schema
- `kafka-topics.md`, `redis-keys.md`
- `shared-schemas/` — cross-workspace contracts (gRPC protos, shared types)

**Why frozen?** Backend and frontend agents both read these contracts during development. Neither is allowed to modify them (STOP rules). If a change is needed, it goes through the Architect Agent with a version bump.

```
/sdlc next
```

### Phase 5: Development

#### Sprint Planning

```
/scrum-sprint planning
```

Creates `docs/sprints/sprint-1-plan.md` with selected user stories, sprint goals, and capacity allocation.

#### Implementing Stories

**Primary stacks** (Angular + Spring Boot):

```
/develop backend US-001
/develop frontend US-001
```

These can run in parallel (both read the frozen `openapi.yaml`, write to different directories).

**Additional workspaces** (Go, Envoy):

```
/develop workspace go-data-plane
```

This command:
1. Reads `state.json → techStack.additional[]` to find the workspace config
2. Reads `docs/tech-refs/go-data-plane/` reference docs for conventions
3. Reads `docs/tech-specs/shared-schemas/` for cross-workspace contracts
4. Implements code in `workspaces/go-data-plane/`

**Backend Agent produces** (DDD layered for Spring Boot):
```
backend/src/main/java/.../user/
├── domain/model/User.java
├── domain/repository/UserRepository.java
├── application/service/CreateUserUseCase.java
├── infrastructure/persistence/UserJpaRepository.java
├── api/controller/UserController.java
└── api/dto/UserRequest.java, UserResponse.java
```

**Frontend Agent produces** (Angular feature module):
```
frontend/src/app/features/user-registration/
├── components/register-form/
├── facade/user-registration.facade.ts
├── store/ (NgRx actions, reducer, selectors, effects)
├── models/user.model.ts
└── user-registration.routes.ts
```

#### Sprint Completion

```
/scrum-sprint progress    # Check progress during sprint
/scrum-sprint review      # End-of-sprint review
/scrum-sprint retro       # Retrospective → generates sprint summary
/sdlc next
```

### Phase 6: Testing

```
/test-suite all
```

The QA Agent (Sonnet) generates and runs tests for **ALL configured workspaces**:

| Workspace | Test Framework | Coverage Target |
|-----------|---------------|----------------|
| backend/ (Spring Boot) | JUnit5 + Mockito, Spring Boot Test | >= 80% |
| frontend/ (Angular) | Jest, Angular Testing Library | >= 70% |
| workspaces/go-data-plane/ | `go test ./...` | Per workspace config |
| workspaces/envoy-edge/ | Config validation | N/A |

**Output**: `docs/testing/test-report.md`, `docs/testing/coverage-report.md`.

```
/sdlc next
```

### Phase 7: Security

```
/security-review
```

The Security Agent (Opus, **read-only**) scans **ALL workspace directories**:
- OWASP Top 10 audit
- Hardcoded credential detection
- Input validation verification
- Auth/authz review
- Stack-specific checks (SQL injection for Java, path traversal for Go, etc.)

```
/compliance-checklist general
```

**Output**: `docs/security/security-review.md`, `docs/security/compliance-report.md`.

```
/sdlc next
```

### Phase 8: Code Review

```
/pr-review create
```

The DevOps Agent creates a PR with sections for **ALL affected workspaces**:

```markdown
## Summary
- [Changes summary]

## Changes by Workspace

### Backend (Spring Boot)
- [Backend changes]

### Frontend (Angular)
- [Frontend changes]

### Go Data Plane
- [Go workspace changes]

## Testing
- [ ] All workspace tests pass
- [ ] Cross-workspace integration verified
```

Then review the PR:

```
/pr-review review 1
```

This spawns Review Agent + Validator Agent in **parallel**:
- **Review Agent** (Opus): architecture compliance, code quality, security patterns
- **Validator Agent** (Opus): DDD governance, boundary violations, coupling score

Combined verdict: APPROVE / REQUEST CHANGES.

```
/sdlc next
```

### Phase 9: Release

```
/release notes v1.0.0
```

Generates release notes with sections for ALL workspaces that had changes.

```
/release checklist
```

Generates deployment checklist with per-workspace build/test verification:

```markdown
## Deployment Checklist — v1.0.0

### Per-Workspace Verification
- [ ] Backend build passes: `mvn clean package`
- [ ] Backend tests pass: `mvn test`
- [ ] Frontend build passes: `ng build`
- [ ] Frontend tests pass: `ng test`
- [ ] Go Data Plane build: `go build ./...`
- [ ] Go Data Plane tests: `go test ./...`
- [ ] Cross-workspace integration verified
```

```
/release tag v1.0.0
```

Creates Git tag, GitHub release, and closes the milestone.

```
/sdlc status
```

**All 9 phases complete!**

---

## Multi-Stack Workspaces

### Project Structure

```
my-project/
├── frontend/                  # Primary frontend
├── backend/                   # Primary backend
├── workspaces/                # Additional tech stacks
│   ├── go-data-plane/         # Each workspace is isolated
│   ├── envoy-edge/
│   └── rust-worker/
├── docs/
│   ├── tech-refs/             # Reference docs for ALL stacks
│   │   ├── go-data-plane/     # Workspace-specific reference docs
│   │   └── project-guide.docx # Overall architecture guide
│   └── tech-specs/
│       └── shared-schemas/    # Cross-workspace contracts (gRPC, OpenAPI)
└── .claude/rules/
    └── 06-tech-stack-context.md  # Auto-generated — single source of truth
```

### Key Configuration Files

#### `.sdlc/state.json → techStack`

```json
{
  "techStack": {
    "primary": {
      "frontend": {
        "name": "Angular",
        "version": "17+",
        "directory": "frontend",
        "buildCmd": "ng build",
        "testCmd": "ng test"
      },
      "backend": {
        "name": "Spring Boot",
        "version": "3.x",
        "directory": "backend",
        "buildCmd": "mvn clean package",
        "testCmd": "mvn test"
      }
    },
    "additional": [
      {
        "name": "Go Data Plane",
        "technology": "Go",
        "directory": "workspaces/go-data-plane",
        "buildCmd": "go build ./...",
        "testCmd": "go test ./..."
      }
    ],
    "databases": ["PostgreSQL", "Redis"],
    "messaging": ["Kafka"]
  }
}
```

#### `.claude/rules/06-tech-stack-context.md` (Auto-Generated)

This file is read by **every agent** before starting work. It contains:
- Primary stacks table (name, version, directory, build/test commands)
- Additional workspaces table
- Database and infrastructure list
- Reference doc locations
- Cross-workspace integration instructions
- Critical rules for all agents

**Regenerate after manual state.json changes:**
```bash
bash scripts/generate-tech-context.sh
```

### Developing in Workspaces

```bash
# Primary stacks
/develop backend US-001         # Implements in backend/
/develop frontend US-001        # Implements in frontend/

# Additional workspaces
/develop workspace go-data-plane    # Implements in workspaces/go-data-plane/
/develop workspace envoy-edge       # Implements in workspaces/envoy-edge/
```

Each workspace command reads:
1. `state.json → techStack.additional[]` for build/test commands
2. `docs/tech-refs/<workspace>/` for reference docs and conventions
3. `docs/tech-specs/shared-schemas/` for cross-workspace contracts

### Cross-Workspace Integration

All workspaces communicate via **defined contracts** stored in `docs/tech-specs/shared-schemas/`:
- REST API: `openapi.yaml`
- gRPC: `.proto` files
- Kafka: Topic definitions in `kafka-topics.md`
- Shared types: TypeScript/Go/Java type definitions

Agents are aware of cross-workspace integration and check for contract compliance.

### Adding a Workspace After Initial Scaffold

1. Edit `.sdlc/state.json` — add entry to `techStack.additional[]`:
   ```json
   {
     "name": "Rust Worker",
     "technology": "Rust",
     "version": "1.75+",
     "directory": "workspaces/rust-worker",
     "type": "worker",
     "language": "Rust",
     "buildCmd": "cargo build",
     "testCmd": "cargo test",
     "referenceDoc": ""
   }
   ```
2. Create the directory: `mkdir -p workspaces/rust-worker`
3. Regenerate tech context: `bash scripts/generate-tech-context.sh`
4. (Optional) Add reference docs: `cp ~/docs/rust-guide.md docs/tech-refs/rust-worker/`

---

## Multi-Agent Architecture

### Agent Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                      AI-NATIVE SDLC FACTORY (v2)                       │
│                                                                        │
│  ┌─────────────── THINKERS (Opus) ──────────────────────────────┐     │
│  │  research-agent    product-agent    architect-agent           │     │
│  │  security-agent    review-agent     validator-agent           │     │
│  │  Deep analysis, reasoning, governance, audit                  │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌─────────────── BUILDERS (Sonnet) ────────────────────────────┐     │
│  │  backend-agent     frontend-agent   qa-agent                  │     │
│  │  Code generation, test writing, implementation                │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌─────────────── EXECUTORS (Haiku) ────────────────────────────┐     │
│  │  devops-agent      memory-agent                               │     │
│  │  Fast CLI operations, context compression                     │     │
│  └───────────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────┘
```

### Agent Details

| Agent | Model | Role | Key Capabilities |
|-------|-------|------|-----------------|
| **research-agent** | Opus | Market research, interactive discovery | 3-phase questionnaire, WebSearch, reference-first |
| **product-agent** | Opus | PRD, epics, stories, roadmap | Capability-driven PRD, story slicing, interactive |
| **architect-agent** | Opus | HLD, LLD, DDD, contracts | Dual ASCII+Mermaid, contract freeze, saga design |
| **backend-agent** | Sonnet | Spring Boot DDD implementation | Layer discipline, aggregate rules, STOP rules |
| **frontend-agent** | Sonnet | Angular 17+ feature modules | Facade pattern, NgRx, lazy loading, STOP rules |
| **qa-agent** | Sonnet | Test pyramid management | JUnit5+Mockito, Jest, Playwright, per-workspace |
| **security-agent** | Opus | OWASP Top 10 audit | All-workspace scan, credential detection (read-only) |
| **devops-agent** | Haiku | Git, gh CLI, CI/CD, releases | PR creation, tagging, all-workspace builds |
| **review-agent** | Opus | PR diff analysis | Architecture compliance, per-workspace patterns (read-only) |
| **validator-agent** | Opus | DDD governance, drift detection | Boundary checks, coupling score, health score (read-only) |
| **memory-agent** | Haiku | Sprint summaries | Context compression, evolution tracking |

### How Skills Delegate to Agents

| Skill | Agent Spawned | Model |
|-------|--------------|-------|
| `/ideate` | research-agent | Opus |
| `/enterprise-prd` | product-agent | Opus |
| `/agile-backlog` | product-agent | Opus |
| `/roadmap` | product-agent | Opus |
| `/hld` | architect-agent | Opus |
| `/lld` | architect-agent | Opus |
| `/ddd-architect` | architect-agent | Opus |
| `/develop backend` | backend-agent | Sonnet |
| `/develop frontend` | frontend-agent | Sonnet |
| `/develop workspace` | backend-agent (adapts to workspace tech) | Sonnet |
| `/test-suite` | qa-agent | Sonnet |
| `/security-review` | security-agent | Opus |
| `/pr-review create` | devops-agent | Haiku |
| `/pr-review review` | review-agent + validator-agent | Opus (parallel) |
| `/release tag` | devops-agent | Haiku |
| `/scrum-sprint retro` | memory-agent | Haiku |
| `/build-with-agent-team` | Multiple agents in parallel | Mixed |

### Multi-Stack Awareness

Every agent reads `.claude/rules/06-tech-stack-context.md` as its first action. This means:
- **Backend Agent** knows about Go/Envoy workspaces for integration awareness
- **QA Agent** runs tests across ALL configured workspaces
- **Security Agent** scans ALL workspace directories
- **Architect Agent** designs architecture covering ALL tech stacks
- **Review Agent** checks code against per-workspace patterns

---

## Agent Teams — Parallel Execution

Agent Teams provide **split-pane tmux visibility** where you can see and interact with all agents simultaneously.

### Setup

```bash
# One-time setup
bash scripts/setup-agents.sh

# Launch with Agent Teams
bash scripts/start-sdlc.sh
```

### When to Use Agent Teams vs Task Tool

| Scenario | Mechanism | Why |
|----------|-----------|-----|
| Backend + Frontend (parallel dev) | **Agent Teams** | Need visibility + interaction |
| Backend + Frontend + Go workspace | **Agent Teams** | 3+ agents, need coordination |
| Security + Validator (parallel review) | **Agent Teams** | See both audit results live |
| DDD + LLD (parallel design) | **Agent Teams** | Both need HLD, write different files |
| Simple gate check | Task tool | Quick, focused, no interaction |
| Memory compression | Task tool | Simple write task |

### What You See in tmux

```
┌──────────────────┬──────────────────┬──────────────────┐
│  LEAD (main)     │  BACKEND AGENT   │  FRONTEND AGENT  │
│                  │  (Sonnet)        │  (Sonnet)        │
│  Coordinating    │  Writing Java    │  Writing Angular  │
│  sprint US-001   │  DDD layers...   │  Feature module.. │
│                  │                  │                   │
│  Task List:      │  Done: Domain    │  Done: Component  │
│  [Ctrl+T]       │  WIP: Repository │  WIP: Facade      │
│  3/8 complete    │  Next: Controller│  Next: Store      │
└──────────────────┴──────────────────┴──────────────────┘
```

### Contract-First Development Pattern

The key to parallel agent execution is **frozen contracts**:

1. **Architect Agent** defines `openapi.yaml` and `schema.sql` during Design phase
2. Contracts are **FROZEN** before Development phase begins
3. Backend Agent implements server side of the contract
4. Frontend Agent implements client side of the contract
5. Both agents have **STOP rules** — they halt if they need to modify contracts
6. If a contract change is needed, it goes through the Architect Agent with a **version bump**

### Pre-Sprint Review Cycle (Sprint 2+)

Before each subsequent sprint, the kit runs a review cycle:

```
Sprint N-1 ends
      │
      ▼
MEMORY AGENT: compress sprint N-1 → sprint-summary.md
      │
      ▼
ARCHITECT AGENT: reviews Sprint N stories + current artifacts
      │
      ├─ New bounded contexts? → define + update CONTEXT_MAP.md
      ├─ New API endpoints? → version bump openapi.yaml (v1.0 → v1.1)
      ├─ Schema changes? → new Flyway migration
      ├─ Nothing new? → SKIP (contracts stay frozen)
      │
      ▼
VALIDATOR AGENT: pre-sprint health check (DDD Health Score)
      │
      ▼
Sprint N executes with RE-FROZEN contracts
```

### Multi-Stack Agent Team Example

For a SASE-like project with 3 tech stacks:

```
/build-with-agent-team docs/sprints/sprint-1-plan.md

┌───────────────┬───────────────┬───────────────┬───────────────┐
│ LEAD          │ BACKEND       │ FRONTEND      │ GO DATA PLANE │
│               │ (Sonnet)      │ (Sonnet)      │ (Sonnet)      │
│ Coordinating  │ Spring Boot   │ Angular       │ Go agent      │
│ sprint 1      │ DDD layers    │ Feature module│ gRPC services │
│               │               │               │               │
│ Contracts:    │ Reads:        │ Reads:        │ Reads:        │
│ openapi.yaml  │ openapi.yaml  │ openapi.yaml  │ shared-schemas│
│ schema.sql    │ schema.sql    │               │ go-data-plane │
│               │               │               │ reference doc │
│ [Ctrl+T]      │ backend/      │ frontend/     │ workspaces/   │
│ Task list     │ ONLY          │ ONLY          │ go-data-plane/│
└───────────────┴───────────────┴───────────────┴───────────────┘
```

Each agent has **clear file ownership** — no conflicts.

---

## Complete Skill Reference

### Master Orchestrator

| Command | Description |
|---------|-------------|
| `/sdlc init [project]` | Initialize new SDLC project, process imported docs, create state |
| `/sdlc status` | Dashboard showing all 9 phases with current status |
| `/sdlc next` | Advance to next phase (runs quality gate first) |
| `/sdlc gate [phase]` | Check quality gate for a specific phase |
| `/sdlc phase [name]` | Jump to a specific phase (with gate check) |
| `/sdlc history` | Show completion timeline with timestamps |

### Phase 1: Ideation

| Command | Description |
|---------|-------------|
| `/ideate [project] [domain]` | Generate product vision with market research |

**Outputs:** `docs/ideation/product-vision.md`

### Phase 2: Requirements

| Command | Description |
|---------|-------------|
| `/enterprise-prd [project] [domain]` | Generate comprehensive PRD |

**Outputs:** `docs/prd/prd.md`

### Phase 3: Project Setup

| Command | Description |
|---------|-------------|
| `/github-project-setup [repo] [owner]` | Create GitHub repo with templates, CI/CD, labels |
| `/agile-backlog [project] [sprints]` | Generate epics, user stories, sprint backlog |
| `/roadmap [project]` | Generate milestone roadmap with Gantt chart |

**Outputs:** GitHub repo, `docs/prd/roadmap.md`, `docs/prd/backlog.md`

### Phase 4: Design

| Command | Description |
|---------|-------------|
| `/hld [project]` | System architecture, component diagrams, tech decisions |
| `/lld [project]` | Class diagrams, sequence diagrams, API contracts |
| `/ddd-architect [domain]` | Bounded contexts, aggregates, domain events |
| `/tech-specs [project] [stack]` | DB schemas, OpenAPI specs, workflow definitions |

**Outputs:** `docs/architecture/hld/`, `docs/architecture/lld/`, `docs/ddd/`, `docs/tech-specs/`

### Phase 5: Development

| Command | Description |
|---------|-------------|
| `/scrum-sprint planning` | Plan a new sprint with story selection |
| `/scrum-sprint progress` | Show current sprint progress |
| `/scrum-sprint review` | Conduct sprint review |
| `/scrum-sprint retro` | Run sprint retrospective |
| `/develop backend [US-XXX]` | Implement backend for a user story |
| `/develop frontend [US-XXX]` | Implement frontend for a user story |
| `/develop api [US-XXX]` | Implement API layer for a user story |
| `/develop workspace [name]` | Implement in an additional workspace |

**Outputs:** Source code, `docs/sprints/sprint-N-plan.md`

### Phase 6: Testing

| Command | Description |
|---------|-------------|
| `/test-suite unit` | Generate and run unit tests |
| `/test-suite integration` | Generate and run integration tests |
| `/test-suite e2e` | Generate and run E2E tests |
| `/test-suite coverage` | Check coverage against thresholds |
| `/test-suite all` | Run all tests and generate report |
| `/tdd-helper` | TDD guidance (Red-Green-Refactor) |

**Outputs:** Test files, `docs/testing/test-report.md`

### Phase 7: Security

| Command | Description |
|---------|-------------|
| `/security-review` | OWASP Top 10 security audit (all workspaces) |
| `/compliance-checklist [industry]` | Industry-specific compliance check |

**Outputs:** `docs/security/security-review.md`, `docs/security/compliance-report.md`

### Phase 8: Code Review

| Command | Description |
|---------|-------------|
| `/pr-review create` | Create a well-structured PR (all-workspace template) |
| `/pr-review review [pr#]` | Automated code review with findings |
| `/pr-review list` | List open PRs |

**Outputs:** GitHub PR, review comments

### Phase 9: Release

| Command | Description |
|---------|-------------|
| `/release notes [version]` | Generate release notes (all-workspace changes) |
| `/release checklist` | Pre-deployment verification checklist |
| `/release tag [version]` | Create Git tag and GitHub release |
| `/release status` | Check release readiness |

**Outputs:** `docs/releases/vX.Y.Z-release-notes.md`, Git tag, GitHub release

### Agent Team Orchestration

| Command | Description |
|---------|-------------|
| `/build-with-agent-team [plan] [agents]` | Parallel sprint execution with split-pane visibility |

---

## Quality Gates

Quality gates enforce that each phase is properly completed before advancing.

| Gate | From → To | What's Checked |
|------|-----------|---------------|
| G1 | Ideation → Requirements | `product-vision.md` exists with vision + problems |
| G2 | Requirements → Setup | `prd.md` exists with FRs, NFRs, personas |
| G3 | Setup → Design | GitHub repo exists, roadmap generated, backlog populated |
| G4 | Design → Development | HLD + LLD docs exist in `docs/architecture/` |
| G5 | Development → Testing | Source code exists, build passes, sprint plan exists |
| G6 | Testing → Security | Coverage meets thresholds (80% backend, 70% frontend) |
| G7 | Security → Code Review | Security review complete, no critical findings |
| G8 | Code Review → Release | PR created and approved, CI checks pass |
| G9 | Release Complete | Release notes generated, Git tag created |

### Imported Docs and Gates

When imported documents exist, gate checks also verify:
- Imported doc was processed and standard doc was generated
- Standard doc meets format requirements (not just the raw import)
- Gaps were identified and addressed

### Bypassing Gates

In exceptional cases, use `--force`:
```
/sdlc phase development --force
```
This logs the bypass in state.json for audit purposes.

---

## Tips & Best Practices

### 1. Start with Documents if You Have Them
The document-first scaffold saves enormous time. Even rough notes, competitor analyses, or partial architecture sketches help — the kit extracts what it can and asks about the rest.

### 2. Use the Guided Flow for New Projects
Start with `/sdlc init` and use `/sdlc next` to walk through each phase. The orchestrator guides you on which skills to run next.

### 3. Use Independent Skills for Iteration
Already past the design phase but need to update the HLD? Just run `/hld [project]` directly — no need to go through the orchestrator.

### 4. Check Status Frequently
Run `/sdlc status` to see your dashboard. It shows what's done, what's in progress, and what's next.

### 5. Sprint-Based Development
During the development phase, use the full Scrum workflow:
1. `/scrum-sprint planning` — Plan the sprint
2. `/develop backend US-XXX` — Implement stories (or `/develop workspace <name>`)
3. `/scrum-sprint progress` — Check progress
4. `/scrum-sprint review` — Review the sprint
5. `/scrum-sprint retro` — Retrospective

### 6. Iterative Design (Dependency Order)
The Design phase has 4 skills that build on each other:
1. `/hld` first (system overview)
2. `/ddd-architect` second (domain modeling) — can run parallel with LLD
3. `/lld` third (implementation details) — can run parallel with DDD
4. `/tech-specs` fourth (concrete specifications — needs both DDD + LLD)

### 7. Use Agent Teams for Parallel Work
When implementing multiple workspaces or running security + governance in parallel, use Agent Teams for visibility:
```
bash scripts/start-sdlc.sh
/build-with-agent-team docs/sprints/sprint-1-plan.md
```

### 8. Review the Tech Context After Changes
After modifying `state.json` (adding workspaces, changing build commands), always regenerate:
```bash
bash scripts/generate-tech-context.sh
```

### 9. Customize Rules Per Stack
Edit the files in `.claude/rules/` to match your team's conventions:
- `01-general.md` — Git workflow, file naming
- `02-quality-gates.md` — Adjust thresholds
- `03-java-patterns.md` — Spring Boot conventions (only if Java selected)
- `04-angular-patterns.md` — Angular conventions (only if Angular selected)
- `05-security.md` — Security standards

### 10. Cross-Workspace Contracts
Store all cross-workspace contracts (gRPC protos, shared types, OpenAPI specs) in `docs/tech-specs/shared-schemas/`. All agents are instructed to check this directory.

---

## File Reference

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project configuration, skill/agent catalog, conventions |
| `.claude/agents/*.md` | Agent definitions (11 multi-stack-aware agents) |
| `.claude/rules/01-05.md` | Coding standards and quality gates |
| `.claude/rules/06-tech-stack-context.md` | Auto-generated tech stack context (single source of truth) |
| `.claude/skills/*/SKILL.md` | Skill definitions (10 skills) |
| `.claude/hooks/*.sh` | Agent team lifecycle hooks |
| `.claude/settings.local.json` | Tool permissions and agent team config |
| `.sdlc/state.json` | SDLC state (phases, techStack, importedDocs, GitHub) |
| `scripts/sdlc-gate-check.sh` | Quality gate validation script |
| `scripts/start-sdlc.sh` | Session launcher with Agent Teams + tmux |
| `scripts/setup-agents.sh` | One-time agent configuration setup |
| `scripts/generate-tech-context.sh` | Generates 06-tech-stack-context.md from state.json |
| `scripts/extract-doc-text.sh` | Extracts text from .docx/.pdf to .md |
| `scripts/analyze-doc.sh` | Document intelligence (tech stack, phase, workspace detection) |
| `docs/` | All generated documentation artifacts |
| `docs/tech-refs/` | Imported reference documents (originals + extracted) |
| `docs/tech-specs/shared-schemas/` | Cross-workspace shared contracts |
| `workspaces/` | Additional tech stack workspace directories |

### Agent Definitions

| Agent | File | Model | Role |
|-------|------|-------|------|
| Research | `.claude/agents/research-agent.md` | Opus | Interactive market research |
| Product | `.claude/agents/product-agent.md` | Opus | PRD, epics, stories |
| Architect | `.claude/agents/architect-agent.md` | Opus | HLD, LLD, DDD, contracts |
| Backend | `.claude/agents/backend-agent.md` | Sonnet | DDD implementation |
| Frontend | `.claude/agents/frontend-agent.md` | Sonnet | Feature modules |
| QA | `.claude/agents/qa-agent.md` | Sonnet | Tests and coverage |
| Security | `.claude/agents/security-agent.md` | Opus | OWASP audit (read-only) |
| DevOps | `.claude/agents/devops-agent.md` | Haiku | Git, PRs, releases |
| Review | `.claude/agents/review-agent.md` | Opus | Code review (read-only) |
| Validator | `.claude/agents/validator-agent.md` | Opus | DDD governance (read-only) |
| Memory | `.claude/agents/memory-agent.md` | Haiku | Sprint summaries |

### Skills

| Skill | Location | Delegates to |
|-------|----------|-------------|
| `/sdlc` | `.claude/skills/sdlc/SKILL.md` | Orchestrates all agents |
| `/ideate` | `.claude/skills/ideate/SKILL.md` | research-agent (Opus) |
| `/roadmap` | `.claude/skills/roadmap/SKILL.md` | product-agent (Opus) |
| `/hld` | `.claude/skills/hld/SKILL.md` | architect-agent (Opus) |
| `/lld` | `.claude/skills/lld/SKILL.md` | architect-agent (Opus) |
| `/develop` | `.claude/skills/develop/SKILL.md` | backend/frontend-agent (Sonnet) |
| `/test-suite` | `.claude/skills/test-suite/SKILL.md` | qa-agent (Sonnet) |
| `/pr-review` | `.claude/skills/pr-review/SKILL.md` | devops/review/validator |
| `/release` | `.claude/skills/release/SKILL.md` | devops-agent (Haiku) |
| `/build-with-agent-team` | `.claude/skills/build-with-agent-team/SKILL.md` | Multiple agents (parallel) |

### Pre-existing Skills (Global — in ~/.claude/commands/)

| Skill | Purpose |
|-------|---------|
| `/enterprise-prd` | PRD generation |
| `/ddd-architect` | DDD design |
| `/scrum-sprint` | Sprint management |
| `/agile-backlog` | Backlog generation |
| `/github-project-setup` | GitHub repo setup |
| `/tech-specs` | Technical specifications |
| `/tdd-helper` | TDD guidance |
| `/security-review` | Security audit |
| `/compliance-checklist` | Compliance checks |
| `/angular-scaffold` | Angular scaffolding |
| `/spring-boot-scaffold` | Spring Boot scaffolding |
