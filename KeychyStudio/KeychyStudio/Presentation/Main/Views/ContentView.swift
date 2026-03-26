//
//  ContentView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 3/18/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable {
    case sendNotification = "알림 보내기!"
    case keyringEvent = "키링 배포"
    case history = "발송 이력"
    case activeEvents = "키링 배포 관리"

    var icon: String {
        switch self {
        case .sendNotification: "paperplane"
        case .keyringEvent: "gift"
        case .history: "list.clipboard"
        case .activeEvents: "shippingbox"
        }
    }

    enum Section: String, CaseIterable {
        case announce = "공지"
        case manage = "관리"
    }

    var section: Section {
        switch self {
        case .sendNotification, .keyringEvent: .announce
        case .history, .activeEvents: .manage
        }
    }

    static func items(for section: Section) -> [SidebarItem] {
        allCases.filter { $0.section == section }
    }
}

struct ContentView: View {
    var authViewModel: AuthViewModel
    @State private var selection: SidebarItem = .sendNotification
    @State private var announcementVM = AnnouncementViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SidebarItem.Section.allCases, id: \.self) { section in
                    Section(section.rawValue) {
                        ForEach(SidebarItem.items(for: section), id: \.self) { item in
                            Label(item.rawValue, systemImage: item.icon)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: { authViewModel.signOut() }) {
                    Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationSplitViewColumnWidth(180)

        } detail: {
            Group {
                switch selection {
                case .sendNotification:
                    AnnouncementView(viewModel: announcementVM)
                case .keyringEvent:
                    KeyringEventView()
                case .history:
                    AnnouncementHistoryView(viewModel: announcementVM)
                case .activeEvents:
                    ActiveEventManagementView()
                }
            }
            .navigationTitle("Keychy Studio")
            .navigationSubtitle(selection.rawValue)
        }
        .frame(width: 900, height: 450)
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
}
