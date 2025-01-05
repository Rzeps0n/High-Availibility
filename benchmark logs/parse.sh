#!/bin/bash

FILE="$1"

if [[ -z "$FILE" ]]; then
  echo "Usage: $0 <log-file>"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE"
  exit 1
fi

auto_downtime=$(grep "auto-increased downtime to continue migration:" "$FILE" | tail -n1 | sed 's/.*migration: //')
if [[ -z "$auto_downtime" ]]; then
  auto_downtime="100 ms"
fi
avg_mig_line=$(grep "average migration speed" "$FILE" | tail -n1)
avg_speed=$(echo "$avg_mig_line" | sed -n 's/.*average migration speed: \(.*\) - downtime.*/\1/p')
downtime=$(echo "$avg_mig_line" | sed 's/.*- downtime //' | tail -n1)
duration=$(grep "migration finished successfully" "$FILE" | sed -nE 's/.*migration finished successfully \(duration ([^)]*)\).*/\1/p')
out_of_parsed=$(grep "migration active" "$FILE" | head -n1 | sed -n 's/.*of \(.*\) VM-state.*/\1/p')

echo "Parsing file: $1"
echo ""
echo "VM Memory size: $out_of_parsed"
echo "(auto-increased) downtime cap: $auto_downtime"
echo "Downtime: $downtime"
echo "Migration duration: $duration"
echo "Average migration speed: $avg_speed"

echo -e "\nTransferred [GiB]\tSpeed [MiB/s]"

grep "migration active" "$FILE" | while read -r line; do
  parsed=$(echo "$line" | sed -nE 's/.*transferred ([0-9.]+) ([GMk]?i?B) of [0-9.]+ [GMk]?i?B VM-state, ([0-9.]+) ([GMk]?i?B\/s).*/\1 \2 \3 \4/p')

  [[ -z "$parsed" ]] && continue

  read transferred_val transferred_unit speed_val speed_unit <<< "$parsed"

  if [[ "$transferred_unit" == "MiB" ]]; then
    transferred_in_gib=$(awk -v val="$transferred_val" 'BEGIN { printf "%.4f", val / 1024 }')
  else
    transferred_in_gib="$transferred_val"
  fi

  if [[ "$speed_unit" == "GiB/s" ]]; then
    speed_in_mib=$(awk -v val="$speed_val" 'BEGIN { printf "%.4f", val * 1024 }')
  else
    speed_in_mib="$speed_val"
  fi

  echo -e "${transferred_in_gib}\t${speed_in_mib}"
done
