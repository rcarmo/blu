(import
    [xml.etree.ElementTree :as et]
    [tabulate [tabulate]])

(def *subscriptions* {})
(def *active-subscription* nil)

(defn parse-publish-settings [filename]
    (let [[subscriptions (.findall (.getroot (.parse et filename)) ".//Subscription")]
          [subs {}]]
        (for [s subscriptions]
            (assoc subs (get s.attrib "Id") s.attrib))
        subs))

(defn dump-subs [subs]
     (let [[summary (.values subs)]]
        (for [s summary]
            (for [k ["ManagementCertificate" "ServiceManagementUrl"]]
                (del (get s k))))
        (print (apply tabulate [summary] {"headers" "keys"}))))

(defn set-active-subs [id]
    (if (in id *subscriptions*)
        (setv *active-subscription* (get *subscriptions* id))))

(defmain [&rest args]
    (let [[subs (parse-publish-settings (get args 1))]]
        (print subs)
        (dump-subs subs)))
