const { onDocumentWritten, onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/* ===================================================================
    1) 리뷰 업데이트 (변경 없음)
=================================================================== */
exports.onReviewCreated = onDocumentWritten(
  "shops/{shopId}/reviews/{reviewId}",
  async (event) => {
    const db = getFirestore();
    const shopId = event.params.shopId;
    const shopRef = db.collection("shops").doc(shopId);
    const reviewsRef = shopRef.collection("reviews");

    const snapshot = await reviewsRef.get();
    const ratings = snapshot.docs
      .map((doc) => doc.data().rating)
      .filter((r) => typeof r === "number");

    const avgRating =
      ratings.length > 0
        ? ratings.reduce((a, b) => a + b, 0) / ratings.length
        : 0;

    await shopRef.update({
      rating: parseFloat(avgRating.toFixed(1)),
      avgRating: parseFloat(avgRating.toFixed(1)),
      reviewCount: ratings.length,
    });

    console.log(
      `✅ Updated shop: ${shopId}, rating: ${avgRating}, reviews: ${ratings.length}`
    );
  }
);

/* ===================================================================
    2) 예약 상태 변경 시 소비자 알림
       (상태: 예약 요청 / 예약 확정 / 예약 완료 / 예약 취소)
=================================================================== */
exports.sendReservationStatusNotification = onDocumentUpdated(
  "reservations/{reservationId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // 상태 안 바뀌었으면 푸시 안 보냄
    if (before.status === after.status) {
      console.log("🔹 상태 변경 없음 → 푸시 안 보냄");
      return;
    }

    const db = getFirestore();
    const userId = after.userId;
    const status = after.status;

    if (!userId) {
      console.log("❌ userId 없음");
      return;
    }

    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.log("❌ 사용자 문서 없음:", userId);
      return;
    }

    const token = userDoc.data().fcmToken;
    if (!token) {
      console.log("❌ 사용자 FCM 토큰 없음");
      return;
    }

    let title = "";
    let body = "";

    switch (status) {
      case "예약 요청":
        title = "새 예약 요청이 접수되었습니다 🐶";
        body = "예약 요청이 정상적으로 접수되었어요.";
        break;
      case "확정":
        title = "예약이 확정되었습니다 🎉";
        body = "사장님이 예약을 확정했어요.";
        break;
      case "완료":
        title = "예약이 완료되었습니다 🐾";
        body = "댕댕이가 예쁘게 변신했어요!";
        break;
      case "취소":
        title = "예약이 취소되었습니다 😢";
        body = "해당 예약이 취소되었어요.";
        break;
      default:
        console.log("🔹 처리하지 않는 상태:", status);
        return;
    }

    const reservationId = event.params.reservationId;

    // 🔥 iOS + Android 다 되는 푸시 구조 (소리 포함)
    const message = {
      token,
      notification: {
        title,
        body,
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
            badge: 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      data: {
        reservationId,
        status,
      },
    };

    try {
      await getMessaging().send(message);
      console.log(`📨 소비자 푸시 성공! 상태: ${status}`);
    } catch (e) {
      console.error("🚨 소비자 푸시 실패:", e);
    }
  }
);

/* ===================================================================
    3) 새 예약 생성 → 사장님 알림
=================================================================== */
exports.sendNewReservationNotification = onDocumentCreated(
  "reservations/{reservationId}",
  async (event) => {
    const data = event.data.data();
    const ownerId = data.ownerId;

    if (!ownerId) {
      console.log("❌ ownerId 없음");
      return;
    }

    const ownerDoc = await admin
      .firestore()
      .collection("owners")
      .doc(ownerId)
      .get();

    if (!ownerDoc.exists) {
      console.log("❌ 사장님 문서 없음:", ownerId);
      return;
    }

    const token = ownerDoc.data().fcmToken;
    if (!token) {
      console.log("❌ 사장님 FCM 토큰 없음");
      return;
    }

    const reservationId = event.params.reservationId;

    // 🔥 iOS 푸시 완전 호환 메시지 (소리 + 배지)
    const message = {
      token,
      notification: {
        title: "📢 새 예약 도착!",
        body: `${data.userName}님이 예약을 요청했습니다.`,
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: "📢 새 예약 도착!",
              body: `${data.userName}님이 예약을 요청했습니다.`,
            },
            sound: "default",
            badge: 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      data: {
        reservationId,
        ownerId,
      },
    };

    try {
      await getMessaging().send(message);
      console.log("📨 사장님 푸시 전송 성공!");
    } catch (e) {
      console.error("🚨 사장님 푸시 전송 실패:", e);
    }
  }
);

/* ===================================================================
    4) 소비자가 예약 취소 → 사장님 알림
=================================================================== */
exports.sendOwnerCancelNotification = onDocumentUpdated(
  "reservations/{reservationId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    // 상태가 바뀌지 않으면 무시
    if (before.status === after.status) return;

    // “취소” 상태가 아니면 종료
    if (after.status !== "취소") return;

    const ownerId = after.ownerId;
    if (!ownerId) {
      console.log("❌ ownerId 없음");
      return;
    }

    // 사장님 문서 가져오기
    const ownerDoc = await admin
      .firestore()
      .collection("owners")
      .doc(ownerId)
      .get();

    if (!ownerDoc.exists) {
      console.log("❌ 사장님 문서 없음:", ownerId);
      return;
    }

    const token = ownerDoc.data().fcmToken;
    if (!token) {
      console.log("❌ 사장님 FCM 토큰 없음");
      return;
    }

    const reservationId = event.params.reservationId;

    // 🔥 iOS 완전 호환 알림
    const message = {
      token,
      notification: {
        title: "📢 예약 취소 안내",
        body: `${after.userName}님이 예약을 취소했습니다.`,
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: "📢 예약 취소 안내",
              body: `${after.userName}님이 예약을 취소했습니다.`,
            },
            sound: "default",
            badge: 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      data: {
        reservationId,
        ownerId,
        status: "취소",
      },
    };

    try {
      await getMessaging().send(message);
      console.log("📨 사장님 취소 알림 전송 성공!");
    } catch (e) {
      console.error("🚨 사장님 취소 알림 실패:", e);
    }
  }
);

