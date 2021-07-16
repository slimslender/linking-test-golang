#!/usr/bin/env bb

(require '[clojure.string :as s])
(require '[babashka.process :as process])

(defn bump [& args]
  (let [filename (or (first args) "base/Dockerfile")]
    (spit filename
          (s/replace
           (slurp filename)
           #":version (\d+)"
           (fn [[_ v]] (format ":version %s" (inc (Integer/parseInt v))))))))

(apply bump *command-line-args*)
(-> (process/sh "git commit -am 'bump'") :out println) 
(-> (process/sh "git push origin main") :out println)
