#!/bin/bash
mkdir -p alignments/recombining
grep 'PHI (Normal):' alignments/*.philog | cut -f1,3 -d':' | sed 's/.philog://' | sort -g -k2 |  awk '$2 < 0.05 && $2!= "--"' |  cut -f1 -d' ' | sort -u | xargs -I{} mv {}.fas alignments/recombining/
