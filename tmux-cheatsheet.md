# tmux cheatsheet

Prefix: `Ctrl+]`

## Start/attach
```
tmux          new session
tmux attach   reconnect to existing
```

## Inside tmux (prefix = Ctrl+])
```
prefix + [     copy mode (scroll, search, yank)
prefix + d     detach (session keeps running)
prefix + c     new window
prefix + n/p   next/prev window
prefix + %     split vertical
prefix + "     split horizontal
prefix + o     cycle panes
prefix + hjkl  select pane by direction
prefix + q     show pane numbers, press # to jump
```

## Copy mode (after prefix + [)
```
hjkl / {}      navigate / paragraph jump
/              search
v              start selection
y              yank
q              exit copy mode
prefix + ]     paste
```
