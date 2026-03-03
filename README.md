# AI-Native SDLC Factory (Multi-Stack)

A **document-first, multi-stack** kit that transforms [Claude Code](https://docs.anthropic.com/en/docs/claude-code) into a complete software development team. Ships with 11 specialized AI agents, 10 orchestrated skills, 9 SDLC phases with enforced quality gates, and intelligent document analysis.

## Key Features

- **Document-First Scaffold**: Import existing docs (PRD, architecture guide, etc.) — the kit reads, analyzes, and auto-detects tech stack and SDLC phases
- **Multi-Stack Support**: Hybrid projects with multiple tech stacks (e.g., Angular + Spring Boot + Go + Envoy)
- **Workspace Isolation**: Each additional tech stack gets its own workspace directory
- **Intelligent Phase Detection**: Auto-advances past SDLC phases that are already covered by imported docs
- **Full Stack Awareness**: All agents and skills are aware of the entire project tech stack

## Supported Tech Stacks

| Layer | Options |
|-------|---------|
| Frontend | Angular 17+, React 18+, Vue 3+, Svelte 5+, or custom |
| Backend | Spring Boot 3.x, Node.js/Express, NestJS, Go, Rust/Actix, Django, FastAPI, or custom |
| Database | PostgreSQL, MySQL, MongoDB, Redis, ClickHouse |
| Messaging | Kafka, RabbitMQ |
| Additional | Any tech via `workspaces/` — Go microservices, Rust workers, Envoy proxies, etc. |
| Architecture | Domain-Driven Design (DDD) by default |

## Prerequisites

- **Claude Code CLI** (latest) — `npm install -g @anthropic-ai/claude-code`
- **Python 3.x** (required for document analysis and state management)
- **Git 2.x+** configured with your credentials
- **GitHub CLI** (`gh`) — `brew install gh` then `gh auth login`
- **tmux** (recommended) — `brew install tmux` for agent team split-pane view
- **Stack-specific tools**: Install per your chosen stack (Node.js, Java/Maven, Go, Rust, etc.)

## Quick Start

```bash
# 1. Clone the kit
git clone https://github.com/YOUR_USERNAME/ai-sdlc-factory-multistack.git
cd ai-sdlc-factory-multistack

# 2. Scaffold a new project (interactive — document-first)
bash create-project.sh my-app ~/projects
# → Asks for existing docs first, analyzes them, auto-detects tech stack
# → Then confirms/asks for tech stack and additional workspaces

# 3. Navigate to your project
cd ~/projects/my-app

# 4. Launch the SDLC Factory
bash scripts/start-sdlc.sh

# 5. Inside Claude Code — initialize (auto-advances past imported phases)
/sdlc init my-app
```

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Agents | 11 | Multi-stack-aware AI agents (Opus/Sonnet/Haiku) |
| Skills | 10 | SDLC phase commands with workspace support |
| Rules | 5+1 | 5 base rules + auto-generated `06-tech-stack-context.md` |
| Hooks | 2 | Agent team lifecycle hooks |
| Scripts | 6 | Gate-check, setup, launcher, doc extraction, doc analysis, tech-context generator |

## SDLC Phases

```
1. IDEATION         /ideate [topic]                    Research Agent (Opus)
       |
2. REQUIREMENTS     /enterprise-prd [project]          Product Agent (Opus)
       |
3. PROJECT SETUP    /github-project-setup [repo]       DevOps Agent (Haiku)
       |
4. DESIGN           /hld + /lld + /ddd-architect       Architect Agent (Opus)
       |
5. DEVELOPMENT      /develop backend + frontend        Backend + Frontend (Sonnet)
       |
6. TESTING          /test-suite all                    QA Agent (Sonnet)
       |
7. SECURITY         /security-review                   Security Agent (Opus)
       |
8. CODE REVIEW      /pr-review create + review         Review + Validator (Opus)
       |
9. RELEASE          /release tag [version]             DevOps Agent (Haiku)
```

Quality gates are enforced between each phase via `/sdlc next`.

## Agent Architecture

```
THINKERS (Opus):    research, product, architect, security, review, validator
BUILDERS (Sonnet):  backend, frontend, qa
EXECUTORS (Haiku):  devops, memory
```

| Agent | Model | Role | Read-Only? |
|-------|-------|------|-----------|
| research-agent | Opus | Market research, interactive discovery | Yes |
| product-agent | Opus | PRD, epics, user stories, roadmap | No |
| architect-agent | Opus | HLD, LLD, DDD, contracts, diagrams | No |
| backend-agent | Sonnet | Spring Boot DDD implementation | No |
| frontend-agent | Sonnet | Angular 17+ feature modules | No |
| qa-agent | Sonnet | JUnit5, Jest, Playwright tests | No |
| security-agent | Opus | OWASP Top 10 audit | Yes |
| devops-agent | Haiku | Git, gh CLI, CI/CD, releases | Yes (code) |
| review-agent | Opus | PR diff analysis, architecture compliance | Yes |
| validator-agent | Opus | DDD governance, drift detection, health score | Yes |
| memory-agent | Haiku | Sprint summaries, context compression | No |

## Project Structure (After Scaffold)

```
my-awesome-app/
├── .claude/
│   ├── agents/              # 11 agent definitions
│   ├── skills/              # 10 SDLC phase skills
│   ├── rules/               # 5 coding standard rules
│   ├── hooks/               # 2 agent team hooks
│   └── settings.local.json  # Tool permissions
├── .sdlc/
│   ├── state.json           # Project state (phase, artifacts, GitHub)
│   └── phases/              # Phase metadata
├── docs/                    # Generated artifacts output
│   ├── ideation/            # Product vision
│   ├── prd/                 # PRD, backlog, roadmap
│   ├── architecture/        # HLD + LLD
│   ├── ddd/                 # Context maps, aggregates
│   ├── tech-specs/          # OpenAPI, schema, configs
│   ├── sprints/             # Sprint plans + summaries
│   ├── security/            # Security review + compliance
│   ├── testing/             # Coverage + test reports
│   └── releases/            # Release notes
├── scripts/
│   ├── sdlc-gate-check.sh  # Quality gate validation
│   ├── setup-agents.sh     # One-time agent config
│   └── start-sdlc.sh       # Session launcher
├── CLAUDE.md                # Master project documentation
├── USAGE-GUIDE.md           # Comprehensive user guide
└── kit.json                 # Kit version metadata
```

## Updating Existing Projects

To update a previously scaffolded project with the latest kit files:

```bash
bash /path/to/ai-sdlc-factory/update-kit.sh /path/to/my-project
```

This updates agents, skills, rules, hooks, and scripts while preserving your project state, generated docs, and source code.

## Detailed Documentation

See [USAGE-GUIDE.md](USAGE-GUIDE.md) for comprehensive documentation including:

- Complete skill reference with arguments and examples
- Multi-agent architecture deep dive
- Agent team walkthrough (phase-by-phase with tmux examples)
- Quality gate definitions and thresholds
- Contract-first development patterns
- Tips and best practices

## License

MIT (or your preferred license)
