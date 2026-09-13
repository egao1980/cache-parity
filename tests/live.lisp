(in-package #:cache-parity/tests)

(deftest probe-returns-boolean
  (ok (member (tcp-reachable-p *cache-host* *cache-port*) '(t nil))))

(deftest valkey-get-put-incr-cas
  (cond
    ((not (live-requested-p "CACHE_PARITY"))
     (skip "PARITY=0 or CACHE_PARITY=0 — live Valkey canary skipped"))
    ((not (tcp-reachable-p *cache-host* *cache-port*))
     (skip (format nil "Valkey/Redis unreachable at ~a:~a — live canary skipped"
                   *cache-host* *cache-port*)))
    (t
     (let ((r (cache-get-put-incr-cas)))
       (ok (string= "v1" (getf r :get)))
       (ok (string= "v2" (getf r :cas)))
       (ok (string= "v2" (getf r :after)))
       (ok (= 1 (getf r :incr-1)))
       (ok (= 3 (getf r :incr-3)))))))
