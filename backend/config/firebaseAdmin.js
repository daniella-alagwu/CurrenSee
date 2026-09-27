import admin from "firebase-admin";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import "./env.js";

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

if (!serviceAccountPath) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT_PATH is missing from backend/.env");
}

const resolvedPath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  serviceAccountPath
);

if (!fs.existsSync(resolvedPath)) {
  throw new Error(`Firebase service account file not found: ${resolvedPath}`);
}

const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, "utf8"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;
