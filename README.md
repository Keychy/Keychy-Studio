# Keychy Studio (v1)

<img width="200" alt="KeychyStudio_AppIcon-watchOS-Default-129x129@2x" src="https://github.com/user-attachments/assets/b5251e5c-b2fc-47e8-8524-8ac032acb1c3" />


  [Keychy](https://apps.apple.com/app/keychy) 서비스 운영을 위한 macOS 관리 앱입니다.  
  **앱 내 공지사항 발송, 키링 이벤트 배포 등 운영 업무를 처리**합니다.
  
  ## 기능

  ### 공지 발송
  - 타이틀 / 서브타이틀 / 내용 작성
  - 딥링크 목적지 선택 (앱스토어, 공방, 앱 홈, 쇼케이스, 키링 선물)
  - 발송 대상 선택 (전체 유저 또는 특정 유저 ID 지정)
  - 발송 전 미리보기 및 확인 Alert
  - 발송 이력 Firestore 저장 및 조회

  ### 키링 이벤트 배포 (v2 업데이트에서)
  - 키링 검색 및 선택
  - 링크 만료 기간 설정
  - 이벤트 배포 링크 생성 및 발송

  ## 사용법

  1. 이 레포를 클론합니다.
  ```bash
  git clone https://github.com/giljihun/KeychyStudio.git
  ```
  2. Xcode로 프로젝트를 엽니다.
  3. `GoogleService-Info.plist`를 프로젝트 루트에 추가합니다. (팀 내부 공유)
  4. 빌드 후 실행합니다.
  6. 앱 실행 시 운영자 계정을 입력합니다.   (팀 내부 공유)
