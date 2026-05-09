#!/usr/bin/env bash
set -e

CORRECT=${1:-"bug"}  # "correct" для корректного варианта

echo "=== Собираем Go-приложение ==="
go build -o shutdown_demo .

echo ""
echo "=== Запускаем с режимом: $CORRECT ==="
echo "    (Ctrl+C через 1 секунду симулируется автоматически)"

if [ "$CORRECT" = "correct" ]; then
    ./shutdown_demo --correct &
else
    ./shutdown_demo &
fi

PID=$!
sleep 1
kill -TERM $PID
wait $PID 2>/dev/null || true

echo ""
echo "=== Трейс (trace.ndjson) ==="
cat trace.ndjson

echo ""
echo "=== Запускаем TLC trace-валидацию ==="

# Ищем tlc в стандартных местах
TLC_JAR=""
for p in \
    "$HOME/tla2tools.jar" \
    "/usr/local/lib/tla2tools.jar" \
    "$(dirname "$(which tlc 2>/dev/null)" 2>/dev/null)/../lib/tla2tools.jar" \
    ""; do
    [ -f "$p" ] && TLC_JAR="$p" && break
done

if [ -z "$TLC_JAR" ]; then
    echo "tla2tools.jar не найден."
    echo "Скачай: https://github.com/tlaplus/tlaplus/releases"
    echo "Положи в ~/tla2tools.jar и запусти снова."
    exit 1
fi

# Community Modules нужны для ndJsonDeserialize
CM_JAR=""
for p in \
    "$HOME/CommunityModules-deps.jar" \
    "/usr/local/lib/CommunityModules-deps.jar" \
    ""; do
    [ -f "$p" ] && CM_JAR="$p" && break
done

if [ -z "$CM_JAR" ]; then
    echo "CommunityModules-deps.jar не найден."
    echo "Скачай: https://github.com/tlaplus/CommunityModules/releases"
    echo "Положи в ~/CommunityModules-deps.jar и запусни снова."
    exit 1
fi

java -cp "$TLC_JAR:$CM_JAR" tlc2.TLC \
    -config TraceValidation.cfg \
    -workers auto \
    TraceValidation.tla

echo ""
echo "=== Готово ==="
