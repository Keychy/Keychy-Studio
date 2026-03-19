//
//  AnnouncementHistoryView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import SwiftUI
import AppKit

// 발송 이력 아이템
struct HistoryItem: Identifiable {
    enum Category {
        case announcement
        case keyringEvent

        var color: Color {
            switch self {
            case .announcement: .blue
            case .keyringEvent: .purple
            }
        }
    }

    let id: String
    let category: Category
    let tag: String       // 공지: 딥링크 값 (홈, 공방, 앱스토어) / 키링 배포: "키링 배포"
    let title: String
    let subtitle: String
    let body: String
    let sentAt: Date

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    var formattedDate: String {
        Self.dateFormatter.string(from: sentAt)
    }
}

// 더미 데이터
private let dummyHistory: [HistoryItem] = [
    .init(
        id: "h1",
        category: .announcement,
        tag: "홈",
        title: "서버 점검 안내",
        subtitle: "3월 20일 새벽 2시~4시",
        body: "안정적인 서비스 제공을 위해 서버 점검을 진행합니다. 이용에 불편을 드려 죄송합니다.",
        sentAt: Date().addingTimeInterval(-3600)
    ),
]

struct AnnouncementHistoryView: View {
    @State private var selectedItem: HistoryItem?

    var body: some View {
        HStack(spacing: 0) {
            listSection
            detailSection
        }
    }

    // MARK: - 이력 목록

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("총 \(dummyHistory.count)건")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(dummyHistory.enumerated()), id: \.element.id) { index, item in
                        historyRow(item, number: index + 1)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 이력 행

    private func historyRow(_ item: HistoryItem, number: Int) -> some View {
        let isSelected = selectedItem?.id == item.id

        return HStack(spacing: 12) {
            // 번호
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // 타이틀 + 날짜
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // 카테고리 태그
            Text(item.tag)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(item.category.color.opacity(0.1))
                .foregroundStyle(item.category.color)
                .clipShape(Capsule())
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedItem = item
            }
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - 상세 정보

    private var detailSection: some View {
        VStack {
            if let item = selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 4) {
                                Text("딥링크 :")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(item.tag)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Text(item.formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }

                        // 타이틀
                        copyableField(label: "타이틀", value: item.title)

                        // 서브타이틀
                        if !item.subtitle.isEmpty {
                            copyableField(label: "서브타이틀", value: item.subtitle)
                        }

                        // 내용
                        if !item.body.isEmpty {
                            copyableField(label: "내용", value: item.body)
                        }
                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("이력을 선택해주세요")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - 복사 가능 필드

    @State private var copiedField: String?

    private func copyableField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    copiedField = label

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedField == label { copiedField = nil }
                    }
                } label: {
                    Image(systemName: copiedField == label ? "checkmark" : "doc.on.doc")
                        .font(.subheadline)
                        .foregroundStyle(copiedField == label ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            Text(value)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .glassEffect(in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    AnnouncementHistoryView()
}
