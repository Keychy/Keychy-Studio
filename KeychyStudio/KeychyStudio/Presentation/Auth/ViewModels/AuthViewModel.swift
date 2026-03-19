//
//  AuthViewModel.swift
//  KeychyStudio
//
//  Created by 길지훈 on 2026-03-18.
//

import Foundation
import FirebaseAuth

@MainActor
@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var isLoading = false
    var isLoggedIn = false
    var showCheck = false

    init() {
        // TODO: 배포 시 자동 로그인 제거 (signOut 복원)
        isLoggedIn = Auth.auth().currentUser != nil
    }

    func login() async {
        errorMessage = ""
        isLoading = true

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            isLoading = false
            showCheck = true

            // 체크 표시 1.5초 보여준 후 메인 화면으로 전환
            try await Task.sleep(for: .seconds(1.5))
            isLoggedIn = true
        } catch {
            isLoading = false
            errorMessage = loginErrorMessage(error)
        }
    }

    // Firebase 에러를 사용자 친화적 메시지로 변환
    private func loginErrorMessage(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case AuthErrorCode.invalidEmail.rawValue:
            return "올바른 이메일 형식이 아닙니다."
        case AuthErrorCode.networkError.rawValue:
            return "네트워크 연결을 확인해주세요."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        default:
            return "로그인에 실패했습니다. (\(error.localizedDescription))"
        }
    }
}
