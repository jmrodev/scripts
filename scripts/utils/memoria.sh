#!/bin/bash
#Check whether running as root
if [ "$(whoami)" = 'root' ]; then
  dmesg | grep "zswap:" | grep --silent "load"
  if [ $? -eq 0 ]; then
    # zswap is active
    echo "zswap information:"
    grep --recursive --color=none . /sys/kernel/debug/zswap/
    read -n 1 -s -r -p "Press any key to continue"
  else
    echo "[warning] zswap not active. Continuing"
  fi
else
  echo "[warning] Not running as root: skipping zswap info"
fi
for szFile in /proc/*/status ; do
  awk '/VmSwap|Name/{printf $2 "\t" $3}END{ print "" }' "$szFile"
done | sort --key 2 --numeric --reverse | more
