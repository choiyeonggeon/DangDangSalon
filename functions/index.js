const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

exports.onReviewCreated = onDocumentWritten("shops/{shopId}/reviews/{reviewId}", async (event) => {
  const db = getFirestore();
  const shopId = event.params.shopId;
  const shopRef = db.collection("shops").doc(shopId);
  const reviewsRef = shopRef.collection("reviews");

  const snapshot = await reviewsRef.get();
  const ratings = snapshot.docs
    .map((doc) => doc.data().rating)
    .filter((r) => typeof r === "number");

  const avgRating = ratings.length > 0
    ? ratings.reduce((a, b) => a + b, 0) / ratings.length
    : 0;

  await shopRef.update({
    avgRating: parseFloat(avgRating.toFixed(1)),
    reviewCount: ratings.length,
  });

  console.log(`✅ Updated ${shopId} average rating: ${avgRating}`);
});
