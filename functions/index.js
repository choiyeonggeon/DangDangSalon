const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

exports.onReviewCreated = onDocumentWritten("shops/{shopId}/reviews/{reviewId}", async (event) => {
  const db = getFirestore();
  const shopId = event.params.shopId;
  const shopRef = db.collection("shops").doc(shopId);
  const reviewsRef = shopRef.collection("reviews");

  // 전체 리뷰 불러오기
  const snapshot = await reviewsRef.get();
  const ratings = snapshot.docs
    .map((doc) => doc.data().rating)
    .filter((r) => typeof r === "number");

  // 평균 계산
  const avgRating = ratings.length > 0
    ? ratings.reduce((a, b) => a + b, 0) / ratings.length
    : 0;

  // 업데이트: rating + reviewCount
  await shopRef.update({
    rating: parseFloat(avgRating.toFixed(1)),   // ⭐️ 앱에서 사용하는 필드 이름
    avgRating: parseFloat(avgRating.toFixed(1)), // (원하면 유지)
    reviewCount: ratings.length,
  });

  console.log(`✅ Updated shop: ${shopId}, rating: ${avgRating}, reviews: ${ratings.length}`);
});
