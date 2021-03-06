;;;-*- Mode: Lisp; Package: obstruction -*-

(in-package :obstruction)

; David Johnson-Davies - 10th May 2020
; Licensed under the MIT license: https://opensource.org/licenses/MIT

; To play the game in the listener evaluate:
; (in-package :obstruction)
; (obstruction #'human (alpha-beta-searcher 3 #'static-evaluation))

;
; Obstruction
;

(defparameter empty 0 "An empty square")
(defparameter black 1 "A black move")
(defparameter white 2 "A white move")
(defparameter grey 3 "An illegal move") 

; Convert boardsize to arraysize

(defun arraysize (boardwidth boardheight) (* boardwidth boardheight))

; Convert arraysize to boardsize - The board is either n x n or (n+1) * n

(defun boardwidth (x) (ceiling (sqrt x)))

(defun boardheight (x) (truncate (sqrt x)))

(defun initial-board (arraysize)
  (make-array arraysize :initial-element empty))

(defun copy-board (board)
  (copy-seq board))

(defun board-to-string (board)
  (map 'string #'(lambda (x) (code-char (+ x (char-code #\0)))) board))

(defun string-to-board (string)
  (let ((board (make-array (length string) :initial-element empty)))
    (map-into board #'(lambda (c) (- (char-code c) (char-code #\0))) string)))

(defun name-of (piece) (char ".OX " piece))

(defun opponent (player) (if (eql player 1) 2 1))

(defun print-board (board)
  (let* ((arraysize (length board))
         (boardwidth (boardwidth arraysize))
         (boardheight (boardheight arraysize)))
    (format t "~%  ")
    (do ((x 0 (1+ x))) ((>= x boardwidth)) (format t "~c " (code-char (+ x (char-code #\A)))))
    (format t "(~a) (~a)~%" (static-evaluation black board) (static-evaluation white board))
    (do ((y 0 (1+ y))) ((>= y boardheight))
      (format t "~d " (1+ y))
      (do ((x 0 (1+ x))) ((>= x boardwidth))
        (format t "~c " (name-of (aref board (+ x (* y boardwidth))))))
      (format t "~%"))))

(defun valid-p (move board)
  (let ((arraysize (length board)))
    (and (integerp move) (>= move 0) (< move arraysize))))

(defparameter *neighbours*
  (let ((neighbours (make-array 17)))
    (dolist (x '((6 5) (6 6) (7 6) (8 7) (8 8)))
      (destructuring-bind (boardwidth boardheight) x
        (let* ((arraysize (arraysize boardwidth boardheight))
               (a (make-array arraysize)))
          (do ((y 0 (1+ y))) ((>= y boardheight))
            (do ((x 0 (1+ x))) ((>= x boardwidth))
              (let ((i (+ x (* y boardwidth)))
                    cells)
                (dolist (offset '((-1 -1) (0 -1) (1 -1) (-1 0) (1 0) (-1 1) (0 1) (1 1)))
                  (destructuring-bind (dx dy) offset
                    (when (and (< -1 (+ x dx) boardwidth) (< -1 (+ y dy) boardheight)) (push (+ (+ x dx) (* (+ y dy) boardwidth)) cells))))
                (setf (aref a i) cells))))
          (setf (aref neighbours (+ boardwidth boardheight)) a))))
          neighbours))

(defun legal-p (move player board)
  (declare (ignore player))
  (eq (aref board move) empty))

(defun make-move (move player board)
  (let* ((arraysize (length board))
         (boardwidth (boardwidth arraysize))
         (boardheight (boardheight arraysize)))
    (setf (aref board move) player)
    (map nil #'(lambda (n) (setf (aref board n) grey)) (aref (aref *neighbours* (+ boardwidth boardheight)) move))
    board))

(defun any-legal-move? (player board)
  (let ((arraysize (length board)))
    (dotimes (move arraysize nil)
    (when (legal-p move player board) (return move)))))

(defun game-won? (player board)
  (not (any-legal-move? player board)))
           
(defun obstruction (bl-strategy wh-strategy &optional (print t) (size 36))
  (let* ((board (initial-board size))
         (player black)
         (result
          (loop
           (let ((strategy (if (eq player black) bl-strategy wh-strategy)))
             (get-move strategy player board print)
             ;; Game ended?
             (setq player (opponent player))
             (when (not (any-legal-move? player board)) (return (opponent player)))))))
    (when print
      (format t "Game over. ~c won~%" (name-of result))
      (print-board board))
    result))

(defun get-move (strategy player board print)
  (when print (print-board board))
  (let ((move (funcall strategy player (copy-board board))))
    (cond
     ((and (valid-p move board) (legal-p move player board))
      (make-move move player board))
     (t (warn "Illegal move: ~d~%" move)
        (get-move strategy player board print)))))

(defun human (player board)
  (let ((arraysize (length board)))
    (format t "~%~c to  move: " (name-of player))
    (let* ((move (read-line))
           (col (- (char-code (char-upcase (char move 0))) (char-code #\A)))
           (row (- (char-code (char move 1)) (char-code #\1))))
      (+ (* row (boardwidth arraysize)) col))))

(defun random-elt (seq) 
  "Pick a random element out of a sequence."
  (when seq (elt seq (random (length seq)))))

(defun random-strategy (player board)
  (random-elt (legal-moves player board)))

(defun static-evaluation (player board)
  ;; Player to move next
  (let* ((arraysize (length board))
         (boardwidth (boardwidth arraysize))
         (boardheight (boardheight arraysize))
         (moves (legal-moves player board))
         (player-count (length moves)))
    (cond
     ((zerop player-count) -1000)
     ((= player-count 1) +1000)
     ((= player-count 2) 
      (if (find (second moves) (aref (aref *neighbours* (+ boardwidth boardheight)) (first moves))) +1000 -1000))
     (t 0))))

(defun maximizer (eval-fn)
  #'(lambda (player board)
      (let* ((moves (legal-moves player board))
             (scores (map 'list #'(lambda (move)
                                    (funcall eval-fn player
                                             (make-move move player (copy-board board))))
                          moves))
             (best (apply #'max scores)))
        (elt moves (position best scores)))))

(defconstant winning-value most-positive-fixnum)
(defconstant losing-value most-negative-fixnum)

(defun legal-moves (player board)
  (let ((arraysize (length board))
        moves)
    (dotimes (move arraysize)
      (when (legal-p move player board) (push move moves)))
    moves))

(defun random-order (list)
  (let ((rlist (map 'list #'(lambda (item) (cons item (random most-positive-fixnum))) list)))
    (map 'list #'car (sort rlist #'< :key #'cdr))))

(defun alpha-beta (player board achievable cutoff ply eval-fn)
  (cond
   ((zerop ply)
    (funcall eval-fn player board))
   (t
    (let* ((moves (random-order (legal-moves player board)))
           (best-move (first moves)))
      (cond
       ((null moves) losing-value)
       (t
        (dolist (move moves)
          (let* ((board2 (make-move move player (copy-board board)))
                 (val (- (alpha-beta (opponent player) board2 (- cutoff) (- achievable) (- ply 1) eval-fn))))
            (when (> val achievable)
              (setf achievable val best-move move)))
          (when (>= achievable cutoff) (return)))
        (values achievable best-move)))))))

(defun alpha-beta-searcher (depth eval-fn)
  #'(lambda (player board)
      (multiple-value-bind (value move)
          (alpha-beta player board losing-value winning-value depth eval-fn)
        (declare (ignore value))
        move)))

(defun obstruction-strategy (rank)
  #'(lambda (player board)
       (case rank
        (0 (funcall (alpha-beta-searcher 2 #'static-evaluation) player board))
        (t (funcall (alpha-beta-searcher (* rank 2) #'static-evaluation) player board)))))

