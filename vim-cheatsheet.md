# Basics


Lookup "vimbegood" program from the primagen to practice



## Three modes
**Inser**: write
**Visual**: select
**Cmd**: to quit save search etc.

## Basic motions
Use relative line numbers
h,j,k,l
number prefix
w,b

a,i
A,I
o,O


Dont use nb + w/b too complex
Instead use f,F,t,T


**important**: vim is all about cmd + nb + motion
e.g
d3k
23k
v2fu


## Quick delete
Delete three next lines: d 3 j
dd
db, dw etc.

## un re do
u or ctrl+r


## Visual mode
v: visual mode to select bits of lines
ishift + v: visual line mode


## yanking (copy paste)
y = copy
p = paste

y in v-mode appends to cursor
y from vl-mode creates a new line


ALL DELETE SENT TO YANK BUFFER

you can paste over a selected region
yy to yank line
go to other line
ctrl+v to select line
p to past: line replaced
OLD LINE NOW IN YANK BUFFER


### duplicate a block
"select the next 5 lines including this current one and paste it later"
y5j
motion
p



### copy/cut mental model
cut paste = d p
copy paste = y p

Because delete and copy go to the same buffer


# Level 2
[https://www.youtube.com/watch?v=5JGVtttuDQA&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R&index=2](https://www.youtube.com/watch?v=5JGVtttuDQA&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R&index=2)

## Motions
_ end
$ beginning statement
0 beginning line

f,F,t,T
; to repeat forwards
, to repeat backwards






# Level 3
https://www.youtube.com/watch?v=KfENDDEpCsI&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R&index=3

## Motions
{,} move by paragraph (empty lines)

ctrl+d / ctrl-u: scroll half page up / down

zz: recenter the view

g, gg


Look into remapping to "zz" to automatically recenter the view


## move to line
cmd: :line number

## searching
cmd :/whathever
then n to move, shift n


search backwards with ? instead of /

think of integrating with zz

## fast search
* sign to automaticall search curret word
/# for backwords search


# Level 4
[https://www.youtube.com/watch?v=qZO9A5F6BZs&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R&index=4](https://www.youtube.com/watch?v=qZO9A5F6BZs&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R&index=4)


