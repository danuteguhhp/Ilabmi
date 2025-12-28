// Lokasi: functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inisialisasi Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function ini dipanggil dari aplikasi Flutter.
 * Ia menerima 'uid' dan mengembalikan 'customToken'.
 */
exports.createCustomToken = functions.https.onCall(async (data, context) => {
  try {
    const uid = data.uid;

    // Cek jika UID ada
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "UID tidak ada",
      );
    }

    // Buat custom token menggunakan UID
    const customToken = await admin.auth().createCustomToken(uid);

    // Kirim token kembali ke aplikasi
    return { token: customToken };
  } catch (error) {
    console.error("Gagal membuat custom token:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Gagal membuat custom token",
    );
  }
});