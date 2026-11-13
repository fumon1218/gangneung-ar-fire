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

1. **oksclass.com 하위 경로로 이전** (사용자 요청, 18시 직전 "뭔가 문제가 있는 것 같다"며 잠시 보류)
   - oksclass.com = 비공개 저장소 `fumon1218/oks-class` → Cloudflare Workers 정적 자산(`wrangler.jsonc`, 빌드 없음, `.assetsignore`로 제외 목록). 기본 브랜치에 올리면 바로 운영 반영 → **반드시 사용자 승인 후 푸시**
   - 할 일: 이 저장소 파일을 `oks-class/<경로>/`(예: `/fire/`)로 복사, `scripts/smoke-test.mjs`가 모든 인라인 `<script>`를 `vm.Script`로 검사하는데 module 문법(import)이 실패하므로 해당 폴더를 점검 대상에서 제외하는 수정 필요, `tools/`·`HANDOVER.md`는 `.assetsignore`에 추가, 파일당 25MiB 한도(최대 targets.mind 11.8MB OK)
   - 배너 QR이 github.io 주소 → 새 주소로 다시 출력할지, github.io에 이동 안내(자바스크립트 리다이렉트)를 둘지 사용자 결정 필요
   - 사용자에게 물어볼 것: 경로 이름, QR 재출력 여부, 무엇이 "문제"였는지
2. **Roblox「배움의 별」이식** — 사용자가 다른 채팅에서 Roblox Studio 작업 중이라 끝나면 진행. 방향: 플레이어 **기본 아바타**에 소화기 Tool(핀·레버·분말 파티클)만 들리고, 교실 사물(다운로드 폴더 원본 glb, webp 아닌 원본 텍스처로) 배치, 불·불이야·대피·소화기함 로직을 Luau로. 시작 시 구조만 읽고 위치를 먼저 묻기. 연결된 Studio 목록은 `list_roblox_studios`로 확인(당시 'Place1'만 열림)
3. **3D 훈련장 확장**: 사무실(멀티탭·복사기, 전기 화재), 놀이터(쓰레기통·낙엽, 바람 등지기) — 교실 조작감 확인 후
4. **현장 확인 필요(아이폰 실기)**: ⓑ 그린월 인식, 실외 동물 바닥 높이(자이로 방식, `EYE=1.25`), 새 배너 9종 실제 인식·불 위치, AR 소화기 훈련의 사물 크기/높이, 확대 방지 효과, 3D 훈련장 조이스틱 조작감
5. 바리스타 체험(주문·음료 받기) 확장 아이디어 — 사용자가 "일단 대기"로 보류
6. 선택 사항: 강아지 쌍둥이 물줄기를 한 줄기로(사용자 "오케" — 현행 유지 중), 학생마다 소화기 연습 초기화 옵션, 출동 순서 고정 옵션

## 7. 알려진 한계
- 웹 AR이라 가상 물체가 실제 사물 뒤로 가려지지 않음
- 시험은 가짜 카메라(사진)로만 했고, 휴대폰 기울기·실제 걸음은 현장에서만 검증 가능
- 소화기 연습의 안전핀·레버 그림은 ChatGPT 소화기 한 장을 마스크로 잘라 만든 레이어(ex_body/pin/lever.webp, 400×600 같은 캔버스)
