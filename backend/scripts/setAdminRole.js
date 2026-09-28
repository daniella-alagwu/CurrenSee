import readline from "node:readline/promises";
import { stdin, stdout } from "node:process";
import admin from "../config/firebaseAdmin.js";

const [emailArg, actionArg = "grant"] = process.argv.slice(2);
const email = emailArg?.trim();
const action = actionArg.toLowerCase();

if (!email || !["grant", "revoke"].includes(action)) {
  console.error(
    "Usage: node scripts/setAdminRole.js <verified-user-email> [grant|revoke]"
  );
  process.exitCode = 1;
} else {
  const prompt = readline.createInterface({ input: stdin, output: stdout });

  try {
    const user = await admin.auth().getUserByEmail(email);
    if (!user.emailVerified) {
      throw new Error("The target Firebase account must verify its email first.");
    }

    const claims = { ...(user.customClaims ?? {}) };
    if (action === "grant") {
      claims.admin = true;
    } else {
      delete claims.admin;
    }

    console.log(
      (action === "grant" ? "Grant admin access to " : "Remove admin access from ") +
        user.email +
        "?"
    );
    const confirmation = await prompt.question(
      "Type the exact email address to confirm: "
    );
    if (confirmation.trim().toLowerCase() !== user.email.toLowerCase()) {
      throw new Error("Confirmation did not match. No role changes were made.");
    }

    await admin.auth().setCustomUserClaims(user.uid, claims);
    console.log(
      "Admin role " +
        (action === "grant" ? "granted to " : "removed from ") +
        user.email +
        "."
    );
    console.log("The user must sign out and sign back in before the app sees the updated role.");
  } catch (error) {
    console.error("Could not update admin role: " + error.message);
    process.exitCode = 1;
  } finally {
    prompt.close();
    await admin.app().delete();
  }
}
