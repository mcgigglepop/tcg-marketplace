package main

import (
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"

	"github.com/mcgigglepop/tcg-marketplace/server/internal/config"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/handlers"
)

// routes sets up the application's HTTP routes and middleware.
func routes(app *config.AppConfig) http.Handler {
	mux := chi.NewRouter()

	// Global middleware
	mux.Use(middleware.Recoverer) // Recover from panics
	mux.Use(NoSurf)               // CSRF protection
	mux.Use(SessionLoad)          // Load and save session data
	mux.Use(ProxyFix)             // trust ALB’s X-Forwarded-Proto: https header

	// Public routes
	mux.Get("/health", handlers.Repo.GetHealth)
	mux.Get("/register", handlers.Repo.GetRegister)
	mux.Post("/register", handlers.Repo.PostRegister)
	mux.Get("/login", handlers.Repo.GetLogin)
	mux.Post("/login", handlers.Repo.PostLogin)
	mux.Get("/email-verification", handlers.Repo.GetEmailVerification)
	mux.Post("/email-verification", handlers.Repo.PostEmailVerification)

	// Serve static files from the ./static directory
	fileServer := http.FileServer(http.Dir("./static/"))
	mux.Handle("/static/*", http.StripPrefix("/static", fileServer))

	return mux
}
