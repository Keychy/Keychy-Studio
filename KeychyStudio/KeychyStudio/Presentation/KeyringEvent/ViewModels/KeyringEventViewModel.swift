//
//  KeyringEventViewModel.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import Foundation
import FirebaseFirestore

// 운영자 정보
struct OperatorInfo: Identifiable, Hashable {
    let id: String
    let nickname: String

    // UID 기준으로만 동등성 판단
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: OperatorInfo, rhs: OperatorInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// Firestore 키링 모델
struct KeyringItem: Identifiable, Hashable {
    let id: String
    let name: String
    let bodyImage: String
    let soundId: String
    let particleId: String
    let createdAt: Date
    let authorId: String
    let selectedTemplate: String
    let selectedRing: String
    let selectedChain: String
    let tags: [String]

    init?(documentId: String, data: [String: Any]) {
        self.id = documentId

        guard let name = data["name"] as? String,
              let bodyImage = data["bodyImage"] as? String,
              let soundId = data["soundId"] as? String,
              let particleId = data["particleId"] as? String,
              let authorId = data["authorId"] as? String,
              let selectedTemplate = data["selectedTemplate"] as? String,
              let selectedRing = data["selectedRing"] as? String,
              let selectedChain = data["selectedChain"] as? String
        else { return nil }

        self.name = name
        self.bodyImage = bodyImage
        self.soundId = soundId
        self.particleId = particleId
        self.authorId = authorId
        self.selectedTemplate = selectedTemplate
        self.selectedRing = selectedRing
        self.selectedChain = selectedChain
        self.tags = data["tags"] as? [String] ?? []

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    var formattedDate: String {
        Self.dateFormatter.string(from: createdAt)
    }
}

@MainActor
@Observable
final class KeyringEventViewModel {
    // 운영자 UID 목록 (추후 여기에 추가하면 됨)
    private var operatorUIDs: [String] = [
        "XNXUs6qHvDd9kaM6k62EfoMR7012",
        "d1enEQOrreV2LjOV3AAzDQ8PgFn1",
        "8zAa5iNvTfeSP2NZ9wACXYVklJg2",
        "saGVmm5hJ0PwgUowspq3XmrtC4O2"
    ]

    var operators: [OperatorInfo] = []
    var selectedOperator: OperatorInfo?
    var keyrings: [KeyringItem] = []
    var selectedKeyring: KeyringItem?
    var eventTitle = ""
    var eventSubtitle = ""
    var eventBody = ""
    var isUnlimitedDeployment = true
    var expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var isLoading = false
    var errorMessage = ""
    var deploySuccess = false

    // 캐시
    private var keyringIdsCache: [String: [String]] = [:]
    private var nicknameCache: [String: String] = [:]
    private var keyringsCache: [String: [KeyringItem]] = [:]

    private let db = Firestore.firestore()

    init() {
        Task { await loadOperators() }
    }

    // 모든 운영자 User 문서를 병렬로 가져와서 nickname + keyringIds 캐시
    private func loadOperators() async {
        isLoading = true
        let db = self.db

        await withTaskGroup(of: (String, String, [String])?.self) { group in
            for uid in operatorUIDs {
                group.addTask {
                    let doc = try? await db.collection("User").document(uid).getDocument()
                    guard let data = doc?.data(),
                          let nickname = data["nickname"] as? String
                    else { return nil }
                    let keyringIds = data["keyrings"] as? [String] ?? []
                    return (uid, nickname, keyringIds)
                }
            }

            for await result in group {
                guard let (uid, nickname, keyringIds) = result else { continue }
                operators.append(OperatorInfo(id: uid, nickname: nickname))
                keyringIdsCache[uid] = keyringIds
                nicknameCache[uid] = nickname
            }
        }

        if let first = operators.first {
            selectedOperator = first
            await fetchKeyrings(for: first)
        } else {
            isLoading = false
        }
    }

    func selectOperator(_ op: OperatorInfo) {
        selectedOperator = op
        selectedKeyring = nil
        eventTitle = ""
        eventSubtitle = ""
        eventBody = ""

        // 캐시 히트 시 Firestore 조회 없이 바로 표시
        if let cached = keyringsCache[op.id] {
            keyrings = cached
            return
        }

        Task { await fetchKeyrings(for: op) }
    }

    // Keyring 컬렉션 조회 후 캐시 저장
    private func fetchKeyrings(for op: OperatorInfo) async {
        guard let keyringIds = keyringIdsCache[op.id],
              !keyringIds.isEmpty else {
            keyrings = []
            return
        }

        isLoading = true
        errorMessage = ""
        let db = self.db

        do {
            var allKeyrings: [KeyringItem] = []

            let batches = stride(from: 0, to: keyringIds.count, by: 10).map {
                Array(keyringIds[$0..<min($0 + 10, keyringIds.count)])
            }

            for batch in batches {
                let snapshot = try await db.collection("Keyring")
                    .whereField(FieldPath.documentID(), in: batch)
                    .getDocuments()

                let items = snapshot.documents.compactMap {
                    KeyringItem(documentId: $0.documentID, data: $0.data())
                }
                allKeyrings.append(contentsOf: items)
            }

            let unknownIds = Set(allKeyrings.map(\.authorId)).subtracting(nicknameCache.keys)
            if !unknownIds.isEmpty {
                await fetchNicknames(for: Array(unknownIds))
            }

            let sorted = allKeyrings.sorted { $0.createdAt > $1.createdAt }
            keyringsCache[op.id] = sorted
            keyrings = sorted
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "키링 로딩 실패: \(error.localizedDescription)"
        }
    }

    // 미지 authorId 닉네임 병렬 fetch → 캐시 저장
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

    // 닉네임 조회 (캐시 우선)
    func nickname(for uid: String) -> String {
        nicknameCache[uid] ?? uid
    }

    // 키링 이벤트 배포
    func deploy() async {
        guard let keyring = selectedKeyring,
              let operatorId = selectedOperator?.id,
              !eventTitle.isEmpty else { return }

        isLoading = true
        deploySuccess = false

        do {
            // 1. PostOffice 문서 생성 (collect 타입 → 무한 수령 가능)
            let postOfficeRef = db.collection("PostOffice").document()
            let postOfficeId = postOfficeRef.documentID
            let shareLink = "https://keychy-f6011.web.app/collect/\(postOfficeId)"

            var postOfficeData: [String: Any] = [
                "type": "collect",
                "senderId": operatorId,
                "keyringId": keyring.id,
                "shareLink": shareLink,
                "createdAt": FieldValue.serverTimestamp()
            ]

            // 무한배포가 아닌 경우에만 expiresAt 저장 (nil → 무한배포로 하위호환)
            if !isUnlimitedDeployment {
                postOfficeData["expiresAt"] = Timestamp(date: expiresAt)
            }

            try await postOfficeRef.setData(postOfficeData)

            // 2. keyringEvents 문서 생성 (푸시 트리거 + postOfficeId 포함)
            try await db.collection("keyringEvents").addDocument(data: [
                "keyringId": keyring.id,
                "keyringName": keyring.name,
                "bodyImage": keyring.bodyImage,
                "authorName": "KEYCHY",
                "soundId": keyring.soundId,
                "particleId": keyring.particleId,
                "title": eventTitle,
                "subtitle": eventSubtitle,
                "body": eventBody,
                "postOfficeId": postOfficeId,
                "deployedAt": FieldValue.serverTimestamp(),
                "deployedBy": operatorId
            ])

            eventTitle = ""
            eventSubtitle = ""
            eventBody = ""
            isUnlimitedDeployment = true
            expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            selectedKeyring = nil
            isLoading = false
            deploySuccess = true
        } catch {
            isLoading = false
            errorMessage = "배포 실패: \(error.localizedDescription)"
        }
    }
}
