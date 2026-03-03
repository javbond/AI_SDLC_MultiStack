#!/bin/bash
# analyze-doc.sh — Document intelligence: detect tech stack, phase coverage, workspaces
#
# Usage:
#   bash scripts/analyze-doc.sh <extracted-md-file>
#
# Output: JSON to stdout with detected tech stack, phase coverage, and workspace suggestions
#
# Example:
#   bash scripts/analyze-doc.sh docs/tech-refs/project-guide-extracted.md
#   → outputs JSON with detected technologies, phases covered, workspaces

set -e

INPUT_FILE="${1:-}"

if [ -z "$INPUT_FILE" ]; then
  echo "Usage: bash scripts/analyze-doc.sh <extracted-md-file>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File not found: $INPUT_FILE"
  exit 1
fi

python3 - "$INPUT_FILE" << 'PYEOF'
import json
import re
import sys

input_file = sys.argv[1]

with open(input_file, 'r', errors='replace') as f:
    content = f.read()

content_lower = content.lower()

# ============================================================
# TECH STACK DETECTION
# ============================================================

tech_patterns = {
    "frontend": {
        "Angular": [r'\bangular\b', r'\bng\b\s*(build|serve|test)', r'\bngmodule\b', r'\bstandalone\s+component'],
        "React": [r'\breact\b', r'\bjsx\b', r'\bnext\.?js\b', r'\busestate\b', r'\buseeffect\b'],
        "Vue": [r'\bvue\b', r'\bvuex\b', r'\bnuxt\b', r'\bpinia\b'],
        "Svelte": [r'\bsvelte\b', r'\bsveltekit\b'],
    },
    "backend": {
        "Spring Boot": [r'\bspring\s*boot\b', r'\b@springbootapplication\b', r'\bspring\s*(mvc|data|security|cloud)\b'],
        "Node.js/Express": [r'\bexpress\b', r'\bnode\.?js\b.*\bexpress\b', r'\bapp\.listen\b'],
        "Node.js/NestJS": [r'\bnestjs\b', r'\b@nestjs\b', r'\b@controller\b.*\bnest\b'],
        "Go": [r'\bgo\b\s*(build|test|mod|run)', r'\bgolang\b', r'\bgoroutine\b', r'\bgin\b.*\bframework\b', r'\benvoy.*\bgo\b|\bgo.*\benvoy\b'],
        "Rust": [r'\brust\b', r'\bcargo\b', r'\bactix\b', r'\btokio\b'],
        "Python/Django": [r'\bdjango\b', r'\bdjango\s*rest\b'],
        "Python/FastAPI": [r'\bfastapi\b', r'\buvicorn\b'],
    },
    "languages": {
        "Java": [r'\bjava\s*\d', r'\bjava\b.*\bjdk\b', r'\bmaven\b', r'\bgradle\b', r'\b\.java\b'],
        "TypeScript": [r'\btypescript\b', r'\b\.ts\b', r'\btsconfig\b'],
        "Go": [r'\bgo\s*(1\.\d+|build|test|mod)', r'\bgolang\b', r'\b\.go\b'],
        "Rust": [r'\brust\b', r'\bcargo\.toml\b', r'\b\.rs\b'],
        "Python": [r'\bpython\s*3\b', r'\bpython\b.*\bpip\b', r'\brequirements\.txt\b'],
        "JavaScript": [r'\bjavascript\b', r'\bnode\.?js\b', r'\bnpm\b'],
    },
    "databases": {
        "PostgreSQL": [r'\bpostgres(ql)?\b', r'\bpg_\b'],
        "MySQL": [r'\bmysql\b', r'\bmariadb\b'],
        "MongoDB": [r'\bmongodb\b', r'\bmongo\b'],
        "Redis": [r'\bredis\b'],
        "ClickHouse": [r'\bclickhouse\b'],
        "Elasticsearch": [r'\belasticsearch\b', r'\belastic\b'],
        "DynamoDB": [r'\bdynamodb\b'],
    },
    "messaging": {
        "Kafka": [r'\bkafka\b', r'\bapache\s*kafka\b'],
        "RabbitMQ": [r'\brabbitmq\b', r'\bamqp\b'],
        "NATS": [r'\bnats\b'],
    },
    "infrastructure": {
        "Kubernetes": [r'\bkubernetes\b', r'\bk8s\b', r'\bhelm\b'],
        "Docker": [r'\bdocker\b', r'\bdockerfile\b'],
        "Envoy": [r'\benvoy\b', r'\bxds\b'],
        "Nginx": [r'\bnginx\b'],
        "Keycloak": [r'\bkeycloak\b'],
        "Terraform": [r'\bterraform\b'],
        "AWS": [r'\baws\b', r'\bamazon\s*web\b', r'\bec2\b', r'\bs3\b'],
        "GCP": [r'\bgcp\b', r'\bgoogle\s*cloud\b'],
        "Azure": [r'\bazure\b', r'\bmicrosoft\s*azure\b'],
    }
}

detected = {}
for category, techs in tech_patterns.items():
    detected[category] = {}
    for tech_name, patterns in techs.items():
        count = 0
        for pattern in patterns:
            count += len(re.findall(pattern, content_lower))
        if count > 0:
            detected[category][tech_name] = count

# Build final tech stack (only include items with significant mentions)
result_tech = {
    "frontend": [],
    "backend": [],
    "languages": [],
    "databases": [],
    "messaging": [],
    "search": [],
    "infrastructure": []
}

for tech, count in sorted(detected.get("frontend", {}).items(), key=lambda x: -x[1]):
    if count >= 1:
        result_tech["frontend"].append(tech)

for tech, count in sorted(detected.get("backend", {}).items(), key=lambda x: -x[1]):
    if count >= 2:  # Higher threshold for backend to avoid false positives
        result_tech["backend"].append(tech)

for tech, count in sorted(detected.get("languages", {}).items(), key=lambda x: -x[1]):
    if count >= 1:
        result_tech["languages"].append(tech)

for tech, count in sorted(detected.get("databases", {}).items(), key=lambda x: -x[1]):
    if count >= 1:
        result_tech["databases"].append(tech)

for tech, count in sorted(detected.get("messaging", {}).items(), key=lambda x: -x[1]):
    if count >= 1:
        result_tech["messaging"].append(tech)

# Separate search from databases
if "Elasticsearch" in result_tech["databases"]:
    result_tech["search"].append("Elasticsearch")
    result_tech["databases"].remove("Elasticsearch")

for tech, count in sorted(detected.get("infrastructure", {}).items(), key=lambda x: -x[1]):
    if count >= 1:
        result_tech["infrastructure"].append(tech)

# ============================================================
# PHASE COVERAGE DETECTION
# ============================================================

phase_patterns = {
    "ideation": {
        "keywords": [r'\bproduct\s*vision\b', r'\bproblem\s*statement\b', r'\btarget\s*audience\b',
                     r'\bvalue\s*proposition\b', r'\bmarket\s*(analysis|research)\b', r'\bexecutive\s*summary\b'],
        "required_for_complete": ["product vision", "problem statement"],
    },
    "requirements": {
        "keywords": [r'\bfunctional\s*requirement\b', r'\bnon-functional\s*requirement\b', r'\bnfr\b',
                     r'\buser\s*persona\b', r'\buse\s*case\b', r'\buser\s*stor(y|ies)\b',
                     r'\bprd\b', r'\bsuccess\s*metric\b', r'\bkpi\b', r'\bacceptance\s*criteria\b',
                     r'\brequirement\b.*\bfr-\d+\b'],
        "required_for_complete": ["functional requirement", "user persona"],
    },
    "architecture": {
        "keywords": [r'\bhigh-level\s*design\b', r'\bhld\b', r'\blow-level\s*design\b', r'\blld\b',
                     r'\bsystem\s*architecture\b', r'\bcomponent\s*diagram\b', r'\bdeployment\s*architecture\b',
                     r'\bmicroservice\b', r'\bbounded\s*context\b', r'\bdata\s*flow\b', r'\bsequence\s*diagram\b'],
        "required_for_complete": ["system architecture", "component"],
    },
    "techSpecs": {
        "keywords": [r'\bapi\s*(contract|spec|endpoint)\b', r'\bopenapi\b', r'\bswagger\b',
                     r'\bdb\s*schema\b', r'\bdatabase\s*schema\b', r'\bgrpc\b', r'\bproto\s*buf\b',
                     r'\bcreate\s*table\b', r'\bschema\.sql\b'],
        "required_for_complete": ["api"],
    },
    "backlog": {
        "keywords": [r'\bepic\b', r'\bsprint\s*plan\b', r'\bbacklog\b', r'\bstory\s*point\b',
                     r'\bsprint\s*\d+\b', r'\bmvp\s*(plan|phase)\b', r'\broadmap\b', r'\bmilestone\b'],
        "required_for_complete": ["sprint", "epic"],
    }
}

phase_coverage = {}
for phase, config in phase_patterns.items():
    matches = []
    total_count = 0
    for pattern in config["keywords"]:
        found = re.findall(pattern, content_lower)
        if found:
            matches.append(pattern)
            total_count += len(found)

    if total_count == 0:
        phase_coverage[phase] = {"covered": False, "confidence": "none", "matchCount": 0, "gaps": []}
    else:
        # Check required items
        gaps = []
        for req in config.get("required_for_complete", []):
            if not re.search(req.replace(" ", r"\s*"), content_lower):
                gaps.append(req)

        if total_count >= 5 and len(gaps) == 0:
            confidence = "high"
        elif total_count >= 2:
            confidence = "medium"
        else:
            confidence = "low"

        phase_coverage[phase] = {
            "covered": True,
            "confidence": confidence,
            "matchCount": total_count,
            "gaps": gaps
        }

# ============================================================
# WORKSPACE/COMPONENT DETECTION
# ============================================================

workspace_patterns = [
    (r'\bcontrol\s*plane\b', "Control Plane"),
    (r'\bdata\s*plane\b', "Data Plane"),
    (r'\badmin\s*(ui|dashboard|portal|console)\b', "Admin UI"),
    (r'\bapi\s*gateway\b', "API Gateway"),
    (r'\bedge\s*(proxy|server)\b', "Edge Proxy"),
    (r'\b(client|desktop|mobile)\s*agent\b', "Client Agent"),
    (r'\bworker\s*(service|process)\b', "Worker Service"),
    (r'\b(micro)?service[s]?\s*:\s*\n', "Microservices"),
]

workspaces = []
seen = set()
for pattern, name in workspace_patterns:
    if re.search(pattern, content_lower) and name not in seen:
        seen.add(name)
        # Try to detect which tech this workspace uses
        tech = "unknown"
        context_window = 500
        for match in re.finditer(pattern, content_lower):
            surrounding = content_lower[max(0, match.start()-context_window):match.end()+context_window]
            if re.search(r'\bgo\b', surrounding) or re.search(r'\bgolang\b', surrounding):
                tech = "Go"
            elif re.search(r'\bspring\b', surrounding) or re.search(r'\bjava\b', surrounding):
                tech = "Spring Boot"
            elif re.search(r'\bangular\b', surrounding):
                tech = "Angular"
            elif re.search(r'\benvoy\b', surrounding):
                tech = "Envoy"
            elif re.search(r'\brust\b', surrounding):
                tech = "Rust"
            elif re.search(r'\bnode\b', surrounding) or re.search(r'\bexpress\b', surrounding):
                tech = "Node.js"
            elif re.search(r'\bpython\b', surrounding):
                tech = "Python"

        # Suggest directory name
        dir_name = name.lower().replace(" ", "-")
        if name == "Admin UI":
            dir_name = "frontend"
        elif name == "Control Plane":
            dir_name = "backend"
        elif name in ("Data Plane", "Edge Proxy", "Client Agent", "API Gateway", "Worker Service"):
            dir_name = f"workspaces/{dir_name}"

        workspaces.append({
            "name": name,
            "technology": tech,
            "suggestedDir": dir_name
        })

# ============================================================
# OUTPUT
# ============================================================

result = {
    "techStack": result_tech,
    "phaseCoverage": phase_coverage,
    "workspaces": workspaces,
    "documentStats": {
        "totalCharacters": len(content),
        "totalLines": content.count('\n'),
        "totalWords": len(content.split())
    }
}

print(json.dumps(result, indent=2))
PYEOF
