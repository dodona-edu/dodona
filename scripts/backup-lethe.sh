#!/bin/bash

# dump-tables-mysql.sh
# Descr: Dump MySQL table data into separate SQL files for a specified database.
# Usage: Run without args for usage info.
# Author: @Trutane, @Noctua
# Ref: http://stackoverflow.com/q/3669121/138325

set -o pipefail -e

mount /mnt/backup
trap 'umount /mnt/backup' EXIT

user="dodona"
db="dodona"

dumpdir="/mnt/backup/$(date +"%Y-%m-%d %H:%M:%S")"
mkdir "$dumpdir"

pass="$(cat $(dirname $0)/pass)"

echo "Dumping tables into separate SQL command files for database '$db' into $dumpdir"

tbl_count=0

for t in $(mysql -NBA -u "$user" -p"$pass" -D "$db" -e 'show tables'); do
    echo "DUMPING TABLE: $db.$t"
    mysqldump -u "$user" -p"$pass" "$db" "$t" | gzip > "$dumpdir/$t.sql"
    tbl_count=$(( tbl_count + 1 ))
done

echo "$tbl_count tables dumped from database '$db' into $dumpdir"
