(import
    [azure.servicemanagement [ServiceManagementService]]
    [base64                  [b64decode]]
    [click                   [argument command group option]]
    [json                    [loads dumps]]
    [os                      [environ]]
    [os.path                 [join]]
    [OpenSSL.crypto          [load-pkcs12 dump-privatekey dump-certificate *filetype-pem*]]
    [subprocess              [Popen *pipe*]]
    [tabulate                [tabulate]]
    [xml.etree.ElementTree :as et])
 
(def *settings-url* "https://manage.windowsazure.com/publishsettings/index")
(def *config-path* (join  (.get environ "HOME") ".blu"))
(def *publish-settings-file* (join *config-path* "GetPublishSettings"))
(def *config-file* (join *config-path* "config.json"))
(def *config* (loads (.read (open *config-file* "r"))))
(def *default-os* "Ubuntu Server 14.04.2.LTS")
(def *sms* nil)

(defn save-config []
    ; commit state to disk
    (.write (open *config-file* "w") (apply dumps [*config*] {"indent" 4})))


(defn cert-path [id]
    (join *config-path* (+ id ".pem")))


(defn pfx2pem [pfx]
    (let [[p12 (load-pkcs12 (str pfx) (str ""))]
          [k   (dump-privatekey *filetype-pem* (.get-privatekey p12))]
          [c   (dump-certificate *filetype-pem* (.get-certificate p12))]]
        (+ k c)))


(defn parse-publish-settings [filename]
    ; parse the Azure Portal Publish Settings file
    (let [[subscriptions (.findall (.getroot (.parse et filename)) ".//Subscription")]
          [subs {}]]
        (for [s subscriptions]
            (let [[id (get s.attrib "Id")]]
                (.write (open (cert-path id) "w")
                        (pfx2pem (b64decode (get s.attrib "ManagementCertificate"))))
                (del (get s.attrib "ManagementCertificate"))
                (assoc subs (get s.attrib "Id") s.attrib)))
        subs))

(with-decorator (apply group [] {"chain" true})
    (defn cli []
        ; Blu is a simplified Azure CLI
        (setv *sms* (get-session))))

(defn dump-subscriptions [subs]
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
            (apply ServiceManagementService []
                {"subscription_id" id
                 "cert_file"       (cert-path id)}))))

(with-decorator (group)
    (defn image []))

(defn get-os-images [sms substr]
    (map
        (fn [i] {"Label" (. i label) "Image" (. i name)})
        (filter
            (fn [i] (in substr (. i label))) 
            (.list-os-images sms))))


(with-decorator (cli.command "images")
                (apply option ["-f" "--filter" "substr"] {"default" *default-os* "help" "partial string of OS name"})
    (defn list-images [substr]
        ; list OS images that match <substr>
        (print
            (apply tabulate [(list (get-os-images (get-session) substr))]
                {"headers" "keys"}))))

(with-decorator (cli.command "info")
    (defn dump-info []
        (dump-subscriptions (get *config* "subscriptions"))))

(defn get-session []
    (if (not (in "subscriptions" *config*))
        (let [[subs (parse-publish-settings *publish-settings-file*)]]
            (assoc *config* "subscriptions" subs)))
    (if (in "active_subscription" *config*)
        (set-active-sub (get *config* "active_subscription"))
        nil))


(defmain [&rest args]
    (cli))
