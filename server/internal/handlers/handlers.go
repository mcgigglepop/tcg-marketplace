package handlers

import (
	"net/http"

	"github.com/mcgigglepop/tcg-marketplace/server/internal/config"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/models"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/render"
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

// GetRegister is the register page handler
func (m *Repository) GetRegister(w http.ResponseWriter, r *http.Request) {
	render.Template(w, r, "register.page.tmpl", &models.TemplateData{})
}

// /////////////////////////////////////////////////////////////
// /////////////////// POST REQUESTS ///////////////////////////
// /////////////////////////////////////////////////////////////
