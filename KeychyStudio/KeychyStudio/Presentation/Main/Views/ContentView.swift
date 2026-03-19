//
//  ContentView.swift
//  KeychyStudio
//
//  Created by 길지훈 on 3/18/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable {
    // 공지
    case generalNotice = "일반 공지사항"
    case updateNotice = "업데이트 알림"
    case keyringEvent = "키링 배포"

    // 이력
    case history = "발송 이력"

    var icon: String {
        switch self {
        case .generalNotice: "megaphone"
        case .updateNotice: "arrow.down.app"
        case .keyringEvent: "gift"
        case .history: "list.clipboard"
        }
    }

    // 섹션 구분용
    enum Section: String, CaseIterable {
        case announce = "공지 발송"
        case manage = "관리"
    }

    var section: Section {
        switch self {
        case .generalNotice, .updateNotice, .keyringEvent: .announce
        case .history: .manage
        }
    }

    static func items(for section: Section) -> [SidebarItem] {
        allCases.filter { $0.section == section }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem = .generalNotice

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

            Spacer()

            Button(role: .destructive) {
                // TODO: 로그아웃 처리
            } label: {
                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .padding()
        } detail: {
            switch selection {
            case .generalNotice:
                AnnouncementView()
            case .updateNotice:
                AnnouncementView()
            case .keyringEvent:
                AnnouncementView()
            case .history:
                AnnouncementHistoryView()
            }
        }
        .frame(minWidth: 700, idealWidth: 900, minHeight: 500, idealHeight: 600)
    }
}

#Preview {
    ContentView()
}
