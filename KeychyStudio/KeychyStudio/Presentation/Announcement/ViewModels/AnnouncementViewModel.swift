//
//  AnnouncementViewModel.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import Foundation
import FirebaseFirestore

// 발송 이력 통합 모델 (공지 + 키링 배포)
struct HistoryDoc: Identifiable, Hashable {
    enum Category: String {
        case announcement = "공지"
        case keyringEvent = "키링 배포"

        var color: String {
            switch self {
            case .announcement: "blue"
            case .keyringEvent: "purple"
            }
        }
    }

    let id: String
    let category: Category
    let tag: String          // 공지: 딥링크 값 / 키링 배포: "키링 배포"
    let title: String
    let subtitle: String
    let body: String
    let sentAt: Date

    // 공지 문서 → 모델
    init?(announcementId: String, data: [String: Any]) {
        self.id = announcementId
        self.category = .announcement

        guard let title = data["title"] as? String,
              let deepLink = data["deepLink"] as? String
        else { return nil }

        self.title = title
        self.subtitle = data["subtitle"] as? String ?? ""
        self.body = data["body"] as? String ?? ""
        self.tag = deepLink

        if let timestamp = data["sentAt"] as? Timestamp {
            self.sentAt = timestamp.dateValue()
        } else {
            self.sentAt = Date()
        }
    }

    // 키링 배포 문서 → 모델
    init?(keyringEventId: String, data: [String: Any]) {
        self.id = keyringEventId
        self.category = .keyringEvent
        self.tag = "키링 배포"

        guard let title = data["title"] as? String else { return nil }

        self.title = title
        self.subtitle = data["subtitle"] as? String ?? ""
        self.body = data["body"] as? String ?? ""

        if let timestamp = data["deployedAt"] as? Timestamp {
            self.sentAt = timestamp.dateValue()
        } else {
            self.sentAt = Date()
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    var formattedDate: String {
        Self.dateFormatter.string(from: sentAt)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: HistoryDoc, rhs: HistoryDoc) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class AnnouncementViewModel {
    var title = ""
    var subtitle = ""
    var body = ""
    var deepLink: DeepLinkDestination = .home
    var isLoading = false
    var errorMessage = ""
    var sendSuccess = false

    // 발송 이력 (공지 + 키링 배포 통합)
    var history: [HistoryDoc] = []
    var isLoadingHistory = false

    private let db = Firestore.firestore()

    init() {
        Task { await fetchHistory() }
    }

    // 공지 발송
    func send() async {
        guard !title.isEmpty, !body.isEmpty else { return }

        isLoading = true
        sendSuccess = false
        errorMessage = ""

        do {
            try await db.collection("announcements").addDocument(data: [
                "title": title,
                "subtitle": subtitle,
                "body": body,
                "deepLink": deepLink.rawValue,
                "sentAt": FieldValue.serverTimestamp()
            ])

            title = ""
            subtitle = ""
            body = ""
            deepLink = .home
            isLoading = false
            sendSuccess = true

            await fetchHistory()
        } catch {
            isLoading = false
            errorMessage = "발송 실패: \(error.localizedDescription)"
        }
    }

    // 발송 이력 조회 (두 컬렉션 병렬 조회 → 시간순 합치기)
    func fetchHistory() async {
        isLoadingHistory = true
        let db = self.db

        async let announcementsTask = db.collection("announcements")
            .order(by: "sentAt", descending: true)
            .getDocuments()

        async let keyringEventsTask = db.collection("keyringEvents")
            .order(by: "deployedAt", descending: true)
            .getDocuments()

        do {
            let (annSnap, krSnap) = try await (announcementsTask, keyringEventsTask)

            let announcements = annSnap.documents.compactMap {
                HistoryDoc(announcementId: $0.documentID, data: $0.data())
            }
            let keyringEvents = krSnap.documents.compactMap {
                HistoryDoc(keyringEventId: $0.documentID, data: $0.data())
            }

            // 시간순 내림차순 합치기
            history = (announcements + keyringEvents).sorted { $0.sentAt > $1.sentAt }
            isLoadingHistory = false
        } catch {
            isLoadingHistory = false
            errorMessage = "이력 로딩 실패: \(error.localizedDescription)"
        }
    }
}
