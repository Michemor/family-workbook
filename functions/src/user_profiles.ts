import { onCall, HttpsError } from "firebase-functions/v2/https";
import admin from "firebase-admin";

const db = admin.firestore();

/**
 * Callable function that creates or updates a user profile document in Firestore.
 * Must be called by an authenticated user.
 */
export const setupUserProfile = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to set a profile."
    );
  }

  const uid = request.auth.uid;
  const {
    username,
    email,
    profilePictureUrl,
    personalityType,
    familyType,
    role,
  } = request.data;

  if (!username || !email) {
    throw new HttpsError(
      "invalid-argument",
      "Username and email are required."
    );
  }

  try {
    // Validate against allowed dropdown options stored in Firestore
    const configDoc = await db
      .collection("SystemConfigurations")
      .doc("dropdownOptions")
      .get();

    if (!configDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Dropdown options configuration not found."
      );
    }

    const allowedOptions: string[] = configDoc.data()?.options ?? [];

    if (personalityType && !allowedOptions.includes(personalityType)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid personality type. Allowed options are: ${allowedOptions.join(", ")}.`
      );
    }

    if (familyType && !allowedOptions.includes(familyType)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid family type. Allowed options are: ${allowedOptions.join(", ")}.`
      );
    }

    if (role && !allowedOptions.includes(role)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid role. Allowed options are: ${allowedOptions.join(", ")}.`
      );
    }

    const profilePayload = {
      uid,
      username,
      email,
      profilePictureUrl: profilePictureUrl ?? null,
      personalityType: personalityType ?? "Unknown",
      familyType: familyType ?? "Unknown",
      role: role ?? "user",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("users").doc(uid).set(profilePayload, { merge: true });

    return { success: true, message: "User profile set successfully." };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("Error setting user profile:", error);
    throw new HttpsError("internal", "An error occurred while setting the user profile.");
  }
});