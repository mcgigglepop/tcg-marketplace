package main

import (
	"log"
	"net/http"

	"github.com/alexedwards/scs/v2"
	appConfig "github.com/mcgigglepop/tcg-marketplace/server/internal/config"
)

const portNumber = ":80"

var app appConfig.AppConfig
var session *scs.SessionManager

func main() {
	// Initialize application
	if err := run(); err != nil {
		log.Fatal(err)
	}

	// Start the HTTP server
	log.Printf("Starting application on port %s", portNumber)
	srv := &http.Server{
		Addr:    portNumber,
		Handler: routes(&app),
	}

	// Run the server
	log.Fatal(srv.ListenAndServe())
}

// run initializes the application config, session, AWS clients, and templates
func run() error {

	session = scs.New()
	app.Session = session
	return nil
}
