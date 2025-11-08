package handlers

import (
	"log"
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

// EmailVerificationGet handles GET requests for the email verification page.
// Redirects to login if no email is found in session.
func (m *Repository) GetEmailVerification(w http.ResponseWriter, r *http.Request) {
	email := m.App.Session.GetString(r.Context(), "user_email")

	if email == "" {
		log.Println("No email found in session, cannot verify email")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	render.Template(w, r, "email-verification.page.tmpl", &models.TemplateData{
		Data: map[string]interface{}{
			"Email": email,
		},
	})
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

// EmailVerificationPost handles POST requests for email verification.
// Validates OTP form, confirms user with Cognito, and redirects appropriately.
func (m *Repository) PostEmailVerification(w http.ResponseWriter, r *http.Request) {
	if err := m.App.Session.RenewToken(r.Context()); err != nil {
		m.App.ErrorLog.Println("Session token renewal failed:", err)
	}

	email := m.App.Session.GetString(r.Context(), "user_email")

	if email == "" {
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	if err := r.ParseForm(); err != nil {
		m.App.ErrorLog.Println("ParseForm error:", err)
	}

	form := forms.New(r.PostForm)
	form.Required("otpFirst", "otpSecond", "otpThird", "otpFourth", "otpFifth", "otpSixth")

	if !form.Valid() {
		log.Printf("[DEBUG] Form validation failed: %+v", form.Errors)
		render.Template(w, r, "email-verification.page.tmpl", &models.TemplateData{
			Form: form,
		})
		return
	}

	// Concatenate OTP digits from form fields
	otpCode := strings.TrimSpace(
		r.Form.Get("otpFirst") +
			r.Form.Get("otpSecond") +
			r.Form.Get("otpThird") +
			r.Form.Get("otpFourth") +
			r.Form.Get("otpFifth") +
			r.Form.Get("otpSixth"),
	)

	_, err := m.App.CognitoClient.ConfirmUser(r.Context(), email, otpCode)
	if err != nil {
		m.App.ErrorLog.Printf("Cognito ConfirmUser failed: %v", err)
		m.App.Session.Put(r.Context(), "error", "Email verification failed. Please try again.")
		http.Redirect(w, r, "/email-verification", http.StatusSeeOther)
		return
	}

	// Remove user email from session after successful verification
	m.App.Session.Remove(r.Context(), "user_email")
	m.App.Session.Put(r.Context(), "flash", "Email Verified.")
	http.Redirect(w, r, "/login", http.StatusSeeOther)
}

// LoginPost handles POST requests for user login.
// Validates form, logs in user with Cognito, and sets session tokens.
func (m *Repository) PostLogin(w http.ResponseWriter, r *http.Request) {
	if err := m.App.Session.RenewToken(r.Context()); err != nil {
		m.App.ErrorLog.Println("Session token renewal failed:", err)
	}

	err := r.ParseForm()
	if err != nil {
		m.App.ErrorLog.Println("ParseForm error:", err)
	}

	form := forms.New(r.PostForm)

	form.Required("email", "password")
	form.IsEmail("email")

	if !form.Valid() {
		render.Template(w, r, "login.page.tmpl", &models.TemplateData{
			Form: form,
		})
		return
	}

	email := strings.TrimSpace(r.Form.Get("email"))
	password := r.Form.Get("password")

	auth_response, userErr := m.App.CognitoClient.Login(r.Context(), email, password)
	if userErr != nil {
		m.App.ErrorLog.Println("Cognito Login failed:", userErr)
		m.App.Session.Put(r.Context(), "error", "Login failed. Please try again.")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	sub, err := m.App.CognitoClient.ExtractSubFromToken(r.Context(), auth_response.IdToken)

	if err != nil {
		// handle error
	}

	// Store user ID and tokens in session
	m.App.Session.Put(r.Context(), "user_id", sub)
	m.App.Session.Put(r.Context(), "id_token", auth_response.IdToken)
	m.App.Session.Put(r.Context(), "access_token", auth_response.AccessToken)
	m.App.Session.Put(r.Context(), "refresh_token", auth_response.RefreshToken)

	m.App.Session.Put(r.Context(), "flash", "login successfully.")
	http.Redirect(w, r, "/track-calories", http.StatusSeeOther)
}