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

    var icon: String {
        switch self {
        case .sendNotification: "paperplane"
        case .keyringEvent: "gift"
        case .history: "list.clipboard"
        }
    }

    enum Section: String, CaseIterable {
        case announce = "공지"
        case manage = "관리"
    }

    var section: Section {
        switch self {
        case .sendNotification, .keyringEvent: .announce
        case .history: .manage
        }
    }

    static func items(for section: Section) -> [SidebarItem] {
        allCases.filter { $0.section == section }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem = .sendNotification

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
            .navigationSplitViewColumnWidth(180)

        } detail: {
            Group {
                switch selection {
                case .sendNotification:
                    AnnouncementView()
                case .keyringEvent:
                    KeyringEventView()
                case .history:
                    AnnouncementHistoryView()
                }
            }
            .navigationTitle("Keychy Studio")
            .navigationSubtitle(selection.rawValue)
        }
        .frame(width: 900, height: 450)
    }
}

#Preview {
    ContentView()
}
