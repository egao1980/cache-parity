(in-package #:cache-parity)

;;; RESP3 over a character (or bivalent) socket. cache-backend-redis
;;; write-string / read-line the stream.

(defun %ascii-write (binary-stream string)
  (loop for c across string
        do (write-byte (char-code c) binary-stream))
  (force-output binary-stream))

(defun %ascii-read-line (binary-stream)
  (let ((out (make-array 0 :element-type 'character :adjustable t :fill-pointer 0)))
    (loop for b = (read-byte binary-stream)
          do (cond
               ((= b 13)
                (let ((n (read-byte binary-stream)))
                  (unless (= n 10)
                    (error 'cache-protocol:cache-error
                           :message "RESP CRLF missing LF"))
                  (return (coerce out 'string))))
               ((= b 10)
                (return (coerce out 'string)))
               (t (vector-push-extend (code-char b) out))))))

(defun %ascii-read-n (binary-stream n)
  (let ((s (make-string n)))
    (dotimes (i n s)
      (setf (char s i) (code-char (read-byte binary-stream))))))

(defun decode-resp3-binary (stream)
  "RESP3 decode from an (unsigned-byte 8) socket. Mirrors cache-backend-redis."
  (let* ((line (%ascii-read-line stream))
         (type (if (plusp (length line)) (char line 0)
                   (error 'cache-protocol:cache-error
                          :message "empty RESP3 line")))
         (rest (subseq line 1)))
    (ecase type
      (#\+ (cache-backend-redis:make-resp-simple-string rest))
      (#\- (cache-backend-redis:make-resp-error rest))
      (#\: (parse-integer rest :junk-allowed t))
      (#\$
       (let ((n (parse-integer rest :junk-allowed t)))
         (if (or (null n) (< n 0))
             :resp-null
             (prog1 (%ascii-read-n stream n)
               (%ascii-read-line stream)))))
      (#\*
       (let ((n (parse-integer rest :junk-allowed t)))
         (if (or (null n) (< n 0))
             :resp-null
             (loop repeat n collect (decode-resp3-binary stream)))))
      (#\_ :resp-null)
      (#\#
       (cond
         ((or (string-equal rest "t") (string= rest "t")) :resp-true)
         ((or (string-equal rest "f") (string= rest "f")) :resp-false)
         (t (error 'cache-protocol:cache-error
                   :message (format nil "bad RESP3 bool ~s" rest)))))
      (#\,
       (let* ((*read-default-float-format* 'double-float)
              (n (read-from-string rest)))
         (float n 1.0d0)))
      (#\%
       (let ((n (parse-integer rest :junk-allowed t)))
         (cache-backend-redis:make-resp-map
          (loop repeat n
                collect (cons (decode-resp3-binary stream)
                              (decode-resp3-binary stream))))))
      (#\~
       (let ((n (parse-integer rest :junk-allowed t)))
         (cache-backend-redis:make-resp-set
          (loop repeat n collect (decode-resp3-binary stream))))))))

(defun make-binary-send-fn (stream)
  (lambda (parts)
    (%ascii-write stream (cache-backend-redis:encode-resp3-command parts))
    (decode-resp3-binary stream)))

(defun call-with-redis-cache (fn &key (host *cache-host*)
                                   (port *cache-port*))
  (let ((sock (usocket:socket-connect host port
                                      :timeout 2
                                      :element-type '(unsigned-byte 8))))
    (unwind-protect
         (let ((cache (cache-backend-redis:make-redis-cache-backend
                       :send-fn (make-binary-send-fn
                                 (usocket:socket-stream sock)))))
           (funcall fn cache))
      (ignore-errors (usocket:socket-close sock)))))

(defun cache-get-put-incr-cas ()
  (call-with-redis-cache
   (lambda (cache)
     (let* ((k (format nil "parity:~d" (get-universal-time)))
            (n (format nil "~a:n" k)))
       (cache-protocol:cache-put cache k "v1")
       (let ((got (cache-protocol:cache-get cache k))
             (cas (cache-protocol:cache-cas cache k "v1" "v2"))
             (after (cache-protocol:cache-get cache k))
             (one (cache-protocol:cache-incr cache n))
             (three (cache-protocol:cache-incr cache n :delta 2)))
         (cache-protocol:cache-delete cache k)
         (cache-protocol:cache-delete cache n)
         (list :get got :cas cas :after after :incr-1 one :incr-3 three))))))
