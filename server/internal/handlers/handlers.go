package handlers

import (
	"net/http"

	"github.com/mcgigglepop/tcg-marketplace/server/internal/config"
)

// Repo is the repository used by the handlers.
var Repo *Repository

// Repository holds the application config and dependencies for handlers.
type Repository struct {
	App *config.AppConfig
}

// NewRepo creates a new Repository with the given app config.
func NewRepo(a *config.AppConfig) *Repository {
	return &Repository{
		App: a,
	}
}

// NewHandlers sets the global Repo variable to the provided repository.
func NewHandlers(r *Repository) {
	Repo = r
}

// ////////////////////////////////////////////////////////////
// /////////////////// GET REQUESTS ///////////////////////////
// ////////////////////////////////////////////////////////////

// GetHealth is the health check handler for ECS
func (m *Repository) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}

// /////////////////////////////////////////////////////////////
// /////////////////// POST REQUESTS ///////////////////////////
// /////////////////////////////////////////////////////////////
