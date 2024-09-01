# Lad

A puzzle game.

Written in 1994 in x86 assembler for the NEC PC-9800 series.

![screenshot](img/screenshot.png)

## How to play

Execute `lad.com`.
I guess it requires `lstg.dat` in the current directory.

According to the source code, especially [key_tbl],

* cursor keys: move the character

* space: [switch the character] to move

* G: give up

* N: move to the next stage

* B: move to the previous stage

* J: [jump to a stage] (enter the number and hit RETURN)

* ESC: quit the game

The robot-like character (called `jos` in the source code) can only
move when the beam it hitting it. It can collect
the bombs. (the circle objects)

The human-like character (called `hks` in the source code) can only
move when the beam in NOT hitting it.

The objective of the game is to [collect all bombs] it seems.
(I have completely forgotten the existance of the `jcxz` instruction!
It was handy when hand-writing assembly.)

[key_tbl]: https://github.com/yamt/lad1994/blob/da3bf32a0f9a2425481b5a18580b3e7e84597829/lad/lad.asm#L286-L296

[switch the character]: https://github.com/yamt/lad1994/blob/da3bf32a0f9a2425481b5a18580b3e7e84597829/lad/lad.asm#L106

[jump to a stage]: https://github.com/yamt/lad1994/blob/da3bf32a0f9a2425481b5a18580b3e7e84597829/lad/lad.asm#L211

[collect all bombs]: https://github.com/yamt/lad1994/blob/da3bf32a0f9a2425481b5a18580b3e7e84597829/lad/lad.asm#L206-L207

In 2024, I was able to run it on an intel macbook with
[Neko Project II] and [FreeDOS(98)].

[Neko Project II]: https://www.yui.ne.jp/np2/

[FreeDOS(98)]: http://bauxite.sakura.ne.jp/software/dos/freedos.htm

I guess `mkladstg.com` is a stage editor. It seems to require a mouse.
I (in 2024) haven't tried it yet.

## The 2024 version

I ported this game to [WASM-4].
[The 2024 version] even has in-game tutorial stages so that
a player doesn't need to read the source code to see how to play!

[WASM-4]: https://wasm4.org/

[The 2024 version]: https://github.com/yamt/lad2024
