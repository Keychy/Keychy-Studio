//
//  AnnouncementHistoryView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import SwiftUI
import AppKit

struct AnnouncementHistoryView: View {
    @Bindable var viewModel: AnnouncementViewModel
    @State private var selectedItem: HistoryDoc?

    var body: some View {
        HStack(spacing: 0) {
            listSection
            detailSection
        }
    }

    // MARK: - 이력 목록

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("총 \(viewModel.history.count)건")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.isLoadingHistory {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("발송 이력이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { index, item in
                            historyRow(item, number: index + 1)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 이력 행

    private func historyRow(_ item: HistoryDoc, number: Int) -> some View {
        let isSelected = selectedItem?.id == item.id
        let tagColor: Color = item.category == .announcement ? .blue : .purple

        return HStack(spacing: 12) {
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 24)

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

            Text(item.tag)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tagColor.opacity(0.1))
                .foregroundStyle(tagColor)
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
                                Text(item.category == .announcement ? "딥링크 :" : "구분 :")
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

                        copyableField(label: "타이틀", value: item.title)

                        if !item.subtitle.isEmpty {
                            copyableField(label: "서브타이틀", value: item.subtitle)
                        }

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
    AnnouncementHistoryView(viewModel: AnnouncementViewModel())
}
