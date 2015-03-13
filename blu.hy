(import
    [azure.servicemanagement [ServiceManagementService]]
    [base64                  [b64decode]]
    [json                    [loads dumps]]
    [os                      [environ]]
    [os.path                 [join]]
    [tabulate                [tabulate]]
    [xml.etree.ElementTree :as et])

(def *config-path* (join  (.get environ "HOME") ".blu"))
(def *publish-settings-file* (join *config-path* "GetPublishSettings"))
(def *config-file* (join *config-path* "config.json"))
(def *config* (loads (.read (open *config-file* "r"))))

(defn save-config []
    ; commit state to disk
    (.write (open *config-file* "w") (apply dumps [*config*] {"indent" 4})))


(defn cert-path [id]
    (join *config-path* (+ id ".pem")))


(defn parse-publish-settings [filename]
    ; parse the Azure Portal Publish Settings file
    (let [[subscriptions (.findall (.getroot (.parse et filename)) ".//Subscription")]
          [subs {}]]
        (for [s subscriptions]
            (let [[id (get s.attrib "Id")]]
                (.write (open (cert-path id) "w")
                        (b64decode (get s.attrib "ManagementCertificate")))
                (del (get s.attrib "ManagementCertificate"))
                (assoc subs (get s.attrib "Id") s.attrib)))
        subs))


(defn dump-subs [subs]
     ; dump known subscriptions
     (let [[summary (.values subs)]]
        (for [s summary]
            (for [k ["ManagementCertificate" "ServiceManagementUrl"]]
                (del (get s k))))
        (print (apply tabulate [summary] {"headers" "keys"}))))


(defn set-active-sub [id]
    ; set the active subscription
    (if (in id (get *config* "subscriptions"))
        (do
            (assoc *config* "active_subscription" id)
            (save-config)
            (ServiceManagementService id (cert-path id)))))


(defn init []
    (if (not (in "subscriptions" *config*))
        (let [[subs (parse-publish-settings *publish-settings-file*)]]
            (assoc *config* "subscriptions" subs)
            (save-config)))
    (if (in "active_subscription" *config*)
        (set-active-sub (get *config* "active_subscription"))
        nil))


(defmain [&rest args]
    (let [[session (init)]]
        (print (.list-os-images session))))
