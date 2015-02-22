#!/bin/bash

# This project uses lowercase variable names and otherwise aims to follow
# the Google Style Guide for shell scripts, found here:
# https://google-styleguide.googlecode.com/svn/trunk/shell.xml


# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Source config file or exit.
if [ -e ${mydir}/config.sh ]; then
  source ${mydir}/config.sh
else
  echo "Could not find required config file at ${mydir}/config.sh. Exiting." >&2
  exit 1
fi

ip_file="${mydir}/my_ip.txt"
log_file="${mydir}/log.txt"

touch "$ip_file"
stored_ip=$(cat "$ip_file")
live_ip=$(wget -O - -q --no-check-certificate --http-user="${http_user}" --http-passwd="${http_passwd}" "$my_ip_url");
 
if [[ "$live_ip" != "$stored_ip" ]]; then

  timestamp=$(date)
  echo "$timestamp: stored_ip: ${stored_ip}; live_ip: ${live_ip}"  >> "$log_file"

  tmpfile=$(mktemp)
  echo "server $ddns_server" >> "$tmpfile"
  echo "zone $ddns_zone" >> "$tmpfile"
  echo "update delete $ddns_domain A" >> "$tmpfile"
  echo "update add $ddns_domain 300 A $live_ip " >> "$tmpfile"
  echo "send" >> "$tmpfile"

  cmd="nsupdate -k \"${mydir}/${key_file}\" \"${tmpfile}\""
  echo "$timestamp: $cmd" >> "$log_file"
  echo "$timestamp: ====== START contents of $tmpfile" >> "$log_file"
  cat "$tmpfile" >> "$log_file"
  echo "$timestamp: ====== END contents of $tmpfile" >> "$log_file"

  eval "$cmd"
  ret=$?
  echo "$timestamp: above command exited with: $ret" >> "$log_file"

  if [[ "$ret" == "0" ]]; then
    echo "$live_ip" > "$ip_file"
  else
    exit 1
  fi
fi
