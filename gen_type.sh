#!/bin/bash

set -eu

for t in Ability BattleArts FindArts ActionArts NegotiationArts KnowledgeArts; do
  echo "$t* = ref object"
  awk -F , '$1=="'"$t"'"{print "  "$3"*: CValue    ## "$2}' key.csv
done
