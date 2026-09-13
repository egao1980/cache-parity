(in-package #:cache-parity)

(defun print-matrix ()
  (format t "~&cache-parity matrix~%")
  (format t "  get/put/incr/cas vs Valkey/Redis at ~a:~a (skip if unreachable)~%"
          *cache-host* *cache-port*)
  (format t "  PARITY=0 or CACHE_PARITY=0 forces skip~%"))
