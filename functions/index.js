const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.autoUpdateElectionStatuses = functions.https.onRequest(async (req, res) => {
  console.log("⏱️ Running scheduled election status update...");

  const lokSabhaDocRef = db.collection("election_status").doc("lok_sabha");
  const subCollections = await lokSabhaDocRef.listCollections();

  let updates = 0;

  for (const subCol of subCollections) {
    const electionRef = lokSabhaDocRef.collection(subCol.id).doc("election_info");
    const snapshot = await electionRef.get();

    if (!snapshot.exists) continue;

    const data = snapshot.data();
    if (!data) continue;

    const now = new Date();

    // Parse Firestore Timestamps or strings into JS Dates
    const parseDate = (value) => {
      if (value instanceof admin.firestore.Timestamp) return value.toDate();
      if (typeof value === "string") return new Date(value);
      return null;
    };

    const nominationEnd = parseDate(data.nominations_end);
    const pollingStart = parseDate(data.polling_start);
    const pollingEnd = parseDate(data.polling_end);

    if (!nominationEnd || !pollingStart || !pollingEnd) continue;

    let newStatus = data.status;

    if (newStatus === "nominations_open" && now >= nominationEnd) {
      newStatus = "polling_open";
    } else if (newStatus === "polling_open" && now >= pollingEnd) {
      newStatus = "completed";
    } else if (newStatus === "nominations_open" && now >= pollingStart) {
      newStatus = "polling_open";
    }

    if (newStatus !== data.status) {
      await electionRef.update({ status: newStatus });
      updates++;
      console.log(`✅ ${electionRef.path} updated to ${newStatus}`);
    }
  }

  res.send(`Election status auto-updater ran. ${updates} updates made.`);
});
