(in-package #:cache-parity)

(defun env-off-p (name)
  (let ((v (string-downcase (or (uiop:getenv name) ""))))
    (member v '("0" "false" "no" "off") :test #'string=)))

(defun live-requested-p (&optional extra)
  (and (not (env-off-p "PARITY"))
       (or (null extra) (not (env-off-p extra)))))

(defun %env (name &optional default)
  (or (uiop:getenv name) default))

(defparameter *cache-host*
  (%env "CACHE_PARITY_HOST" "127.0.0.1"))

(defparameter *cache-port*
  (parse-integer (%env "CACHE_PARITY_PORT" "6379") :junk-allowed t))

(defun tcp-reachable-p (host port &key (timeout 0.4))
  (handler-case
      (let ((sock (usocket:socket-connect host port
                                          :timeout timeout
                                          :element-type '(unsigned-byte 8))))
        (usocket:socket-close sock)
        t)
    (error () nil)))

(defun valkey-reachable-p ()
  (and (live-requested-p "CACHE_PARITY")
       (tcp-reachable-p *cache-host* *cache-port*)))
