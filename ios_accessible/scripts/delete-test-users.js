// One-off cleanup tool for the fast-lit-ios Firebase project: lists (and,
// with --delete, removes) every Firebase Auth user. Authenticates via
// Application Default Credentials (gcloud auth application-default login)
// rather than a service account key file, so no credential ever needs to
// be stored in this repo.
//
// Usage:
//   node delete-test-users.js            # dry run: lists users only
//   node delete-test-users.js --delete   # actually deletes every user

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp({
  credential: applicationDefault(),
  projectId: "fast-lit-ios",
});
const auth = getAuth();

async function listAllUsers() {
  const users = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    users.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);
  return users;
}

async function main() {
  const shouldDelete = process.argv.includes("--delete");
  const users = await listAllUsers();

  if (users.length === 0) {
    console.log("No users found.");
    return;
  }

  console.log(`Found ${users.length} user(s):`);
  for (const user of users) {
    console.log(`  ${user.uid}  ${user.email ?? "(no email)"}`);
  }

  if (!shouldDelete) {
    console.log("\nDry run only — re-run with --delete to actually remove these users.");
    return;
  }

  const result = await auth.deleteUsers(users.map((user) => user.uid));
  console.log(`\nDeleted ${result.successCount} user(s), ${result.failureCount} failure(s).`);
  for (const error of result.errors) {
    console.log(`  Failed at index ${error.index}: ${error.error.message}`);
  }
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error);
  process.exit(1);
});
