// triggers/postConfirmation.js
import { ddb, TABLE, KeyBuilders, ITEM_TYPES } from "../lib/db.js";
import { PutCommand } from "@aws-sdk/lib-dynamodb";

/**
 * Cognito Post Confirmation Lambda Trigger
 * Creates a user profile in DynamoDB after email verification
 * 
 * Event structure:
 * - event.request.userAttributes.sub: Cognito user ID
 * - event.request.userAttributes.email: User email
 * - event.request.userAttributes.given_name: First name (optional)
 * - event.request.userAttributes.family_name: Last name (optional)
 */
export const handler = async (event) => {
  try {
    const userAttributes = event.request.userAttributes;
    const userID = userAttributes.sub;
    const email = userAttributes.email?.toLowerCase() || "";
    const givenName = userAttributes.given_name || "";
    const familyName = userAttributes.family_name || "";
    
    // Build display name from given/family name, or use email prefix as fallback
    const displayName = givenName || familyName
      ? `${givenName} ${familyName}`.trim()
      : email.split("@")[0];

    const now = new Date().toISOString();

    // Build keys using helper functions
    const userKey = KeyBuilders.userProfile(userID);
    const emailKey = KeyBuilders.emailLookup(email, userID);

    // Create user profile item according to kyc.md schema
    const userProfile = {
      ...userKey,
      ...emailKey,
      Type: ITEM_TYPES.USER,
      userID: userID,
      email: email,
      displayName: displayName,
      roles: ["buyer"], // Default role - buyer only
      createdAt: now,
      updatedAt: now,
    };

    // Use PutCommand with ConditionExpression to make it idempotent
    // This ensures we don't overwrite existing profiles
    await ddb.send(
      new PutCommand({
        TableName: TABLE,
        Item: userProfile,
        ConditionExpression: "attribute_not_exists(PK)",
      })
    );

    console.log(`User profile created for ${userID} (${email})`);
    return event;
  } catch (error) {
    // If item already exists (ConditionalCheckFailedException), that's okay
    // This makes the function idempotent
    if (error.name === "ConditionalCheckFailedException") {
      console.log(`User profile already exists for ${event.request.userAttributes.sub}`);
      return event;
    }

    // Log other errors but don't fail the confirmation
    // Cognito will still confirm the user even if this fails
    console.error("Error creating user profile:", error);
    return event;
  }
};
