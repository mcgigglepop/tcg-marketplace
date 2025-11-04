package main

import (
	"context"
	"encoding/gob"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/alexedwards/scs/redisstore"
	"github.com/alexedwards/scs/v2"
	"github.com/gomodule/redigo/redis"

	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/cognito"
	appConfig "github.com/mcgigglepop/tcg-marketplace/server/internal/config"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/handlers"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/helpers"
	"github.com/mcgigglepop/tcg-marketplace/server/internal/render"
)

const portNumber = ":80"

var app appConfig.AppConfig
var session *scs.SessionManager
var infoLog *log.Logger
var errorLog *log.Logger

func getEnvOrExit(key string) string {
	val := os.Getenv(key)
	if val == "" {
		log.Fatalf("Missing required env var: %s", key)
	}
	return val
}

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
	gob.Register(map[string]int{})
	inProduction := flag.Bool("production", true, "Application is in production")
	useCache := flag.Bool("cache", true, "Use template cache")

	cognitoUserPoolID := flag.String(
		"cognito-user-pool-id",
		os.Getenv("COGNITO_USER_POOL_ID"),
		"Cognito user pool ID",
	)

	cognitoClientID := flag.String(
		"cognito-client-id",
		os.Getenv("COGNITO_CLIENT_ID"),
		"Cognito app client ID",
	)

	// parse flags
	flag.Parse()

	if *cognitoUserPoolID == "" || *cognitoClientID == "" {
		fmt.Println("Missing Cognito flags")
		os.Exit(1)
	}

	app.InProduction = *inProduction
	app.UseCache = *useCache

	infoLog = log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errorLog = log.New(os.Stdout, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)
	app.InfoLog = infoLog
	app.ErrorLog = errorLog

	// Redis connection setup using redigo
	redisEndpoint := getEnvOrExit("REDIS_ENDPOINT") // format: host:port
	redisPassword := os.Getenv("REDIS_PASSWORD")    // optional

	// Create a redigo connection pool
	pool := &redis.Pool{
		MaxIdle:     10,
		MaxActive:   100,
		IdleTimeout: 240 * time.Second,
		Dial: func() (redis.Conn, error) {
			opts := []redis.DialOption{}
			if redisPassword != "" {
				opts = append(opts, redis.DialPassword(redisPassword))
			}
			c, err := redis.Dial("tcp", redisEndpoint, opts...)
			if err != nil {
				return nil, fmt.Errorf("failed to connect to Redis: %v", err)
			}
			return c, nil
		},
		TestOnBorrow: func(c redis.Conn, t time.Time) error {
			if time.Since(t) < time.Minute {
				return nil
			}
			_, err := c.Do("PING")
			return err
		},
	}

	// Test connection immediately
	conn := pool.Get()
	defer conn.Close()
	if _, err := conn.Do("PING"); err != nil {
		log.Fatalf("failed to connect to Redis: %v", err)
	}
	infoLog.Println("Connected to Redis for session storage")

	// set up session
	session = scs.New()
	session.Store = redisstore.New(pool)
	session.Lifetime = 24 * time.Hour
	session.Cookie.Persist = true
	session.Cookie.SameSite = http.SameSiteLaxMode
	session.Cookie.Secure = app.InProduction
	app.Session = session

	// AWS SDK config
	awsCfg, err := awsConfig.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal("failed to load AWS config:", err)
	}

	// Cognito client
	cognitoClient, err := cognito.NewCognitoClientWithCfg(awsCfg, *cognitoUserPoolID, *cognitoClientID)
	if err != nil {
		log.Fatal("failed to create Cognito client:", err)
	}

	app.CognitoClient = cognitoClient

	tc, err := render.CreateTemplateCache()
	if err != nil {
		log.Fatal("Cannot create template cache")
		return err
	}
	app.TemplateCache = tc

	repo := handlers.NewRepo(&app)
	handlers.NewHandlers(repo)
	render.NewRenderer(&app)
	helpers.NewHelpers(&app)

	return nil
}
