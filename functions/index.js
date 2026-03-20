const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();
setGlobalOptions({ maxInstances: 10, region: "asia-northeast3" });

// 공지 발송 → FCM 푸시 (keychyNews 토픽)
exports.onAnnouncementCreated = onDocumentCreated(
  "announcements/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const message = {
      topic: "keychyNews",
      notification: {
        title: data.title || "",
        body: data.body || "",
      },
      apns: {
        payload: {
          aps: {
            alert: {
              subtitle: data.subtitle || "",
            },
            sound: "default",
          },
        },
      },
      data: {
        type: "announcement",
        deepLink: data.deepLink || "홈",
      },
    };

    try {
      const response = await getMessaging().send(message);
      logger.info("공지 푸시 발송 성공", { response, docId: event.params.docId });
    } catch (error) {
      logger.error("공지 푸시 발송 실패", { error, docId: event.params.docId });
    }
  }
);

// 키링 배포 → FCM 푸시 (keychyNews 토픽)
exports.onKeyringEventCreated = onDocumentCreated(
  "keyringEvents/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const message = {
      topic: "keychyNews",
      notification: {
        title: data.title || "",
        body: data.body || "",
      },
      apns: {
        payload: {
          aps: {
            alert: {
              subtitle: data.subtitle || "",
            },
            sound: "default",
          },
        },
      },
      data: {
        type: "keyringEvent",
        keyringId: data.keyringId || "",
        postOfficeId: data.postOfficeId || "",
      },
    };

    try {
      const response = await getMessaging().send(message);
      logger.info("키링 배포 푸시 발송 성공", { response, docId: event.params.docId });
    } catch (error) {
      logger.error("키링 배포 푸시 발송 실패", { error, docId: event.params.docId });
    }
  }
);
