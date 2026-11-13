import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
const $ = id => document.getElementById(id);
const V = (x = 0, y = 0, z = 0) => new THREE.Vector3(x, y, z);
const rnd = s => (Math.random() * 2 - 1) * s;
const ST = [], cur = null, HEROES = { x: { mode: 'twin' } }, heroKey = 'x';

// ================= 렌더러 · 장면 =================
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(1.75, devicePixelRatio)); renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true; renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.toneMapping = THREE.ACESFilmicToneMapping; renderer.toneMappingExposure = 1.05;
document.body.prepend(renderer.domElement);
const scene = new THREE.Scene(); scene.background = new THREE.Color(0xf6ead8);
const stage = scene;
const camera = new THREE.PerspectiveCamera(55, innerWidth / innerHeight, .05, 80);
scene.add(camera);
addEventListener('resize', () => { renderer.setSize(innerWidth, innerHeight); camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); });
scene.add(new THREE.HemisphereLight(0xfff6e8, 0x9a7a5a, 1.6));
const sun = new THREE.DirectionalLight(0xfff2dd, 2.2); sun.position.set(-4, 7, 3); sun.castShadow = true;
sun.shadow.mapSize.set(1024, 1024); Object.assign(sun.shadow.camera, { left: -7, right: 7, top: 7, bottom: -7, near: 1, far: 20 }); sun.shadow.bias = -.0008; scene.add(sun);

// ================= 파티클 · 소리 (본 게임과 같은 코드) =================
let waterTint = [.95, .95, .97], heavyTint = [.95, .95, .97];
/*PARTICLES*/
const smokeP = new Particles(500, THREE.NormalBlending, 'smoke');
const fireP = new Particles(2200, THREE.AdditiveBlending, 'fire');
const steamP = new Particles(400, THREE.NormalBlending, 'steam');
const powderP = new Particles(1600, THREE.NormalBlending, 'powder');
const allP = [smokeP, fireP, steamP, powderP];
/*AUDIO*/


// ================= 교실 만들기 =================
const RW = 10, RD = 8, RH = 3; // 방 크기(m)
const colliders = []; // {x0,x1,z0,z1}
function block(x, z, w, d) { colliders.push({ x0: x - w / 2, x1: x + w / 2, z0: z - d / 2, z1: z + d / 2 }); }
function canvasTex(w, h, draw) { const c = document.createElement('canvas'); c.width = w; c.height = h; draw(c.getContext('2d'), w, h); const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 4; return t; }
// 바닥: 나무 마루
const floorTex = canvasTex(1024, 1024, (g, w, h) => {
  for (let i = 0; i < 16; i++) { const y = i * h / 16; g.fillStyle = `hsl(${30 + rnd(3)},${48 + rnd(6)}%,${62 + rnd(5)}%)`; g.fillRect(0, y, w, h / 16);
    g.fillStyle = 'rgba(90,50,20,.25)'; g.fillRect(0, y, w, 2); const off = (i % 2) * w / 3; for (let x = off; x < w + w / 1.5; x += w / 1.5) g.fillRect(x % w, y, 2, h / 16);
    for (let k = 0; k < 40; k++) { g.fillStyle = `rgba(120,70,30,${Math.random() * .06})`; g.fillRect(Math.random() * w, y + Math.random() * h / 16, 60 + Math.random() * 120, 1.5); } }
});
floorTex.wrapS = floorTex.wrapT = THREE.RepeatWrapping; floorTex.repeat.set(3, 2.4);
const floor = new THREE.Mesh(new THREE.PlaneGeometry(RW, RD), new THREE.MeshStandardMaterial({ map: floorTex, roughness: .55 }));
floor.rotation.x = -Math.PI / 2; floor.receiveShadow = true; scene.add(floor);
// 벽
const wallTex = canvasTex(512, 512, (g, w, h) => { g.fillStyle = '#fbf2e2'; g.fillRect(0, 0, w, h); g.fillStyle = '#f39a3d'; g.fillRect(0, h * .62, w, h * .05); g.fillStyle = '#e7d3b4'; g.fillRect(0, h * .67, w, h * .33); g.fillStyle = 'rgba(0,0,0,.05)'; for (let x = 0; x < w; x += 32) g.fillRect(x, h * .67, 2, h * .33); });
wallTex.wrapS = THREE.RepeatWrapping;
function wall(w, x, z, ry) { const t = wallTex.clone(); t.needsUpdate = true; t.repeat.set(w / 3, 1); const m = new THREE.Mesh(new THREE.PlaneGeometry(w, RH), new THREE.MeshStandardMaterial({ map: t, roughness: .9 })); m.position.set(x, RH / 2, z); m.rotation.y = ry; m.receiveShadow = true; scene.add(m); return m; }
const wallN = wall(RW, 0, -RD / 2, 0), wallS = wall(RW, 0, RD / 2, Math.PI), wallW = wall(RD, -RW / 2, 0, Math.PI / 2), wallE = wall(RD, RW / 2, 0, -Math.PI / 2);
block(0, -RD / 2 - .5, RW + 2, 1); block(0, RD / 2 + .5, RW + 2, 1); block(-RW / 2 - .5, 0, 1, RD + 2); block(RW / 2 + .5, 0, 1, RD + 2);
const box = (w, h, d, color, x, y, z, opt = {}) => { const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), new THREE.MeshStandardMaterial({ color, roughness: .6, ...opt })); m.position.set(x, y, z); m.castShadow = m.receiveShadow = true; scene.add(m); return m; };
// 칠판 (앞벽)
const boardTex = canvasTex(1024, 400, (g, w, h) => { g.fillStyle = '#2f6b4f'; g.fillRect(0, 0, w, h); g.strokeStyle = 'rgba(255,255,255,.8)'; g.lineWidth = 6; g.lineCap = 'round';
  g.font = 'bold 74px sans-serif'; g.fillStyle = 'rgba(255,255,255,.9)'; g.fillText('불이 나면?', 60, 110);
  g.font = 'bold 52px sans-serif'; ['① "불이야!" 외치기', '② 소화기: 핀 → 노즐 → 손잡이 → 쓸기', '③ 크면 대피! 낮은 자세로'].forEach((t, i) => g.fillText(t, 70, 200 + i * 70));
  g.fillStyle = '#ffd35a'; g.beginPath(); g.arc(900, 90, 40, 0, 7); g.fill(); });
box(4.2, 1.5, .08, 0x8a5a2e, 0, 1.65, -RD / 2 + .04); const board = new THREE.Mesh(new THREE.PlaneGeometry(4, 1.35), new THREE.MeshStandardMaterial({ map: boardTex, roughness: .9 })); board.position.set(0, 1.65, -RD / 2 + .09); scene.add(board);
// 창문 (왼쪽 벽)
const winTex = canvasTex(256, 256, (g, w, h) => { const gr = g.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, '#9fd8ff'); gr.addColorStop(1, '#dff3ff'); g.fillStyle = gr; g.fillRect(0, 0, w, h); g.fillStyle = 'rgba(255,255,255,.9)'; g.beginPath(); g.ellipse(80, 90, 50, 22, 0, 0, 7); g.ellipse(120, 80, 40, 26, 0, 0, 7); g.fill(); g.fillStyle = '#7cc46a'; g.fillRect(0, 200, w, 56); });
for (const z of [-2.2, 0.4, 3.0 - .6]) { const f = box(.08, 1.4, 1.8, 0xffffff, -RW / 2 + .03, 1.6, z); const gl = new THREE.Mesh(new THREE.PlaneGeometry(1.65, 1.25), new THREE.MeshBasicMaterial({ map: winTex })); gl.position.set(-RW / 2 + .08, 1.6, z); gl.rotation.y = Math.PI / 2; scene.add(gl); box(.1, .05, 1.8, 0xffffff, -RW / 2 + .06, 1.6, z); }
// 커튼 (창가)
const curtain = new THREE.Group(); for (let i = 0; i < 6; i++) { const c = new THREE.Mesh(new THREE.CylinderGeometry(.07, .07, 1.9, 8), new THREE.MeshStandardMaterial({ color: 0xf27a7a, roughness: .9 })); c.position.set(-RW / 2 + .15, 1.5, -3.2 + i * .13); c.castShadow = true; curtain.add(c); } scene.add(curtain);
// 비상구 문 (오른쪽 뒤)
const DOOR = V(RW / 2 - .02, 0, 2.6);
box(.08, 2.15, 1.05, 0x6b7f99, RW / 2 - .04, 1.075, DOOR.z, { metalness: .3 }); box(.1, .06, .5, 0xd8d8d8, RW / 2 - .1, 1.0, DOOR.z - .25, { metalness: .8, roughness: .3 });
const exitTex = canvasTex(256, 128, (g, w, h) => { g.fillStyle = '#18a84a'; g.fillRect(0, 0, w, h); g.fillStyle = '#fff'; g.font = 'bold 64px sans-serif'; g.fillText('🏃', 18, 92); g.font = 'bold 46px sans-serif'; g.fillText('비상구', 110, 82); });
const exitSign = new THREE.Mesh(new THREE.PlaneGeometry(.7, .35), new THREE.MeshBasicMaterial({ map: exitTex })); exitSign.position.set(RW / 2 - .06, 2.45, DOOR.z); exitSign.rotation.y = -Math.PI / 2; scene.add(exitSign);
const exitGlow = new THREE.Mesh(new THREE.CircleGeometry(.9, 32), new THREE.MeshBasicMaterial({ color: 0x2bd96a, transparent: true, opacity: 0 })); exitGlow.rotation.x = -Math.PI / 2; exitGlow.position.set(RW / 2 - .8, .02, DOOR.z); scene.add(exitGlow);
// 소화기함 (문 옆) — 새 소화기
const CAB = V(RW / 2 - .25, 0, .9);
box(.4, .7, .5, 0xd11e1e, CAB.x, .35, CAB.z); const cabTex = canvasTex(128, 128, (g) => { g.fillStyle = '#fff'; g.fillRect(0, 0, 128, 128); g.fillStyle = '#d11e1e'; g.font = 'bold 30px sans-serif'; g.fillText('소화기', 18, 74); });
const cabLabel = new THREE.Mesh(new THREE.PlaneGeometry(.32, .32), new THREE.MeshBasicMaterial({ map: cabTex })); cabLabel.position.set(CAB.x - .21, .45, CAB.z); cabLabel.rotation.y = -Math.PI / 2; scene.add(cabLabel); block(CAB.x, CAB.z, .5, .6);

// ================= 가구 (다운로드 폴더 자산) =================
const loader = new GLTFLoader();
const load = n => new Promise((res, rej) => loader.load(`train/${n}.glb`, g => { g.scene.traverse(o => { if (o.isMesh) { o.castShadow = o.receiveShadow = true; } }); res(g.scene); }, undefined, rej));
function fitH(obj, h) { const b = new THREE.Box3().setFromObject(obj), s = h / (b.max.y - b.min.y); obj.scale.multiplyScalar(s); const b2 = new THREE.Box3().setFromObject(obj); obj.position.y -= b2.min.y; return obj; }
function place(proto, h, x, z, ry = 0, solid = true) { const o = proto.clone(); fitH(o, h); o.rotation.y = ry; o.position.x = x; o.position.z = z; scene.add(o); if (solid) { const b = new THREE.Box3().setFromObject(o); block((b.min.x + b.max.x) / 2, (b.min.z + b.max.z) / 2, b.max.x - b.min.x, b.max.z - b.min.z); } return o; }
let player, ext3, FIRE_SPOTS = [];
async function buildRoom() {
  const [desk, chair, shelf, bins, plant, table, ff] = await Promise.all(['desk', 'chair', 'bookshelf', 'recyclebins', 'planter', 'table', 'firefighter'].map(load));
  pct(80);
  for (let r = 0; r < 2; r++) for (let c = 0; c < 3; c++) { const x = -2.4 + c * 2.4, z = -.6 + r * 2.1; place(desk, .78, x, z, 0); place(chair, .85, x, z + .62, Math.PI, false); }
  const tdesk = place(table, .8, 2.2, -2.7, 0); // 교탁
  place(shelf, 1.7, -1.5, RD / 2 - .25, Math.PI);
  place(shelf, 1.7, -.6, RD / 2 - .25, Math.PI);
  const bin = place(bins, .55, 3.9, -3.5, -Math.PI / 2);
  place(plant, .8, -4.4, 3.5, 0);
  // 교탁 위 종이 더미
  const papers = new THREE.Group(); for (let i = 0; i < 6; i++) { const p = new THREE.Mesh(new THREE.BoxGeometry(.32, .012, .24), new THREE.MeshStandardMaterial({ color: i % 2 ? 0xffffff : 0xf3efe4 })); p.position.set(rnd(.04), i * .013, rnd(.04)); p.rotation.y = rnd(.3); papers.add(p); } papers.position.set(2.2, .81, -2.7); scene.add(papers);
  FIRE_SPOTS = [
    { name: '휴지통', p: V(3.9, .55, -3.5), stand: V(2.8, 0, -2.6) },
    { name: '교탁 위 종이', p: V(2.2, .85, -2.7), stand: V(1.2, 0, -1.6) },
    { name: '창가 커튼', p: V(-RW / 2 + .3, .6, -2.9), stand: V(-3.6, 0, -2.4) },
    { name: '책꽂이', p: V(-1.05, .8, RD / 2 - .35), stand: V(-1.0, 0, 2.6) },
  ];
  // 플레이어 (소방관 어린이)
  player = new THREE.Group(); const body = fitH(ff, 1.05); body.rotation.y = 0; player.add(body); player.userData.body = body; scene.add(player);
  player.position.set(3.4, 0, 2.4); player.rotation.y = -Math.PI * .75; S.yaw = player.rotation.y + Math.PI;
  ext3 = makeExtinguisher(); scene.add(ext3);
}
// ================= 소화기 3D (코드로 제작) =================
function makeExtinguisher() {
  const g = new THREE.Group(), red = new THREE.MeshStandardMaterial({ color: 0xe0161c, roughness: .28, metalness: .15 }), yel = new THREE.MeshStandardMaterial({ color: 0xffc81e, roughness: .35 }),
    blk = new THREE.MeshStandardMaterial({ color: 0x1c1c1e, roughness: .45 }), sil = new THREE.MeshStandardMaterial({ color: 0xc9ccd2, roughness: .25, metalness: .85 }), wht = new THREE.MeshStandardMaterial({ color: 0xf7f7f7, roughness: .5 });
  const add = (geo, mat, x, y, z) => { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = true; g.add(m); return m; };
  add(new THREE.CylinderGeometry(.1, .1, .4, 32), red, 0, .26, 0);
  add(new THREE.SphereGeometry(.1, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), red, 0, .46, 0);
  add(new THREE.CylinderGeometry(.105, .105, .06, 32), blk, 0, .03, 0);
  for (const y of [.12, .4]) add(new THREE.CylinderGeometry(.103, .103, .025, 32), yel, 0, y, 0);
  const lab = add(new THREE.CylinderGeometry(.1015, .1015, .16, 32, 1, true, -Math.PI / 3, Math.PI * 2 / 3), wht, 0, .26, 0); lab.rotation.y = Math.PI / 2;
  add(new THREE.CylinderGeometry(.03, .035, .08, 16), sil, 0, .58, 0);
  const gauge = add(new THREE.CylinderGeometry(.028, .028, .015, 24), wht, .0, .6, .035); gauge.rotation.x = Math.PI / 2;
  add(new THREE.TorusGeometry(.028, .004, 8, 24), sil, 0, .6, .043);
  const lever = new THREE.Group(); lever.position.set(-.02, .64, 0); g.add(lever);
  const lv = new THREE.Mesh(new THREE.BoxGeometry(.2, .02, .04), blk); lv.position.set(-.09, .01, 0); lv.rotation.z = -.18; lever.add(lv);
  add(new THREE.BoxGeometry(.18, .02, .04), blk, -.1, .58, 0).rotation.z = .25;
  const pin = new THREE.Group(); pin.position.set(-.03, .615, 0); g.add(pin);
  const rod = new THREE.Mesh(new THREE.CylinderGeometry(.005, .005, .09, 8), sil); rod.rotation.z = Math.PI / 2; rod.position.x = -.03; pin.add(rod);
  const ring = new THREE.Mesh(new THREE.TorusGeometry(.03, .007, 10, 24), yel); ring.position.x = -.1; pin.add(ring);
  // 호스 + 노즐
  const hoseCurve = new THREE.CatmullRomCurve3([V(.03, .6, 0), V(.12, .58, 0), V(.17, .35, .02), V(.2, .2, .1), V(.22, .22, .2)]);
  const hose = new THREE.Mesh(new THREE.TubeGeometry(hoseCurve, 32, .014, 8), blk); hose.castShadow = true; g.add(hose);
  const noz = new THREE.Group(); noz.position.set(.22, .22, .2); g.add(noz);
  const cone = new THREE.Mesh(new THREE.CylinderGeometry(.03, .012, .12, 20, 1, true), blk); cone.rotation.x = Math.PI / 2; cone.position.z = .06; noz.add(cone);
  const col = new THREE.Mesh(new THREE.CylinderGeometry(.018, .018, .03, 16), yel); col.rotation.x = Math.PI / 2; noz.add(col);
  g.userData = { lever, pin, noz };
  return g;
}

// ================= 상태 =================
const S = { mode: 3, pin: false, powder: 100, yelled: false, fire: null, round: 0, cleared: 0, evac: false, yaw: Math.PI * .75, pitch: -.15, aimYaw: 0, spraying: false, swing: 0, lastAim: 0, swDir: 0, swAcc: 0, started: false, stars: 0 };
const tip = t => { $('tip').textContent = t; };
const coach = t => { $('coach').innerHTML = t; };
function pct(v) { $('pct').textContent = v; }

// 불
function startFire() {
  const opts = FIRE_SPOTS.filter((f, i) => i !== S.lastSpot); const k = Math.floor(Math.random() * opts.length); const f = opts[k]; S.lastSpot = FIRE_SPOTS.indexOf(f);
  S.fire = { ...f, size: .35, hp: 100, acc: 0, sacc: 0, seen: false, t: 0 }; S.yelled = false; S.evac = false;
  sfx.ignite(); noise(1.2, 200, 1500, .25, 'bandpass');
  tip('🔥 어딘가에서 타는 냄새가 나요… 불난 곳을 찾아요!');
  updSteps();
}
const fireLight = new THREE.PointLight(0xff7a2a, 0, 7, 1.6); scene.add(fireLight);
function damageFire(d) {
  const f = S.fire; if (!f) return; f.hp -= d; f.size = Math.max(.2, f.size - d * .004);
  if (f.hp <= 0) {
    for (let i = 0; i < 40; i++) steamP.spawn(f.p.clone().add(V(rnd(.3), rnd(.2), rnd(.3))), V(rnd(.5), 1 + Math.random(), rnd(.5)), 1.4, .3, 1.2);
    S.fire = null; fireLight.intensity = 0; sfx.out(); S.cleared++; S.stars += S.yelled ? 2 : 1;
    tip(`✅ ${f.name} 불을 껐어요! ${S.yelled ? '⭐⭐ "불이야!"도 외쳤어요' : '⭐ (다음엔 "불이야!"도 외쳐요)'}`);
    if (S.cleared >= 3) setTimeout(finish, 1500); else setTimeout(startFire, 4000);
    updSteps();
  }
}
function finish() { sfx.win(); $('done').classList.remove('hidden'); $('stars').textContent = '⭐'.repeat(Math.min(6, S.stars)); try { localStorage.setItem('gnfire-train', JSON.stringify({ t: Date.now(), stars: S.stars })); } catch (e) { } }

// ================= 조작 =================
const keys = {}; addEventListener('keydown', e => keys[e.code] = true); addEventListener('keyup', e => keys[e.code] = false);
const joy = { id: null, x0: 0, y0: 0, x: 0, y: 0 }, look = { id: null, x: 0, y: 0 };
const jb = $('joy'), jk = $('knob');
jb.addEventListener('pointerdown', e => { joy.id = e.pointerId; const r = jb.getBoundingClientRect(); joy.x0 = r.left + r.width / 2; joy.y0 = r.top + r.height / 2; jb.setPointerCapture(e.pointerId); joyMove(e); audio(); });
jb.addEventListener('pointermove', e => { if (e.pointerId === joy.id) joyMove(e); });
const joyEnd = e => { if (e.pointerId === joy.id) { joy.id = null; joy.x = joy.y = 0; jk.style.transform = ''; } };
jb.addEventListener('pointerup', joyEnd); jb.addEventListener('pointercancel', joyEnd);
function joyMove(e) { let dx = e.clientX - joy.x0, dy = e.clientY - joy.y0; const L = Math.hypot(dx, dy), m = 50; if (L > m) { dx *= m / L; dy *= m / L; } joy.x = dx / m; joy.y = dy / m; jk.style.transform = `translate(${dx}px,${dy}px)`; }
// 화면 끌기: 1인칭=둘러보기, 3인칭=분사 중 좌우 조준
const cv = renderer.domElement;
cv.addEventListener('pointerdown', e => { look.id = e.pointerId; look.x = e.clientX; look.y = e.clientY; cv.setPointerCapture(e.pointerId); audio(); });
cv.addEventListener('pointermove', e => { if (e.pointerId !== look.id) return; const dx = e.clientX - look.x, dy = e.clientY - look.y; look.x = e.clientX; look.y = e.clientY;
  if (S.mode === 1) { S.yaw -= dx * .006; S.pitch = Math.max(-1.1, Math.min(.6, S.pitch - dy * .005)); }
  else { S.yaw -= dx * .008; } });
const lookEnd = e => { if (e.pointerId === look.id) look.id = null; }; cv.addEventListener('pointerup', lookEnd); cv.addEventListener('pointercancel', lookEnd);
// 버튼
const sprayBtn = $('spray');
sprayBtn.addEventListener('pointerdown', e => { e.preventDefault(); audio();
  if (!S.pin) { tip('🔒 먼저 노란 안전핀을 뽑아요! (왼쪽 위 ① 버튼)'); $('pinBtn').classList.add('shake'); setTimeout(() => $('pinBtn').classList.remove('shake'), 500); return; }
  if (S.powder <= 0) { tip('소화기가 비었어요! 비상구 옆 빨간 소화기함으로 가요'); return; }
  S.spraying = true; sprayBtn.classList.add('on'); hoseSnd.on(.12); hoseSnd.f && hoseSnd.f.frequency.setTargetAtTime(3200, ac.currentTime, .05); });
const sprayEnd = () => { S.spraying = false; sprayBtn.classList.remove('on'); hoseSnd.on(0); sizzleSnd.on(0); };
sprayBtn.addEventListener('pointerup', sprayEnd); sprayBtn.addEventListener('pointercancel', sprayEnd); sprayBtn.addEventListener('pointerleave', sprayEnd);
$('pinBtn').onclick = () => { if (S.pin) return; audio(); S.pin = true; sfx.pop(); $('pinBtn').classList.add('used'); pinFly = 1; tip('✅ 안전핀을 뽑았어요! 이제 불 쪽으로 가서 노즐을 겨눠요'); updSteps(); };
$('yell').onclick = () => { if (!S.fire || S.yelled) return; audio(); S.yelled = true; siren(); floatText('불이야!!'); tip('📣 "불이야!" 잘 외쳤어요! 이제 소화기로 꺼요'); updSteps(); };
$('view').onclick = () => { S.mode = S.mode === 3 ? 1 : 3; $('view').textContent = S.mode === 3 ? '👁 1인칭' : '🗺 3인칭'; if (S.mode === 1) S.yaw = player.rotation.y + Math.PI; };
$('go').onclick = () => { audio(); $('intro').classList.add('hidden'); S.started = true; setTimeout(startFire, 1200); tip('교실을 둘러봐요. 왼쪽 아래 동그라미로 걸어요'); };
$('again').onclick = () => location.reload();
function siren() { for (let i = 0; i < 3; i++) { tone('sawtooth', 700, 1100, .3, .1, i * .32, 2500); tone('sawtooth', 1100, 700, .3, .08, i * .32 + .16, 2500); } }
function floatText(t) { const el = document.createElement('div'); el.className = 'float'; el.textContent = t; document.body.appendChild(el); setTimeout(() => el.remove(), 1200); }
let pinFly = 0;
function updSteps() {
  const f = S.fire, near = f && player.position.distanceTo(V(f.p.x, 0, f.p.z)) < 4.2;
  const st = [S.yelled || !f ? 'ok' : f && f.seen ? 'on' : '', S.pin ? 'ok' : 'on', near ? 'ok' : (S.pin ? 'on' : ''), S.spraying ? 'on' : ''];
  document.querySelectorAll('#steps .s').forEach((el, i) => el.className = 's ' + st[i]);
}

// ================= 충돌 =================
const PR = .28;
function collide(p) {
  for (const c of colliders) {
    const cx = Math.max(c.x0, Math.min(p.x, c.x1)), cz = Math.max(c.z0, Math.min(p.z, c.z1)), dx = p.x - cx, dz = p.z - cz, d = Math.hypot(dx, dz);
    if (d < PR) { if (d > 1e-4) { p.x = cx + dx / d * PR; p.z = cz + dz / d * PR; } else { p.x += PR; } }
  }
}

// ================= 루프 =================
const clock = new THREE.Clock(), tmp = V(), fwd = V();
let walkT = 0, sweepScore = 0;
function loop() {
  requestAnimationFrame(loop);
  const dt = Math.min(clock.getDelta(), .05), t = clock.elapsedTime;
  if (!player) { renderer.render(scene, camera); return; }
  // 이동
  let mx = joy.x + ((keys.KeyD || keys.ArrowRight) ? 1 : 0) - ((keys.KeyA || keys.ArrowLeft) ? 1 : 0), mz = joy.y + ((keys.KeyS || keys.ArrowDown) ? 1 : 0) - ((keys.KeyW || keys.ArrowUp) ? 1 : 0);
  const mag = Math.min(1, Math.hypot(mx, mz)), sp = (S.spraying ? 1.0 : 2.4) * mag;
  if (mag > .08) {
    let dir;
    if (S.mode === 3) dir = V(mx, 0, mz).normalize();
    else { const fy = S.yaw; dir = V(-Math.sin(fy) * -mz * -1, 0, 0); dir.set(Math.sin(fy) * mz + Math.cos(fy) * mx, 0, Math.cos(fy) * mz - Math.sin(fy) * mx).normalize(); }
    player.position.addScaledVector(dir, sp * dt); collide(player.position);
    if (S.mode === 3 && !S.spraying) { const ty = Math.atan2(dir.x, dir.z); let d = ty - player.rotation.y; d = Math.atan2(Math.sin(d), Math.cos(d)); player.rotation.y += d * Math.min(1, dt * 10); S.yaw = player.rotation.y + Math.PI; }
    walkT += dt * 9 * mag;
  } else walkT *= .9;
  if (S.mode === 1 || S.spraying) player.rotation.y = S.yaw + Math.PI;
  const b = player.userData.body; b.position.y = Math.abs(Math.sin(walkT)) * .05; b.rotation.z = Math.sin(walkT) * .08;
  // 카메라
  const facing = V(Math.sin(player.rotation.y), 0, Math.cos(player.rotation.y));
  if (S.mode === 3) { const target = player.position.clone().add(V(0, .6, 0)); camera.position.lerp(V(player.position.x, 6.2, player.position.z + 4.6), Math.min(1, dt * 4)); camera.lookAt(target); ext3.visible = true; b.visible = true; }
  else { camera.position.set(player.position.x, 1.15, player.position.z); camera.rotation.set(0, 0, 0); camera.rotation.order = 'YXZ'; camera.rotation.y = S.yaw; camera.rotation.x = S.pitch; b.visible = false; }
  // 소화기 위치
  if (S.mode === 3) { ext3.scale.setScalar(1.25); ext3.position.copy(player.position).addScaledVector(facing, .22).add(V(Math.cos(player.rotation.y) * .22, .05 + b.position.y, -Math.sin(player.rotation.y) * .22)); ext3.rotation.set(0, player.rotation.y - Math.PI / 2, 0); }
  else { ext3.scale.setScalar(.62); const off = V(.2, -.4, -.78).applyEuler(camera.rotation); ext3.position.copy(camera.position).add(off); ext3.rotation.set(0, 0, 0); ext3.quaternion.copy(camera.quaternion); ext3.rotateY(-Math.PI / 2 + .35); ext3.rotateZ(S.spraying ? -.05 : 0); }
  const U = ext3.userData; U.lever.rotation.z = S.spraying ? -.28 : 0;
  if (pinFly > 0) { pinFly -= dt; U.pin.position.x -= dt * .4; U.pin.position.y += dt * .3; if (pinFly <= 0) U.pin.visible = false; }
  // 노즐 방향: 3인칭은 몸 앞쪽, 1인칭은 시선
  const aimDir = S.mode === 3 ? V(Math.sin(player.rotation.y), S.fire ? Math.max(-.5, Math.min(.3, (S.fire.p.y + .1 - .45) / Math.max(.8, player.position.distanceTo(V(S.fire.p.x, 0, S.fire.p.z))))) : -.25, Math.cos(player.rotation.y)).normalize() : V(0, 0, -1).applyEuler(camera.rotation);
  ext3.updateMatrixWorld(true); const nozW = U.noz.getWorldPosition(V());
  // 분사
  if (S.spraying) {
    S.powder = Math.max(0, S.powder - dt * 6.5); if (S.powder <= 0) { sprayEnd(); tip('소화기가 비었어요! 비상구 옆 빨간 소화기함으로 가요'); }
    for (let i = 0; i < 14; i++) { const d = aimDir.clone().add(V(rnd(.12), rnd(.08), rnd(.12))).normalize(); powderP.spawn(nozW.clone().addScaledVector(aimDir, .1), d.multiplyScalar(7 + Math.random() * 3), .55 + Math.random() * .3, .06, .55); }
    // 쓸기 판정: 조준 각도가 좌우로 오가면 보너스
    const a = Math.atan2(aimDir.x, aimDir.z); let da = a - S.lastAim; da = Math.atan2(Math.sin(da), Math.cos(da)); S.lastAim = a;
    if (Math.abs(da) > .002) { const dir = Math.sign(da); if (dir !== S.swDir) { if (S.swAcc > .12) sweepScore = Math.min(1, sweepScore + .35); S.swDir = dir; S.swAcc = 0; } S.swAcc += Math.abs(da); }
  }
  sweepScore = Math.max(0, sweepScore - dt * .25);
  // 불
  const f = S.fire;
  if (f) {
    f.t += dt; const fpos = f.p; const dist = player.position.distanceTo(V(fpos.x, 0, fpos.z));
    if (!f.seen && dist < 4.8) { f.seen = true; tip('🔥 불이 났어요! 먼저 "불이야!" 하고 외쳐요 (📣 버튼)'); updSteps(); }
    $('yell').classList.toggle('hidden', !(f.seen && !S.yelled));
    if (!S.evac) f.size = Math.min(2.2, f.size + dt * (S.spraying ? 0 : .018));
    if (f.size > 1.7 && !S.evac) { S.evac = true; tip('🚨 불이 너무 커졌어요! 끄지 말고 비상구로 대피해요 (초록 불빛)'); siren(); }
    const k = f.size;
    f.acc += dt * 120 * k; while (f.acc > 1) { f.acc--; fireP.spawn(fpos.clone().add(V(rnd(.25 * k), 0, rnd(.25 * k))), V(rnd(.25), 1 + Math.random() * 1.2 * Math.sqrt(k), rnd(.25)), .5 + Math.random() * .45, .25 * k + .1, .08); }
    f.sacc += dt * 8 * k; while (f.sacc > 1) { f.sacc--; smokeP.spawn(fpos.clone().add(V(rnd(.2), .6 * k, rnd(.2))), V(rnd(.2), .7, rnd(.2)), 2.4, .3 * k, 1.2 * k); }
    fireLight.position.copy(fpos).add(V(0, .5, 0)); fireLight.intensity = (2.5 + Math.sin(t * 23) * .5) * k;
    fireSnd.on(.1 + .2 * Math.min(1, k));
    // 맞히기: 노즐에서 불까지 거리·각도
    if (S.spraying && !S.evac) {
      const to = fpos.clone().sub(nozW); to.y = 0; const dd = to.length(); to.normalize(); const ah = V(aimDir.x, 0, aimDir.z).normalize(); const dot = to.dot(ah);
      if (dd < 4.2 && dot > .86) { const eff = (1 - dd / 5) * (1 + sweepScore * 1.2); damageFire(dt * 32 * eff); sizzleSnd.on(.14); if (Math.random() < .5) steamP.spawn(fpos.clone().add(V(rnd(.2), .3, rnd(.2))), V(rnd(.3), 1, rnd(.3)), 1, .2, .8);
        if (sweepScore < .2 && f.hp < 92 && !S.sweepHint) { S.sweepHint = true; tip('💡 누른 채로 화면을 좌우로 끌어 빗자루처럼 쓸면 더 잘 꺼져요!'); } }
      else { sizzleSnd.on(0); if (dd >= 4.2 && dot > .8 && !S.farHint) { S.farHint = true; tip('조금 더 가까이 가요! 분말이 닿지 않아요'); } }
    }
    if (S.evac) { exitGlow.material.opacity = .35 + Math.sin(t * 6) * .25; if (player.position.distanceTo(V(RW / 2 - .8, 0, DOOR.z)) < 1.1) { tip('👏 안전하게 대피했어요! 큰 불은 끄지 않고 대피하는 게 정답이에요'); S.fire = null; fireLight.intensity = 0; fireSnd.on(0); exitGlow.material.opacity = 0; S.stars++; S.cleared++; if (S.cleared >= 3) setTimeout(finish, 1500); else setTimeout(startFire, 4000); } }
  } else { fireSnd.on(0); $('yell').classList.add('hidden'); }
  // 소화기함: 새 소화기
  if (player.position.distanceTo(V(CAB.x, 0, CAB.z)) < 1.1 && (S.powder < 100 || !S.pin && false)) { if (S.powder < 99) { S.powder = 100; S.pin = false; U.pin.visible = true; U.pin.position.set(-.03, .615, 0); $('pinBtn').classList.remove('used'); sfx.found(); tip('🧯 새 소화기를 들었어요! 안전핀부터 뽑아요'); updSteps(); } }
  $('gauge').style.width = S.powder + '%';
  // 방향 안내 화살표 (불이 화면 밖일 때)
  if (f) { const sp2 = f.p.clone().add(V(0, .5, 0)).project(camera); const off = sp2.z > 1 || Math.abs(sp2.x) > .9 || Math.abs(sp2.y) > .9; const ar = $('arrow'); ar.style.display = off ? 'block' : 'none';
    if (off) { let x = sp2.x, y = sp2.y; if (sp2.z > 1) { x = -x; y = -y; } const ang = Math.atan2(-y, x); const R = Math.min(innerWidth, innerHeight) * .38; ar.style.left = innerWidth / 2 + Math.cos(ang) * R + 'px'; ar.style.top = innerHeight / 2 + Math.sin(ang) * R + 'px'; ar.style.transform = `translate(-50%,-50%) rotate(${ang}rad)`; } }
  else $('arrow').style.display = 'none';
  if (S.started && (t % .5) < dt) updSteps();
  // 파티클 크기
  const k = innerHeight * renderer.getPixelRatio() / (2 * Math.tan(camera.fov * Math.PI / 360));
  for (const p of allP) { p.mat.uniforms.uScale.value = k; p.mat.uniforms.uMax.value = 160 * renderer.getPixelRatio(); p.update(dt); }
  renderer.render(scene, camera);
}
pct(10); window.__S = S; window.__P = () => player;
buildRoom().then(() => { pct(100); $('loading').classList.add('hidden'); $('go').classList.remove('hidden'); }).catch(e => { $('loading').textContent = '불러오기 실패: ' + e.message; });
loop();
