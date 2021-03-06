;;;-*- Mode: Lisp; Package: games -*-

(in-package :3dox)

; David Johnson-Davies - 10th May 2020
; Licensed under the MIT license: https://opensource.org/licenses/MIT

; To play the game in the listener evaluate:
; (in-package :3dox)
; (3dox #'human (alpha-beta-searcher 3 #'count-difference))

;
; Three-dimensional Noughts and Crosses
;

(defconstant empty 0 "An empty square")
(defconstant black 1 "A black move")
(defconstant white 2 "A white move")

(defun initial-board ()
  (make-array 64 :initial-element empty))

(defun copy-board (board)
  (copy-seq board))

(defun board-to-string (board)
  (map 'string #'(lambda (x) (code-char (+ x (char-code #\0)))) board))

(defun string-to-board (string)
  (let ((board (make-array 64 :initial-element empty)))
    (map-into board #'(lambda (c) (- (char-code c) (char-code #\0))) string)))

(defun name-of (piece) (char ".OX" piece))

(defun opponent (player) (if (eql player 1) 2 1))

(defun print-board (board)
  (format t "  A B C D    E F G H    I J K L    M N O P (~a) (~a)~%" (count-difference black board) (count-difference white board))
  (do ((y 0 (1+ y))) ((> y 3))
    (format t "~d " (1+ y))
    (do ((z 0 (1+ z))) ((> z 3))
      (do ((x 0 (1+ x))) ((> x 3))
        (format t "~c " (name-of (bref board (+ x (* 4 (+ y (* 4 z))))))))
      (format t "   "))
    (format t "~%"))
  (format t "~%"))

(defparameter *all-lines*
  (let (lines)
    ;; Rows
    (do ((z 0 (+ z 16))) ((> z 48))
      (do ((y 0 (+ y 4))) ((> y 12))
        (push (list (+ z y) (+ z y 1) (+ z y 2) (+ z y 3)) lines))
      (do ((x 0 (+ x 1))) ((> x 3))
        (push (list (+ z x) (+ z x 4) (+ z x 8) (+ z x 12)) lines))
      (push (list (+ z) (+ z 5) (+ z 10) (+ z 15)) lines)
      (push (list (+ z 3) (+ z 6) (+ z 9) (+ z 12)) lines))
    ;; Vertical
    (do ((x 0 (+ x 1))) ((> x 3))
      (do ((y 0 (+ y 4))) ((> y 12))
        (push (list (+ x y) (+ x y 16) (+ x y 32) (+ x y 48)) lines))
      (push (list (+ x 0) (+ x 20) (+ x 40) (+ x 60)) lines)
      (push (list (+ x 12) (+ x 24) (+ x 36) (+ x 48)) lines))
    (do ((y 0 (+ y 4))) ((> y 12))
      (push (list (+ y 0) (+ y 17) (+ y 34) (+ y 51)) lines)
      (push (list (+ y 3) (+ y 18) (+ y 33) (+ y 48)) lines))
    ;; Diagonals
    (push (list 0 21 42 63) lines)
    (push (list 15 26 37 48) lines)
    (push (list 3 22 41 60) lines)
    (push (list 12 25 38 51) lines)
    lines))

(defun bref (board square) (aref board square))
(defsetf bref (board square) (val) 
  `(setf (aref ,board ,square) ,val))

(defun valid-p (move)
  (and (integerp move) (>= move 0) (<= move 63)))

(defun legal-p (move player board)
  (eq (bref board move) empty))

(defun make-move (move player board)
  (setf (bref board move) player)
  board)

(defun any-legal-move? (player board)
  (dotimes (move 64 nil)
    (when (legal-p move player board) (return move))))
           
(defun 3dox (bl-strategy wh-strategy &optional (print t))
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
      (print-board board))))

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
  (format t "~%~c to  move: " (name-of player))
  (let* ((move (read-line))
         (col (nth
               (- (char-code (char-upcase (char move 0))) (char-code #\A))
               '(0 1 2 3 16 17 18 19 32 33 34 35 48 49 50 51)))
         (row (* 4 (- (char-code (char move 1)) (char-code #\1)))))
    (+ row col)))

(defun random-elt (seq) 
  "Pick a random element out of a sequence."
  (when seq (elt seq (random (length seq)))))

(defun random-strategy (player board)
  (random-elt (legal-moves player board)))

(defun legal-moves (player board)
  (let (legal)
    (dotimes (move 64)
      (when (legal-p move player board) (push move legal)))
    legal))

(defun game-won? (player board)
  (some #'(lambda (line) (when (every #'(lambda (move) (eq (bref board move) player)) line) line)) *all-lines*))

; Counts player's pieces minus opponent's pieces

; Player has just moved - line of opponent's three is fatal

(defun count-difference (player board)
  (let* ((opponent (opponent player))
         (scores (map 'list #'(lambda (line)
                           (let ((player-count (count-if #'(lambda (move) (eq (bref board move) player)) line))
                                 (opponent-count (count-if #'(lambda (move) (eq (bref board move) opponent)) line)))
                             (cond
                              ((zerop opponent-count) (case player-count (0 0) (1 10) (2 100) (3 1000) (4 10000)))
                              ((zerop player-count) (case opponent-count (0 0) (1 -10) (2 -100) (3 -10000) (4 -10000)))
                              (t 0))))
                 *all-lines*)))
    (apply #'+ scores)))

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

