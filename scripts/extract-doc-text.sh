#!/bin/bash
# extract-doc-text.sh — Extract text from .docx/.pdf/.txt/.md files into a readable .md
#
# Usage:
#   bash scripts/extract-doc-text.sh <input-file> <output-dir>
#
# Examples:
#   bash scripts/extract-doc-text.sh /path/to/guide.docx docs/tech-refs/
#   bash scripts/extract-doc-text.sh /path/to/spec.pdf docs/tech-refs/project/
#
# Supported formats:
#   .docx  → python3 zipfile+XML extraction
#   .pdf   → python3 (PyPDF2 if available, else basic extraction)
#   .md    → copy as-is
#   .txt   → copy as-is

set -e

INPUT_FILE="${1:-}"
OUTPUT_DIR="${2:-}"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: bash scripts/extract-doc-text.sh <input-file> <output-dir>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File not found: $INPUT_FILE"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Get filename without extension
BASENAME=$(basename "$INPUT_FILE")
NAME="${BASENAME%.*}"
EXT="${BASENAME##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

OUTPUT_FILE="$OUTPUT_DIR/${NAME}-extracted.md"

case "$EXT_LOWER" in
  docx)
    echo "Extracting text from .docx: $BASENAME"
    python3 << PYEOF
import zipfile
import xml.etree.ElementTree as ET
import os

input_file = '$INPUT_FILE'
output_file = '$OUTPUT_FILE'

try:
    z = zipfile.ZipFile(input_file)
    xml_content = z.read('word/document.xml')
    tree = ET.fromstring(xml_content)

    output = []
    ns_w = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'

    for elem in tree.iter():
        if elem.tag == ns_w + 't':
            if elem.text:
                output.append(elem.text)
        elif elem.tag == ns_w + 'p':
            output.append('\n')
        elif elem.tag == ns_w + 'tab':
            output.append('\t')
        elif elem.tag == ns_w + 'br':
            output.append('\n')

    text = ''.join(output).strip()

    with open(output_file, 'w') as f:
        f.write('# Extracted from: $BASENAME\n')
        f.write('> Auto-extracted by AI-SDLC MultiStack Kit\n\n')
        f.write(text)
        f.write('\n')

    print(f'  Extracted {len(text)} characters to {output_file}')
except Exception as e:
    print(f'  Warning: Could not extract text from .docx: {e}')
    with open(output_file, 'w') as f:
        f.write('# Extraction failed for: $BASENAME\n')
        f.write('> Please manually convert this document to markdown.\n')
PYEOF
    ;;

  pdf)
    echo "Extracting text from .pdf: $BASENAME"
    python3 << PYEOF
output_file = '$OUTPUT_FILE'
input_file = '$INPUT_FILE'
basename = '$BASENAME'

extracted = False

# Try PyPDF2 first
try:
    from PyPDF2 import PdfReader
    reader = PdfReader(input_file)
    text_parts = []
    for page in reader.pages:
        t = page.extract_text()
        if t:
            text_parts.append(t)
    text = '\n\n'.join(text_parts)
    if text.strip():
        with open(output_file, 'w') as f:
            f.write(f'# Extracted from: {basename}\n')
            f.write('> Auto-extracted by AI-SDLC MultiStack Kit (PyPDF2)\n\n')
            f.write(text)
            f.write('\n')
        print(f'  Extracted {len(text)} characters to {output_file}')
        extracted = True
except ImportError:
    pass
except Exception as e:
    print(f'  Warning: PyPDF2 extraction failed: {e}')

# Try pdfplumber as fallback
if not extracted:
    try:
        import pdfplumber
        with pdfplumber.open(input_file) as pdf:
            text_parts = []
            for page in pdf.pages:
                t = page.extract_text()
                if t:
                    text_parts.append(t)
        text = '\n\n'.join(text_parts)
        if text.strip():
            with open(output_file, 'w') as f:
                f.write(f'# Extracted from: {basename}\n')
                f.write('> Auto-extracted by AI-SDLC MultiStack Kit (pdfplumber)\n\n')
                f.write(text)
                f.write('\n')
            print(f'  Extracted {len(text)} characters to {output_file}')
            extracted = True
    except ImportError:
        pass
    except Exception as e:
        print(f'  Warning: pdfplumber extraction failed: {e}')

if not extracted:
    with open(output_file, 'w') as f:
        f.write(f'# Extraction requires PyPDF2 or pdfplumber: {basename}\n')
        f.write('> Install: pip3 install PyPDF2  OR  pip3 install pdfplumber\n')
        f.write('> Then re-run: bash scripts/extract-doc-text.sh <file> <output-dir>\n')
        f.write('> Or manually convert this PDF to markdown.\n')
    print(f'  Warning: No PDF library available. Install PyPDF2: pip3 install PyPDF2')
    print(f'  Created placeholder at {output_file}')
PYEOF
    ;;

  md|markdown)
    echo "Copying .md file: $BASENAME"
    cp "$INPUT_FILE" "$OUTPUT_FILE"
    echo "  Copied to $OUTPUT_FILE"
    ;;

  txt|text)
    echo "Converting .txt to .md: $BASENAME"
    {
      echo "# Extracted from: $BASENAME"
      echo "> Source: plain text file"
      echo ""
      cat "$INPUT_FILE"
    } > "$OUTPUT_FILE"
    echo "  Converted to $OUTPUT_FILE"
    ;;

  *)
    echo "Warning: Unsupported file format: .$EXT_LOWER"
    echo "  Supported: .docx, .pdf, .md, .txt"
    echo "  Copying file as-is to $OUTPUT_DIR/"
    cp "$INPUT_FILE" "$OUTPUT_DIR/"
    echo "  Please manually convert to markdown if needed."
    exit 0
    ;;
esac

# Output the path for callers to capture
echo "$OUTPUT_FILE"
