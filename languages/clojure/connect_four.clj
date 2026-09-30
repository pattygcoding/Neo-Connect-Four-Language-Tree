(require '[clojure.string :as str])

(def ^:private rows 6)
(def ^:private cols 7)
(def ^:private empty-cell ".")
(def ^:private player-marks ["X" "O"])
(def ^:private header "=== Connect Four ===\nGet four of your pieces in a row to win. Columns are numbered 1-7.\n")

(defn- new-board []
    (vec (repeat rows (vec (repeat cols empty-cell)))))

(defn- render [board]
    (let [labels (str " " (str/join " " (range 1 (inc cols))))
        border (str "+" (apply str (repeat (dec (* cols 2)) "-")) "+")
        row-strings (mapv (fn [row] (str "|" (str/join " " row) "|")) (reverse board))]
        (str/join "\n" (concat [labels border] row-strings [border]))))

(defn- cell-at [board r c]
    (nth (nth board r) c))

(defn- lowest-empty-row [board col]
    (let [index (first (keep-indexed (fn [i row] (when (= (nth row col) empty-cell) i)) board))]
        (if (nil? index) -1 index)))

(defn- has-four? [board player]
    (let [at? (fn [r c] (= (cell-at board r c) player))
        horizontal (some true? (for [r (range rows) c (range (- cols 3))]
            (and (at? r c) (at? r (+ c 1)) (at? r (+ c 2)) (at? r (+ c 3)))))
        vertical (some true? (for [r (range (- rows 3)) c (range cols)]
            (and (at? r c) (at? (+ r 1) c) (at? (+ r 2) c) (at? (+ r 3) c))))
        diagonal-up (some true? (for [r (range (- rows 3)) c (range (- cols 3))]
            (and (at? r c) (at? (+ r 1) (+ c 1)) (at? (+ r 2) (+ c 2)) (at? (+ r 3) (+ c 3)))))
        diagonal-down (some true? (for [r (range 3 rows) c (range (- cols 3))]
            (and (at? r c) (at? (- r 1) (+ c 1)) (at? (- r 2) (+ c 2)) (at? (- r 3) (+ c 3)))))]
        (boolean (or horizontal vertical diagonal-up diagonal-down))))

(defn- whole-number? [token]
    (boolean (re-matches #"[+-]?[0-9]+" token)))

(defn- validate [board token]
    (cond
        (= token "") {:error "Invalid input: no column entered."}
        (not (whole-number? token)) {:error (str "Invalid input: \"" token "\" is not a whole number.")}
        :else
        (let [value (bigint token)]
            (cond
                (or (< value 1) (> value cols)) {:error (str "Invalid input: \"" token "\" is out of range (1-7).")}
                (= -1 (lowest-empty-row board (dec (int value)))) {:error (str "Column " value " is full.")}
                :else {:ok (dec (int value))}))))

(defn- ask-column [board player]
    (print (str "Player " player ", choose a column (1-7): "))
    (flush)
    (let [line (read-line)]
        (if (nil? line)
            (do
                (print "\nInput closed. Goodbye.\n")
                (flush)
                nil)
            (let [result (validate board (str/trim line))]
                (if (contains? result :ok)
                    (:ok result)
                    (do
                        (print (str "\n" (:error result) "\n"))
                        (flush)
                        (ask-column board player)))))))

(defn- loop-game [board moves player-index]
    (let [player (nth player-marks player-index)]
        (if-let [column (ask-column board player)]
            (let [row (lowest-empty-row board column)
                new-board (assoc-in board [row column] player)
                new-moves (inc moves)]
                (print (str "\n" (render new-board) "\n"))
                (flush)
                (cond
                    (has-four? new-board player)
                    (do
                        (print (str "Player " player " wins!\n"))
                        (flush))

                    (= new-moves (* rows cols))
                    (do
                        (print "It's a tie!\n")
                        (flush))

                    :else
                    (loop-game new-board new-moves (- 1 player-index))))
            nil)))

(defn -main []
    (let [board (new-board)]
        (print (str header "\n" (render board) "\n"))
        (flush)
        (loop-game board 0 0)))

(-main)
