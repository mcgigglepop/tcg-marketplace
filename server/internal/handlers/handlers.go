package handlers

import (
	"net/http"
	"strings"

	"github.com/mcgigglepop/tcg-marketplace/server/internal/config"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/forms"
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

// GetLogin is the login page handler
func (m *Repository) GetLogin(w http.ResponseWriter, r *http.Request) {
	render.Template(w, r, "login.page.tmpl", &models.TemplateData{})
}

// /////////////////////////////////////////////////////////////
// /////////////////// POST REQUESTS ///////////////////////////
// /////////////////////////////////////////////////////////////

func (m *Repository) PostRegister(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	if err := m.App.Session.RenewToken(ctx); err != nil {
		m.App.ErrorLog.Printf("session renewal failed: %v", err)
		http.Error(w, "unable to process request", http.StatusInternalServerError)
		return
	}

	if err := r.ParseForm(); err != nil {
		m.App.ErrorLog.Printf("registration form parse failed: %v", err)
		http.Error(w, "invalid form submission", http.StatusBadRequest)
		return
	}

	form := forms.New(r.PostForm)
	form.Required("email", "password")
	form.IsEmail("email")

	if !form.Valid() {
		w.WriteHeader(http.StatusUnprocessableEntity)
		render.Template(w, r, "register.page.tmpl", &models.TemplateData{
			Form: form,
		})
		return
	}

	email := strings.ToLower(strings.TrimSpace(r.Form.Get("email")))
	password := r.Form.Get("password")

	if email == "" || password == "" {
		m.App.ErrorLog.Println("registration missing email or password after validation")
		http.Error(w, "missing registration details", http.StatusBadRequest)
		return
	}

	if err := m.App.CognitoClient.RegisterUser(ctx, email, password); err != nil {
		m.App.ErrorLog.Printf("cognito RegisterUser failed for %s: %v", email, err)
		m.App.Session.Put(ctx, "error", "Registration failed. Please try again.")
		http.Redirect(w, r, "/register", http.StatusSeeOther)
		return
	}

	m.App.InfoLog.Printf("registration initiated for %s", email)

	m.App.Session.Put(ctx, "user_email", email)
	m.App.Session.Put(ctx, "flash", "Registered successfully. Please check your email for verification.")
	http.Redirect(w, r, "/email-verification", http.StatusSeeOther)
}
