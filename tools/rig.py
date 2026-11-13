import bpy, math, mathutils, sys
from mathutils import Vector, Quaternion, Matrix

V = Vector
def ss(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t)
FPS = 24

def clean():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS

def load(path):
    bpy.ops.import_scene.gltf(filepath=path)
    mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
    # apply transforms so vertex coords are world coords
    bpy.ops.object.select_all(action='DESELECT'); mesh.select_set(True); bpy.context.view_layer.objects.active = mesh
    if mesh.parent:
        mw = mesh.matrix_world.copy(); mesh.parent = None; mesh.matrix_world = mw
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(bpy.context.scene.objects):
        if o != mesh: bpy.data.objects.remove(o)
    return mesh

def build(mesh, bones):
    """bones: list of (name, head, tail, parent, allow(fn(co)->bool) or None)"""
    arm_data = bpy.data.armatures.new('Rig'); arm = bpy.data.objects.new('Rig', arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='EDIT')
    for name, h, t, parent, _ in bones:
        b = arm_data.edit_bones.new(name); b.head = V(h); b.tail = V(t)
        if parent: b.parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    # weights: inverse distance to bone segment, masked, top-2
    groups = {n: mesh.vertex_groups.new(name=n) for n, *_ in bones}
    segs = [(n, V(h), V(t), allow) for n, h, t, p, allow in bones]
    for v in mesh.data.vertices:
        co = v.co; cand = []
        for n, a, b, allow in segs:
            mult = 1.0
            if allow:
                r = allow(co); mult = float(r)
                if mult <= 0: continue
            ab = b - a; tt = max(0, min(1, (co - a).dot(ab) / max(ab.length_squared, 1e-9)))
            d = (co - (a + ab * tt)).length
            cand.append((mult / (d + .04) ** 4, n))
        if not cand:
            for n, a, b, allow in segs:
                ab = b - a; tt = max(0, min(1, (co - a).dot(ab) / max(ab.length_squared, 1e-9)))
                cand.append((1 / ((co - (a + ab * tt)).length + .02) ** 6, n))
        cand.sort(reverse=True); cand = cand[:3]; s = sum(w for w, _ in cand)
        for w, n in cand: groups[n].add([v.index], w / s, 'REPLACE')
    mesh.parent = arm
    mod = mesh.modifiers.new('Armature', 'ARMATURE'); mod.object = arm
    return arm

def rot_global(arm, bname, axis, deg):
    """pose-bone quaternion that rotates the bone around a GLOBAL (armature-space) axis"""
    B = arm.data.bones[bname].matrix_local.to_3x3()
    R = Matrix.Rotation(math.radians(deg), 3, V(axis))
    return (B.inverted() @ R @ B).to_quaternion()

def action(arm, name, frames, keyfn):
    """keyfn(f) -> {bone: (axis, deg) or [(axis,deg),...] or ('loc', Vector)}"""
    act = bpy.data.actions.new(name); act.use_fake_user = True
    arm.animation_data_create(); arm.animation_data.action = act
    for pb in arm.pose.bones: pb.rotation_mode = 'QUATERNION'
    for f in frames:
        poses = keyfn(f)
        for pb in arm.pose.bones:
            q = Quaternion(); loc = V((0, 0, 0))
            spec = poses.get(pb.name, [])
            if isinstance(spec, tuple): spec = [spec]
            for item in spec:
                if item[0] == 'loc': loc = item[1]
                else: q = rot_global(arm, pb.name, item[0], item[1]) @ q
            pb.rotation_quaternion = q; pb.location = loc
            pb.keyframe_insert('rotation_quaternion', frame=f); pb.keyframe_insert('location', frame=f)
    track = arm.animation_data.nla_tracks.new(); track.name = name
    track.strips.new(name, frames[0], act)
    arm.animation_data.action = None
    return act

def export(path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_animations=True,
                              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
                              export_apply=False, export_image_format='AUTO')

S = math.sin; PI = math.pi
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)   # Blender axes: X right, -Y forward, Z up
which = sys.argv[sys.argv.index('--') + 1:]

# ---------------- 용암 골렘 (걷기·내려찍기) ----------------
if 'golem' in which:
    clean(); m = load('/home/claude/vill/LavaGolem.glb')
    arm = build(m, [
        ('hips', (0, 0, .40), (0, 0, .55), None, lambda c: (1 - ss(.22, .32, abs(c.x))) * ss(.25, .38, c.z)),
        ('spine', (0, 0, .55), (0, 0, .75), 'hips', lambda c: (1 - ss(.26, .36, abs(c.x))) * ss(.4, .5, c.z)),
        ('head', (0, -.02, .75), (0, -.02, .9), 'spine', lambda c: abs(c.x) < .2 and c.z > .68),
        ('leg.L', (.17, 0, .42), (.17, 0, .02), 'hips', lambda c: ss(-.02, .06, c.x) * (1 - ss(.38, .48, c.z))),
        ('leg.R', (-.17, 0, .42), (-.17, 0, .02), 'hips', lambda c: ss(-.02, .06, -c.x) * (1 - ss(.38, .48, c.z))),
        ('arm.L', (.3, 0, .72), (.42, 0, .25), 'spine', lambda c: ss(.2, .34, c.x) * ss(.1, .2, c.z)),
        ('arm.R', (-.3, 0, .72), (-.42, 0, .25), 'spine', lambda c: ss(.2, .34, -c.x) * ss(.1, .2, c.z)),
    ])
    def walk(f):
        p = 2 * PI * f / 24; s = S(p)
        return {'leg.L': (X, 22 * s), 'leg.R': (X, -22 * s), 'arm.L': (X, -18 * s), 'arm.R': (X, 18 * s),
                'hips': [('loc', V((0, abs(S(p)) * .025, 0))), (Y, 4 * s)], 'spine': (Z, 5 * s)}
    action(arm, 'Walk', list(range(0, 25, 2)), walk)
    def attack(f):
        t = f / 24; up = S(min(1, t / .5) * PI / 2) if t < .5 else 1 - (t - .5) / .5
        slam = S(min(1, t / .45) * PI / 2) if t < .45 else max(0, 1 - (t - .55) / .45)
        return {'arm.L': (X, -50 * slam), 'arm.R': (X, -50 * slam), 'spine': (X, -22 * slam), 'head': (X, 10 * slam), 'hips': ('loc', V((0, -.03 * slam, 0)))}
    action(arm, 'Attack', list(range(0, 25, 2)), attack)
    export('/home/claude/rigged/lavagolem.glb'); print('golem ok')

# ---------------- 미라 (뒤뚱 걷기·던지기) ----------------
if 'mummy' in which:
    clean(); m = load('/home/claude/vill/Mummy.glb')
    arm = build(m, [
        ('hips', (0, 0, .40), (0, 0, .58), None, lambda c: abs(c.x) < .26 and c.z > .3),
        ('spine', (0, 0, .58), (0, 0, .78), 'hips', lambda c: abs(c.x) < .28 and c.z > .5),
        ('head', (0, 0, .78), (0, 0, 1.0), 'spine', lambda c: c.z > .7 and abs(c.x) < .3),
        ('leg.L', (.12, 0, .42), (.12, 0, .02), 'hips', lambda c: c.x > .02 and c.z < .45),
        ('leg.R', (-.12, 0, .42), (-.12, 0, .02), 'hips', lambda c: c.x < -.02 and c.z < .45),
        ('arm.L', (.22, 0, .70), (.42, -.1, .62), 'spine', lambda c: c.x > .2 and c.z > .4),
        ('arm.R', (-.22, 0, .70), (-.42, -.1, .62), 'spine', lambda c: c.x < -.2 and c.z > .4),
    ])
    def walk(f):
        p = 2 * PI * f / 24; s = S(p)
        return {'leg.L': (X, 16 * s), 'leg.R': (X, -16 * s), 'hips': [(Y, 9 * s), ('loc', V((0, abs(s) * .02, 0)))],
                'arm.L': [(Z, 10 * S(p + 1)), (X, 8 * s)], 'arm.R': [(Z, -10 * S(p + 1)), (X, -8 * s)], 'head': (Y, -6 * s)}
    action(arm, 'Walk', list(range(0, 25, 2)), walk)
    def attack(f):
        t = f / 24; k = S(min(1, t / .4) * PI / 2) if t < .4 else max(0, 1 - (t - .4) / .3)
        return {'arm.L': (X, -110 * k + 60 * (t > .4) * (1 - k)), 'arm.R': (X, -110 * k + 60 * (t > .4) * (1 - k)), 'spine': (X, 12 * (1 - k) * (t > .4))}
    action(arm, 'Attack', list(range(0, 25, 2)), attack)
    export('/home/claude/rigged/mummy.glb'); print('mummy ok')

# ---------------- 불새 (날갯짓·급강하) ----------------
if 'phoenix' in which:
    clean(); m = load('/home/claude/vill/Phoenix.glb')
    arm = build(m, [
        ('body', (0, 0, .30), (0, 0, .68), None, lambda c: abs(c.x) < .14),
        ('head', (0, 0, .68), (0, 0, .96), 'body', lambda c: abs(c.x) < .12 and c.z > .6),
        ('tail', (0, 0, .30), (0, 0, 0), 'body', lambda c: c.z < .33),
        ('wing1.L', (.08, 0, .60), (.28, 0, .70), 'body', lambda c: c.x > .06 and c.z > .4),
        ('wing2.L', (.28, 0, .70), (.5, 0, .85), 'wing1.L', lambda c: c.x > .2 and c.z > .4),
        ('wing1.R', (-.08, 0, .60), (-.28, 0, .70), 'body', lambda c: c.x < -.06 and c.z > .4),
        ('wing2.R', (-.28, 0, .70), (-.5, 0, .85), 'wing1.R', lambda c: c.x < -.2 and c.z > .4),
    ])
    def fly(f):
        p = 2 * PI * f / 12; s = S(p); s2 = S(p - .8)
        return {'wing1.L': (Y, -38 * s), 'wing2.L': (Y, -25 * s2), 'wing1.R': (Y, 38 * s), 'wing2.R': (Y, 25 * s2),
                'body': ('loc', V((0, -s * .02, 0))), 'tail': (X, 6 * S(p + 1.5)), 'head': (X, 4 * s)}
    action(arm, 'Fly', list(range(0, 13, 1)), fly)
    def attack(f):
        t = f / 24; k = S(t * PI)
        return {'wing1.L': (Y, 50 * k), 'wing1.R': (Y, -50 * k), 'head': (X, -35 * k), 'body': (X, -20 * k), 'tail': (X, 25 * k)}
    action(arm, 'Attack', list(range(0, 25, 2)), attack)
    export('/home/claude/rigged/phoenix.glb'); print('phoenix ok')

# ---------------- 우주 보스 (몸통 물결·돌진) ----------------
if 'boss' in which:
    clean(); m = load('/home/claude/vill/SpaceBoss.glb')
    # spine chain through slice centroids
    zs = [i / 8 for i in range(9)]; pts = []
    vs = [v.co for v in m.data.vertices]
    for i in range(8):
        sl = [c for c in vs if zs[i] <= c.z < zs[i + 1] + 1e-6]
        c = sum(sl, V((0, 0, 0))) / max(1, len(sl)); pts.append(V((c.x, c.y, (zs[i] + zs[i + 1]) / 2)))
    pts = [V((pts[0].x, pts[0].y, 0))] + pts + [V((pts[-1].x, pts[-1].y - .05, 1.0))]
    bones = []
    for i in range(len(pts) - 1):
        bones.append((f's{i}', tuple(pts[i]), tuple(pts[i + 1]), f's{i-1}' if i else None, None))
    arm = build(m, bones)
    n = len(bones)
    def idle(f):
        p = 2 * PI * f / 36
        return {f's{i}': [(Y, 7 * S(p - i * .7)), (X, 4 * S(p * 1 - i * .5 + 1))] for i in range(1, n)}
    action(arm, 'Fly', list(range(0, 37, 3)), idle)
    def attack(f):
        t = f / 24; k = S(t * PI)
        return {**{f's{i}': (X, -10 * k * (i / n)) for i in range(1, n)}, f's{n-1}': (X, -35 * k)}
    action(arm, 'Attack', list(range(0, 25, 2)), attack)
    export('/home/claude/rigged/spaceboss.glb'); print('boss ok')
