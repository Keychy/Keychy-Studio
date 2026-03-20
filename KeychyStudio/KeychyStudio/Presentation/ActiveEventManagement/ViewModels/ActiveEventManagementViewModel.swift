//
//  ActiveEventManagementViewModel.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-20.
//

import Foundation
import FirebaseFirestore

// 활성 이벤트 모델 — PostOffice(collect) + keyringEvents 조인 결과
struct ActiveEvent: Identifiable, Hashable {
    let id: String              // PostOffice 문서 ID
    let keyringId: String
    let keyringName: String
    let bodyImage: String
    let deployedBy: String      // 운영자 UID
    let deployedByName: String  // 운영자 닉네임
    let deployedAt: Date
    let expiresAt: Date?        // nil이면 무한배포
    let shareLink: String
    let eventTitle: String

    // 만료 상태 판별
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var statusText: String {
        if expiresAt == nil { return "무한 배포" }
        if isExpired { return "만료됨" }
        return "배포 중"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    var formattedDeployDate: String {
        Self.dateFormatter.string(from: deployedAt)
    }

    var formattedExpiresDate: String? {
        guard let expiresAt else { return nil }
        return Self.dateFormatter.string(from: expiresAt)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ActiveEvent, rhs: ActiveEvent) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class ActiveEventManagementViewModel {
    var events: [ActiveEvent] = []
    var isLoading = false
    var errorMessage = ""
    var showDeleteConfirm = false
    var deleteSuccess = false

    private let db = Firestore.firestore()
    private var nicknameCache: [String: String] = [:]

    init() {
        Task { await fetchEvents() }
    }

    // PostOffice(collect) 조회 → keyringEvents 조인 → 운영자 닉네임 fetch
    func fetchEvents() async {
        isLoading = true
        errorMessage = ""

        do {
            // 1. PostOffice에서 collect 타입만 조회 (정렬은 클라이언트에서 처리)
            let postOfficeSnap = try await db.collection("PostOffice")
                .whereField("type", isEqualTo: "collect")
                .getDocuments()

            // 2. keyringEvents 전체 조회 (postOfficeId로 매핑)
            let keyringEventsSnap = try await db.collection("keyringEvents")
                .getDocuments()

            // postOfficeId → keyringEvents 데이터 매핑
            var eventsByPostOfficeId: [String: [String: Any]] = [:]
            for doc in keyringEventsSnap.documents {
                let data = doc.data()
                if let postOfficeId = data["postOfficeId"] as? String {
                    eventsByPostOfficeId[postOfficeId] = data
                }
            }

            // 3. 운영자 UID 수집 → 닉네임 일괄 fetch
            let operatorUIDs = Set(postOfficeSnap.documents.compactMap {
                $0.data()["senderId"] as? String
            })

            let unknownUIDs = operatorUIDs.filter { nicknameCache[$0] == nil }
            if !unknownUIDs.isEmpty {
                await fetchNicknames(for: Array(unknownUIDs))
            }

            // 4. 조인하여 ActiveEvent 생성
            var result: [ActiveEvent] = []
            for doc in postOfficeSnap.documents {
                let postOfficeData = doc.data()
                let postOfficeId = doc.documentID

                guard let keyringId = postOfficeData["keyringId"] as? String,
                      let senderId = postOfficeData["senderId"] as? String,
                      let shareLink = postOfficeData["shareLink"] as? String
                else { continue }

                let eventData = eventsByPostOfficeId[postOfficeId]

                let deployedAt: Date
                if let ts = postOfficeData["createdAt"] as? Timestamp {
                    deployedAt = ts.dateValue()
                } else {
                    deployedAt = Date()
                }

                let expiresAt: Date?
                if let ts = postOfficeData["expiresAt"] as? Timestamp {
                    expiresAt = ts.dateValue()
                } else {
                    expiresAt = nil
                }

                let event = ActiveEvent(
                    id: postOfficeId,
                    keyringId: keyringId,
                    keyringName: eventData?["keyringName"] as? String ?? "알 수 없음",
                    bodyImage: eventData?["bodyImage"] as? String ?? "",
                    deployedBy: senderId,
                    deployedByName: nicknameCache[senderId] ?? senderId,
                    deployedAt: deployedAt,
                    expiresAt: expiresAt,
                    shareLink: shareLink,
                    eventTitle: eventData?["title"] as? String ?? ""
                )
                result.append(event)
            }

            // 클라이언트 정렬 (최신순)
            events = result.sorted { $0.deployedAt > $1.deployedAt }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "이벤트 로딩 실패: \(error.localizedDescription)"
        }
    }

    // PostOffice 문서 삭제 → iOS에서 .notFound 에러 표시 (기존 로직 활용)
    func deleteEvent(_ event: ActiveEvent) async {
        isLoading = true
        deleteSuccess = false

        do {
            try await db.collection("PostOffice").document(event.id).delete()

            // 목록에서 제거
            events.removeAll { $0.id == event.id }
            isLoading = false
            deleteSuccess = true
        } catch {
            isLoading = false
            errorMessage = "이벤트 종료 실패: \(error.localizedDescription)"
        }
    }

    private func fetchNicknames(for uids: [String]) async {
        let db = self.db

        await withTaskGroup(of: (String, String)?.self) { group in
            for uid in uids {
                group.addTask {
                    let doc = try? await db.collection("User").document(uid).getDocument()
                    guard let nickname = doc?.data()?["nickname"] as? String
                    else { return nil }
                    return (uid, nickname)
                }
            }

            for await result in group {
                guard let (uid, nickname) = result else { continue }
                nicknameCache[uid] = nickname
            }
        }
    }
}
