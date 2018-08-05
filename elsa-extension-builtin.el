(require 'elsa-analyser)
(require 'elsa-infer)

;; * boolean functions
(defun elsa--analyse-not (form scope)
  (let ((errors (elsa--analyse-function-call form scope))
        (args (cdr (oref form sequence))))
    (let ((arg-type (oref (car args) type)))
      (cond
       ((elsa-type-accept (elsa-type-nil) arg-type) ;; definitely false
        (oset form type (elsa-type-t)))
       ((not (elsa-type-accept arg-type (elsa-type-nil))) ;; definitely true
        (oset form type (elsa-type-nil)))
       (t (oset form type (elsa-make-type 't?)))))
    errors))

;; * list functions
(defun elsa--analyse-car (form scope)
  (let* ((errors (elsa--analyse-function-call form scope)))
    (-when-let* ((arg (cadr (oref form sequence)))
                 (arg-type (oref arg type)))
      (when (elsa-type-list-p arg-type)
        (oset form type (elsa-type-make-nullable (oref arg-type item-type)))))
    errors))

;; * predicates
(defun elsa--analyse-stringp (form scope)
  (let ((errors (elsa--analyse-function-call form scope)))
    (oset form type
          (elsa--infer-unary-fn form
            (lambda (arg-type)
              (cond
               ((elsa-type-accept (elsa-type-string) arg-type)
                (elsa-type-t))
               ;; if the arg-type has string as a component, for
               ;; example int | string, then it might evaluate
               ;; sometimes to true and sometimes to false
               ((elsa-type-accept arg-type (elsa-type-string))
                (elsa-make-type 't?))
               (t (elsa-type-nil))))))
    errors))

(provide 'elsa-extension-builtin)
