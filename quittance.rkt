#lang racket

(require xml gregor json net/base64)

(define data (with-input-from-file "quittances.json"
               read-json))

(define (bytes->string b)
  (parameterize ([current-locale "C"])
    (bytes->string/locale b)))

(define (image->base64-web filename)
  (string-append "data:image/jpeg;base64," (bytes->string (base64-encode (file->bytes filename)))))

(define (generate-quittance-html proprietaire logement locataire quittance-date quittance-emission quittance-periode-de quittance-periode-a)
  (xexpr->string
   `(html
     (head
      (meta ((charset "utf-8"))))
     (body ((style "margin: 10%"))
           (p (b ,(hash-ref proprietaire 'nom)) (br)
              ,(hash-ref proprietaire 'adresse) (br)
              ,(hash-ref proprietaire 'cp) " " ,(hash-ref proprietaire 'ville))
           (p ((align "right")) (b ,(hash-ref locataire 'nom)) (br)
              ,(hash-ref locataire 'adresse) (br)
              ,(hash-ref locataire 'cp) " " ,(hash-ref locataire 'ville))
           (h1 "Quittance " ,quittance-date)
           (p "Période du " ,quittance-periode-de " au " ,quittance-periode-a)
           (h2 ,(hash-ref logement 'adresse) " " ,(hash-ref logement 'cp) " " ,(hash-ref logement 'ville))
           (table ((width "50%")
                   (style "border: 1px solid black;")
                   (align "center"))
                  (tr
                   (td "Loyer " ,quittance-date)
                   (td ,(number->string (hash-ref logement 'loyer)) "€"))
                  (tr
                   (td "Charges " ,quittance-date)
                   (td ,(number->string (hash-ref logement 'charges)) "€"))
                  (tr
                   (td (b "Total"))
                   (td ,(number->string (+ (hash-ref logement 'loyer) (hash-ref logement 'charges))) "€")))
           (p "Je soussigné " ,(hash-ref proprietaire 'nom) ", propriétaire du logement désigné ci-dessus, déclare avoir reçu de la part du locataire l'ensemble des sommes mentionnées ci-dessus au titre de loyer et charges.")
           (p "Le " ,quittance-emission)
           (img ((src ,(image->base64-web (hash-ref proprietaire 'signature)))
                 (height "150")
                 (width "400")))
           (p "Cette quittance annule tous les reçus qui auraient pu être établis précédemment en cas de paiement partiel du montant du présent terme. Elle est à conserver pendant trois ans par le locataire (loi n° 89-462 du 6 juillet 1989 : art. 7-1).")))))

(define (write-html-to-file filename proprietaire logement locataire quittance-date quittance-emission quittance-periode-de quittance-periode-a)
  (with-output-to-file filename
    #:exists 'replace
    (lambda ()
      (printf (generate-quittance-html proprietaire logement locataire quittance-date quittance-emission quittance-periode-de quittance-periode-a)))))

(define (execute-wkhtmltopdf filename-in filename-out)
  (system* "/usr/bin/wkhtmltopdf" filename-in filename-out))

(define (generate-quittance-pdf filename-html filename-pdf proprietaire logement locataire quittance-date quittance-emission quittance-periode-de quittance-periode-a)
  (begin
    (write-html-to-file filename-html proprietaire logement locataire quittance-date quittance-emission quittance-periode-de quittance-periode-a)
    (execute-wkhtmltopdf filename-html filename-pdf)
    (delete-file filename-html)))

(define (generate-all-quittances-pdf (quittance-generation (now)))
  (map (lambda (logement)
         (let* ((proprietaire (hash-ref data 'proprietaire))
                (locataire (hash-ref logement 'locataire))
                (locataire-nom (hash-ref locataire 'nom))
                (filename-base (string-append "quittance-"
                                              (string-replace locataire-nom " " "-")))
                (filename-date (~t quittance-generation "M-y"))
                (filename-html (string-append filename-base "-" filename-date ".html"))
                (filename-pdf (string-append filename-base "-" filename-date ".pdf"))
                (quittance-date (parameterize ((current-locale "fr"))
                                  (~t quittance-generation "MMMM y")))
                (quittance-emission (~t quittance-generation "MM/y"))
                (quittance-periode-de (~t quittance-generation "01/MM/y"))
                (quittance-periode-a (string-append (number->string (days-in-month (->year quittance-generation) (->month quittance-generation)))
                                                    (~t quittance-generation "/MM/y"))))
           (generate-quittance-pdf filename-html
                                   filename-pdf
                                   proprietaire
                                   logement
                                   locataire
                                   quittance-date
                                   quittance-emission
                                   quittance-periode-de
                                   quittance-periode-a)))
         (hash-ref data 'logements)))

(define args (current-command-line-arguments))

(cond
  ((= 0 (vector-length args))
   (generate-all-quittances-pdf))
  ((= 2 (vector-length args))
   (generate-all-quittances-pdf (date (string->number (vector-ref args 0))
                                      (string->number (vector-ref args 1)))))
  (else
   (error "Wrong number of command line parameters")))
  