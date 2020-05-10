;;;-*- Mode: Lisp; Package: gomoku -*-

(in-package :gomoku)

; David Johnson-Davies - 10th May 2020
; Licensed under the MIT license: https://opensource.org/licenses/MIT

; To play the game in the listener evaluate:
; (in-package :gomoku)
; (gomoku #'human (alpha-beta-searcher 3 #'count-difference))

;
; Go-Moku
;

(defparameter empty 0 "An empty square")
(defparameter black 1 "A black move")
(defparameter white 2 "A white move")

(defparameter boardsize 15 "The size of the grid")
(defparameter arraysize (* boardsize boardsize) "The size of the array")

(defun initial-board ()
  (make-array arraysize :initial-element empty))

(defun copy-board (board)
  (copy-seq board))

(defun name-of (piece) (char ".OX" piece))

(defun opponent (player) (if (eql player 1) 2 1))

(defun print-board (board)
  (format t "~%   A B C D E F G H I J K L M N O (~a) (~a)~%" (count-difference black board) (count-difference white board))
  (do ((y 0 (1+ y))) ((>= y boardsize))
    (format t "~2,d " (1+ y))
    (do ((x 0 (1+ x))) ((>= x boardsize))
      (format t "~c " (name-of (bref board (+ x (* y boardsize))))))
    (format t "~%")))

(defparameter *all-lines*
  (let (lines)
    ;; Rows
  (do ((y 0 (1+ y)) (line nil nil)) ((>= y boardsize))
    (do ((x 0 (1+ x))) ((>= x boardsize))
      (push (+ x (* y boardsize)) line))
    (push line lines))
    ;; Columns
  (do ((x 0 (1+ x)) (line nil nil)) ((>= x boardsize))
    (do ((y 0 (1+ y))) ((>= y boardsize))
      (push (+ x (* y boardsize)) line))
    (push line lines))
  ;; Diagonals
   (do ((z 0 (1+ z)) (line nil nil)) ((>= z boardsize))
     (do ((y z (1+ y)) (x 0 (1+ x))) ((>= y boardsize)) (push (+ x (* y boardsize)) line))
     (push line lines))
   ;;
    (do ((z 1 (1+ z)) (line nil nil)) ((>= z boardsize))
     (do ((y 0 (1+ y)) (x z (1+ x))) ((>= x boardsize)) (push (+ x (* y boardsize)) line))
     (push line lines))
    ;;
    (do ((z 0 (1+ z)) (line nil nil)) ((>= z boardsize))
     (do ((y z (1+ y)) (x (- boardsize 1) (1- x))) ((>= y boardsize)) (push (+ x (* y boardsize)) line))
     (push line lines))
   ;;
    (do ((z 1 (1+ z)) (line nil nil)) ((>= z boardsize))
     (do ((y 0 (1+ y)) (x (- boardsize 1 z) (1- x))) ((< x 0)) (push (+ x (* y boardsize)) line))
     (push line lines))
  (remove-if #'(lambda (line) (< (length line) 5)) lines)))

(defun bref (board square) (aref board square))
(defsetf bref (board square) (val) 
  `(setf (aref ,board ,square) ,val))

(defun valid-p (move)
  (and (integerp move) (>= move 0) (< move arraysize)))

(defun legal-p (move player board)
  (eq (bref board move) empty))

(defun make-move (move player board)
  (setf (bref board move) player)
  board)

(defun any-legal-move? (player board)
  (dotimes (move arraysize nil)
    (when (legal-p move player board) (return move))))
           
(defun gomoku (bl-strategy wh-strategy &optional (print t))
  (let* ((board (initial-board))
         (player black)
         (result
          (loop
           (let ((strategy (if (eq player black) bl-strategy wh-strategy)))
             (get-move strategy player board print)
             ;; Game ended?
             (when (not (any-legal-move? player board)) (return nil))
             (when (game-won? player board) (return player))
             (setq player (if (eq player black) white black))))))
    (when print
      (format t "Game over. ~c won~%" (name-of result))
      (print-board board))
    result))

(defun get-move (strategy player board print)
  (when print (print-board board))
  (let ((move (funcall strategy player (copy-board board))))
    (cond
     ((and (valid-p move) (legal-p move player board))
      (make-move move player board))
     (t (warn "Illegal move: ~d~%" move)
        (get-move strategy player board print)))))

(defun human (player board)
  (declare (ignore board))
  (format t "~%~c to move: " (name-of player))
  (let* ((move (read-line))
         (col (- (char-code (char-upcase (char move 0))) (char-code #\A)))
         (row (1- (parse-integer move :start 1))))
    (+ (* row boardsize) col)))

(defun random-elt (seq) 
  "Pick a random element out of a sequence."
  (when seq (elt seq (random (length seq)))))

(defun random-strategy (player board)
  (random-elt (legal-moves player board)))

;
; Get a list of moves to consider
; Only try moves touching another piece
;

(defun legal-moves (player board)
  (let (legal)
    (dotimes (move arraysize)
      (when
          (and
           (legal-p move player board)
           (some #'(lambda (offset)
                     (and (<= 0 (+ move offset) 224)
                          (not (eq empty (bref board (+ move offset))))))
                 '(-1 1 -14 -15 -16 14 15 16)))
        (push move legal)))
    (or legal '(96 97 98 111 112 113 126 127 128))))

; Returns winning line

(defun game-won? (player board)
  (some #'(lambda (line)
            (let ((count 0))
              (some 
               #'(lambda (move)
                   (if (eq (bref board move) player) (incf count) (setq count 0))
                   (>= count 5))
               line)))
        *all-lines*))

(defun winning-line (player board)
 (let (win)
   (some #'(lambda (line)
            (let ((count 0))
              (some 
               #'(lambda (move)
                   (cond
                    ((eq (bref board move) player)
                     (incf count)
                     (push move win))
                    (t (setq count 0 win nil)))
                   (when (>= count 5) win))
               line)))
        *all-lines*)))

(defun score (player r1 p1 r2 p2 r3 p3)
  (cond
   ((= p2 empty) 0)
   ((= p2 player) ; Player to move next - assume is O
    (case r2
      (5 5000000) ; line of 5
      (4 ; opponent will win now
        (cond
         ((and (>= r1 1) (= p1 empty)) 1000000) ; .OOOO
         ((and (>= r3 1) (= p3 empty)) 1000000) ; OOOO.
         (t 0)))
      (3 
        (cond 
         ((and (>= r1 2) (= p1 empty) (>= r3 1) (= p3 empty)) 1000000) ; ..OOO.
         ((and (>= r1 1) (= p1 empty) (>= r3 2) (= p3 empty)) 1000000) ; .OOO..
         (t 0)))
      (2
       (cond
        ((and (= p1 empty) (= p3 empty)) (+ (* r1 r3))) ; 1 or 2 with spaces around
        (t 0)))
      (1
       (cond
        ((and (= p1 empty) (= p3 empty)) (+ (round (* r1 r3) 10))) ; 1 or 2 with spaces around
        (t 0)))
      (t 0)))
   (t ; opponent
    (case r2
      (5 -5000000) ; line of 5
      (4 ; will win next go
        (cond
         ((and (>= r1 1) (= p1 empty) (>= r3 1) (= p3 empty)) -100000) ; .XXXX.
         (t 0)))
      (3 
        (cond 
         ((and (>= r1 2) (= p1 empty) (>= r3 2) (= p3 empty)) -10000) ; ..XXX..
         ((and (>= r1 1) (= p1 empty) (>= r3 1) (= p3 empty)) -1000) ; .XXX.
         ((and (>= r1 1) (= p1 empty) (>= r3 2) (= p3 empty)) -1000) ; XXX..
         (t 0)))
      (2
       (cond
        ((and (= p1 empty) (= p3 empty)) (- (* r1 r3))) ; 1 or 2 with spaces around
        (t 0)))
      (1
       (cond
        ((and (= p1 empty) (= p3 empty)) (- (round (* r1 r3) 10))) ; 1 or 2 with spaces around
        (t 0)))
      (t 0)))))

(defun run (player board line)
  (let ((score 0) (run 0) (r1 0) (r2 0) (r3 0) (p1 0) (p2 0) (p3 0) (last 0))
    (map nil #'(lambda (move)
                 (let ((piece (bref board move)))
                   (cond
                    ((eq piece last) (incf run))
                    (t (setq r3 r2 p3 p2)
                       (setq r2 r1 p2 p1)
                       (setq r1 run p1 last)
                       (setq run 1)
                       (incf score (score player r1 p1 r2 p2 r3 p3))))
                   (setq last piece)))
         line)
    (setq r3 r2 p3 p2)
    (setq r2 r1 p2 p1)
    (setq r1 run p1 last)
    (incf score (score player r1 p1 r2 p2 r3 p3))
    score))

(defun count-difference (player board)
  (let ((score 0))
    (map nil #'(lambda (line) (incf score (run player board line))) *all-lines*)
    score))

(defun maximizer (eval-fn)
  #'(lambda (player board)
      (let* ((moves (legal-moves player board))
             (scores (map 'list #'(lambda (move)
                                  (funcall eval-fn player
                                           (make-move move player (copy-board board))))
                          moves))
             (best (apply #'max scores)))
        (elt moves (position best scores)))))

(defun maximize-difference (player board)
  (funcall (maximizer #'count-difference) player board))

(defconstant winning-value most-positive-fixnum)
(defconstant losing-value most-negative-fixnum)

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
       ((game-won? player board) winning-value)
       ((game-won? (opponent player) board) losing-value)
       ((null moves) 0)
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
