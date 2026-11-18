# 인수인계 — 강릉분원 AR「불끄기 대작전」

작성일: 2026-11-13 (금) 18시
작성: Claude (이전 채팅). 다음 채팅에서 이 파일 하나만 읽으면 이어서 작업할 수 있도록 정리했습니다.

---

## 0. 한눈에 보기

| 항목 | 내용 |
|---|---|
| 의뢰인 | Peter, 강원특별자치도교육청특수교육원 강릉분원 분원장 |
| 목적 | 특수교육대상학생이 분원 건물·실내를 비추며 AR로 불을 끄고, 안전체험관에서 선물을 받는 체험. 안전체험관 교육(소화기·대피)과 연계 |
| 운영 주소 | https://fumon1218.github.io/gangneung-ar-fire/ (GitHub Pages, 공개) |
| 저장소 | `fumon1218/gangneung-ar-fire` (공개, main 브랜치에 올리면 1~2분 뒤 반영) |
| 기술 | 순수 정적 웹(HTML 한 파일). three.js 0.170(jsdelivr importmap), MindAR 1.2.5 **core Controller**(`mindar-image.prod.js`), 빌드 없음 |
| 약속·제약 | **과금 금지**(유료 기능은 먼저 묻기. ChatGPT는 Plus 회원이라 이미지 생성 OK). Tripo AI는 크레딧 들므로 사용 전 승인. 사용자의 Blender·Roblox Studio는 **다른 채팅에서 작업 중일 수 있으니 겹치면 대기 후 순차 진행**. 공개·배포 결정은 사용자에게(현재 GitHub Pages 공개는 승인됨). 다운로드 폴더 자산은 사용자 소유("다 내 자산") — 단 three.js 예제 모델은 사용 금지 |
| 말투 | 사용자는 한국어, 격식 있는 행정 문체 선호. 결과는 짧게 요약 + 캡처 이미지로 보여 주면 좋아함 |

---

## 1. 화면 흐름 (index.html)

1. **시작 카드**: 불 끄는 친구 9종 중 선택 → `🚒 소방대 본부로 가기`
2. **소방대 본부(로비)** `#lobby` (배경 lobby.webp, ChatGPT 그림)
   - `🧯 소화기 4단계 연습` → `#ext` 화면 (완료 시 localStorage `gnfire-ext=true`, 배지 🏅 소화기 박사, 출동 버튼 잠금 해제)
   - `🏫 3D 불끄기 훈련장` → `train.html`
   - `📷 AR 소화기 훈련` → `index.html?train`
   - `🏢 실외 출동` / `🏠 실내 출동` → 카메라 켜짐, 사이렌, 지도에 🔥 한 곳 표시(무작위), 그곳을 비추면 악당 등장·불 → 끄면 3초 뒤 다른 곳에 새 불 → 모두 끄면 선물 코드
3. **AR 본 게임**: 화면 꾹 누르기 = 물 뿌리기(친구별 고유 효과), 동물 친구 3마리 자동 분사, 악당이 불 뿜음(rigged Walk/Fly + Attack)
4. **미니맵** (왼쪽 위, 보물지도 map_out.webp / map_in.webp): 🔥 불난 곳, ✓ 끈 곳, ? 미확인, 파란 원 = 지금 장소. 누르면 크게 펼침. 불 나면 테두리 빨간 경보

### 코스·장소 (DEFAULT_ST, 인덱스 = targets.mind 순서)
- 실외 코스 st 1~5: 0=정문 간판(start), 1=① 배너(start), 2~5=②~⑤ 배너, 6~14=건물 자연 특징(②모서리 창, 필로티, ③계단, ④커튼월, ⑤옥상정원 근거리 4장)
- 실내 코스 st 6~9 (ⓐ바리스타=미라, ⓑ그린월=불새, ⓒ비상대피 안내도=용암 골렘, ⓓ안전체험관=우주 보스): 15~22 = 실내 자연 특징 사진, **23~26 = 실내 배너 ⓐ~ⓓ**
- 배너 공통: `BANNER_W=0.56`(인식 그림 폭 m), `BANNER_GROUND=-0.60`. 실외 배너 불 좌표는 예전 배너 대비 y +0.78 보정됨
- `#calib` 해시로 보정 모드(불 위치 슬라이더) 사용 가능

### 주요 코드 블록 (index.html 안 주석 제목으로 검색)
`DEFAULT_ST`, `VILLAINS`, `HEROES`, `파티클`(Particles 클래스: fire/smoke/steam/water/bubble/heavy/powder), `소리 (파일 없이 직접 합성)`(audioSession=playback으로 무음 스위치 대응), `미니맵`, `로비 · 출동`(alarmAt, pickFire, announce, dispatch), `소화기 4단계 연습`(EX 상태, ex_*.webp 레이어), `AR 소화기 훈련`(TRAIN, TR 상태), `게임 상태`(setupStation, damage, win), `호스`(heroSpray, Jet 리본 물줄기), `자이로`, `MindAR`(anchorFound: 자이로로 실제 공간 기준 자세 평활화), `placeOnGround`(실외 동물을 휴대폰 높이 1.25m 아래 바닥에), `lookLocal`(무대 좌표→세계 좌표 lookAt — 악당 방향 버그 수정 핵심)

---

## 2. 3D 불끄기 훈련장 (train.html)
- 교실 10×8m, 칠판(수칙), 창문·커튼, 초록 비상구, 소화기함. 가구·주인공은 다운로드 폴더 `00_정리_1112/1_3D모델/소품_기타`(Desk, Chair, Table, Bookshelf, RecycleBins, Planter_raw) + `캐릭터_몬스터_동물/firefighter toy figure 3d model.glb` → `train/*.glb`(meshopt 해제·512 webp)
- 1인칭/3인칭 전환(👁), 조이스틱 이동, 📣불이야(별+1) → ①안전핀 → 4m 이내 접근 → ③꾹 누르기 + 좌우 끌기(쓸기 보너스) → 불 3개 해결. 불이 커지면 비상구 대피, 분말 소진 시 소화기함에서 교체
- **소스는 조각으로 관리**: `tools/train-src/`(shell.html, main.js, part2.js, aud.js) → `python3 tools/train-src/build.py` 로 train.html 조립. part2.js/aud.js는 index.html의 파티클·소리 코드 복사본
- 시험용 디버그: `window.__S`, `window.__P()`

## 3. AR 소화기 훈련 (index.html?train)
- 표식 크기 선택(X배너 f=1 / A4 f=0.56/0.186 / 건물 f=1) → 표식 인식 → 자이로로 실제 바닥(휴대폰 1.2m 아래, 1.6~3m 앞)에 책상·의자·종이·분리수거함·책꽂이·화분 배치 → 불 3개 순차
- 손에 든 소화기는 `extScene/extCam` 별도 장면으로 화면에 덧그림(AR 카메라 단위가 MindAR 픽셀 단위라 근접 물체가 잘려서)
- 조준 = 화면 가운데 원(휴대폰 방향), 쓸기 = 분사 중 휴대폰 좌우로 흔들기, 3.5m 이내만 유효, 너무 커지면 🏃 대피 버튼

---

## 4. 자산·인쇄물 위치

| 무엇 | 어디 |
|---|---|
| ChatGPT 원화(배너 9장, 지도 2장, 로비, 소화기 부품) | 사용자 Mac `~/Downloads/ar_banner_art/` (out1~5, ina~ind, in1, map_out, map_in, lobby, ext_body/fire/noz/room) |
| 인쇄용 X배너(600×1800mm, 100dpi PDF) | `~/Downloads/AR불끄기대작전_새배너/` (실외 5쪽, 실내 4쪽, 테스트용 A4 9쪽, 미리보기) |
| 배너 합성 스크립트 | `tools/banner/make.py` (원화 out*.png/in*.png 필요, QR=운영 주소, 인식 그림 영역: 상단 800mm부터 560×840mm) |
| 인식 표식 원본 이미지 27장 | `tools/targets/T0~T26.jpg` (T1~T5, T23~T26 = 새 배너 그림 부분) |
| ChatGPT 대화 | "포스터 이미지 생성" 대화에 모든 원화 프롬프트 기록 |
| 3D 자산 원본 | `~/Downloads/00_정리_1112/1_3D모델/` (1276개 glb/fbx, 대부분 meshopt 압축 → `gltf-transform copy`로 해제) |

**ChatGPT 이미지 받는 법(브라우저 창)**: 생성 이미지 `<img alt="생성된 이미지">`의 blob을 fetch → `<a download>`로 다운로드 폴더에 저장 → `device_stage_files`로 가져오기. 다운로드가 가끔 누락되므로 확인 후 재시도. 파일명은 ASCII 권장(한글은 NFD로 저장됨).

---

## 5. 작업 도구 (컨테이너, 새 채팅에선 다시 준비 필요)
- 정적 서버: 저장소 폴더에서 `python3 -m http.server 8765` (명령 안에서 같이 실행)
- 시험: Playwright + Chrome, `--use-file-for-fake-video-capture=fake.y4m` (사진을 ffmpeg로 y4m 변환). 예시 스크립트 `tools/sttest.py`, `ltest.py`(로비·연습·출동), `artest.py`(?train), `ttest3.py`(train.html)
  - 로컬 시험 땐 CDN 주소를 node_modules로 바꾼 사본 사용: `sed -e 's#https://cdn.jsdelivr.net/npm/three@0.170.0/#/node_modules/three/#g' -e 's#https://cdn.jsdelivr.net/npm/mind-ar@1.2.5/dist/#/node_modules/mind-ar/dist/#'` (npm i three@0.170.0 mind-ar@1.2.5)
- **targets.mind 재학습**: `tools/compile.html`(파일 목록 T0~T26) + `tools/compile.py` → 헤드리스 Chrome에서 MindAR Compiler 실행(약 5분) → targets.mind(11.8MB). **표식 순서를 바꾸면 DEFAULT_ST 인덱스도 같이 바꿀 것**
- 악당 리깅: `tools/rig.py` (bpy 4.3, uv Python 3.11 venv) — golem/mummy: Walk+Attack, phoenix/spaceboss: Fly+Attack
- git 푸시: `git -c push.negotiate=true push`, 커밋 끝에 Co-Authored-By / Claude-Session 줄

---

## 6. 남은 일 (우선순위)

1. **배너 QR 재출력** — oksclass.com/fire/ 반영 완료(10장). 배너 QR을 새 주소로 바꿀지 결정 필요
2. **Roblox「배움의 별」이식** — 사용자가 다른 채팅에서 Roblox Studio 작업 중이라 끝나면 진행. 방향: 플레이어 **기본 아바타**에 소화기 Tool(핀·레버·분말 파티클)만 들리고, 교실 사물(다운로드 폴더 원본 glb, webp 아닌 원본 텍스처로) 배치, 불·불이야·대피·소화기함 로직을 Luau로. 시작 시 구조만 읽고 위치를 먼저 묻기. 연결된 Studio 목록은 `list_roblox_studios`로 확인(당시 'Place1'만 열림)
3. **3D 훈련장 확장**: 사무실(멀티탭·복사기, 전기 화재), 놀이터(쓰레기통·낙엽, 바람 등지기) — 교실 조작감 확인 후
4. **현장 확인 필요(아이폰 실기)**: ⓑ 그린월 인식, 실외 동물 바닥 높이(자이로 방식, `EYE=1.25`), 새 배너 9종 실제 인식·불 위치, AR 소화기 훈련의 사물 크기/높이, 확대 방지 효과, 3D 훈련장 조이스틱 조작감
5. 바리스타 체험(주문·음료 받기) 확장 아이디어 — 사용자가 "일단 대기"로 보류
6. 선택 사항: 강아지 쌍둥이 물줄기를 한 줄기로(사용자 "오케" — 현행 유지 중), 학생마다 소화기 연습 초기화 옵션, 출동 순서 고정 옵션

## 7. 알려진 한계
- 웹 AR이라 가상 물체가 실제 사물 뒤로 가려지지 않음
- 시험은 가짜 카메라(사진)로만 했고, 휴대폰 기울기·실제 걸음은 현장에서만 검증 가능
- 소화기 연습의 안전핀·레버 그림은 ChatGPT 소화기 한 장을 마스크로 잘라 만든 레이어(ex_body/pin/lever.webp, 400×600 같은 캔버스)

---

## 8. 2026-11-18 추가: 새 코스 3개 (연수동·체험동·야외)

- 사용자가 분원 공간 사진 69장(15곳)을 보냄 → 인식 시험(사진별 변형 3회, 다른 장소와 혼동 0건) 후 41장을 기준 사진으로 채택
- **코스별 인식 파일 분리**: `targets.mind`(실외·실내, 0~26) / `targets_yeonsu.mind`(100~) / `targets_cheheom.mind`(200~) / `targets_yaoe.mind`(300~). 출동 시 `loadMind()`가 코스 파일로 컨트롤러를 다시 만듦(`mindOff`로 전역 인덱스 변환, `postM`은 객체)
- 정의 원본: `tools/courses.py`(사진명, w, 바닥선 비율, 악당, 비행 여부) → DEFAULT_ST 100~/200~/300~ 항목 생성. 기준 사진은 `tools/targets/<코스>/`, 재학습은 `tools/compile2.html?c=<코스>` + `tools/compile2.py <코스>`
- 장소(st): 연수동 10 로비·11 사무실·12 소회의실·13 중회의실·14 공연장 / 체험동 20 북카페·21 2층 로비·22 동아리실·23 디지털 융합·24 e스포츠·25 장애이해·26 진로직업·**27 안전체험관(마지막 고정, final)** / 야외 30 통로 쉼터·31 뒤편
- 로비에 🏛 연수동 / 🧪 체험동 / 🌲 야외 출동 버튼, 미니맵 `map_yeonsu/cheheom/yaoe.webp`(ChatGPT, 원본 `~/Downloads/ar_banner_art/`), 선물 코드 접두어 연수-/체험-/야외-
- **안전 미션 퀴즈**(`QUIZ`, `showQuiz`): 불을 끈 뒤 장소별 판단 문제(전기 화재, 충전 배터리, 소화기 위치 찾기, 비상구, 계단 아래 대피, 119, 함께 대피, 기름 화재, 바람 등지기). 음성 읽기 포함
- 시험용 훅 `window.__dbg.alarm(st)`(지금 불난 곳 강제 지정)
- 시험 완료: 체험동(진로직업), 연수동(로비), 야외(뒤편) 가짜 카메라로 불 → 끄기 → 퀴즈까지 확인. 기존 실외 코스·AR 소화기 훈련 회귀 확인
- 현장 확인 필요: 실제 인식률(조명·가구 배치 변화), 장소별 바닥 높이·악당 크기(사진 추정값), 중회의실은 인식 약함 → A4 표식 권장, 야외는 X배너 병행 권장

- **2026-11-18 변경(사용자 요청 "비춘 곳에서만 불이 나게, 너무 멀어서")**: 출동 시 불 위치를 무작위로 정하지 않음. 지도에 안 끈 곳 전부 🔥, 학생이 비춘 장소(안 끈 곳)에서 바로 불. 끈 뒤 퀴즈 → "남은 곳 N곳" 안내. 체험동 안전체험관(final)은 다른 곳을 다 끈 뒤에만 불(지도에 🔒 마지막). `pickFire/announce`는 더 이상 출동 흐름에서 쓰지 않음

## 9. 2026-11-18 추가: 완성도 패키지 ("다 적용해줘")
- **⚙️ 설정** (로비, localStorage `gnfire-settings`): 이름·모둠, 난이도(쉬움 dmg×1.7·성장×0.5 / 보통 / 도전 dmg×0.7·성장×1.8 + ⏱ 타이머), 조용한 모드(사이렌→차임, 깜빡임 끔, 볼륨 0.45, 입자 절반), 큰 글씨, 고대비, 안내 읽어주기(`tip()`→`say()`), 한 번 톡=계속 뿌리기, 퀴즈 그림 카드(선택지 앞 이모지를 큰 기호로).
- **🎯 현장 보정** (설정→현장 보정, 또는 `#calib`): 모든 장소의 불 xyz·크기, 바닥 높이, 악당 크기, 친구 크기. 기본값과 다른 것만 `gnfire-calib`에 저장, 📋 복사/💾 JSON 받기. 받은 JSON을 DEFAULT_ST에 반영하면 모든 기기에 적용.
- **인식 도움말**: 10초간 인식 안 되면 안내 + A4 카드 안내. `markers_a4.pdf`(24장, `tools/make_a4.py`로 재생성).
- **학생 기록** `rec` (`gnfire-rec`): 끈 장소·시각, 퀴즈 첫 시도 정답, 소화기 연습, 완주 코스·초. 결과 코드 `GNF1.<base64url JSON>`.
- **🏅 인증서**(로비·완료 화면): 캔버스 1080×1500 JPG, QR = `teacher.html#GNF1...` → 교사 폰 기본 카메라로 찍으면 기록장에 자동 추가.
- **teacher.html**: 코드 붙여넣기 / BarcodeDetector 스캔(안드로이드 크롬) / 해시 자동 추가, 모둠 합계, 학생별 표, CSV(BOM, 엑셀 한글 OK). 교사 기기 localStorage `gnfire-teacher`.
- **📖 악당 도감**: 코스별 장소 카드(`vil_*.webp`, 끈 곳만 컬러).
- **🎬 만화**: `comic_intro.webp`(첫 출발 시 1회, 로비 🎬로 다시 보기), `comic_ending.webp`(첫 완주 시 1회). 2×2 칸을 한 칸씩 확대 + 자막 + 읽어주기. "처음부터 다시 하기"가 기록·만화 표시를 초기화.
- **PWA**: manifest.json, icon192/512, sw.js(HTML은 네트워크 우선, 나머지 캐시 우선). **.mind/GLB를 바꾸면 sw.js의 `V` 버전을 올릴 것.**
- 디버그 훅(`__dbg`, train `__S/__P`)은 localhost 또는 `?debug`에서만.
- 인쇄물: `badges_a4.pdf`(원형 60mm 배지 12개, `tools/make_stickers.py`).
- 수업 지도안·활동지: Claude Docs 문서 "불 끄기 대작전 AR 수업 지도안·활동지".
- 테스트: `/home/claude/tst/mk.sh`로 site/st_test.html 생성(CDN→node_modules), st15/st17/st18.py.

## 10. oksclass.com/fire/ 이전 상태
- oks-class 저장소 main에는 11/13판 `fire/`가 이미 올라가 있음(다른 세션 커밋 34d7a4d). 현재 oksclass.com은 블록공방 홈페이지 + /fire/ + /iep/ 구조(예전 smoke-test 스크립트 없음).
- **2026-11-18 22:40 사용자 승인 → `fire-update`를 main에 병합·배포 완료(9e35cca).** 이후 갱신도 이 저장소 → `oks-class/fire/` 복사 후 사용자 확인을 받고 main에 푸시.
- 반영 후: 배너 QR을 `https://oksclass.com/fire/`로 다시 만들기, 교사 기록장 주소 `https://oksclass.com/fire/teacher.html`.
- 루트 sw.js가 옛 캐시를 지우므로 /fire/ 캐시가 한 번 비워질 수 있음(다시 받으면 됨).

## 11. 기기 점검표 (현장 투입 전)
| 항목 | 안드로이드(갤럭시) | 아이폰·아이패드 |
|---|---|---|
| 브라우저 | 크롬 최신 | 사파리 |
| 카메라 권한 | 주소창 자물쇠 → 권한 → 카메라 허용 | 설정 → 사파리 → 카메라 허용 |
| 소리 | 무음/진동 해제, 미디어 볼륨 | 측면 무음 스위치 해제 |
| 자이로 | 기본 허용 | 첫 출동 때 "동작 및 방향" 허용 |
| 홈 화면 추가 | 메뉴 → 홈 화면에 추가 | 공유 → 홈 화면에 추가 |
| 화면 꺼짐 | 화면 자동 꺼짐 5분 이상 | 자동 잠금 5분 이상 |
| 발열·배터리 | 80% 이상, 케이스 벗기면 발열↓ | 동일 |
| 교사 QR 스캔 | 크롬 기록장 📷 스캔 또는 기본 카메라 | 기본 카메라로 인증서 QR |

## 12. 배움의 별(Roblox) 불끄기 던전 — 2026-11-18
- 사회의 별(SocialPlanet) 포탈 "🧯 불끄기 훈련장" → 전용 교실(DungeonServer 던전 구조 사용). 서버 `ServerScriptService.DungeonServer.FireDrill`(ModuleScript), 화면 `StarterPlayerScripts.FireDrillClient`.
- PlanetGravity 수정 2곳: 캐릭터 속성 `FaceCam`(몸이 카메라 방향), 플레이어 속성 `CamFirst`(1인칭 카메라).
- 소화기: 몸통은 몸에 고정, 노즐은 `AimWeld` C0로 카메라 조준을 부드럽게 따라감(뿌릴 때 떨림·반동), 호스는 Beam. 서버에 "aim" 메시지로 다른 사람에게도 보임.
- 3D 자산(ServerStorage.FireDrillAssets): ExtBody 116027546544217, ExtNozzle 91054148975454, Heater 74125665491136, Plug 72724347335931 (ChatGPT 그림 → Tripo, 각 30크레딧). RecycleBins/Planter/WallClock는 업로드했지만 메시가 깨져 사용 안 함.
- 참고 그림·초기 소스: `tools/ref/`, `tools/roblox/`(초기본 — 최신본은 Studio 안).
- Studio 저장(File → Save)은 사용자가 확인 후 직접.
