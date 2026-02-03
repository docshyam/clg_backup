#!/bin/sh

# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------
backup_dir="/root/backup.sss.updated/data"
script_dir="/root/backup.sss.updated/script"
last_file="${script_dir}/last_backed_up_sample_id.txt"
chunk_size=500
window_size=10000

CREDS_FILE="/directory_of_credential_file"

mysql_user=$(grep -E '^MYSQL_USER=' "$CREDS_FILE" | cut -d= -f2-)
mysql_pass=$(grep -E '^MYSQL_PASSWORD=' "$CREDS_FILE" | cut -d= -f2-)
mysql_host="127.0.0.1"
mysql_db="clg"

tables="LIST_OF_IMPORTANT_AND_FAST_GROWING_TABLES"

# ---------------------------------------------------------
# 1. Read last backed up sample_id
# ---------------------------------------------------------
last_backed_up=$(cat "$last_file")
echo "Last backed up sample_id: $last_backed_up"

# ---------------------------------------------------------
# 2. Determine new start point
# ---------------------------------------------------------
start_sample=$(( last_backed_up - window_size ))

# Do not allow negative values
if [ "$start_sample" -lt 0 ]; then
    start_sample=0
fi

# Round start_sample DOWN to nearest chunk size
start_sample=$(( start_sample - (start_sample % chunk_size) ))

echo "Backup will start from: $start_sample"

# ---------------------------------------------------------
# 3. Determine end point for new backup
# ---------------------------------------------------------
# Query database to get max sample_id
max_sample=$(mysql -h $mysql_host -u $mysql_user -p$mysql_pass \
    -N -e "select max(sample_id) from sample_link" $mysql_db)

echo "Max sample_id in DB: $max_sample"

# ---------------------------------------------------------
# Backup loop
# ---------------------------------------------------------
current=$start_sample

while [ "$current" -lt "$max_sample" ]; do
    
    next=$(( current + chunk_size ))

    echo "Backing up sample_id $current to $next ..."

    for table in $tables; do

        outfile="${backup_dir}/${table}.${current}_${next}.sql"

        mysqldump --replace -h $mysql_host -u $mysql_user -p$mysql_pass \
            $mysql_db $table \
            --where="sample_id between $current and $next" \
            > "$outfile"

    done

    current=$next
done

# ---------------------------------------------------------
# 4. Update last backup file
# ---------------------------------------------------------
echo "$max_sample" > "$last_file"
echo "Updated last backed up sample_id to $max_sample"

# ---------------------------------------------------------
# 5. Delete old files (older than last 10,000 sample_id)
# ---------------------------------------------------------
min_keep=$(( max_sample - window_size ))
if [ "$min_keep" -lt 0 ]; then
    min_keep=0
fi

echo "Deleting files older than sample_id $min_keep ..."

find "$backup_dir" -type f \
    -name "*.sql" \
    | while read f; do
        # Extract start number from filename
        n=$(echo "$f" | sed 's/.*\.\([0-9]\+\)_.*/\1/')
        if [ "$n" -lt "$min_keep" ]; then
            rm -f "$f"
        fi
    done

echo "Cleanup completed."
