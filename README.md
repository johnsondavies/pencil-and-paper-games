# Pencil and paper games
These are the Lisp programs used to implement the game playing features of my website [Pencil and Paper Games](http://www.papg.com/). You can run them in the Listener in any Common Lisp implementation.

## Table of contents
* [Go-Moku](#go-moku)
* [Obstruction](#obstruction)
* [3D Noughts and Crosses](#3dox)


## Go-Moku
The game is played on a large piece of squared paper, at least 15 x 15. The players take turns in marking a square with their symbol (eg O and X). The first player to get five squares in a row, horizontally, vertically, or diagonally, wins.

#### The interface
````text
O to  move: i7

   A B C D E F G H I J K L M N O (-13) (13)
 1 . . . . . . . . . . . . . . . 
 2 . . . . . . . . . . . . . . . 
 3 . . . . . . . . . . . . . . . 
 4 . . . . . . . . . . . . . . . 
 5 . . . . . . . . . . . . . . . 
 6 . . . . . . . . X . O . . . . 
 7 . . . . . . O O O X . . . . . 
 8 . . . . . . O O X . . . . . . 
 9 . . . . . . . X X . . . . . . 
10 . . . . . . X . . . . . . . . 
11 . . . . . O . . . . . . . . . 
12 . . . . . . . . . . . . . . . 
13 . . . . . . . . . . . . . . . 
14 . . . . . . . . . . . . . . . 
15 . . . . . . . . . . . . . . . 

````
#### Running the program

Load the file **gomoku.lisp**. Then evaluate the following commands in the Listener:

    (in-package :gomoku)
    (gomoku #'human (alpha-beta-searcher 3 #'count-difference))
    
You are 'O' and you start. You should give your move as a grid reference such as H7. 

If you want to make it easy to beat the computer try:

    (gomoku #'human (alpha-beta-searcher 3 #'random-strategy))

## Obstruction
The game is played on a grid; 6 x 6 is a good size. One player is 'O' and the other is 'X'.

Players take turns in writing their symbol in a cell. The restriction is that you can only play in a cell if all its neighbours are empty; the available cells are shown as dots on the printed board.

The first player unable to move loses.

#### The interface
````text
O to move: c1

  A B C D E F (0) (0)
1 O   O       
2           X 
3 .           
4 .   O   O   
5             
6 X   . .   X 
````
#### Running the program

Load the file **obstruction.lisp**. Then evaluate the following commands in the Listener:

    (in-package :obstruction)
    (obstruction #'human (alpha-beta-searcher 3 #'static-evaluation))
    
You are 'O' and you start. You should give your move as a grid reference such as D3. 

If you want to make it easy to beat the computer try:

    (obstruction #'human (alpha-beta-searcher 3 #'random-strategy))
    
## 3D Noughts and Crosses
The game is played on a 4 x 4 x 4 board, represented by four 4 x 4 grids in a row.

The players take turns in drawing their symbol, O or X, in one of the cells. The first player to make a line of four cells in any direction wins. Winning lines can be horizontal, vertical, diagonal within one grid, vertical between grids, diagonal between grids, or diagonal in all three dimensions.

#### The interface
````text
O to  move: e3
  A B C D    E F G H    I J K L    M N O P (-9140) (-8860)
1 . . . X    . . . .    . . . .    . . . .    
2 . . . O    . . . .    . . . .    . . . .    
3 O O . X    O O . O    . O O X    . X . X    
4 . . . X    . . . .    . . . .    . . . X  
````
#### Running the program

Load the file **3dox.lisp**. Then evaluate the following commands in the Listener:

    (in-package :3dox)
    (3dox #'human (alpha-beta-searcher 3 #'count-difference))
    
You are 'O' and you start. You should give your move as a grid reference such as J3. 

If you want to make it easy to beat the computer try:

    (3dox #'human (alpha-beta-searcher 3 #'random-strategy))

