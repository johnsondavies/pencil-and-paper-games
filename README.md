# Pencil and paper games
Common Lisp programs to play pencil and paper games.

These are the Lisp programs used to implement the game playing features of my website **Pencil and Paper Games**. You can run them in the Listener in any Common Lisp implementation.

## Table of contents
* [Go-Moku](#go-moku)
* [Obstruction](#obstruction)


## Go-Moku
The game is played on a large piece of squared paper, at least 15 x 15. The players take turns in marking a square with their symbol (eg O and X). The first player to get five squares in a row, horizontally, vertically, or diagonally, wins.

## Obstruction
The game is played on a grid; 6 x 6 is a good size. One player is 'O' and the other is 'X'.

Players take turns in writing their symbol in a cell. The restriction is that you can only play in a cell if all its neighbours are empty (shown shaded in the following diagrams).

The first player unable to move loses.

O to  move: f1
  A B C D E F (0) (0)
1 . . . . _ O 
2 . . . . _ _ 
3 . _ _ _ . . 
4 . _ O _ _ _ 
5 . _ _ _ X _ 
6 . . . _ _ _ 

