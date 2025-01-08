#!/bin/bash

# This scrips has been written by https://github.com/wbond
# https://github.com/wbond/mtmux/tree/master

if [[ -e ~/.mtmux/$1 ]]; then
    SERVERS=$(cat ~/.mtmux/$1)
    SESSION_NAME=$1
else
    SERVERS="$@"
    SESSION_NAME=mtmux-$(echo "$@" | shasum - | awk '{print $1}')
fi

tmux new-session -d -s $SESSION_NAME
shift
for SERVER in $SERVERS; do
    tmux split-window "${SSH_CMD:-ssh} $SERVER"
    tmux select-layout tiled
done
tmux kill-pane -t 0
tmux select-pane -t 0
tmux select-layout tiled
tmux bind-key m set-window-option synchronize-panes
tmux set-window-option synchronize-panes on
tmux attach -t $SESSION_NAME
