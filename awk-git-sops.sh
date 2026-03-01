#!/bin/sh
# git-sops.sh
# Usage: git-sops.sh encrypt|decrypt <file1> [file2 ...]

CMD="$1"
shift
[ -z "$CMD" ] && echo "Usage: $0 encrypt|decrypt <file...>" && exit 1

for FILE in "$@"; do
  [ ! -f "$FILE" ] && echo "File not found: $FILE" && continue

  # Определяем формат по расширению
  case "$FILE" in
    *.env) TYPE="dotenv" ;;
    *.yaml|*.yml) TYPE="yaml" ;;
    *.json) TYPE="json" ;;
    *) TYPE="binary" ;;
  esac

  if [ "$CMD" = "encrypt" ]; then
    # создаём имя файла с .sops перед расширением
    BASE=$(echo "$FILE" | sed 's/\(.*\)\.\(.*\)/\1/')
    EXT=$(echo "$FILE" | sed 's/\(.*\)\.\(.*\)/\2/')
    ENCRYPTED="$BASE.sops.$EXT"

    # проверка изменений
    if [ -f "$ENCRYPTED" ]; then
      TMP=$(mktemp)
      sops --decrypt --input-type "$TYPE" "$ENCRYPTED" > "$TMP"
      if diff -q "$FILE" "$TMP" >/dev/null 2>&1; then
        echo "No changes detected: $FILE"
        rm "$TMP"
        continue
      fi
      rm "$TMP"
    fi

    echo "Encrypting: $FILE -> $ENCRYPTED"
    sops --encrypt --input-type "$TYPE" --output-type "$TYPE" "$FILE" > "$ENCRYPTED"

  elif [ "$CMD" = "decrypt" ]; then
    # убираем .sops из имени
    case "$FILE" in
      *.sops.*) DECRYPTED=$(echo "$FILE" | sed 's/\.sops//') ;;
      *) echo "File does not contain .sops: $FILE"; continue ;;
    esac

    # определяем формат по расширению
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
