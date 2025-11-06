package models

// User represents a user in the system, anchored to Cognito
type User struct {
	PK          string   `dynamodbav:"PK"`
	SK          string   `dynamodbav:"SK"`
	Type        string   `dynamodbav:"Type"`
	UserID      string   `dynamodbav:"userID"`
	Email       string   `dynamodbav:"email"`
	DisplayName string   `dynamodbav:"displayName"`
	Roles       []string `dynamodbav:"roles"`
	GSI1PK      string   `dynamodbav:"GSI1PK"`
	GSI1SK      string   `dynamodbav:"GSI1SK"`
	CreatedAt   string   `dynamodbav:"createdAt"`
	UpdatedAt   string   `dynamodbav:"updatedAt"`
}