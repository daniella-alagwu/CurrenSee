// One-time fix: accounts suspended by the old code were also "disabled" inside
// Firebase, so Firebase blocks their sign-in with "This user account has been
// disabled by an administrator" and they never reach the suspended page.
// Suspension now lives only in MySQL (users.status), so re-enable them in Firebase.
//
// Run once from the backend folder:  node scripts/reenableSuspendedUsers.js
import admin from "../config/firebaseAdmin.js";
import db from "../config/db.js";

try {
  const [rows] = await db.query(
    "SELECT email, firebase_uid AS uid FROM users WHERE status = 'SUSPENDED'",
  );
  let fixed = 0;

  for (const row of rows) {
    try {
      const fb = await admin.auth().getUser(row.uid);
      if (fb.disabled) {
        await admin.auth().updateUser(row.uid, { disabled: false });
        fixed++;
        console.log(`Re-enabled sign-in for ${row.email}`);
      }
    } catch (err) {
      if (err?.code !== "auth/user-not-found") throw err;
    }
  }

  console.log(
    `Done. ${fixed} of ${rows.length} suspended account(s) needed re-enabling.`,
  );
} catch (error) {
  console.error("Could not re-enable suspended users: " + error.message);
  process.exitCode = 1;
} finally {
  await admin.app().delete();
  await db.end();
}
