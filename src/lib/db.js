// db.js
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

// Initialize DynamoDB client
const client = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-west-2",
});

export const ddb = DynamoDBDocumentClient.from(client);

// Table name from environment variable (set by Lambda)
export const TABLE = process.env.USER_TABLE || process.env.TABLE_NAME;
if (!TABLE) {
  throw new Error("Missing USER_TABLE or TABLE_NAME env var");
}

// Global Secondary Index names
export const GSI1 = "GSI1"; // Email lookup: GSI1PK = EMAIL#<email>, GSI1SK = USER#<userID>
export const GSI2 = "GSI2"; // Seller status: GSI2PK = SELLER_STATUS#<status>, GSI2SK = USER#<userID>

// Primary key attribute names
export const PK = "PK"; // Partition key
export const SK = "SK"; // Sort key

// GSI key attribute names
export const GSI1PK = "GSI1PK";
export const GSI1SK = "GSI1SK";
export const GSI2PK = "GSI2PK";
export const GSI2SK = "GSI2SK";

// Item type constants
export const ITEM_TYPES = {
  USER: "USER",
  SELLER_APP: "SELLER_APP",
  USER_EVENT: "USER_EVENT",
};

// Helper functions for building keys according to the schema
export const KeyBuilders = {
  /**
   * Build primary key for user profile
   * @param {string} userID - Cognito sub or UUID
   * @returns {{PK: string, SK: string}}
   */
  userProfile: (userID) => ({
    PK: `USER#${userID}`,
    SK: "PROFILE",
  }),

  /**
   * Build GSI1 key for email lookup
   * @param {string} email - User email (will be lowercased)
   * @param {string} userID - User ID
   * @returns {{GSI1PK: string, GSI1SK: string}}
   */
  emailLookup: (email, userID) => ({
    GSI1PK: `EMAIL#${email.toLowerCase()}`,
    GSI1SK: `USER#${userID}`,
  }),

  /**
   * Build primary key for seller application
   * @param {string} userID - User ID
   * @param {string} timestamp - ISO timestamp (optional, defaults to current time)
   * @returns {{PK: string, SK: string}}
   */
  sellerApp: (userID, timestamp = null) => ({
    PK: `USER#${userID}`,
    SK: `SELLER_APP#${timestamp || new Date().toISOString()}`,
  }),

  /**
   * Build GSI2 key for seller status lookup
   * @param {string} status - Seller status (draft, submitted, kyc_pending, verified, rejected)
   * @param {string} userID - User ID
   * @returns {{GSI2PK: string, GSI2SK: string}}
   */
  sellerStatus: (status, userID) => ({
    GSI2PK: `SELLER_STATUS#${status}`,
    GSI2SK: `USER#${userID}`,
  }),

  /**
   * Build primary key for user event/audit log
   * @param {string} userID - User ID
   * @param {string} timestamp - ISO timestamp (optional, defaults to current time)
   * @returns {{PK: string, SK: string}}
   */
  userEvent: (userID, timestamp = null) => ({
    PK: `USER#${userID}`,
    SK: `EVENT#${timestamp || new Date().toISOString()}`,
  }),
};