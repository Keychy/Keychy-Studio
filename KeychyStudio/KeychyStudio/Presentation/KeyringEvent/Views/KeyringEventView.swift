//
//  KeyringEventView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import SwiftUI

// 메모리 이미지 캐시 (앱 생명주기 동안 유지)
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

// AsyncImage 대체 — 한 번 받은 이미지는 메모리 캐시에서 즉시 표시
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

struct KeyringEventView: View {
    @State private var viewModel = KeyringEventViewModel()
    @State private var showConfirmAlert = false

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    var body: some View {
        HStack(spacing: 0) {
            keyringListSection
            detailSection
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showConfirmAlert = true
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(viewModel.selectedKeyring == nil || viewModel.eventTitle.isEmpty)
            }
        }
        .alert("키링 배포", isPresented: $showConfirmAlert) {
            Button("취소", role: .cancel) {}
            Button("배포", role: .destructive) {
                Task { await viewModel.deploy() }
            }
        } message: {
            if viewModel.isUnlimitedDeployment {
                Text("정말 배포하시겠습니까?\n전체 유저에게 푸시가 전송됩니다.\n(무한 배포)")
            } else {
                Text("정말 배포하시겠습니까?\n전체 유저에게 푸시가 전송됩니다.\n(만료: \(viewModel.expiresAt.formatted(date: .abbreviated, time: .shortened)))")
            }
        }
        .alert("배포 완료", isPresented: $viewModel.deploySuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("키링 이벤트가 성공적으로 배포되었습니다.")
        }
    }

    // MARK: - 키링 목록

    private var keyringListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 운영자 태그
            VStack(alignment: .leading, spacing: 8) {
                Text("운영자")
                    .font(.title3)
                    .fontWeight(.medium)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.operators) { op in
                            Button {
                                viewModel.selectOperator(op)
                            } label: {
                                Text(op.nickname)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedOperator == op
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.primary.opacity(0.05)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 키링 그리드
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.keyrings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("키링이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.keyrings) { keyring in
                            keyringCard(keyring)
                        }
                    }
                    .padding(.top, 10)
                }
            }

            // 에러 메시지
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 키링 카드

    private func keyringCard(_ keyring: KeyringItem) -> some View {
        let isSelected = viewModel.selectedKeyring == keyring

        return VStack(spacing: 8) {
            CachedAsyncImage(url: keyring.bodyImage)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)

            Text(keyring.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .lineLimit(1)
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedKeyring = keyring
            }
        }
    }

    // MARK: - 상세정보 + 배포 폼

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let keyring = viewModel.selectedKeyring {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 키링 상세정보 헤더
                        HStack(spacing: 16) {
                            CachedAsyncImage(url: keyring.bodyImage)
                                .frame(width: 80, height: 80)
                                .glassEffect(in: .rect(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(keyring.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("\(viewModel.nickname(for: keyring.authorId)) → KEYCHY")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // 상세 정보 그리드
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            infoCard(icon: "calendar", label: "만든 날", value: keyring.formattedDate)
                            infoCard(icon: "sparkles", label: "이펙트", value: keyring.particleId)
                            infoCard(icon: "speaker.wave.2", label: "사운드", value: keyring.soundId)
                            infoCard(icon: "person", label: "만든이", value: viewModel.nickname(for: keyring.authorId))
                        }

                        // 배포 설정
                        VStack(alignment: .leading, spacing: 12) {
                            Text("배포 설정")
                                .font(.title3)
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("보낸 사람 표시명")
                                    .font(.body)
                                    .fontWeight(.medium)
                                TextField("KEYCHY", text: Binding(
                                    get: { viewModel.senderDisplayName },
                                    set: { viewModel.senderDisplayName = $0 }
                                ))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .glassEffect(.regular.tint(.clear))
                            }

                            Toggle("무한 배포", isOn: Binding(
                                get: { viewModel.isUnlimitedDeployment },
                                set: { viewModel.isUnlimitedDeployment = $0 }
                            ))
                            .toggleStyle(.switch)

                            if !viewModel.isUnlimitedDeployment {
                                DatePicker(
                                    "만료일",
                                    selection: Binding(
                                        get: { viewModel.expiresAt },
                                        set: { viewModel.expiresAt = $0 }
                                    ),
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.field)
                            }
                        }

                        // 배포 폼
                        VStack(alignment: .leading, spacing: 12) {
                            Text("배포 알림 작성")
                                .font(.title3)
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("타이틀")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(viewModel.eventTitle.count)/30")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.eventTitle.count > 30 ? Color.red : Color.gray)
                                }
                                TextField("배포 알림 타이틀", text: $viewModel.eventTitle)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .glassEffect(.regular.tint(.clear))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("서브타이틀")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text("(Optional)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                    Text("\(viewModel.eventSubtitle.count)/30")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.eventSubtitle.count > 30 ? Color.red : Color.gray)
                                }
                                TextField("배포 알림 서브타이틀", text: $viewModel.eventSubtitle)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .glassEffect(.regular.tint(.clear))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("내용")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(viewModel.eventBody.count)/120")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.eventBody.count > 120 ? Color.red : Color.gray)
                                }
                                TextEditor(text: $viewModel.eventBody)
                                    .font(.body)
                                    .padding(6)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .glassEffect(in: .rect(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("키링을 선택해주세요")
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
}

#Preview {
    KeyringEventView()
}
