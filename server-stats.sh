#!/bin/bash

# Improved server-stats.sh
# Author: Siddiq
# Description: Menyimpan status performa server ke log, dengan opsi notifikasi

# === Konfigurasi ===
LOGFILE="/var/log/server-stats.log"
MAX_LOG_SIZE=512000  # 500 KB
EMAIL="your@email.com"    # kosongkan jika tidak ingin
TELEGRAM_BOT=""
TELEGRAM_CHAT_ID=""

# === Warna Terminal ===
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  CYAN='\033[0;36m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  MAGENTA='\033[0;35m'
  NC='\033[0m'
else
  GREEN='' CYAN='' YELLOW='' RED='' MAGENTA='' NC=''
fi

SEPARATOR="=============================================================="
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# === Rotasi log sederhana ===
if [ -f "$LOGFILE" ] && [ "$(stat -c %s "$LOGFILE")" -gt "$MAX_LOG_SIZE" ]; then
  mv "$LOGFILE" "$LOGFILE.bak"
fi

# === Fungsi Output + Simpan ===
log() {
  echo -e "$@" | tee -a "$LOGFILE"
}

log "\n📅 Report Time: $NOW"
log "$SEPARATOR"
log "🖥️  OS Info"
log "$SEPARATOR"
log "$(lsb_release -d | cut -f2)"

log "\n$SEPARATOR"
log "⏱️  CPU Uptime"
log "$SEPARATOR"
log "$(uptime -p)"

log "\n$SEPARATOR"
log "💻 CPU Usage"
log "$SEPARATOR"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
log "Usage   : ${YELLOW}$CPU%${NC}"

log "\n$SEPARATOR"
log "🧠 Memory Usage"
log "$SEPARATOR"
free -m | awk -v Y="$YELLOW" -v NC="$NC" 'NR==2{
  total=$2; used=$3; free=$4;
  printf "Total Memory   : %.1f MB\nUsed Memory    : %.1f MB (%.1f%%)\nFree/Available : %.1f MB (%.1f%%)\n", total, used, used/total*100, free, free/total*100
}'

log "\n$SEPARATOR"
log "💽 Disk Usage"
log "$SEPARATOR"
df -h / | awk 'NR==2{
  printf "Disk Size      : %s\nUsed Space     : %s (%s)\nAvailable       : %s\n", $2, $3, $5, $4
}'

log "\n🔥 Top 5 Processes by CPU"
ps -eo user,pid,%cpu,%mem,command --sort=-%cpu | head -n 6 | tee -a "$LOGFILE"

log "\n🧠 Top 5 Processes by Memory"
ps -eo user,pid,%cpu,%mem,command --sort=-%mem | head -n 6 | tee -a "$LOGFILE"

log "$SEPARATOR"

# === Notifikasi Opsional ===

# Email
if [[ -n "$EMAIL" ]]; then
  mail -s "Server Status: $NOW" "$EMAIL" < "$LOGFILE"
fi

# Telegram
if [[ -n "$TELEGRAM_BOT" && -n "$TELEGRAM_CHAT_ID" ]]; then
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="📊 Server Stats Report - $NOW\nCPU: $CPU%" > /dev/null
fi

