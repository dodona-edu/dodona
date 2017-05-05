#!/bin/bash

echo "[$(date)] Initiating dodona backup"

set -o pipefail -e

# ============================================================
# mounting (and unmounting) our backup directory

mount /mnt/backup
pushd /mnt/backup
trap 'popd && umount /mnt/backup' EXIT

# ============================================================
# rotate previous backups

calls="$([ -f calls ] && cat calls || true)"
calls="$((calls + 1))"
calls="$((calls % 28))"
echo "$calls" > calls

if (( calls % 14 == 0 )); then
    [ -e 28-days-ago ] && rm -rf 28-days-ago         || true
    [ -e 14-days-ago ] && mv 14-days-ago 28-days-ago || true
    [ -e 07-days-ago ] && mv 07-days-ago 14-days-ago || true
fi

if (( calls % 7 == 0 )); then
    [ -e 07-days-ago ] && rm -rf 07-days-ago         || true
    [ -e 06-days-ago ] && mv 06-days-ago 07-days-ago || true
fi

[ -e 06-days-ago ] && rm -rf 06-days-ago         || true
[ -e 05-days-ago ] && mv 05-days-ago 06-days-ago || true
[ -e 04-days-ago ] && mv 04-days-ago 05-days-ago || true
[ -e 03-days-ago ] && mv 03-days-ago 04-days-ago || true
[ -e 02-days-ago ] && mv 02-days-ago 03-days-ago || true
[ -e 01-days-ago ] && mv 01-days-ago 02-days-ago || true

# ============================================================
# create new backup

# dump-tables-mysql.sh
# Descr: Dump MySQL table data into separate SQL files for a specified database.
# Author: @Trutane, @Noctua
# Ref: http://stackoverflow.com/q/3669121/138325
user="dodona"
db="dodona"
pass="$(cat pass)"

mkdir 01-days-ago

echo "[$(date)] Dumping tables"

tbl_count=0

for t in $(mysql -NBA -u "$user" -p"$pass" -D "$db" -e 'show tables'); do
    echo "DUMPING TABLE: $db.$t"
    mysqldump --skip-extended-insert -u "$user" -p"$pass" "$db" "$t" | gzip > "01-days-ago/$t.sql.gz"
    tbl_count=$(( tbl_count + 1 ))
done

echo "$tbl_count tables dumped from database '$db'"

echo "[$(date)] Finished dodona backup"
