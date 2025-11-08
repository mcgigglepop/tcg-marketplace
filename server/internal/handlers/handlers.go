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

// EmailVerificationGet handles GET requests for the email verification page.
// Redirects to login if no email is found in session.
func (m *Repository) GetEmailVerification(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	email := m.App.Session.GetString(ctx, "user_email")

	if email == "" {
		m.App.InfoLog.Println("email verification attempted without session email; redirecting to login")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	render.Template(w, r, "email-verification.page.tmpl", &models.TemplateData{
		Data: map[string]interface{}{
			"Email": email,
		},
	})
}

// GetLogout is the logout page handler
func (m *Repository) GetLogout(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	_ = m.App.Session.Destroy(ctx)
	_ = m.App.Session.RenewToken(ctx)
	m.App.Session.Put(ctx, "flash", "Logged out successfully.")
	http.Redirect(w, r, "/login", http.StatusSeeOther)
}

// GetDashboard is the dashboard page handler
func (m *Repository) GetBuyerDashboard(w http.ResponseWriter, r *http.Request) {
	render.Template(w, r, "buyer-dashboard.page.tmpl", &models.TemplateData{})
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
	ctx := r.Context()

	if err := m.App.Session.RenewToken(ctx); err != nil {
		m.App.ErrorLog.Printf("session renewal failed during email verification: %v", err)
		http.Error(w, "unable to process request", http.StatusInternalServerError)
		return
	}

	email := strings.ToLower(strings.TrimSpace(m.App.Session.GetString(ctx, "user_email")))
	if email == "" {
		m.App.InfoLog.Println("email verification attempted without session email; redirecting to login")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	if err := r.ParseForm(); err != nil {
		m.App.ErrorLog.Printf("email verification form parse failed: %v", err)
		http.Error(w, "invalid form submission", http.StatusBadRequest)
		return
	}

	form := forms.New(r.PostForm)
	form.Required("otpFirst", "otpSecond", "otpThird", "otpFourth", "otpFifth", "otpSixth")

	if !form.Valid() {
		w.WriteHeader(http.StatusUnprocessableEntity)
		render.Template(w, r, "email-verification.page.tmpl", &models.TemplateData{
			Form: form,
		})
		return
	}

	otpCode := strings.TrimSpace(
		r.Form.Get("otpFirst") +
			r.Form.Get("otpSecond") +
			r.Form.Get("otpThird") +
			r.Form.Get("otpFourth") +
			r.Form.Get("otpFifth") +
			r.Form.Get("otpSixth"),
	)

	if len(otpCode) != 6 {
		m.App.ErrorLog.Printf("invalid OTP length for %s", email)
		m.App.Session.Put(ctx, "error", "Invalid code. Please enter the 6-digit code sent to your email.")
		http.Redirect(w, r, "/email-verification", http.StatusSeeOther)
		return
	}

	if _, err := m.App.CognitoClient.ConfirmUser(ctx, email, otpCode); err != nil {
		m.App.ErrorLog.Printf("cognito ConfirmUser failed for %s: %v", email, err)
		m.App.Session.Put(ctx, "error", "Email verification failed. Please try again.")
		http.Redirect(w, r, "/email-verification", http.StatusSeeOther)
		return
	}

	m.App.InfoLog.Printf("email verified for %s", email)

	m.App.Session.Remove(ctx, "user_email")
	m.App.Session.Put(ctx, "flash", "Email verified successfully. You can now log in.")
	http.Redirect(w, r, "/login", http.StatusSeeOther)
}

// LoginPost handles POST requests for user login.
// Validates form, logs in user with Cognito, and sets session tokens.
func (m *Repository) PostLogin(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	if err := m.App.Session.RenewToken(ctx); err != nil {
		m.App.ErrorLog.Printf("session renewal failed during login: %v", err)
		http.Error(w, "unable to process request", http.StatusInternalServerError)
		return
	}

	if err := r.ParseForm(); err != nil {
		m.App.ErrorLog.Printf("login form parse failed: %v", err)
		http.Error(w, "invalid form submission", http.StatusBadRequest)
		return
	}

	form := forms.New(r.PostForm)
	form.Required("email", "password")
	form.IsEmail("email")

	if !form.Valid() {
		w.WriteHeader(http.StatusUnprocessableEntity)
		render.Template(w, r, "login.page.tmpl", &models.TemplateData{
			Form: form,
		})
		return
	}

	email := strings.ToLower(strings.TrimSpace(r.Form.Get("email")))
	password := r.Form.Get("password")

	if email == "" || password == "" {
		m.App.ErrorLog.Println("login missing email or password after validation")
		http.Error(w, "missing login details", http.StatusBadRequest)
		return
	}

	authResponse, err := m.App.CognitoClient.Login(ctx, email, password)
	if err != nil {
		m.App.ErrorLog.Printf("cognito Login failed for %s: %v", email, err)
		m.App.Session.Put(ctx, "error", "Login failed. Please try again.")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	sub, err := m.App.CognitoClient.ExtractSubFromToken(ctx, authResponse.IdToken)
	if err != nil {
		m.App.ErrorLog.Printf("failed extracting sub from token for %s: %v", email, err)
		m.App.Session.Put(ctx, "error", "Login failed. Please try again.")
		http.Redirect(w, r, "/login", http.StatusSeeOther)
		return
	}

	m.App.InfoLog.Printf("user %s logged in", sub)

	m.App.Session.Put(ctx, "user_id", sub)
	m.App.Session.Put(ctx, "id_token", authResponse.IdToken)
	m.App.Session.Put(ctx, "access_token", authResponse.AccessToken)
	m.App.Session.Put(ctx, "refresh_token", authResponse.RefreshToken)

	m.App.Session.Put(ctx, "flash", "Logged in successfully.")
	http.Redirect(w, r, "/dashboard", http.StatusSeeOther)
}
