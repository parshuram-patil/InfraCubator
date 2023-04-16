package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
)

type Vote struct {
	Name  string `json:"name"`
	Message string    `json:"message"`
}

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Ok")
    })

    http.HandleFunc("/vote", vote)

    log.Fatal(http.ListenAndServe(":8080", nil))
}

func vote(w http.ResponseWriter, r *http.Request) {
	var vote Vote
	err := json.NewDecoder(r.Body).Decode(&vote)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	vote.Message = "Thanks for voting " + vote.Name

	json.NewEncoder(w).Encode(vote)
}