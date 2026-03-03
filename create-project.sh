#!/bin/bash
# create-project.sh — Document-first interactive scaffold for AI-Native SDLC Factory (Multi-Stack)
#
# Usage:
#   bash create-project.sh <project-name> [target-directory]
#
# Flow:
#   1. Project name
#   2. Ask for existing documents FIRST (product vision, PRD, architecture guide, etc.)
#   3. Analyze documents → auto-detect tech stack, phases, workspaces
#   4. Confirm detected results, ask only what's missing
#   5. Generate project with standard SDLC docs from imports
#
# Examples:
#   bash create-project.sh my-app
#   bash create-project.sh sase-platform ~/projects

set -e

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Parse arguments ---
PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-.}"

if [ -z "$PROJECT_NAME" ]; then
  echo ""
  echo "Usage: bash create-project.sh <project-name> [target-directory]"
  echo ""
  echo "Examples:"
  echo "  bash create-project.sh my-app"
  echo "  bash create-project.sh sase-platform ~/projects"
  echo ""
  exit 1
fi

# Validate project name
if ! echo "$PROJECT_NAME" | grep -qE '^[a-zA-Z][a-zA-Z0-9_-]*$'; then
  echo "Error: Project name must start with a letter and contain only letters, numbers, hyphens, underscores."
  exit 1
fi

# --- Resolve paths ---
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)/$PROJECT_NAME" || PROJECT_DIR="$TARGET_DIR/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
  echo "Error: Directory already exists: $PROJECT_DIR"
  exit 1
fi

echo ""
echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│    AI-NATIVE SDLC FACTORY — Multi-Stack Scaffold        │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${GREEN}  Project: ${BOLD}$PROJECT_NAME${NC}"
echo ""

# ==============================================================
# STEP 1: COLLECT DOCUMENTS (document-first approach)
# ==============================================================

echo -e "${YELLOW}Step 1/5: Do you have any existing project documents?${NC}"
echo -e "  (product vision, PRD, requirements, architecture guide, tech specs, etc.)"
echo -e "  These will be analyzed to auto-detect tech stack, phases, and project scope."
echo ""

DOC_FILES=()
ANALYSIS_RESULTS=()
MERGED_TECH='{"frontend":[],"backend":[],"languages":[],"databases":[],"messaging":[],"search":[],"infrastructure":[]}'
MERGED_PHASES='{"ideation":{"covered":false},"requirements":{"covered":false},"architecture":{"covered":false},"techSpecs":{"covered":false},"backlog":{"covered":false}}'
MERGED_WORKSPACES='[]'
HAS_DOCS=false

read -p "  Do you have existing documents? (y/n): " HAS_DOCS_INPUT
echo ""

if [[ "$HAS_DOCS_INPUT" =~ ^[Yy] ]]; then
  HAS_DOCS=true
  echo "  Enter file paths one per line (blank line when done):"

  while true; do
    read -p "  > " DOC_PATH
    if [ -z "$DOC_PATH" ]; then
      break
    fi

    # Expand ~ if present
    DOC_PATH="${DOC_PATH/#\~/$HOME}"

    if [ ! -f "$DOC_PATH" ]; then
      echo -e "  ${RED}File not found: $DOC_PATH (skipping)${NC}"
      continue
    fi

    DOC_FILES+=("$DOC_PATH")
    echo -e "  ${GREEN}Added: $(basename "$DOC_PATH")${NC}"
  done

  if [ ${#DOC_FILES[@]} -gt 0 ]; then
    echo ""
    echo -e "  ${CYAN}Analyzing ${#DOC_FILES[@]} document(s)...${NC}"

    # Create temp dir for analysis
    TEMP_DIR=$(mktemp -d)

    for doc in "${DOC_FILES[@]}"; do
      BASENAME=$(basename "$doc")
      echo -e "  ${CYAN}  Extracting: $BASENAME${NC}"

      # Extract text
      EXTRACTED=$(bash "$KIT_DIR/scripts/extract-doc-text.sh" "$doc" "$TEMP_DIR" 2>&1 | tail -1)

      if [ -f "$EXTRACTED" ]; then
        # Analyze
        ANALYSIS=$(bash "$KIT_DIR/scripts/analyze-doc.sh" "$EXTRACTED" 2>/dev/null || echo '{}')
        ANALYSIS_RESULTS+=("$ANALYSIS")
        echo -e "  ${GREEN}  Analyzed: $BASENAME${NC}"
      fi
    done

    # Merge analysis results using a temp file for safe JSON handling
    if [ ${#ANALYSIS_RESULTS[@]} -gt 0 ]; then
      # Write each analysis result to temp files
      for i in "${!ANALYSIS_RESULTS[@]}"; do
        echo "${ANALYSIS_RESULTS[$i]}" > "$TEMP_DIR/analysis_$i.json"
      done

      MERGED=$(python3 -c "
import json, glob, os

temp_dir = '$TEMP_DIR'
results = []
for f in sorted(glob.glob(os.path.join(temp_dir, 'analysis_*.json'))):
    with open(f) as fh:
        results.append(json.load(fh))

merged_tech = {'frontend':[],'backend':[],'languages':[],'databases':[],'messaging':[],'search':[],'infrastructure':[]}
for r in results:
    ts = r.get('techStack', {})
    for key in merged_tech:
        for item in ts.get(key, []):
            if item not in merged_tech[key]:
                merged_tech[key].append(item)

merged_phases = {}
for r in results:
    for phase, info in r.get('phaseCoverage', {}).items():
        if phase not in merged_phases or (info.get('covered') and info.get('matchCount', 0) > merged_phases.get(phase, {}).get('matchCount', 0)):
            merged_phases[phase] = info

seen = set()
merged_ws = []
for r in results:
    for ws in r.get('workspaces', []):
        if ws['name'] not in seen:
            seen.add(ws['name'])
            merged_ws.append(ws)

result = {'techStack': merged_tech, 'phaseCoverage': merged_phases, 'workspaces': merged_ws}
print(json.dumps(result))
")
      MERGED_TECH=$(echo "$MERGED" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['techStack']))")
      MERGED_PHASES=$(echo "$MERGED" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['phaseCoverage']))")
      MERGED_WORKSPACES=$(echo "$MERGED" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['workspaces']))")
    fi

    # Clean up temp dir
    rm -rf "$TEMP_DIR"

    # Display analysis results
    echo ""
    echo -e "  ${BLUE}┌─ Document Analysis Results ──────────────────────────────┐${NC}"

    DETECTED_FE=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('frontend',[])) or 'none detected')")
    DETECTED_BE=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('backend',[])) or 'none detected')")
    DETECTED_DB=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('databases',[])) or 'none')")
    DETECTED_MSG=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('messaging',[])) or 'none')")
    DETECTED_INFRA=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(d.get('infrastructure',[])) or 'none')")

    echo -e "  ${BLUE}│${NC}  Tech detected:"
    echo -e "  ${BLUE}│${NC}    Frontend:  ${GREEN}$DETECTED_FE${NC}"
    echo -e "  ${BLUE}│${NC}    Backend:   ${GREEN}$DETECTED_BE${NC}"
    echo -e "  ${BLUE}│${NC}    Databases: ${GREEN}$DETECTED_DB${NC}"
    echo -e "  ${BLUE}│${NC}    Messaging: ${GREEN}$DETECTED_MSG${NC}"
    echo -e "  ${BLUE}│${NC}    Infra:     ${GREEN}$DETECTED_INFRA${NC}"
    echo -e "  ${BLUE}│${NC}"
    echo -e "  ${BLUE}│${NC}  Phase coverage:"

    for phase in ideation requirements architecture techSpecs backlog; do
      COVERED=$(echo "$MERGED_PHASES" | python3 -c "import sys,json; d=json.load(sys.stdin); p=d.get('$phase',{}); print('true' if p.get('covered') else 'false')")
      CONFIDENCE=$(echo "$MERGED_PHASES" | python3 -c "import sys,json; d=json.load(sys.stdin); p=d.get('$phase',{}); print(p.get('confidence','none'))")
      if [ "$COVERED" = "true" ]; then
        if [ "$CONFIDENCE" = "high" ]; then
          ICON="${GREEN}✅${NC}"
        else
          ICON="${YELLOW}⚠️ ${NC}"
        fi
        echo -e "  ${BLUE}│${NC}    $ICON $phase (confidence: $CONFIDENCE)"
      else
        echo -e "  ${BLUE}│${NC}    ⏳ $phase (not covered)"
      fi
    done

    echo -e "  ${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
  fi
fi

# ==============================================================
# STEP 2: CONFIRM / SELECT TECH STACK
# ==============================================================

echo -e "${YELLOW}Step 2/5: Tech Stack Configuration${NC}"

if [ "$HAS_DOCS" = true ] && [ ${#DOC_FILES[@]} -gt 0 ]; then
  echo -e "  Based on your documents, confirm or change:"
  echo ""
fi

# --- Frontend ---
DETECTED_FE_FIRST=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); fe=d.get('frontend',[]); print(fe[0] if fe else '')")
if [ -n "$DETECTED_FE_FIRST" ]; then
  read -p "  Frontend: $DETECTED_FE_FIRST [correct? y/n]: " FE_CONFIRM
  if [[ "$FE_CONFIRM" =~ ^[Yy] ]] || [ -z "$FE_CONFIRM" ]; then
    FRONTEND="$DETECTED_FE_FIRST"
  else
    FRONTEND=""
  fi
else
  FRONTEND=""
fi

if [ -z "$FRONTEND" ]; then
  echo "  Select Primary Frontend:"
  echo "    [1] Angular 17+  [2] React 18+  [3] Vue 3+  [4] Svelte 5+  [5] None  [6] Other"
  read -p "  > " FE_CHOICE
  case "$FE_CHOICE" in
    1) FRONTEND="Angular" ;; 2) FRONTEND="React" ;; 3) FRONTEND="Vue" ;;
    4) FRONTEND="Svelte" ;; 5) FRONTEND="" ;; 6) read -p "  Enter name: " FRONTEND ;; *) FRONTEND="" ;;
  esac
fi
echo -e "  ${GREEN}Frontend: ${FRONTEND:-None}${NC}"

# --- Backend ---
DETECTED_BE_FIRST=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); be=d.get('backend',[]); print(be[0] if be else '')")
if [ -n "$DETECTED_BE_FIRST" ]; then
  read -p "  Backend: $DETECTED_BE_FIRST [correct? y/n]: " BE_CONFIRM
  if [[ "$BE_CONFIRM" =~ ^[Yy] ]] || [ -z "$BE_CONFIRM" ]; then
    BACKEND="$DETECTED_BE_FIRST"
  else
    BACKEND=""
  fi
else
  BACKEND=""
fi

if [ -z "$BACKEND" ]; then
  echo "  Select Primary Backend:"
  echo "    [1] Spring Boot  [2] Express  [3] NestJS  [4] Go  [5] Rust  [6] Django  [7] FastAPI  [8] None  [9] Other"
  read -p "  > " BE_CHOICE
  case "$BE_CHOICE" in
    1) BACKEND="Spring Boot" ;; 2) BACKEND="Node.js/Express" ;; 3) BACKEND="Node.js/NestJS" ;;
    4) BACKEND="Go" ;; 5) BACKEND="Rust/Actix" ;; 6) BACKEND="Python/Django" ;; 7) BACKEND="Python/FastAPI" ;;
    8) BACKEND="" ;; 9) read -p "  Enter name: " BACKEND ;; *) BACKEND="" ;;
  esac
fi
echo -e "  ${GREEN}Backend: ${BACKEND:-None}${NC}"

# --- Databases ---
DETECTED_DBS=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d.get('databases',[])))")
if [ -n "$DETECTED_DBS" ]; then
  read -p "  Databases: $DETECTED_DBS [correct? y/n]: " DB_CONFIRM
  if [[ "$DB_CONFIRM" =~ ^[Yy] ]] || [ -z "$DB_CONFIRM" ]; then
    DATABASES="$DETECTED_DBS"
  else
    DATABASES=""
  fi
else
  DATABASES=""
fi

if [ -z "$DATABASES" ]; then
  echo "  Databases (comma-separated): [1] PostgreSQL [2] MySQL [3] MongoDB [4] Redis [5] ClickHouse [6] None"
  read -p "  > " DB_CHOICE
  DB_MAP=("" "PostgreSQL" "MySQL" "MongoDB" "Redis" "ClickHouse")
  DATABASES=""
  IFS=',' read -ra DB_NUMS <<< "$DB_CHOICE"
  for num in "${DB_NUMS[@]}"; do
    num=$(echo "$num" | tr -d ' ')
    if [ "$num" -ge 1 ] 2>/dev/null && [ "$num" -le 5 ]; then
      [ -n "$DATABASES" ] && DATABASES="$DATABASES,"
      DATABASES="${DATABASES}${DB_MAP[$num]}"
    fi
  done
fi
echo -e "  ${GREEN}Databases: ${DATABASES:-None}${NC}"

# --- Messaging ---
DETECTED_MSG_VAL=$(echo "$MERGED_TECH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d.get('messaging',[])))")
if [ -n "$DETECTED_MSG_VAL" ]; then
  read -p "  Messaging: $DETECTED_MSG_VAL [correct? y/n]: " MSG_CONFIRM
  if [[ "$MSG_CONFIRM" =~ ^[Yy] ]] || [ -z "$MSG_CONFIRM" ]; then
    MESSAGING="$DETECTED_MSG_VAL"
  else
    MESSAGING=""
  fi
else
  echo "  Messaging: [1] Kafka [2] RabbitMQ [3] None"
  read -p "  > " MSG_CHOICE
  case "$MSG_CHOICE" in 1) MESSAGING="Kafka" ;; 2) MESSAGING="RabbitMQ" ;; *) MESSAGING="" ;; esac
fi
echo -e "  ${GREEN}Messaging: ${MESSAGING:-None}${NC}"
echo ""

# ==============================================================
# STEP 3: ADDITIONAL WORKSPACES
# ==============================================================

echo -e "${YELLOW}Step 3/5: Additional Tech Stack Workspaces${NC}"

ADDITIONAL_STACKS='[]'

# Check if doc analysis found additional workspaces
DETECTED_WS_COUNT=$(echo "$MERGED_WORKSPACES" | python3 -c "import sys,json; ws=json.load(sys.stdin); print(len([w for w in ws if 'workspaces/' in w.get('suggestedDir','')]))" 2>/dev/null || echo "0")

if [ "$DETECTED_WS_COUNT" -gt 0 ]; then
  echo "  Workspaces detected from documents:"
  echo "$MERGED_WORKSPACES" | python3 -c "
import sys, json
ws = json.load(sys.stdin)
for i, w in enumerate(ws):
    if 'workspaces/' in w.get('suggestedDir', ''):
        print(f\"    {i+1}. {w['name']} ({w['technology']}) -> {w['suggestedDir']}/\")
"
  read -p "  Keep these? (y/n): " WS_CONFIRM
  if [[ "$WS_CONFIRM" =~ ^[Yy] ]] || [ -z "$WS_CONFIRM" ]; then
    ADDITIONAL_STACKS=$(echo "$MERGED_WORKSPACES" | python3 -c "
import sys, json
ws = json.load(sys.stdin)
result = []
for w in ws:
    if 'workspaces/' in w.get('suggestedDir', ''):
        result.append({'name': w['name'], 'technology': w['technology'], 'version': '',
            'directory': w['suggestedDir'], 'type': 'microservice', 'language': w['technology'],
            'buildCmd': '', 'testCmd': '', 'referenceDoc': ''})
print(json.dumps(result))
")
  fi
fi

read -p "  Add additional workspace? (y/n): " ADD_MORE
while [[ "$ADD_MORE" =~ ^[Yy] ]]; do
  echo ""
  read -p "    Name: " WS_NAME
  read -p "    Technology: " WS_TECH
  read -p "    Version: " WS_VERSION
  WS_DIR_DEFAULT=$(echo "$WS_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  read -p "    Directory [workspaces/$WS_DIR_DEFAULT]: " WS_DIR
  WS_DIR="${WS_DIR:-workspaces/$WS_DIR_DEFAULT}"
  echo "    Type: [1] microservice [2] worker [3] agent [4] proxy [5] library [6] other"
  read -p "    > " WS_TYPE_NUM
  case "$WS_TYPE_NUM" in
    1) WS_TYPE="microservice" ;; 2) WS_TYPE="worker" ;; 3) WS_TYPE="agent" ;;
    4) WS_TYPE="proxy" ;; 5) WS_TYPE="library" ;; *) WS_TYPE="other" ;;
  esac
  read -p "    Build command: " WS_BUILD
  read -p "    Test command: " WS_TEST
  read -p "    Reference doc (path or 'none'): " WS_REF
  [ "$WS_REF" = "none" ] && WS_REF=""
  WS_REF="${WS_REF/#\~/$HOME}"

  # Write to temp file for safe JSON handling
  WS_TEMP=$(mktemp)
  echo "$ADDITIONAL_STACKS" > "$WS_TEMP"
  ADDITIONAL_STACKS=$(python3 -c "
import json
with open('$WS_TEMP') as f:
    stacks = json.load(f)
stacks.append({'name':'$WS_NAME','technology':'$WS_TECH','version':'$WS_VERSION',
    'directory':'$WS_DIR','type':'$WS_TYPE','language':'$WS_TECH',
    'buildCmd':'$WS_BUILD','testCmd':'$WS_TEST','referenceDoc':'$WS_REF'})
print(json.dumps(stacks))
")
  rm -f "$WS_TEMP"

  echo -e "  ${GREEN}Added: $WS_NAME ($WS_TECH) → $WS_DIR/${NC}"
  read -p "  Add another? (y/n): " ADD_MORE
done
echo ""

# ==============================================================
# STEP 4: CREATE PROJECT
# ==============================================================

echo -e "${YELLOW}Step 4/5: Creating project...${NC}"
echo ""

# 4a: Copy kit files
echo -e "  ${CYAN}Copying kit files...${NC}"
mkdir -p "$PROJECT_DIR"

if command -v rsync &>/dev/null; then
  rsync -a --exclude='.DS_Store' --exclude='.git/' --exclude='examples/' \
    --exclude='create-project.sh' --exclude='update-kit.sh' --exclude='README.md' \
    "$KIT_DIR/" "$PROJECT_DIR/"
else
  cp -r "$KIT_DIR/" "$PROJECT_DIR/"
  rm -rf "$PROJECT_DIR/.git" "$PROJECT_DIR/examples" "$PROJECT_DIR/create-project.sh" "$PROJECT_DIR/update-kit.sh" "$PROJECT_DIR/README.md"
fi
echo -e "  ${GREEN}Kit files copied${NC}"

# 4b: Conditionally remove stack-specific rules
if [ -z "$BACKEND" ] || [[ ! "$BACKEND" =~ ^Spring ]]; then
  rm -f "$PROJECT_DIR/.claude/rules/03-java-patterns.md"
  echo -e "  ${YELLOW}Removed 03-java-patterns.md (no Java/Spring Boot)${NC}"
fi
if [ -z "$FRONTEND" ] || [ "$FRONTEND" != "Angular" ]; then
  rm -f "$PROJECT_DIR/.claude/rules/04-angular-patterns.md"
  echo -e "  ${YELLOW}Removed 04-angular-patterns.md (no Angular)${NC}"
fi

# 4c: Create workspace and docs directories
mkdir -p "$PROJECT_DIR/docs/tech-refs" "$PROJECT_DIR/docs/tech-specs/shared-schemas"
touch "$PROJECT_DIR/docs/tech-refs/.gitkeep" "$PROJECT_DIR/docs/tech-specs/shared-schemas/.gitkeep"

WS_TEMP=$(mktemp)
echo "$ADDITIONAL_STACKS" > "$WS_TEMP"
python3 -c "
import json, os
with open('$WS_TEMP') as f:
    stacks = json.load(f)
for s in stacks:
    d = os.path.join('$PROJECT_DIR', s['directory'])
    os.makedirs(d, exist_ok=True)
    open(os.path.join(d, '.gitkeep'), 'w').close()
    print(f'  Created: {s[\"directory\"]}/')
"

# 4d: Copy and extract imported documents
if [ "$HAS_DOCS" = true ] && [ ${#DOC_FILES[@]} -gt 0 ]; then
  echo -e "  ${CYAN}Processing imported documents...${NC}"
  for doc in "${DOC_FILES[@]}"; do
    cp "$doc" "$PROJECT_DIR/docs/tech-refs/"
    bash "$KIT_DIR/scripts/extract-doc-text.sh" "$doc" "$PROJECT_DIR/docs/tech-refs" 2>&1 | head -2 | sed 's/^/  /'
  done
fi

# 4e: Copy workspace reference docs
python3 -c "
import json, os, shutil
with open('$WS_TEMP') as f:
    stacks = json.load(f)
for s in stacks:
    ref = s.get('referenceDoc', '')
    if ref and os.path.isfile(ref):
        ws_name = os.path.basename(s['directory'])
        ref_dir = os.path.join('$PROJECT_DIR', 'docs', 'tech-refs', ws_name)
        os.makedirs(ref_dir, exist_ok=True)
        shutil.copy2(ref, ref_dir)
        basename = os.path.basename(ref)
        s['referenceDoc'] = f'docs/tech-refs/{ws_name}/{basename}'
        print(f'  Ref doc: {basename} -> docs/tech-refs/{ws_name}/')
# Rewrite stacks with updated ref paths
with open('$WS_TEMP', 'w') as f:
    json.dump(stacks, f)
" 2>/dev/null || true
ADDITIONAL_STACKS=$(cat "$WS_TEMP")
rm -f "$WS_TEMP"

# 4f: Initialize state.json
echo -e "  ${CYAN}Initializing state...${NC}"

# Write temp files for safe JSON passing
STATE_TECH_TMP=$(mktemp)
STATE_PHASES_TMP=$(mktemp)
STATE_WS_TMP=$(mktemp)
echo "$MERGED_TECH" > "$STATE_TECH_TMP"
echo "$MERGED_PHASES" > "$STATE_PHASES_TMP"
echo "$ADDITIONAL_STACKS" > "$STATE_WS_TMP"

python3 << PYEOF
import json
from datetime import datetime, timezone

state_path = '$PROJECT_DIR/.sdlc/state.json'
with open(state_path, 'r') as f:
    state = json.load(f)

now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
state['project'] = '$PROJECT_NAME'
state['createdAt'] = now
state['updatedAt'] = now

frontend_name = '$FRONTEND'
backend_name = '$BACKEND'
databases = [d.strip() for d in '$DATABASES'.split(',') if d.strip()]
messaging = [m.strip() for m in '$MESSAGING'.split(',') if m.strip()]

with open('$STATE_TECH_TMP') as f:
    merged_tech = json.load(f)
with open('$STATE_PHASES_TMP') as f:
    merged_phases = json.load(f)
with open('$STATE_WS_TMP') as f:
    additional_ws = json.load(f)

fe_configs = {
    "Angular": {"version":"17+","language":"TypeScript","buildCmd":"ng build","testCmd":"ng test","rulesFile":"04-angular-patterns.md"},
    "React": {"version":"18+","language":"TypeScript","buildCmd":"npm run build","testCmd":"npm test","rulesFile":""},
    "Vue": {"version":"3+","language":"TypeScript","buildCmd":"npm run build","testCmd":"npm test","rulesFile":""},
    "Svelte": {"version":"5+","language":"TypeScript","buildCmd":"npm run build","testCmd":"npm test","rulesFile":""},
}
be_configs = {
    "Spring Boot": {"version":"3.x","language":"Java 17+","buildCmd":"mvn clean package","testCmd":"mvn test","rulesFile":"03-java-patterns.md"},
    "Node.js/Express": {"version":"18+","language":"JavaScript","buildCmd":"npm run build","testCmd":"npm test","rulesFile":""},
    "Node.js/NestJS": {"version":"10+","language":"TypeScript","buildCmd":"npm run build","testCmd":"npm test","rulesFile":""},
    "Go": {"version":"1.21+","language":"Go","buildCmd":"go build ./...","testCmd":"go test ./...","rulesFile":""},
    "Rust/Actix": {"version":"latest","language":"Rust","buildCmd":"cargo build","testCmd":"cargo test","rulesFile":""},
    "Python/Django": {"version":"5+","language":"Python 3.12+","buildCmd":"python manage.py check","testCmd":"python manage.py test","rulesFile":""},
    "Python/FastAPI": {"version":"0.100+","language":"Python 3.12+","buildCmd":"pip install -e .","testCmd":"pytest","rulesFile":""},
}

if frontend_name:
    cfg = fe_configs.get(frontend_name, {"version":"","language":"","buildCmd":"","testCmd":"","rulesFile":""})
    state['techStack']['primary']['frontend'] = {"name":frontend_name,"version":cfg["version"],"directory":"frontend","language":cfg["language"],"buildCmd":cfg["buildCmd"],"testCmd":cfg["testCmd"],"rulesFile":cfg["rulesFile"]}
if backend_name:
    cfg = be_configs.get(backend_name, {"version":"","language":"","buildCmd":"","testCmd":"","rulesFile":""})
    state['techStack']['primary']['backend'] = {"name":backend_name,"version":cfg["version"],"directory":"backend","language":cfg["language"],"buildCmd":cfg["buildCmd"],"testCmd":cfg["testCmd"],"rulesFile":cfg["rulesFile"]}

state['techStack']['databases'] = databases
state['techStack']['messaging'] = messaging
state['techStack']['search'] = merged_tech.get('search', [])
state['techStack']['infrastructure'] = merged_tech.get('infrastructure', [])
state['techStack']['additional'] = additional_ws

# Imported docs tracking
doc_files = [f for f in [$(printf '"%s",' "${DOC_FILES[@]}")] if f.strip()]
if doc_files and doc_files[0]:
    import os
    first_doc = os.path.basename(doc_files[0])
    first_name = os.path.splitext(first_doc)[0]
    state['importedDocs']['projectGuide'] = {
        "original": f"docs/tech-refs/{first_doc}",
        "extracted": f"docs/tech-refs/{first_name}-extracted.md",
        "importedAt": now
    }
    for phase_key in ['ideation','requirements','architecture','techSpecs','backlog']:
        phase_info = merged_phases.get(phase_key, {})
        if phase_info.get('covered'):
            state['importedDocs'][phase_key] = {
                "original": f"docs/tech-refs/{first_doc}",
                "extracted": f"docs/tech-refs/{first_name}-extracted.md",
                "importedAt": now
            }

# Phase auto-advance based on imports
# IMPORTANT: Imported docs are REFERENCE only — never mark as fully 'completed'.
# Even high-confidence imports need review and gap-filling via /sdlc init.
# At most, mark as 'in_progress' with source 'imported' or 'imported_partial'.
phase_map = {'ideation':'ideation','requirements':'requirements','architecture':'design','techSpecs':'design','backlog':'project_setup'}
for doc_key, phase_key in phase_map.items():
    if state.get('importedDocs', {}).get(doc_key):
        phase_info = merged_phases.get(doc_key, {})
        if phase_info.get('covered') and phase_info.get('confidence') == 'high':
            # High confidence = good starting point, but still needs review & questions
            state['phases'][phase_key]['status'] = 'in_progress'
            state['phases'][phase_key]['source'] = 'imported'
        elif phase_info.get('covered'):
            if state['phases'][phase_key]['status'] == 'pending':
                state['phases'][phase_key]['status'] = 'in_progress'
                state['phases'][phase_key]['source'] = 'imported_partial'

with open(state_path, 'w') as f:
    json.dump(state, f, indent=2)
    f.write('\n')

print(f'  Project: {state["project"]}')
PYEOF

rm -f "$STATE_TECH_TMP" "$STATE_PHASES_TMP" "$STATE_WS_TMP"
echo ""

# ==============================================================
# STEP 5: FINALIZE
# ==============================================================

echo -e "${YELLOW}Step 5/5: Finalizing...${NC}"

# Generate 06-tech-stack-context.md
bash "$PROJECT_DIR/scripts/generate-tech-context.sh" "$PROJECT_DIR" 2>&1 | sed 's/^/  /'

# Git init
cd "$PROJECT_DIR"
if git init -b main &>/dev/null; then
  echo -e "  ${GREEN}Git initialized (main)${NC}"
else
  git init &>/dev/null
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
fi

# Setup agents
[ -f scripts/setup-agents.sh ] && bash scripts/setup-agents.sh 2>&1 | sed 's/^/  /'

# Build stack summary
STACK_SUMMARY=""
[ -n "$FRONTEND" ] && STACK_SUMMARY="$FRONTEND"
[ -n "$BACKEND" ] && STACK_SUMMARY="${STACK_SUMMARY:+$STACK_SUMMARY / }$BACKEND"
WS_NAMES=$(echo "$ADDITIONAL_STACKS" | python3 -c "import sys,json; ws=json.load(sys.stdin); print(' / '.join(w['name'] for w in ws))" 2>/dev/null || echo "")
[ -n "$WS_NAMES" ] && STACK_SUMMARY="${STACK_SUMMARY:+$STACK_SUMMARY / }$WS_NAMES"
[ -z "$STACK_SUMMARY" ] && STACK_SUMMARY="No stack configured"

KIT_VERSION=$(python3 -c "import json; print(json.load(open('kit.json'))['version'])" 2>/dev/null || echo "2.0.0")

# Commit
git add -A
git commit -m "$(cat <<EOF
chore: scaffold from AI-SDLC MultiStack kit v${KIT_VERSION}

Project: ${PROJECT_NAME}
Stack: ${STACK_SUMMARY}
Docs imported: ${#DOC_FILES[@]}
EOF
)" &>/dev/null

echo -e "  ${GREEN}Initial commit created${NC}"
echo ""

# Summary
START_PHASE=$(python3 -c "
import json
with open('.sdlc/state.json') as f:
    s = json.load(f)
# Start at the first non-pending phase (imported docs create 'in_progress' phases)
# or the first pending phase if none are in_progress
for n in ['ideation','requirements','project_setup','design','development','testing','security','code_review','release']:
    status = s['phases'][n]['status']
    source = s['phases'][n].get('source')
    if status == 'in_progress' and source in ('imported', 'imported_partial'):
        print(n); break
    elif status == 'pending':
        print(n); break
else:
    print('ideation')
" 2>/dev/null || echo "ideation")

echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│                   Project Ready!                         │${NC}"
echo -e "${BLUE}├──────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}  Project:  ${GREEN}${PROJECT_NAME}${NC}"
echo -e "${BLUE}│${NC}  Location: ${GREEN}${PROJECT_DIR}${NC}"
echo -e "${BLUE}│${NC}  Kit:      ${GREEN}v${KIT_VERSION} (MultiStack)${NC}"
echo -e "${BLUE}│${NC}  Stack:    ${GREEN}${STACK_SUMMARY}${NC}"
[ ${#DOC_FILES[@]} -gt 0 ] && echo -e "${BLUE}│${NC}  Imported: ${GREEN}${#DOC_FILES[@]} document(s) (as reference)${NC}"
echo -e "${BLUE}│${NC}  Start:    ${GREEN}Phase: $START_PHASE${NC}"
echo -e "${BLUE}│${NC}"
if [ ${#DOC_FILES[@]} -gt 0 ]; then
  echo -e "${BLUE}│${NC}  ${YELLOW}Note:${NC} Imported docs are used as REFERENCE."
  echo -e "${BLUE}│${NC}  /sdlc init will review them, ask questions to"
  echo -e "${BLUE}│${NC}  ensure completeness, and generate standard docs."
  echo -e "${BLUE}│${NC}"
fi
echo -e "${BLUE}│${NC}  ${YELLOW}Next Steps:${NC}"
echo -e "${BLUE}│${NC}  ${GREEN}1.${NC} cd $PROJECT_DIR"
echo -e "${BLUE}│${NC}  ${GREEN}2.${NC} Review: docs/ and .claude/rules/06-tech-stack-context.md"
echo -e "${BLUE}│${NC}  ${GREEN}3.${NC} bash scripts/start-sdlc.sh"
echo -e "${BLUE}│${NC}  ${GREEN}4.${NC} /sdlc init $PROJECT_NAME"
echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
echo ""
