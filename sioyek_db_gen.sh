#!/bin/bash


PDFs="$HOME/PDFs"
TTRPGs="$HOME/Downloads/TTRPGs"
SIOYEK="$HOME/.local/share/sioyek"
LOCALDB="$SIOYEK/local.db"
SHAREDDB="$SIOYEK/shared.db"

#backup just in case
[[ -f "$LOCALDB" ]] && cp "$LOCALDB" "$LOCALDB.backup"
[[ -f "$SHAREDDB" ]] && cp "$SHAREDDB" "$SHAREDDB.backup" 

echo "Compiling PDF list..."
mapfile -t FILES < <( ( find $PDFs -type f -iregex "^.*\.pdf$" -printf "$PDFs/%P\n"; find $TTRPGs -type f -iregex "^.*\.pdf$" -printf "$TTRPGs/%P\n" ) | cat | sort --version-sort )

# save against collision errors
echo "Calculating file hashes..."

i=0
mapfile -t HASHES < <( for FILE in "${FILES[@]}"; do md5sum "$FILE" | cut -d' ' -f1 ; done )



echo "Creating database..."
sqlite3 "$LOCALDB" "drop table if exists document_hash;"
sqlite3 "$LOCALDB" "create table if not exists document_hash (id INTEGER PRIMARY KEY AUTOINCREMENT,path TEXT,hash TEXT);"

sqlite3 "$SHAREDDB" "create table if not exists bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT,document_path TEXT,desc TEXT,offset_y REAL);"
sqlite3 "$SHAREDDB" "create table if not exists highlights (id INTEGER PRIMARY KEY AUTOINCREMENT,document_path TEXT,desc TEXT,type CHAR, begin_x REAL,begin_y REAL,end_x REAL, end_y REAL);"
sqlite3 "$SHAREDDB" "create table if not exists links (id INTEGER PRIMARY KEY AUTOINCREMENT,src_document TEXT,dst_document TEXT,src_offset_y REAL,dst_offset_x REAL,dst_offset_y REAL,dst_zoom_level REAL);"
sqlite3 "$SHAREDDB" "create table if not exists marks (id INTEGER PRIMARY KEY AUTOINCREMENT,document_path TEXT,symbol CHAR,offset_y REAL,UNIQUE(document_path, symbol));"

sqlite3 "$SHAREDDB" "drop table if exists opened_books;"
sqlite3 "$SHAREDDB" "create table opened_books (id INTEGER PRIMARY KEY AUTOINCREMENT,path TEXT UNIQUE,zoom_level REAL,offset_x REAL,offset_y REAL,last_access_time TEXT);"

i=0
for FILE in "${FILES[@]}"; do
        FILE=$( echo "$FILE" | sed -r "s|'|''|g" )
        DATE=$( shuf -n1 -i$(date -d '1987-01-01' '+%s')-$(date '+%s') | xargs -I{} date -d '@{}' '+%Y-%m-%d %H:%M:%S' )
        echo $FILE
        sqlite3 "$LOCALDB"  "insert into document_hash (path, hash) values ('$FILE', '${HASHES[i]}');"
        sqlite3 "$SHAREDDB"  "insert into opened_books (path, zoom_level, offset_x, offset_y, last_access_time) values ('${HASHES[i]}', 1.5, 0, 300, '$DATE');"
        ((i++))
done

echo "Done."