const VS = `attribute float size; attribute float alpha; attribute vec3 color; varying float vA; varying vec3 vC; uniform float uScale; uniform float uMax;
void main(){ vA=alpha; vC=color; vec4 mv=modelViewMatrix*vec4(position,1.); gl_Position=projectionMatrix*mv; float z=-mv.z; if(z<.35){vA=0.;gl_PointSize=0.;return;} gl_PointSize=min(size*uScale/z, uMax); }`;
const FS = `varying float vA; varying vec3 vC; void main(){ float d=length(gl_PointCoord-.5); if(d>.5) discard; gl_FragColor=vec4(vC, smoothstep(.5,0.,d)*vA); }`;
class Particles {
  constructor(n, blending, kind) {
    Object.assign(this, { n, kind, i: 0 });
    for (const k of ['pos', 'col', 'vel']) this[k] = new Float32Array(n * 3);
    for (const k of ['size', 'alpha', 'life', 'max', 's0', 's1']) this[k] = new Float32Array(n);
    const g = this.g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.BufferAttribute(this.pos, 3)); g.setAttribute('color', new THREE.BufferAttribute(this.col, 3));
    g.setAttribute('size', new THREE.BufferAttribute(this.size, 1)); g.setAttribute('alpha', new THREE.BufferAttribute(this.alpha, 1));
    this.mat = new THREE.ShaderMaterial({ vertexShader: VS, fragmentShader: FS, transparent: true, depthWrite: false, depthTest: false, blending, uniforms: { uScale: { value: 1 }, uMax: { value: 140 } } });
    const p = new THREE.Points(g, this.mat); p.frustumCulled = false; p.renderOrder = 5; stage.add(p);
  }
  spawn(p, v, life, s0, s1) { const i = this.i; this.i = (i + 1) % this.n; this.pos.set([p.x, p.y, p.z], i * 3); this.vel.set([v.x, v.y, v.z], i * 3); this.life[i] = this.max[i] = life; this.s0[i] = s0; this.s1[i] = s1; }
  clear() { this.life.fill(0); }
  update(dt) {
    const grav = this.kind === 'powder' ? -.4 : this.kind === 'water' ? -9.8 : this.kind === 'fire' ? 1.5 : this.kind === 'bubble' ? .25 : this.kind === 'heavy' ? -7 : .6;
    for (let i = 0; i < this.n; i++) {
      if (this.life[i] <= 0) { this.alpha[i] = 0; this.size[i] = 0; continue; }
      this.life[i] -= dt; const t = 1 - Math.max(0, this.life[i]) / this.max[i], j = i * 3;
      this.vel[j + 1] += grav * dt;
      if (this.kind === 'powder') { const k = Math.pow(.2, dt); this.vel[j] *= k; this.vel[j + 1] *= k; this.vel[j + 2] *= k; } else if (this.kind !== 'water' && this.kind !== 'heavy') { this.vel[j] *= this.kind === 'bubble' ? .97 : .985; this.vel[j + 2] *= this.kind === 'bubble' ? .97 : .985; }
      this.pos[j] += this.vel[j] * dt; this.pos[j + 1] += this.vel[j + 1] * dt; this.pos[j + 2] += this.vel[j + 2] * dt;
      this.size[i] = this.s0[i] + (this.s1[i] - this.s0[i]) * t;
      let r, g, b, a;
      if (this.kind === 'fire') {
        if (t < .18) { const k = t / .18; r = 1; g = 1 - .15 * k; b = .75 - .55 * k; }
        else if (t < .55) { const k = (t - .18) / .37; r = 1; g = .85 - .45 * k; b = .2 - .15 * k; }
        else { const k = (t - .55) / .45; r = 1 - .45 * k; g = .4 - .32 * k; b = .05; }
        a = Math.pow(1 - t, 1.3) * .85;
      } else if (this.kind === 'smoke') { r = g = b = .4 + .3 * t; a = .4 * (1 - t) * Math.min(1, t * 6); }
      else if (this.kind === 'steam') { r = g = b = .97; a = .6 * (1 - t); }
      else if (this.kind === 'powder') { r = g = b = .97; a = .75 * (1 - t) * Math.min(1, t * 8); }
      else if (this.kind === 'bubble') { r = .85; g = .95; b = 1; a = .55 * (1 - t) * (.6 + .4 * Math.sin(i + t * 20)); }
      else { const c = this.kind === 'heavy' ? heavyTint : waterTint; r = c[0]; g = c[1]; b = c[2]; a = .95 * (1 - t * t); }
      this.col.set([r, g, b], j); this.alpha[i] = a;
    }
    for (const k of ['position', 'color', 'size', 'alpha']) this.g.attributes[k].needsUpdate = true;
  }
}
