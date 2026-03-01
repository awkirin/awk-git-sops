#!/usr/bin/env bash
# ~/.local/bin/awk-sops
# Usage: awk-sops encrypt|decrypt <file1> [file2 ...]
# CLI для sops с проверкой изменений

set -euo pipefail

CMD="${1:-}"
shift || true
[ -z "$CMD" ] && { echo "Usage: $0 encrypt|decrypt <file1> [file2 ...]"; exit 1; }

# Проверка изменений без учета метаданных sops
check_changes() {
    local FILE="$1"
    local ENCRYPTED="$2"
    local TYPE="$3"

    local TMP=$(mktemp)
    sops --decrypt --input-type "$TYPE" "$ENCRYPTED" > "$TMP"

    local RES=1

    case "$TYPE" in
      dotenv)
        TMP_SORT=$(mktemp)
        TMP_SORT2=$(mktemp)
        sort "$FILE" > "$TMP_SORT"
        sort "$TMP" > "$TMP_SORT2"
        diff -q "$TMP_SORT" "$TMP_SORT2" >/dev/null 2>&1 && RES=0 || RES=1
        rm -f "$TMP_SORT" "$TMP_SORT2"
        ;;
      yaml)
        if command -v yq >/dev/null 2>&1; then
          TMP_YAML1=$(mktemp)
          TMP_YAML2=$(mktemp)
          yq eval -o=json "$FILE" > "$TMP_YAML1"
          yq eval -o=json "$TMP" > "$TMP_YAML2"
          diff -q "$TMP_YAML1" "$TMP_YAML2" >/dev/null 2>&1 && RES=0 || RES=1
          rm -f "$TMP_YAML1" "$TMP_YAML2"
        else
          diff -q "$FILE" "$TMP" >/dev/null 2>&1 && RES=0 || RES=1
        fi
        ;;
      json)
        if command -v jq >/dev/null 2>&1; then
          TMP_JSON1=$(mktemp)
          TMP_JSON2=$(mktemp)
          jq -S . "$FILE" > "$TMP_JSON1"
          jq -S . "$TMP" > "$TMP_JSON2"
          diff -q "$TMP_JSON1" "$TMP_JSON2" >/dev/null 2>&1 && RES=0 || RES=1
          rm -f "$TMP_JSON1" "$TMP_JSON2"
        else
          diff -q "$FILE" "$TMP" >/dev/null 2>&1 && RES=0 || RES=1
        fi
        ;;
      *)
        diff -q "$FILE" "$TMP" >/dev/null 2>&1 && RES=0 || RES=1
        ;;
    esac

    rm -f "$TMP"
    return $RES
}

for FILE in "$@"; do
  [ ! -f "$FILE" ] && { echo "File not found: $FILE"; continue; }

  case "$FILE" in
    *.env) TYPE="dotenv" ;;
    *.yaml|*.yml) TYPE="yaml" ;;
    *.json) TYPE="json" ;;
    *) TYPE="binary" ;;
  esac

  if [ "$CMD" = "encrypt" ]; then
    BASE="${FILE%.*}"
    EXT="${FILE##*.}"
    ENCRYPTED="$BASE.sops.$EXT"

    if [ -f "$ENCRYPTED" ]; then
      if check_changes "$FILE" "$ENCRYPTED" "$TYPE"; then
        echo "No changes detected: $FILE"
        continue
      fi
    fi

    echo "Encrypting: $FILE -> $ENCRYPTED"
    sops --encrypt --input-type "$TYPE" --output-type "$TYPE" "$FILE" > "$ENCRYPTED"

  elif [ "$CMD" = "decrypt" ]; then
    case "$FILE" in
      *.sops.*) DECRYPTED="${FILE/.sops/}" ;;
      *) echo "File does not contain .sops: $FILE"; continue ;;
    esac

    case "$DECRYPTED" in
      *.env) TYPE="dotenv" ;;
      *.yaml|*.yml) TYPE="yaml" ;;
      *.json) TYPE="json" ;;
      *) TYPE="binary" ;;
    esac

    echo "Decrypting: $FILE -> $DECRYPTED"
    sops --decrypt --input-type "$TYPE" --output-type "$TYPE" "$FILE" > "$DECRYPTED"

  else
    echo "Unknown command: $CMD"
    exit 1
  fi
done
