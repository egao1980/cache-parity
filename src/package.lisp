(defpackage #:cache-parity
  (:use #:cl)
  (:export #:*cache-host*
           #:*cache-port*
           #:env-off-p
           #:live-requested-p
           #:tcp-reachable-p
           #:valkey-reachable-p
           #:call-with-redis-cache
           #:cache-get-put-incr-cas
           #:print-matrix))

(in-package #:cache-parity)
