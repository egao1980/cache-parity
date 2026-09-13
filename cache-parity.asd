(defsystem "cache-parity"
  :version "0.1.0"
  :description "Interop canary: cache-backend-redis vs dockerized Valkey/Redis"
  :author "egao1980"
  :license "MIT"
  :depends-on ("cache-protocol"
               "cache-backend-redis"
               "usocket"
               "uiop")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "probe")
               (:file "valkey")
               (:file "report"))
  :in-order-to ((test-op (test-op "cache-parity/tests"))))

(defsystem "cache-parity/tests"
  :depends-on ("cache-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "live"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "cache-parity tests failed"))))
