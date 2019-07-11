#!/bin/bash

set -eu

echo "var arts: Table[string, int]"
for t in BattleArts FindArts ActionArts NegotiationArts KnowledgeArts; do
  awk -F , '$1=="'"$t"'"{print "arts = html.parseArts(\""$4"\")"; exit}' key.csv
  echo "var $t = new $t"
  awk -F , '$1=="'"$t"'"{print "'$t'."$3" = CValue(name: \""$2"\", num: arts[\""$2"\"])"}' key.csv
  echo
done
