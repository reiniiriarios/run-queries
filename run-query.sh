#!/bin/bash
# Bash script for running queries against database and writing a csv file
# Author: Emma Litwa-Vulcu

thisdir="${BASH_SOURCE%/*}"
if [[ ! -d "$thisdir" ]]; then thisdir="$PWD"; fi
. "$thisdir/config.sh"

shopt -s nullglob
queries=(sql/*.sql)

errorexit() {
    echo -e "\033[31mError: $1\033[0m"
    exit 1
}

spin() {
    echo -en "\033[?25l"
    local -r pid="${1}"
    local sp=("/" "-" '\\' "|")
    local sc=0
    while ps a | awk '{print $1}' | grep -q "${pid}"; do
        printf "\r ${sp[$sc]}"
        let ++sc
        if [[ $sc = ${#sp[@]} ]]; then sc=0; fi
        sleep 0.05
    done
    echo -en "\r               \r"
    echo -en "\033[?25h"
}

echo -e "\033[35mRun Query Against Database\033[0m"
opt=1
for file in "${queries[@]}"; do
    query=${file##*/}
    query=${query%.sql}
    echo -e "[\033[32m$opt\033[0m] $query"
    let "opt+=1"
done
echo -en "\033[35mEnter number:\033[0m "

read choice
if ! [[ $choice =~ ^[0-9]+$ ]]; then
    errorexit "Invalid option, non-numeric value"
fi
let "choice-=1"

if [ -z ${queries[choice]} ]; then
    errorexit "Invalid option, option not found"
fi

filename=${queries[choice]##*/}
filename=${filename%.sql}

datetime=$(date +"%Y-%m-%d-%H%M%S")

sqlfile=sql/$filename.sql
tsvfile=tsv/$filename.$datetime.tsv
csvfile=csv/$filename.$datetime.csv

if [ ! -n "$filename" ]; then
	errorexit "Filename empty"
elif [ ! -f "$sqlfile" ]; then
	errorexit "File '$sqlfile' not found"
fi

echo -e "\033[36mRunning \033[33m$filename\033[36m...\033[0m"

sql=$(cat "$sqlfile" | sed 's/\r//g' | tr -s '\n' ' ' | tr -s '\t' ' ') || errorexit "Unable to read query"
# breaks on double quote in $sqlfile... so don't use those?

ssh -i "$sshkey" $sshuser@$sshhost "mysql -h $sqlhost -u $sqluser -p'$sqlpass' $sqldb -e \"$sql\"" > "$tsvfile" &
spin "$!"
if [ ! -f "$tsvfile" ]; then
    errorexit "Running SQL query over SSH failed"
fi

awk 'BEGIN { FS="\t"; OFS="," } {
  rebuilt=0
  for(i=1; i<=NF; ++i) {
    if ($i ~ /,/ && $i !~ /^".*"$/) { 
      gsub("\"", "\"\"", $i)
      $i = "\"" $i "\""
      rebuilt=1 
    }
  }
  if (!rebuilt) { $1=$1 }
  print
}' "$tsvfile" > "$csvfile" || errorexit "Error converting tsv to csv"

echo -e "\033[36mSaved to:\033[0m $csvfile"

echo -e "\033[32mDone\033[0m"
