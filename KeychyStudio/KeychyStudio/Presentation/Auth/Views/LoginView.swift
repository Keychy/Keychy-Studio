//
//  LoginView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-18.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // 앱 아이콘 + 타이틀
            VStack(spacing: 4) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Keychy Studio")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .fontDesign(.serif)

                Text("v1")
                    .font(.title3)
                    .fontDesign(.serif)
                    .foregroundStyle(.secondary)
            }

            // 입력 필드
            VStack(spacing: 12) {
                TextField("이메일", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .textContentType(.emailAddress)
                    .padding(8)
                    .glassEffect(.regular.tint(.clear))

                SecureField("비밀번호", text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .textContentType(.password)
                    .padding(8)
                    .glassEffect(.regular.tint(.clear))
                    .onSubmit {
                        Task { await viewModel.login() }
                    }
            }
            .frame(width: 260)

            // 에러 메시지
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // 로그인 버튼 / 로딩 / 체크
            if viewModel.showCheck {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("로그인") {
                    Task { await viewModel.login() }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
            }
        }
        .padding(40)
        .frame(width: 300, height: 400)
        .containerBackground(.ultraThinMaterial, for: .window)
        .animation(.easeInOut, value: viewModel.showCheck)
        .animation(.easeInOut, value: viewModel.isLoading)
    }
}

#Preview {
    LoginView()
}
