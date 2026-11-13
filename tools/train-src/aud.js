// ================= 소리 (파일 없이 직접 합성) =================
let ac = null, soundOn = true, master = null;
try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (e) { } // 아이폰 무음 스위치여도 소리 나게
function audio() {
  if (!ac) { try { ac = new (window.AudioContext || window.webkitAudioContext)();
    const comp = ac.createDynamicsCompressor(); master = ac.createGain(); master.gain.value = .9; master.connect(comp).connect(ac.destination);
    const b = ac.createBuffer(1, 1, 22050), src = ac.createBufferSource(); src.buffer = b; src.connect(master); src.start(); } catch (e) { } }
  if (ac && ac.state !== 'running') ac.resume(); return ac;
}
const OUT = () => master || ac.destination;
const nbuf = {};
function noiseBuf(kind, sec = 2) {
  if (nbuf[kind]) return nbuf[kind];
  const b = ac.createBuffer(1, ac.sampleRate * sec, ac.sampleRate), d = b.getChannelData(0); let last = 0;
  for (let i = 0; i < d.length; i++) {
    const w = Math.random() * 2 - 1;
    if (kind === 'brown') { last = (last + .02 * w) / 1.02; d[i] = last * 3.5; }
    else if (kind === 'crackle') { last = (last + .02 * w) / 1.02; d[i] = last * 1.2 + (Math.random() < .0009 ? w * 2.2 : 0) + (Math.random() < .004 ? w * .5 : 0); }
    else d[i] = w;
  }
  return nbuf[kind] = b;
}
function noise(dur, f0, f1, vol, type = 'lowpass', kind = 'white', q = 1) {
  if (!soundOn || !audio()) return; const t = ac.currentTime;
  const s = ac.createBufferSource(); s.buffer = noiseBuf(kind); s.loop = true; const f = ac.createBiquadFilter(); f.type = type; f.Q.value = q;
  f.frequency.setValueAtTime(f0, t); f.frequency.exponentialRampToValueAtTime(f1, t + dur);
  const g = ac.createGain(); g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + .04); g.gain.exponentialRampToValueAtTime(.001, t + dur);
  s.connect(f).connect(g).connect(OUT()); s.start(t); s.stop(t + dur + .05);
}
function tone(type, f0, f1, dur, vol, delay = 0, lp = 0) {
  if (!soundOn || !audio()) return; const t = ac.currentTime + delay;
  const o = ac.createOscillator(), g = ac.createGain(); o.type = type; o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
  g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + .02); g.gain.exponentialRampToValueAtTime(.001, t + dur);
  let node = o.connect(g); if (lp) { const f = ac.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lp; g.connect(f); node = f; }
  node.connect(OUT()); o.start(t); o.stop(t + dur + .05);
}
function chime(notes) { notes.forEach((n, i) => { tone('triangle', n, n, .5, .18, i * .12); tone('sine', n * 2, n * 2, .3, .05, i * .12); }); }
// 악당별 울음소리
const ROAR = {
  dragon:  () => { tone('sawtooth', 190, 80, 1.1, .32, 0, 900); tone('sawtooth', 140, 60, 1.2, .2, .05, 600); noise(1.1, 1200, 300, .2); },
  golem:   () => { tone('sawtooth', 75, 40, 1.4, .45, 0, 350); noise(1.4, 400, 80, .35, 'lowpass', 'brown'); },
  phoenix: () => { tone('triangle', 900, 1600, .35, .2); tone('triangle', 1500, 700, .6, .18, .3); tone('sine', 2400, 1800, .5, .06, .3); },
  boss:    () => { tone('square', 220, 110, 1, .12, 0, 1500); tone('square', 223, 330, 1, .1, 0, 1500); tone('sine', 60, 40, 1, .3); },
  mummy:   () => { tone('sawtooth', 150, 105, 1.4, .25, 0, 700); tone('sawtooth', 152, 100, 1.4, .15, .1, 500); },
};
const sfx = {
  roar: () => (ROAR[(ST[cur] && ST[cur].villain) || 'dragon'] || ROAR.dragon)(),
  breath: () => { noise(1.8, 300, 2500, .3, 'bandpass', 'white', .8); noise(1.8, 200, 120, .35, 'lowpass', 'brown'); },
  ignite: () => { noise(.6, 3000, 500, .3, 'bandpass'); tone('sine', 120, 50, .5, .3); },
  out: () => { noise(1.4, 7000, 1800, .4, 'highpass'); noise(1, 1500, 400, .2, 'bandpass'); chime([660, 880, 1175]); },
  win: () => chime([523, 659, 784, 1047, 1319]), found: () => chime([440, 554, 659]),
  pop: () => { tone('sine', 520, 140, .18, .35); noise(.12, 2500, 800, .2, 'bandpass'); },
  boing: () => { tone('sine', 260, 640, .25, .3); tone('sine', 520, 900, .2, .08); },
  thump: () => { tone('sine', 140, 38, .45, .55); noise(.3, 600, 120, .3, 'lowpass', 'brown'); },
  splash: () => { noise(.45, 2500, 500, .3, 'bandpass', 'white', .7); noise(.3, 800, 200, .2); },
  blub: () => { const f = 300 + Math.random() * 500; tone('sine', f, f * 2.2, .09, .16); },
};
// 계속 나는 소리 (호스, 불, 치익)
function loopSnd(kind, type, freq, q = 1) {
  const o = { g: null, on(v) {
    if (!soundOn || !audio()) { v = 0; if (!this.g) return; }
    if (!this.g) { const s = ac.createBufferSource(); s.buffer = noiseBuf(kind); s.loop = true; const f = ac.createBiquadFilter(); f.type = type; f.frequency.value = freq; f.Q.value = q;
      this.f = f; this.g = ac.createGain(); this.g.gain.value = 0; s.connect(f).connect(this.g).connect(OUT()); s.start(); }
    this.g.gain.setTargetAtTime(v, ac.currentTime, .08); } };
  return o;
}
const fireSnd = loopSnd('crackle', 'lowpass', 2600), sizzleSnd = loopSnd('white', 'highpass', 5200), hoseSnd = loopSnd('white', 'bandpass', 1800, .9);
const HOSE_TONE = { twin: [1800, .14], ice: [4200, .12], fountain: [900, .2], bubble: [700, .05], burst: [1500, .05], balloon: [1500, .04], ball: [1500, .04], ring: [2400, .05], cannon: [1100, .05] };
function hoseSound(on) {
  if (!on) { hoseSnd.on(0); return; }
  const [f, v] = HOSE_TONE[HEROES[heroKey].mode] || [1800, .12]; hoseSnd.on(v); if (hoseSnd.f) hoseSnd.f.frequency.setTargetAtTime(f, ac.currentTime, .05);
}
