//
//  AnnouncementView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-19.
//

import SwiftUI

enum DeepLinkDestination: String, CaseIterable {
    case home = "홈"
    case workshop = "공방"
    case appStore = "앱스토어"
}

struct AnnouncementView: View {
    @Bindable var viewModel: AnnouncementViewModel
    @State private var showConfirmAlert = false

    var body: some View {
        HStack(spacing: 0) {
            formSection

            previewSection
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showConfirmAlert = true
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(viewModel.title.isEmpty || viewModel.body.isEmpty)
            }
        }
        .alert("공지 발송", isPresented: $showConfirmAlert) {
            Button("취소", role: .cancel) {}
            Button("발송", role: .destructive) {
                Task { await viewModel.send() }
            }
        } message: {
            Text("꺼진 불도 다시 보자.?")
        }
        .alert("발송 완료", isPresented: $viewModel.sendSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("공지가 성공적으로 발송되었습니다.")
        }
    }

    // MARK: - 작성 폼

    private var formSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 타이틀
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("타이틀")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(viewModel.title.count)/30")
                            .font(.caption)
                            .foregroundStyle(viewModel.title.count > 30 ? Color.red : Color.gray)
                    }
                    TextField("타이틀을 입력하세요.", text: $viewModel.title)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .glassEffect(.regular.tint(.clear))
                }

                // 서브타이틀
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Text("서브타이틀")
                                .font(.title3)
                                .fontWeight(.medium)
                            Text("(Optional)")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text("\(viewModel.subtitle.count)/30")
                            .font(.caption)
                            .foregroundStyle(viewModel.subtitle.count > 30 ? Color.red : Color.gray)
                    }
                    TextField("서브타이틀을 입력하세요.", text: $viewModel.subtitle)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .glassEffect(.regular.tint(.clear))
                }

                // 딥링크 목적지
                VStack(alignment: .leading, spacing: 8) {
                    Text("딥링크")
                        .font(.title3)
                        .fontWeight(.medium)
                    Picker("", selection: $viewModel.deepLink) {
                        ForEach(DeepLinkDestination.allCases, id: \.self) { dest in
                            Text(dest.rawValue).tag(dest)
                        }
                    }
                    .labelsHidden()
                }

                // 내용
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("내용")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(viewModel.body.count)/120")
                            .font(.caption)
                            .foregroundStyle(viewModel.body.count > 120 ? Color.red : Color.gray)
                    }
                    TextEditor(text: $viewModel.body)
                        .font(.title3)
                        .padding(6)
                        .frame(minHeight: 100, maxHeight: .infinity)
                        .scrollContentBackground(.hidden)
                        .glassEffect(in: .rect(cornerRadius: 12))
                }

            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 미리보기

    private var previewSection: some View {
        GeometryReader { geo in
            VStack {
                Text("미리보기")
                    .font(.title3)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                    .frame(maxHeight: 90)

                // 실제 iOS 푸시 알림 스타일
                HStack(alignment: .top, spacing: 14) {
                    // 앱 아이콘
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 알림 내용
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(viewModel.title.isEmpty ? "타이틀" : viewModel.title)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(viewModel.title.isEmpty ? .secondary : .primary)
                                .lineLimit(1)

                            Spacer()

                            Text("지금")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if !viewModel.subtitle.isEmpty {
                            Text(viewModel.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(viewModel.body.isEmpty ? "내용을 입력하세요" : viewModel.body)
                            .font(.subheadline)
                            .foregroundStyle(viewModel.body.isEmpty ? .secondary : .primary)
                            .lineLimit(4)
                    }
                }
                .padding(20)
                .frame(width: geo.size.width * 0.85, alignment: .leading)
                .glassEffect(in: .rect(cornerRadius: 15))

                // 딥링크 목적지
                HStack(spacing: 6) {
                    Text("딥링크 👉 \(viewModel.deepLink.rawValue)")
                        .font(.body)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 12)

                Spacer()
            }
            .padding(24)
            .frame(width: geo.size.width)
        }
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.03))
    }
}

#Preview {
    AnnouncementView(viewModel: AnnouncementViewModel())
}
