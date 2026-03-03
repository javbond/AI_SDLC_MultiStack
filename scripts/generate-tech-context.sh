#!/bin/bash
# generate-tech-context.sh — Generate .claude/rules/06-tech-stack-context.md from state.json
#
# Usage:
#   bash scripts/generate-tech-context.sh [project-root]
#
# Reads: .sdlc/state.json
# Writes: .claude/rules/06-tech-stack-context.md
#
# This is the SINGLE SOURCE OF TRUTH for all agents and skills to know the project's
# full tech stack, workspace layout, reference docs, and integration points.

set -e

PROJECT_ROOT="${1:-.}"
STATE_FILE="$PROJECT_ROOT/.sdlc/state.json"
OUTPUT_FILE="$PROJECT_ROOT/.claude/rules/06-tech-stack-context.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "Error: state.json not found at $STATE_FILE"
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

python3 << PYEOF
import json
import os
from datetime import datetime, timezone

state_file = '$STATE_FILE'
output_file = '$OUTPUT_FILE'
project_root = '$PROJECT_ROOT'

with open(state_file, 'r') as f:
    state = json.load(f)

project = state.get('project', 'unnamed')
tech = state.get('techStack', {})
imported = state.get('importedDocs', {})
primary = tech.get('primary', {})
additional = tech.get('additional', [])
databases = tech.get('databases', [])
messaging = tech.get('messaging', [])
search = tech.get('search', [])
infrastructure = tech.get('infrastructure', [])
architecture = tech.get('architecture', 'DDD')

lines = []
lines.append('# Project Tech Stack Context (AUTO-GENERATED)')
lines.append(f'> Generated: {datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}')
lines.append('> Do NOT edit manually. Regenerate: bash scripts/generate-tech-context.sh')
lines.append('')
lines.append(f'## Project: {project}')
lines.append('')

# Primary Stacks
lines.append('## Primary Stacks')
lines.append('')
fe = primary.get('frontend')
be = primary.get('backend')

if fe or be:
    lines.append('| Layer | Technology | Version | Language | Directory | Build | Test | Rules |')
    lines.append('|-------|-----------|---------|----------|-----------|-------|------|-------|')
    if fe:
        lines.append(f'| Frontend | {fe.get("name", "N/A")} | {fe.get("version", "")} | {fe.get("language", "")} | {fe.get("directory", "frontend")}/ | {fe.get("buildCmd", "")} | {fe.get("testCmd", "")} | {fe.get("rulesFile", "N/A")} |')
    if be:
        lines.append(f'| Backend | {be.get("name", "N/A")} | {be.get("version", "")} | {be.get("language", "")} | {be.get("directory", "backend")}/ | {be.get("buildCmd", "")} | {be.get("testCmd", "")} | {be.get("rulesFile", "N/A")} |')
else:
    lines.append('_No primary frontend/backend configured._')
lines.append('')

# Additional Workspaces
if additional:
    lines.append('## Additional Workspaces')
    lines.append('')
    lines.append('| Name | Technology | Version | Directory | Type | Language | Build | Test |')
    lines.append('|------|-----------|---------|-----------|------|----------|-------|------|')
    for ws in additional:
        lines.append(f'| {ws.get("name", "")} | {ws.get("technology", "")} | {ws.get("version", "")} | {ws.get("directory", "")}/ | {ws.get("type", "")} | {ws.get("language", "")} | {ws.get("buildCmd", "")} | {ws.get("testCmd", "")} |')
    lines.append('')

# Databases & Infrastructure
lines.append('## Databases & Infrastructure')
lines.append('')
if databases:
    lines.append(f'- Databases: {", ".join(databases)}')
if messaging:
    lines.append(f'- Messaging: {", ".join(messaging)}')
if search:
    lines.append(f'- Search: {", ".join(search)}')
if infrastructure:
    lines.append(f'- Infrastructure: {", ".join(infrastructure)}')
if not (databases or messaging or search or infrastructure):
    lines.append('_No databases/infrastructure configured yet._')
lines.append('')

# Architecture
lines.append(f'## Architecture Pattern: {architecture}')
lines.append('')

# Reference Documentation
lines.append('## Reference Documentation')
lines.append('')
lines.append('ALL agents MUST consult these before working on the respective stack:')
lines.append('')

has_refs = False

# Project-level guide
project_guide = imported.get('projectGuide') if imported else None
if project_guide:
    extracted = project_guide.get('extracted', '')
    if extracted:
        lines.append(f'- **Project Guide**: {extracted}')
        has_refs = True

# Per-workspace reference docs
for ws in additional:
    ref = ws.get('referenceDoc', '')
    if ref:
        lines.append(f'- **{ws.get("name", "")}**: {ref}')
        has_refs = True

# Primary stack rules
if fe and fe.get('rulesFile'):
    lines.append(f'- **{fe.get("name", "Frontend")} patterns**: .claude/rules/{fe["rulesFile"]}')
    has_refs = True
if be and be.get('rulesFile'):
    lines.append(f'- **{be.get("name", "Backend")} patterns**: .claude/rules/{be["rulesFile"]}')
    has_refs = True

if not has_refs:
    lines.append('_No reference docs configured yet._')
lines.append('')

# Imported Documents
if imported and any(v for v in imported.values() if v):
    lines.append('## Imported Project Documents')
    lines.append('')
    phase_names = {
        'ideation': 'Ideation (Product Vision)',
        'requirements': 'Requirements (PRD)',
        'architecture': 'Architecture (HLD/LLD)',
        'backlog': 'Backlog (Epics/Stories)',
        'techSpecs': 'Tech Specs (API/DB)',
        'projectGuide': 'Project Guide'
    }
    for key, label in phase_names.items():
        doc = imported.get(key)
        if doc:
            lines.append(f'- **{label}**: {doc.get("extracted", doc.get("original", "N/A"))}')
    lines.append('')

# Integration Points
if additional:
    lines.append('## Integration Points')
    lines.append('')
    lines.append('All workspaces are part of a SINGLE project. Cross-workspace integration:')
    lines.append('- API contracts: `docs/tech-specs/` (OpenAPI, gRPC proto files)')
    lines.append('- Shared schemas: `docs/tech-specs/shared-schemas/`')
    lines.append('- Each workspace communicates via defined contracts (REST, gRPC, Kafka topics)')
    lines.append('')

    # Auto-generate integration arrows
    all_dirs = []
    if fe:
        all_dirs.append(('Frontend', fe.get('name', ''), fe.get('directory', 'frontend')))
    if be:
        all_dirs.append(('Backend', be.get('name', ''), be.get('directory', 'backend')))
    for ws in additional:
        all_dirs.append((ws.get('type', 'workspace'), ws.get('name', ''), ws.get('directory', '')))

    if len(all_dirs) > 1:
        lines.append('Integration map:')
        for i, (type1, name1, dir1) in enumerate(all_dirs):
            for j, (type2, name2, dir2) in enumerate(all_dirs):
                if i < j:
                    lines.append(f'- {name1} ({dir1}/) <-> {name2} ({dir2}/)')
        lines.append('')

# Critical instructions
lines.append('## CRITICAL FOR ALL AGENTS')
lines.append('')
lines.append('1. **ALWAYS** read this file FIRST before starting any work')
lines.append('2. Be aware of **ALL** tech stacks listed above — not just your primary workspace')
lines.append('3. When reviewing/testing, check **ALL** workspace directories listed above')
lines.append('4. Reference docs in `docs/tech-refs/` contain patterns and conventions for non-default stacks — **READ THEM**')
lines.append('5. When generating architecture (HLD/LLD), cover **ALL** workspaces and their integration')
lines.append('6. Build/test commands are workspace-specific — use the correct command for each directory')
if imported and any(v for v in imported.values() if v):
    lines.append('7. Check `importedDocs` in state.json — imported documents contain pre-existing project context')
lines.append('')

# Write output
with open(output_file, 'w') as f:
    f.write('\n'.join(lines))

print(f'Generated: {output_file}')

# Count stats
workspace_count = len(additional) + (1 if fe else 0) + (1 if be else 0)
ref_count = sum(1 for ws in additional if ws.get('referenceDoc'))
if project_guide:
    ref_count += 1
imported_count = sum(1 for v in (imported or {}).values() if v)

print(f'  Stacks: {workspace_count} | Ref docs: {ref_count} | Imported docs: {imported_count}')
PYEOF

echo "Done."
