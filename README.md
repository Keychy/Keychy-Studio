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
  - 발송 이력 Firestore 저장 및 조회 (키링 배포 이력 포함, 상세 정보 표시)

  ### 키링 이벤트 배포
  - 키링 검색 및 선택
  - 배포 설정: 보낸사람 표시명(`senderDisplayName`) 커스텀 설정
  - 배포 설정: 무한배포 토글 / 만료일 DatePicker 선택
  - 이벤트 배포 링크 생성 및 발송
  - Cloud Functions(FCM) 연동 푸시 알림 트리거

  ### 키링 배포 관리
  - 활성 배포 이벤트 목록 조회 (썸네일 + 이름 + 배포일 + 만료 상태)
  - 배포 상태 태그: 활성(초록) / 만료됨(빨강) / 무한배포(회색)
  - 이벤트 상세 정보 확인 (키링 이미지, 배포 링크, 배포자 등)
  - 이벤트 종료 (PostOffice 문서 삭제)

  ## 사용법

  1. 이 레포를 클론합니다.
  ```bash
  git clone https://github.com/giljihun/KeychyStudio.git
  ```
  2. Xcode로 프로젝트를 엽니다.
  3. `GoogleService-Info.plist`를 프로젝트 루트에 추가합니다. (팀 내부 공유)
  4. 빌드 후 실행합니다.
  6. 앱 실행 시 운영자 계정을 입력합니다.   (팀 내부 공유)
