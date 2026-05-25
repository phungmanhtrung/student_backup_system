#!/bin/bash
cd /student_backup_system

# ===== CONFIG =====
BACKUP_DIR="./backups"
DATA_DIR="./data"
LOG_FILE="./logs/backup.log"
MAX_BACKUPS=5

# ===== FUNCTIONS =====

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_internet() {
    echo "Checking internet connection..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "Internet connection OK."
        log_message "Internet check: OK"
    else
        echo "No internet connection."
        log_message "Internet check: FAIL"
    fi
}

perform_backup() {
    mkdir -p "$BACKUP_DIR"

    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

    echo "Compressing data..."
    if tar -czf "$BACKUP_FILE" "$DATA_DIR" 2>/dev/null; then
        echo "Backup successful: $BACKUP_FILE"
        log_message "Backup successful: $BACKUP_FILE"
    else
        echo "Backup failed!"
        log_message "Backup failed"
        return 1
    fi

    echo "Cleaning old backups, keeping $MAX_BACKUPS latest..."
    cd "$BACKUP_DIR" || return
    ls -t *.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -f
    cd - > /dev/null
    log_message "Cleaned old backups (kept $MAX_BACKUPS)."
}

list_backups() {
    echo "Backup list in $BACKUP_DIR:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "(no backup files)"
    else
        echo "(empty or missing directory)"
    fi
}

view_log() {
    echo "Log content ($LOG_FILE):"
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "No log yet."
    fi
}

# ===== MENU =====
show_menu() {
    clear
    echo "       STUDENT BACKUP SYSTEM          "
    echo "1. Backup data"
    echo "2. View backup list"
    echo "3. View log"
    echo "4. Check internet"
    echo "5. Push to GitHub (bonus)"
    echo "6. Exit"
    echo -n "Select option [1-6]: "
}

# ===== MAIN =====
if [ "$1" == "auto" ]; then
    log_message "===== Auto backup started ====="
    check_internet
    perform_backup
    log_message "===== Auto backup finished ====="
    exit 0
fi

while true; do
    show_menu
    read choice
    case $choice in
        1) perform_backup ;;
        2) list_backups ;;
        3) view_log ;;
        4) check_internet ;;
        5) 
            echo "Pushing to GitHub..."
            git add -A
            git commit -m "Auto backup and update $(date)" 2>/dev/null
            git push origin main 2>/dev/null && echo "Push successful." || echo "Push failed."
            ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
    echo ""
    echo "Press Enter to continue..."
    read -r
done
