// index.ts — Cloud Functions entry point
import admin from "firebase-admin";

// Initialize the Admin SDK once at the root level
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// ── Module imports ──────────────────────────────────────────────────────────
//
// NOTE: Password reset is handled natively by Firebase Authentication
// (FirebaseAuth.sendPasswordResetEmail in the Flutter client).
// No Cloud Function is needed — auth.ts is reserved for future
// server-side auth event triggers.

import { onResponseSubmittedUpdateXP } from "./track_progress.js";
import { setupUserProfile } from "./user_profiles.js";

// ── Exports ─────────────────────────────────────────────────────────────────

// Gamification & XP tracking domain
export { onResponseSubmittedUpdateXP };

// User management & profile domain
export { setupUserProfile };