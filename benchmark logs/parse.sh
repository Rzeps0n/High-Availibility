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

# Parse the auto-downtime
auto_downtime=$(grep "auto-increased downtime to continue migration:" "$FILE" | tail -n1 | sed 's/.*migration: //')
[[ -z "$auto_downtime" ]] && auto_downtime="100 ms"

# Parse average speed and downtime
avg_mig_line=$(grep "average migration speed" "$FILE" | tail -n1)
avg_speed=$(echo "$avg_mig_line" | sed -n 's/.*average migration speed: \(.*\) - downtime.*/\1/p')
downtime=$(echo "$avg_mig_line" | sed 's/.*- downtime //' | tail -n1)

# Parse duration
duration=$(grep "migration finished successfully" "$FILE" \
  | sed -nE 's/.*migration finished successfully \(duration ([^)]*)\).*/\1/p')

# Parse VM memory size (e.g., "16.0 GiB")
out_of_parsed=$(grep "migration active" "$FILE" | head -n1 \
  | sed -n 's/.*of \(.*\) VM-state.*/\1/p')

# If you want to remove the ".0", use awk:
mem_gib=$(echo "$out_of_parsed" | awk '{printf "%.f", $1}')

##############################
# Print summary information #
##############################
echo -e "Parsing file:\t$1"

echo -e "VM Memory size:\t${mem_gib}\tGiB"
echo -e "(auto-increased) downtime cap:\t${auto_downtime%\ ms}\tms"
echo -e "Downtime:\t${downtime%\ ms}\tms"
echo -e "Migration duration:\t$duration"
echo -e "Average migration speed:\t${avg_speed%\ GiB/s}\tGiB/s"

echo -e "\nTransferred [GiB]\tSpeed [MiB/s]"

#######################################
# Parse and convert transferred speed #
#######################################
grep "migration active" "$FILE" | while read -r line; do
  parsed=$(echo "$line" | sed -nE \
    's/.*transferred ([0-9.]+) ([GMk]?i?B) of [0-9.]+ [GMk]?i?B VM-state, ([0-9.]+) ([GMk]?i?B\/s).*/\1 \2 \3 \4/p')

  [[ -z "$parsed" ]] && continue

  read transferred_val transferred_unit speed_val speed_unit <<< "$parsed"

  # Convert transferred to GiB if reported in MiB
  if [[ "$transferred_unit" == "MiB" ]]; then
    transferred_in_gib=$(awk -v val="$transferred_val" 'BEGIN { printf "%.4f", val / 1024 }')
  else
    transferred_in_gib="$transferred_val"
  fi

  # Convert speed to MiB/s if reported in GiB/s
  if [[ "$speed_unit" == "GiB/s" ]]; then
    speed_in_mib=$(awk -v val="$speed_val" 'BEGIN { printf "%.4f", val * 1024 }')
  else
    speed_in_mib="$speed_val"
  fi

  echo -e "${transferred_in_gib}\t${speed_in_mib}"
done
