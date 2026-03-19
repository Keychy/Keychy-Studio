//
//  KeychyStudioApp.swift
//  KeychyStudio
//
//  Created by 길지훈 on 3/18/26.
//

import SwiftUI
import FirebaseCore

@main
struct KeychyStudioApp: App {
    @State private var authViewModel: AuthViewModel

    init() {
        FirebaseApp.configure()
        // Firebase 초기화 후에 AuthViewModel 생성해야 Auth.auth() 접근 가능
        _authViewModel = State(initialValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
        .windowResizability(.contentSize)
    }
}
