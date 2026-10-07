import readline from "node:readline/promises";
import { stdin, stdout } from "node:process";
import admin from "../config/firebaseAdmin.js";
import db from "../config/db.js";

const [emailArg, actionArg = "grant"] = process.argv.slice(2);
const email = emailArg?.trim();
const action = actionArg.toLowerCase();

if (!email || !["grant", "revoke", "owner"].includes(action)) {
  console.error(
    "Usage: node scripts/setAdminRole.js <verified-user-email> [grant|revoke|owner]"
  );
  process.exitCode = 1;
} else {
  const prompt = readline.createInterface({ input: stdin, output: stdout });

  try {
    const user = await admin.auth().getUserByEmail(email);
    if (!user.emailVerified) {
      throw new Error("The target Firebase account must verify its email first.");
    }

    const [profiles] = await db.query(
      "SELECT id FROM users WHERE firebase_uid = ?",
      [user.uid]
    );
    if (action === "owner" && !profiles[0]) {
      throw new Error("Sign in to the app once first so the user's MySQL profile exists.");
    }
    const [owners] = await db.query(
      "SELECT firebase_uid FROM users WHERE is_primary_admin = TRUE LIMIT 1"
    );
    if (action === "owner" && owners[0] && owners[0].firebase_uid !== user.uid) {
      throw new Error("A primary admin is already assigned. Do not create a second primary admin.");
    }

    const claims = { ...(user.customClaims ?? {}) };
    if (action === "grant" || action === "owner") {
      claims.admin = true;
      if (action === "owner") claims.primaryAdmin = true;
    } else {
      if (claims.primaryAdmin === true || owners[0]?.firebase_uid === user.uid) {
        throw new Error("The primary admin cannot be revoked with this command.");
      }
      delete claims.admin;
      delete claims.primaryAdmin;
    }

    const verb = action === "owner" ? "Assign primary admin to " :
      action === "grant" ? "Grant admin access to " : "Remove admin access from ";
    console.log(
      verb + user.email + "?"
    );
    const confirmation = await prompt.question(
      "Type the exact email address to confirm: "
    );
    if (confirmation.trim().toLowerCase() !== user.email.toLowerCase()) {
      throw new Error("Confirmation did not match. No role changes were made.");
    }

    await admin.auth().setCustomUserClaims(user.uid, claims);
    if (action === "revoke") {
      await admin.auth().revokeRefreshTokens(user.uid);
    }
    const role = action === "revoke" ? "USER" : "ADMIN";
    const isPrimary = action === "owner" || (claims.primaryAdmin === true);
    if (profiles[0]) {
      await db.query(
        "UPDATE users SET role = ?, is_primary_admin = ? WHERE firebase_uid = ?",
        [role, isPrimary, user.uid]
      );
    }
    console.log(
      action === "owner"
        ? `Primary admin assigned to ${user.email}.`
        : `Admin access ${action === "grant" ? "granted to" : "removed from"} ${user.email}.`
    );
    if (profiles[0]) {
      console.log("The MySQL profile role was updated too.");
    }
    console.log("The user must sign out and sign back in before the app sees the updated role.");
  } catch (error) {
    console.error("Could not update admin role: " + error.message);
    process.exitCode = 1;
  } finally {
    prompt.close();
    await admin.app().delete();
    await db.end();
  }
}
