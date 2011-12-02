#lang racket

(require "rsound.rkt"
         "private/s16vector-add.rkt"
         ffi/unsafe
         ffi/vector)

;; almost-safe (tm) utilities for copying sounds.

;; if you don't lie about the target buffer and its length,
;; you'll be safe.

(provide zero-buffer!
         rs-copy-add!)

(define frame-size (* channels s16-size))
(define (frames->bytes f) (* frame-size f))

;; given a cpointer and a length in frames,
;; fill it with zeros.
(define (zero-buffer! buf len)
  (memset buf 0 (frames->bytes len)))

;; given a target cpointer and an offset in frames
;; and a source rsound and an offset in frames
;; and a number of frames to copy and the length 
;; of the target buffer in frames, check that we're not
;; reading or writing off the end of either buffer
;; and then do a copy-and-add.
(define (rs-copy-add! tgt tgt-offset 
                      src src-offset
                      copy-frames buf-frames)
  (unless (<= 0 tgt-offset (+ tgt-offset copy-frames) buf-frames)
    (error 'rs-copy-add! "tgt bounds violation, must have (0 <= ~s <= ~s <= ~s)"
           tgt-offset (+ tgt-offset copy-frames) buf-frames))
  (unless (<= 0 src-offset (+ src-offset copy-frames)(rsound-frames src))
    (error 'rs-copy-add! "src bounds violation, must have (0 <= ~s <= ~s <= ~s)"
           src-offset 
           (+ src-offset copy-frames)
           (rsound-frames src)))
  (define tgt-ptr (ptr-add tgt (frames->bytes tgt-offset)))
  (define src-real-offset (+ src-offset (rsound-start src)))
  (define src-ptr (ptr-add (s16vector->cpointer (rsound-data src))
                           (frames->bytes src-real-offset)))
  (s16buffer-add!/c tgt-ptr src-ptr (* channels copy-frames)))