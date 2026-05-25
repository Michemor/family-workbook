import { onDocumentCreated } from "firebase-functions/v2/firestore";
import admin from "firebase-admin";

const db = admin.firestore();

/**
 * Triggered when a new response document is created under:
 *   users/{userId}/responses/{responseId}
 *
 * Awards XP to the user based on the response type.
 */
export const onResponseSubmittedUpdateXP = onDocumentCreated(
  "users/{userId}/responses/{responseId}",
  async (event) => {
    const userId = event.params.userId;
    const data = event.data?.data();

    if (!data) return;

    // Base XP award — extend this logic as needed per response type
    const xpAwarded: number = data.xpValue ?? 10;

    const userRef = db.collection("users").doc(userId);

    try {
      await userRef.update({
        totalXP: admin.firestore.FieldValue.increment(xpAwarded),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Awarded ${xpAwarded} XP to user ${userId}`);
    } catch (error) {
      console.error(`Failed to update XP for user ${userId}:`, error);
    }
  }
);
