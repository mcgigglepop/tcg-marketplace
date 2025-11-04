package config

import (
	"html/template"
	"log"

	"github.com/alexedwards/scs/v2"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/cognito"
)

// AppConfig holds the application configuration and shared dependencies.
type AppConfig struct {
	UseCache      bool                          // Whether to use the template cache
	TemplateCache map[string]*template.Template // Cached templates
	InfoLog       *log.Logger                   // Logger for informational messages
	ErrorLog      *log.Logger                   // Logger for error messages
	InProduction  bool                          // True if running in production
	Session       *scs.SessionManager           // Session manager
	CognitoClient *cognito.CognitoClient        // AWS Cognito client for authentication
}
