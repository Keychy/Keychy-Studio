# Keychy Studio (v1)

  [Keychy](https://apps.apple.com/app/keychy) 서비스 운영을 위한 macOS 관리 앱입니다.  
  **앱 내 공지사항 발송, 키링 이벤트 배포 등 운영 업무를 처리**합니다.

<img width="312" alt="image" src="https://github.com/user-attachments/assets/734d0cd9-4ea3-4c60-8ec5-53ffb1d3bd3d" />
<img width="612" alt="image" src="https://github.com/user-attachments/assets/a108c38b-dce3-4d07-b081-69336da71bbe" />
<img width="452" alt="image" src="https://github.com/user-attachments/assets/f031595d-dfaf-420f-8e8c-65d4a171605e" />
<img width="452" alt="image" src="https://github.com/user-attachments/assets/8ca6225c-fa33-416c-a2a9-14312652d94c" />


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
  5. `.env` 파일을 프로젝트 루트에 추가합니다. (팀 내부 공유)
  6. 앱 실행 시 운영자 계정을 입력합니다.   (팀 내부 공유)
