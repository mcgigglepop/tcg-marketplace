Awesome—let’s get you a clean, production-ready registration flow that supports buyers first, then a smooth upgrade to verified seller. Below is a concrete blueprint tailored to Go + chi + .tmpl on DynamoDB (with Cognito for auth), plus code/schema you can drop in.

High-level flow

Buyer sign-up

User signs up (Cognito Hosted UI or username/password on your site → Cognito API).

Cognito sends email verification automatically.

After verification, your backend creates a User profile in DynamoDB.

Role = buyer by default.

Seller upgrade

Buyer clicks “Become a Seller”.

Complete required steps (address, phone, tax form attestation, payout onboarding with Stripe Connect, KYC with Stripe Identity/Persona).

Webhook callbacks update DynamoDB to seller_pending → seller_verified on approval.

Only seller_verified can list items or receive payouts.

DynamoDB single-table design

Table: marketplace (single table, on-demand or provisioned)

Primary key

PK (string)

SK (string)

GSIs

GSI1 (for lookup by email):

GSI1PK = EMAIL#<lowercasedEmail>

GSI1SK = USER#<userID>

GSI2 (for seller status dashboards/search):

GSI2PK = SELLER_STATUS#<status> (e.g., pending, verified, rejected)

GSI2SK = USER#<userID>

Item shapes

User profile

PK:  USER#<userID>
SK:  PROFILE
Type: USER
userID: "<cognitoSub or uuid>"
email: "<lowercase>"
displayName: "<string>"
roles: ["buyer"] | ["buyer","seller_pending"] | ["buyer","seller_verified"]
createdAt: "<RFC3339>"
updatedAt: "<RFC3339>"
GSI1PK: EMAIL#<email>
GSI1SK: USER#<userID>


Seller application (one active; keep history if you want)

PK:  USER#<userID>
SK:  SELLER_APP#<yyyy-mm-ddThh:mm:ssZ>
Type: SELLER_APP
status: "draft" | "submitted" | "kyc_pending" | "rejected" | "approved"
requiredSteps: ["address","payout","kyc","tos"]
completedSteps: ["address","payout"]
kycProvider: "stripe_identity" | "persona"
kycRef: "<external-check-id>"
payoutProvider: "stripe"
payoutRef: "<acct_123>"
notes: "<optional reviewer notes>"
createdAt, updatedAt
GSI2PK: SELLER_STATUS#<status>
GSI2SK: USER#<userID>


Audit trail (optional, great for disputes)

PK:  USER#<userID>
SK:  EVENT#<ts>
Type: USER_EVENT
event: "REGISTERED" | "EMAIL_VERIFIED" | "SELLER_SUBMITTED" | "KYC_APPROVED" | ...
meta: { ... }
createdAt

Auth choices (recommended)

AWS Cognito User Pool for sign-up/verification/password reset and OIDC tokens.

Store Cognito sub as your canonical userID.

Use Cognito Hosted UI (low effort) or SRP/Hosted APIs if you need custom UI.

Your Go backend verifies JWT access tokens on every request (middleware).

Routes & pages

Public

GET /register → Sign-up form (or redirect to Cognito Hosted UI)

POST /register → If doing custom UI: call Cognito SignUp, then show “check your email”

GET /auth/callback → Hosted UI redirect; create user profile if first login

Authenticated (buyer)

GET /account → Profile page

POST /account → Update profile

Seller upgrade

GET /seller/onboard → checklist UI (address, tax, payout, KYC)

POST /seller/onboard/address → save address

POST /seller/onboard/payout → create Stripe Connect account link; redirect user

POST /seller/onboard/kyc/start → create verification session; redirect user

Webhooks:

POST /webhooks/stripe → payout account capabilities/requirements updates

POST /webhooks/kyc → KYC result → flip to seller_verified

Middleware

auth (JWT from Cognito), csrftoken, rateLimit, secureHeaders

Go: minimal repo shape
cmd/api/main.go
internal/http/router.go
internal/http/middleware.go
internal/handlers/auth.go
internal/handlers/account.go
internal/handlers/seller.go
internal/handlers/webhooks.go
internal/db/dynamo.go
internal/db/user_repo.go
internal/core/users.go
internal/core/sellers.go
web/templates/*.tmpl

Go (chi) – core snippets

JWT middleware (Cognito) sketch

// middleware.go
func Auth(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    token := extractBearer(r.Header.Get("Authorization"))
    if token == "" {
      http.Error(w, "unauthorized", http.StatusUnauthorized); return
    }
    claims, err := verifyCognitoJWT(r.Context(), token) // JWKS validate
    if err != nil { http.Error(w, "invalid token", http.StatusUnauthorized); return }
    ctx := context.WithValue(r.Context(), "user", claims)
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}


Create user profile on first login (idempotent)

// users.go
type User struct {
  PK, SK            string `dynamodbav:"PK" dynamodbav:"SK"`
  Type              string `dynamodbav:"Type"`
  UserID            string `dynamodbav:"userID"`
  Email             string `dynamodbav:"email"`
  DisplayName       string `dynamodbav:"displayName"`
  Roles             []string `dynamodbav:"roles"`
  GSI1PK            string `dynamodbav:"GSI1PK"`
  GSI1SK            string `dynamodbav:"GSI1SK"`
  CreatedAt         string `dynamodbav:"createdAt"`
  UpdatedAt         string `dynamodbav:"updatedAt"`
}

func (r *UserRepo) EnsureUserProfile(ctx context.Context, userID, email, display string) error {
  now := time.Now().UTC().Format(time.RFC3339)
  u := User{
    PK: "USER#" + userID, SK: "PROFILE", Type: "USER",
    UserID: userID, Email: strings.ToLower(email), DisplayName: display,
    Roles: []string{"buyer"},
    GSI1PK: "EMAIL#" + strings.ToLower(email),
    GSI1SK: "USER#" + userID,
    CreatedAt: now, UpdatedAt: now,
  }
  av, _ := attributevalue.MarshalMap(u)

  // Create only if not exists
  _, err := r.ddb.PutItem(ctx, &dynamodb.PutItemInput{
    TableName: aws.String(r.table),
    Item:      av,
    ConditionExpression: aws.String("attribute_not_exists(PK)"),
  })
  if isConditionalCheckErr(err) {
    // Already exists — update display/email if needed (optional)
    return nil
  }
  return err
}


Lookup by email (unique constraint)

Enforce uniqueness at Cognito (email unique) and keep a GSI1 to find user by email if needed.

Start seller onboarding

// sellers.go
type SellerApp struct {
  PK, SK                  string `dynamodbav:"PK" dynamodbav:"SK"`
  Type                    string `dynamodbav:"Type"`
  Status                  string `dynamodbav:"status"`
  RequiredSteps           []string `dynamodbav:"requiredSteps"`
  CompletedSteps          []string `dynamodbav:"completedSteps"`
  KYCProvider, KYCRef     string `dynamodbav:"kycProvider" dynamodbav:"kycRef"`
  PayoutProvider, PayoutRef string `dynamodbav:"payoutProvider" dynamodbav:"payoutRef"`
  GSI2PK, GSI2SK          string `dynamodbav:"GSI2PK" dynamodbav:"GSI2SK"`
  CreatedAt, UpdatedAt    string `dynamodbav:"createdAt" dynamodbav:"updatedAt"`
}

func (r *SellerRepo) CreateOrGetDraft(ctx context.Context, userID string) (*SellerApp, error) {
  // Try to find latest draft/active. If none, create a new draft with required steps.
  app := &SellerApp{
    PK: "USER#" + userID,
    SK: "SELLER_APP#" + time.Now().UTC().Format(time.RFC3339),
    Type: "SELLER_APP",
    Status: "draft",
    RequiredSteps: []string{"address","payout","kyc","tos"},
    CompletedSteps: []string{},
    GSI2PK: "SELLER_STATUS#draft",
    GSI2SK: "USER#" + userID,
    CreatedAt: time.Now().UTC().Format(time.RFC3339),
    UpdatedAt: time.Now().UTC().Format(time.RFC3339),
  }
  item, _ := attributevalue.MarshalMap(app)
  _, err := r.ddb.PutItem(ctx, &dynamodb.PutItemInput{
    TableName: aws.String(r.table), Item: item,
  })
  return app, err
}

func (r *UserRepo) MarkSellerStatus(ctx context.Context, userID, status string) error {
  // Update roles atomically
  now := time.Now().UTC().Format(time.RFC3339)
  _, err := r.ddb.UpdateItem(ctx, &dynamodb.UpdateItemInput{
    TableName: aws.String(r.table),
    Key: map[string]types.AttributeValue{
      "PK": &types.AttributeValueMemberS{Value: "USER#" + userID},
      "SK": &types.AttributeValueMemberS{Value: "PROFILE"},
    },
    UpdateExpression: aws.String("SET #roles = :roles, updatedAt = :now"),
    ExpressionAttributeNames: map[string]string{"#roles": "roles"},
    ExpressionAttributeValues: map[string]types.AttributeValue{
      ":roles": &types.AttributeValueMemberL{Value: toAttrList(roleSliceFor(status))},
      ":now":   &types.AttributeValueMemberS{Value: now},
    },
  })
  return err
}


roleSliceFor could return:

buyer, seller_pending for pending

buyer, seller_verified for approved

.tmpl pages you’ll want

register.tmpl – (if not using Hosted UI) email, password, display name, CSRF token.

account.tmpl – profile form; banner “Become a seller”.

seller_onboard.tmpl – checklist (address ✅ payout ✅ kyc ⏳ tos ✅), auto-refresh status.

seller_pending.tmpl – “We’re reviewing your verification…”.

seller_verified.tmpl – congrats, create first listing CTA.

Keep forms POST with hidden CSRF, server-side validation errors rendered inline.

KYC + payouts (pluggable)

Stripe Connect (recommended)

Create account: type=express, scope payouts.

Store acct_xxx in SellerApp payoutRef.

Redirect user to Account Link for onboarding.

Webhook updates (account.updated, capability.updated) → if requirements met, set seller_verified.

KYC (Stripe Identity or Persona)

Start verification session; store KYCRef.

Webhook on success/failure updates SellerApp status and User roles.

Why both?

Payouts compliance lives in Stripe.

Identity/KYC may need additional signals; you can rely on Stripe only to keep it simpler.

Security & fraud-prevention must-haves (registration tier)

Email verification (Cognito) before creating any seller application.

Rate-limit signups & login attempts (IP + fingerprint).

reCAPTCHA/Turnstile on sign-up and seller steps.

Address + phone verification (e.g., USPS/E.164).

Audit trail on every role/status transition.

Webhook verification (Stripe signature / Persona secret).

Least privilege IAM for DynamoDB, SES, webhooks.

Testing checklist

Unit tests for: EnsureUserProfile, role transitions, webhook handlers.

Integration tests that simulate:

Cognito sign-up/verify

First login → profile creation idempotency

Seller onboarding happy path (address → payout → kyc → approved)

Webhook retries & signature check

Permission checks (only seller_verified can POST /listings)

“Do this next” (concrete next steps)

Spin Cognito (User Pool + client; email verification on).

Create DynamoDB table + GSI1/GSI2.

Wire JWT middleware (JWKS verify).

Implement EnsureUserProfile on /auth/callback.

Build seller checklist page + routes above.

Integrate Stripe Connect (Express) and KYC provider; add webhooks.

Flip feature flag so only seller_verified sees “Create Listing”.

If you want, I can generate:

the Terraform (DynamoDB table + GSIs + Cognito basics),

the chi router + handlers scaffolding,

and the initial .tmpl files (register/onboard/checklist).
Say the word and I’ll drop in all three.