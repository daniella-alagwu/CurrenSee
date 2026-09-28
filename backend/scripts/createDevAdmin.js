import admin from "../config/firebaseAdmin.js";

const email = process.env.DEV_ADMIN_EMAIL?.trim().toLowerCase();
const password = process.env.ADMINPASS;
const seedingEnabled = process.env.ALLOW_DEV_ADMIN_SEED === "true";
const production = process.env.NODE_ENV === "production";

try {
  if (production || !seedingEnabled) {
    throw new Error(
      "Dev admin creation is disabled. Use only a development Firebase project and set ALLOW_DEV_ADMIN_SEED=true locally."
    );
  }

  if (!email || !email.endsWith(".test") || !password || password.length < 12) {
    throw new Error(
      "Set DEV_ADMIN_EMAIL to an address ending in .test and ADMINPASS to at least 12 characters in backend/.env."
    );
  }

  const user = await admin.auth().createUser({
    email,
    password,
    displayName: "CurrenSee Admin",
    emailVerified: true,
    disabled: false,
  });

  try {
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
  } catch (error) {
    await admin.auth().deleteUser(user.uid).catch(() => {});
    throw error;
  }

  console.log("Development admin created in Firebase: " + email);
  console.log("Email marked verified for testing; no email was sent.");
  console.log("Sign in through the app to create the corresponding MySQL profile.");
} catch (error) {
  console.error("Could not create development admin: " + error.message);
  process.exitCode = 1;
} finally {
  await admin.app().delete().catch(() => {});
}
