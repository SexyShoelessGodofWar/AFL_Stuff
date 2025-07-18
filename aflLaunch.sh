#!/usr/bin/env bash
#
#  launch_afl_tmux.sh  –  spin up 1 master + 30 slave afl-fuzz instances
#                         each in its own tmux window.
#
#  environment overrides
#    SESSION   – tmux session name            (default: afl_fuzz)
#    IN_DIR    – corpus directory             (default: ./input_corpus)
#    OUT_DIR   – afl output directory         (default: ./output_findings)
#    TARGET    – fuzz target binary           (default: none, must be specified)
#    SLAVES    – number of slave instances    (default: 30)
#
#  AFL_USE_ASAN=1 afl-fuzz -i input_corpus -o findings -- ./fuzz_target @@  #
#
#  For persistent mode, the @@ is superfluous but can be included anyway.

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -s SESSION     tmux session name (default: afl_fuzz)
  -i IN_DIR      corpus directory (default: ./input_corpus)
  -o OUT_DIR     afl output directory (default: ./output_findings)
  -t TARGET      fuzz target binary (required)
  -n SLAVES      number of slave instances (default: 30)
  -h             display this help and exit

All instances auto-restart if they exit.
EOF
    exit 0
}

# Parse command line options
while getopts ":s:i:o:t:n:h" opt; do
    case ${opt} in
        s) SESSION="$OPTARG" ;;
        i) IN_DIR="$OPTARG" ;;
        o) OUT_DIR="$OPTARG" ;;
        t) TARGET="$OPTARG" ;;
        n) SLAVES="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Set defaults if not provided
SESSION=${SESSION:-afl_fuzz}
IN_DIR=${IN_DIR:-./input_corpus}
OUT_DIR=${OUT_DIR:-./output_findings}
SLAVES=${SLAVES:-30}
AFL_ENV="AFL_USE_ASAN=1"      # add more env flags here if you need them
WATCHDOG_SLEEP=5              # seconds between restarts

# TARGET must be specified
if [ -z "${TARGET:-}" ]; then
    echo "ERROR: TARGET must be specified with -t"
    usage
fi

[[ -x "$TARGET" ]] || { echo "ERROR: target '$TARGET' not found or not executable"; exit 1; }

# Create session (detached) if it doesn't exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session  -d -s "$SESSION" -n master
else
    echo "[*] Re-using existing tmux session '$SESSION'"
fi

# helper → build the long command line once
afl_cmd () {
  local role=$1
  shift
  echo "$AFL_ENV afl-fuzz $role -i \"$IN_DIR\" -o \"$OUT_DIR\" -- \"$TARGET\" @@"
}

# ---- master ----------------------------------------------------------------
tmux send-keys  -t "$SESSION:master" \
  "while true; do $(afl_cmd '-M master'); echo '[master] crashed – restarting in $WATCHDOG_SLEEP s'; sleep $WATCHDOG_SLEEP; done" C-m

# ---- slaves ----------------------------------------------------------------
for n in $(seq -w 1 "$SLAVES"); do
    win="s$n"
    tmux new-window   -t "$SESSION" -n "$win"
    tmux send-keys    -t "$SESSION:$win" \
      "while true; do $(afl_cmd "-S slave$n"); echo '[slave$n] crashed – restarting in $WATCHDOG_SLEEP s'; sleep $WATCHDOG_SLEEP; done" C-m
done

# Put focus back on the master window
tmux select-window -t "$SESSION:master"

cat <<EOF

[+] tmux session '$SESSION' launched
    1 master   window : master
    $SLAVES slave windows : s01 … s$(printf "%02d" "$SLAVES")

Attach with:
    tmux attach -t $SESSION

Hop through fuzzers:
    Ctrl-b  n   (next window)
    Ctrl-b  p   (previous window)

All instances auto-restart if they exit.
EOF
