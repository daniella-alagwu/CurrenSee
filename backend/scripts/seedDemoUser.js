import admin from "../config/firebaseAdmin.js";

const email = process.env.DEMO_USER_EMAIL?.trim().toLowerCase();
const password = process.env.DEMO_USER_PASSWORD;

const seedingEnabled = process.env.ALLOW_DEV_ADMIN_SEED === "true";
const production = process.env.NODE_ENV === "production";

try {
if (production || !seedingEnabled) {
throw new Error(
"Demo user creation is disabled. Use only a development Firebase project and set ALLOW_DEV_ADMIN_SEED=true locally."
);
}

if (!email || !email.endsWith(".test") || !password || password.length < 12) {
throw new Error(
"Set DEMO_USER_EMAIL to an address ending in .test and DEMO_USER_PASSWORD to at least 12 characters in backend/.env."
);
}

const user = await admin.auth().createUser({
email,
password,
displayName: "CurrenSee Demo User",
emailVerified: true,
disabled: false,
});

console.log("Development demo user created in Firebase: " + email);
console.log("Email marked verified for testing; no email was sent.");
console.log("Sign in through the app to create the corresponding MySQL profile.");
} catch (error) {
console.error("Could not create development demo user: " + error.message);
process.exitCode = 1;
} finally {
await admin.app().delete().catch(() => {});
}
