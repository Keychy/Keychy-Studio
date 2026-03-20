//
//  ActiveEventManagementView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-20.
//

import SwiftUI
import AppKit

// KeyringEventView에 정의된 CachedAsyncImage를 재사용하기 위해 동일한 캐시 참조
// (ImageCache가 private이므로 여기서는 AsyncImage 대신 동일한 패턴으로 구현)
private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, NSImage>()

    func get(_ url: String) -> NSImage? {
        cache.object(forKey: url as NSString)
    }

    func set(_ image: NSImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}

private struct CachedAsyncImage: View {
    let url: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(.tertiary)
            }
        }
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        if let cached = ImageCache.shared.get(url) {
            image = cached
            return
        }

        guard let imageUrl = URL(string: url),
              let (data, _) = try? await URLSession.shared.data(from: imageUrl),
              let nsImage = NSImage(data: data)
        else { return }

        ImageCache.shared.set(nsImage, for: url)
        image = nsImage
    }
}

struct ActiveEventManagementView: View {
    @State private var viewModel = ActiveEventManagementViewModel()
    @State private var selectedEvent: ActiveEvent?
    @State private var eventToDelete: ActiveEvent?

    var body: some View {
        HStack(spacing: 0) {
            listSection
            detailSection
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.fetchEvents() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("이벤트 종료", isPresented: $viewModel.showDeleteConfirm) {
            Button("취소", role: .cancel) { eventToDelete = nil }
            Button("종료", role: .destructive) {
                guard let event = eventToDelete else { return }
                Task { await viewModel.deleteEvent(event) }
                // 삭제한 이벤트가 선택 중이었으면 선택 해제
                if selectedEvent?.id == event.id {
                    selectedEvent = nil
                }
                eventToDelete = nil
            }
        } message: {
            Text("이 이벤트를 종료하시겠습니까?\nPostOffice 문서가 삭제되어 더 이상 수령할 수 없게 됩니다.")
        }
        .alert("이벤트 종료 완료", isPresented: $viewModel.deleteSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("이벤트가 성공적으로 종료되었습니다.")
        }
    }

    // MARK: - 이벤트 목록

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("총 \(viewModel.events.count)건")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("배포된 이벤트가 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.events) { event in
                            eventRow(event)
                        }
                    }
                }
            }

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 이벤트 행

    private func eventRow(_ event: ActiveEvent) -> some View {
        let isSelected = selectedEvent?.id == event.id
        let statusColor: Color = {
            if event.isExpired { return .red }
            if event.expiresAt == nil { return .gray }
            return .green
        }()

        return HStack(spacing: 12) {
            // 키링 썸네일
            CachedAsyncImage(url: event.bodyImage)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.keyringName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(event.formattedDeployDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // 만료 상태 태그
            Text(event.statusText)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.1))
                .foregroundStyle(statusColor)
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
                selectedEvent = event
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
            if let event = selectedEvent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 키링 이미지 + 기본 정보
                        HStack(spacing: 16) {
                            CachedAsyncImage(url: event.bodyImage)
                                .frame(width: 80, height: 80)
                                .glassEffect(in: .rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(event.keyringName)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(event.eventTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // 정보 카드
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            infoCard(icon: "person", label: "배포자", value: event.deployedByName)
                            infoCard(icon: "calendar", label: "배포일", value: event.formattedDeployDate)
                            infoCard(
                                icon: "clock",
                                label: "만료일",
                                value: event.formattedExpiresDate ?? "무한 배포"
                            )
                            infoCard(
                                icon: "circle.fill",
                                label: "상태",
                                value: event.statusText
                            )
                        }

                        // 공유 링크
                        copyableField(label: "공유 링크", value: event.shareLink)

                        Spacer()

                        // 이벤트 종료 버튼
                        Button(role: .destructive) {
                            eventToDelete = event
                            viewModel.showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("이벤트 종료")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("이벤트를 선택해주세요")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - 정보 카드

    private func infoCard(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(12)
        .glassEffect(.regular.tint(.clear))
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
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .glassEffect(in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    ActiveEventManagementView()
}
