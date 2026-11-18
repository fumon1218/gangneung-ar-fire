local ds = game.ServerScriptService.DungeonServer
local m = ds:FindFirstChild("FireDrill") or Instance.new("ModuleScript"); m.Name = "FireDrill"
m.Source = [==[-- 🧯 불끄기 훈련장 던전 (사회별): 교실에 불이 나면 📣 불이야 → ① 안전핀 → ② 겨누기 → ③④ 꾹 눌러 좌우로 쓸기
-- 강릉분원 AR「불 끄기 대작전」3D 훈련장을 옮겨 온 것. 화면은 StarterPlayerScripts.FireDrillClient
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local A = { id = "fire", model = "FireDrillRoom", planet = "SocialPlanet", name = "불끄기 훈련장", icon = "🧯", color = Color3.fromRGB(255, 110, 70),
	tip = "교실에 불이 났어요! 소화기를 들고 불을 찾아 꺼요.", entry = { x = 60, z = 20 }, depth = 520 }

local W, D, H = 64, 48, 16 -- 교실 가로·세로·높이 (스터드)
local N_FIRES = 3
local SPRAY_RANGE = 24
local POWDER_USE = 6.5 -- 초당 분말 사용량 (100 = 가득)

local CTX
local rng = Random.new()
local inside = {} -- p -> { pin, powder, yelled, stars, spray, lastHit }
local sess = { state = "idle", n = 0, fire = nil, players = {} }
local firesF, ext

local function P(props)
	local p = Instance.new("Part"); p.Anchored = true; p.CastShadow = false; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	if not p.Parent then p.Parent = CTX.G end
	return p
end
local function at(x, y, z) return CTX.O * CFrame.new(x, y, z) end
local function send(p, kind, data) if p.Parent then CTX.remote:FireClient(p, "fd", kind, data or {}) end end
local function toAll(kind, data) for p in pairs(inside) do send(p, kind, data) end end

-- 불 날 수 있는 곳 (교실 좌표, 바닥 y=0)
local SPOTS = {
	{ key = "bin", name = "쓰레기통", x = -27, z = -19, y = 2.6, why = "휴지통 불은 작을 때 바로 꺼요" },
	{ key = "curtain", name = "창가 커튼", x = 29.5, z = -6, y = 4, why = "커튼은 불이 빨리 번져요" },
	{ key = "plug", name = "멀티탭", x = -6, z = -17.5, y = 0.8, why = "전기 불: 어른이 전기를 끄고 소화기로!" },
	{ key = "books", name = "책꽂이", x = -29, z = 8, y = 4, why = "종이는 잘 타요" },
	{ key = "heater", name = "난로", x = 22, z = 16, y = 1.5, why = "난로 옆에는 물건을 두지 않아요" },
}

-- ===== 소화기 (몸에 붙이는 모델) =====
local function makeExt()
	local m = Instance.new("Model"); m.Name = "Extinguisher"
	local function part(props) local p = Instance.new("Part"); p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true; p.CastShadow = false; p.Material = Enum.Material.SmoothPlastic
		for k, v in pairs(props) do p[k] = v end; p.Parent = m; return p end
	local body = part({ Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.15, 1.15), Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.Metal })
	body.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.pi / 2)
	part({ Name = "Cap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 0.9, 0.9), Color = Color3.fromRGB(40, 40, 44), CFrame = CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.pi / 2) })
	part({ Name = "Label", Size = Vector3.new(0.9, 0.8, 0.05), Color = Color3.fromRGB(255, 240, 210), CFrame = CFrame.new(0, 0.1, -0.58) })
	part({ Name = "Lever", Size = Vector3.new(0.25, 0.12, 1.0), Color = Color3.fromRGB(30, 30, 30), CFrame = CFrame.new(0, 1.85, -0.25) * CFrame.Angles(math.rad(-12), 0, 0) })
	part({ Name = "Handle", Size = Vector3.new(0.25, 0.12, 0.9), Color = Color3.fromRGB(30, 30, 30), CFrame = CFrame.new(0, 1.62, -0.2) })
	local pin = part({ Name = "Pin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.32, 0.32), Color = Color3.fromRGB(255, 215, 40), Material = Enum.Material.Neon, CFrame = CFrame.new(0.35, 1.7, -0.15) })
	pin:SetAttribute("Pin", true)
	part({ Name = "Hose", Size = Vector3.new(0.18, 0.18, 1.3), Color = Color3.fromRGB(20, 20, 20), CFrame = CFrame.new(0, 1.65, -0.95) })
	local noz = part({ Name = "Nozzle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.32, 0.32), Color = Color3.fromRGB(25, 25, 25), CFrame = CFrame.new(0, 1.65, -1.75) * CFrame.Angles(0, math.pi / 2, 0) })
	local att = Instance.new("Attachment"); att.Name = "Out"; att.Parent = noz
	att.WorldCFrame = CFrame.lookAt(Vector3.new(0, 1.65, -2.05), Vector3.new(0, 1.55, -10))
	local em = Instance.new("ParticleEmitter"); em.Name = "Powder"; em.Enabled = false; em.Rate = 140; em.EmissionDirection = Enum.NormalId.Front
	em.Speed = NumberRange.new(26, 34); em.SpreadAngle = Vector2.new(9, 9); em.Lifetime = NumberRange.new(0.45, 0.7); em.Drag = 2.5; em.Acceleration = Vector3.new(0, -6, 0)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 2.6) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1) })
	em.Color = ColorSequence.new(Color3.fromRGB(250, 250, 255)); em.LightInfluence = 0.6; em.Texture = "rbxasset://textures/particles/smoke_main.dds"; em.Parent = att
	m.PrimaryPart = body
	return m
end

local function equip(p)
	local ch = p.Character; if not ch then return end
	local old = ch:FindFirstChild("Extinguisher"); if old then old:Destroy() end
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart"); if not torso then return end
	local m = ext:Clone()
	-- 가슴 앞 오른쪽에 들고, 호스 끝은 앞을 향하게
	m:PivotTo(torso.CFrame * CFrame.new(0.7, -1.1, -1.0))
	for _, bp in ipairs(m:GetDescendants()) do
		if bp:IsA("BasePart") then local w = Instance.new("WeldConstraint"); w.Part0 = torso; w.Part1 = bp; w.Parent = bp; bp.Anchored = false end
	end
	m.Parent = ch
	ch:SetAttribute("FaceCam", true)
end
local function unequip(p)
	local ch = p.Character; if not ch then return end
	local m = ch:FindFirstChild("Extinguisher"); if m then m:Destroy() end
	ch:SetAttribute("FaceCam", nil)
end
local function setSpray(p, on)
	local ch = p.Character; local m = ch and ch:FindFirstChild("Extinguisher")
	local em = m and m:FindFirstChild("Powder", true)
	if em then em.Enabled = on end
end

-- ===== 불 =====
local function newFire(spot)
	local base = P({ Name = "Fire", Size = Vector3.new(2, 0.4, 2), CFrame = at(spot.x, spot.y, spot.z), Transparency = 1, CanCollide = false, CanQuery = false, Parent = firesF })
	local f = Instance.new("Fire"); f.Size = 3; f.Heat = 9; f.Color = Color3.fromRGB(255, 120, 30); f.SecondaryColor = Color3.fromRGB(255, 220, 60); f.Parent = base
	local sm = Instance.new("Smoke"); sm.Opacity = 0.18; sm.RiseVelocity = 4; sm.Size = 3; sm.Color = Color3.fromRGB(70, 70, 75); sm.Parent = base
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 140, 60); l.Range = 18; l.Brightness = 2.2; l.Parent = base
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromScale(5, 1.2); bb.StudsOffsetWorldSpace = Vector3.new(0, 7, 0); bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.Parent = base
	local bar = Instance.new("Frame"); bar.Size = UDim2.fromScale(1, 0.35); bar.Position = UDim2.fromScale(0, 0.6); bar.BackgroundColor3 = Color3.fromRGB(40, 20, 20); bar.Parent = bb
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame"); fill.Name = "Fill"; fill.Size = UDim2.fromScale(1, 1); fill.BackgroundColor3 = Color3.fromRGB(255, 110, 40); fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 0.55); tl.BackgroundTransparency = 1; tl.TextScaled = true; tl.Font = Enum.Font.GothamBlack
	tl.TextColor3 = Color3.fromRGB(255, 240, 220); tl.TextStrokeTransparency = 0.2; tl.Text = "🔥 " .. spot.name; tl.Parent = bb
	return { part = base, fire = f, smoke = sm, light = l, fill = fill, spot = spot, hp = 100, grow = 0, bigT = 0, t0 = os.clock() }
end

local function fireInfo(F)
	if not F then return nil end
	return { name = F.spot.name, why = F.spot.why, pos = F.part.Position, hp = F.hp, big = F.grow >= 1 }
end

local function nextFire()
	if sess.state ~= "playing" then return end
	sess.n += 1
	if sess.n > N_FIRES then
		sess.state = "done"
		for p in pairs(sess.players) do
			local st = inside[p]
			if st then
				local stars = math.min(5, st.stars)
				CTX.addCoins(p, 3 + stars)
				send(p, "done", { stars = stars, coins = 3 + stars, out = sess.out, evac = st.evac })
			end
		end
		sess.players = {}
		return
	end
	local pool = {}
	for _, s in ipairs(SPOTS) do if not sess.used[s.key] then table.insert(pool, s) end end
	local spot = pool[rng:NextInteger(1, #pool)]
	sess.used[spot.key] = true
	for _, st in pairs(inside) do st.yelled = false end
	sess.fire = newFire(spot)
	toAll("fire", { n = sess.n, total = N_FIRES, fire = fireInfo(sess.fire) })
end

local function putOut(F, by)
	if not F or F.dead then return end
	F.dead = true
	sess.out += 1
	F.fire.Enabled = false; F.light.Enabled = false
	local st = by and inside[by]; if st then st.stars += 1 end
	-- 하얀 김
	local em = Instance.new("ParticleEmitter"); em.Rate = 0; em.Speed = NumberRange.new(4, 9); em.SpreadAngle = Vector2.new(60, 60); em.Lifetime = NumberRange.new(1, 1.8)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) }); em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	em.Color = ColorSequence.new(Color3.fromRGB(235, 240, 245)); em.Texture = "rbxasset://textures/particles/smoke_main.dds"; em.Parent = F.part; em:Emit(40)
	if CTX.fx then for p in pairs(inside) do pcall(function() CTX.fx:FireClient(p, "confetti", F.part.Position) end) end end
	toAll("out", { n = sess.n, total = N_FIRES, by = by and by.DisplayName or nil, why = F.spot.why })
	Debris:AddItem(F.part, 4)
	sess.fire = nil
	task.delay(3.5, nextFire)
end

local function startGame(p)
	if sess.state == "playing" then sess.players[p] = true; send(p, "fire", { n = sess.n, total = N_FIRES, fire = fireInfo(sess.fire) }); return end
	sess = { state = "playing", n = 0, fire = nil, players = {}, used = {}, out = 0 }
	for q, st in pairs(inside) do sess.players[q] = true; st.stars = 0; st.evac = false; st.powder = 100; send(q, "start", { total = N_FIRES }); send(q, "powder", { v = 100 }) end
	task.delay(2, nextFire)
end

-- ===== 교실 짓기 =====
local function furn(name, cf, height)
	local F = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Furniture")
	local src = F and F:FindFirstChild(name)
	if not src then return nil end
	local m = src:Clone()
	local _, size = m:GetBoundingBox()
	if height then pcall(function() m:ScaleTo(m:GetScale() * height / size.Y) end) end
	local _, s2 = m:GetBoundingBox()
	m:PivotTo(cf * CFrame.new(0, s2.Y / 2, 0))
	for _, bp in ipairs(m:GetDescendants()) do if bp:IsA("BasePart") then bp.Anchored = true end end
	m.Parent = CTX.G
	return m
end

local function sign(part, face, text, bg, fg)
	local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.LightInfluence = 0.2; sg.Parent = part
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundColor3 = bg or Color3.new(1, 1, 1); tl.BackgroundTransparency = bg and 0 or 1
	tl.TextColor3 = fg or Color3.new(1, 1, 1); tl.TextScaled = true; tl.Font = Enum.Font.GothamBold; tl.Text = text; tl.TextWrapped = true; tl.Parent = sg
	return tl
end

function A.build(ctx)
	CTX = ctx
	ext = makeExt()
	firesF = Instance.new("Folder"); firesF.Name = "Fires"; firesF.Parent = ctx.G
	local wallC, floorC = Color3.fromRGB(246, 238, 222), Color3.fromRGB(196, 150, 100)
	P({ Name = "Floor", Size = Vector3.new(W, 1, D), CFrame = at(0, -0.5, 0), Color = floorC, Material = Enum.Material.WoodPlanks, CanCollide = true })
	P({ Name = "Ceiling", Size = Vector3.new(W, 1, D), CFrame = at(0, H + 0.5, 0), Color = Color3.fromRGB(250, 250, 248), CanCollide = true })
	-- 벽 (+z 벽에 문, +x 벽에 창문)
	P({ Name = "Wall", Size = Vector3.new(W, H, 1), CFrame = at(0, H / 2, -D / 2 - 0.5), Color = wallC, CanCollide = true })
	P({ Name = "Wall", Size = Vector3.new(1, H, D), CFrame = at(-W / 2 - 0.5, H / 2, 0), Color = wallC, CanCollide = true })
	P({ Name = "Wall", Size = Vector3.new(1, 4, D), CFrame = at(W / 2 + 0.5, 2, 0), Color = wallC, CanCollide = true })
	P({ Name = "Wall", Size = Vector3.new(1, 3, D), CFrame = at(W / 2 + 0.5, H - 1.5, 0), Color = wallC, CanCollide = true })
	P({ Name = "Window", Size = Vector3.new(0.4, H - 7, D), CFrame = at(W / 2 + 0.5, 4 + (H - 7) / 2, 0), Color = Color3.fromRGB(170, 215, 255), Material = Enum.Material.Glass, Transparency = 0.55, CanCollide = true })
	for i = -2, 2 do P({ Name = "Frame", Size = Vector3.new(0.6, H - 7, 0.4), CFrame = at(W / 2 + 0.3, 4 + (H - 7) / 2, i * 10), Color = Color3.fromRGB(255, 255, 255) }) end
	-- 커튼
	for _, z in ipairs({ -16, -6, 6, 16 }) do P({ Name = "Curtain", Size = Vector3.new(0.3, H - 4, 4), CFrame = at(W / 2 - 0.4, (H - 4) / 2 + 2, z), Color = Color3.fromRGB(120, 180, 120), Material = Enum.Material.Fabric }) end
	-- 앞문 쪽 벽(+z), 가운데 문 구멍 8칸
	P({ Name = "Wall", Size = Vector3.new((W - 8) / 2, H, 1), CFrame = at(-(W + 8) / 4, H / 2, D / 2 + 0.5), Color = wallC, CanCollide = true })
	P({ Name = "Wall", Size = Vector3.new((W - 8) / 2, H, 1), CFrame = at((W + 8) / 4, H / 2, D / 2 + 0.5), Color = wallC, CanCollide = true })
	P({ Name = "Wall", Size = Vector3.new(8, H - 9, 1), CFrame = at(0, 9 + (H - 9) / 2, D / 2 + 0.5), Color = wallC, CanCollide = true })
	local door = P({ Name = "Door", Size = Vector3.new(8, 9, 0.6), CFrame = at(0, 4.5, D / 2 + 0.6), Color = Color3.fromRGB(150, 105, 70), Material = Enum.Material.Wood, CanCollide = true })
	local ex = P({ Name = "ExitSign", Size = Vector3.new(6, 1.6, 0.3), CFrame = at(0, 10.6, D / 2 - 0.2), Color = Color3.fromRGB(30, 170, 80), Material = Enum.Material.Neon })
	sign(ex, Enum.NormalId.Back, "🏃 비상구", nil, Color3.new(1, 1, 1))
	-- 칠판 (-z 벽)
	local bd = P({ Name = "Board", Size = Vector3.new(26, 8, 0.4), CFrame = at(0, 7.5, -D / 2 + 0.2), Color = Color3.fromRGB(40, 90, 70) })
	sign(bd, Enum.NormalId.Back, "🔥 불이 나면\n📣 \"불이야!\" 외치기\n🧯 핀 뽑고 · 겨누고 · 꾹 누르고 · 좌우로 쓸기\n🏃 불이 크면 낮은 자세로 비상구로!", nil, Color3.fromRGB(255, 255, 240))
	-- 선생님 책상 + 멀티탭
	P({ Name = "TeacherDesk", Size = Vector3.new(10, 3, 4), CFrame = at(-6, 1.5, -15), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, CanCollide = true })
	P({ Name = "Plug", Size = Vector3.new(2.4, 0.4, 0.8), CFrame = at(-6, 0.2, -17.5), Color = Color3.fromRGB(245, 245, 245) })
	for i = 0, 2 do P({ Name = "Cord", Size = Vector3.new(0.15, 0.15, 3), CFrame = at(-6.8 + i * 0.8, 0.1, -19), Color = Color3.fromRGB(20, 20, 20) }) end
	-- 학생 책상·의자 3×3
	for r = 0, 2 do
		for c = -1, 1 do
			local x, z = c * 14, -3 + r * 8
			if not furn("Desk", at(x, 0, z), 3) then P({ Name = "Desk", Size = Vector3.new(4, 2.8, 3), CFrame = at(x, 1.4, z), Color = Color3.fromRGB(200, 160, 110), CanCollide = true }) end
			if not furn("Chair", at(x, 0, z + 3.2) * CFrame.Angles(0, math.pi, 0), 3.4) then P({ Name = "Chair", Size = Vector3.new(2.4, 2, 2.4), CFrame = at(x, 1, z + 3.2), Color = Color3.fromRGB(90, 140, 220), CanCollide = true }) end
		end
	end
	-- 책꽂이·쓰레기통·난로
	if not furn("Bookshelf", at(-30, 0, 8) * CFrame.Angles(0, math.pi / 2, 0), 8) then P({ Name = "Bookshelf", Size = Vector3.new(2.5, 8, 6), CFrame = at(-30, 4, 8), Color = Color3.fromRGB(150, 100, 60), CanCollide = true }) end
	P({ Name = "Bin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 2.2, 2.2), CFrame = at(-27, 1.3, -19) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(80, 130, 200), CanCollide = true })
	P({ Name = "Paper", Size = Vector3.new(1.4, 0.4, 1.2), CFrame = at(-27, 2.7, -19), Color = Color3.fromRGB(250, 250, 240) })
	P({ Name = "Heater", Size = Vector3.new(3, 3, 1.6), CFrame = at(22, 1.5, 16), Color = Color3.fromRGB(230, 230, 230), Material = Enum.Material.Metal, CanCollide = true })
	P({ Name = "HeaterGlow", Size = Vector3.new(2.4, 1.8, 0.1), CFrame = at(22, 1.6, 15.15), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon })
	-- 소화기함 (문 옆, 다 쓰면 여기서 새 소화기)
	local cab = P({ Name = "Cabinet", Size = Vector3.new(3, 5, 1.4), CFrame = at(-8, 3.5, D / 2 - 0.7), Color = Color3.fromRGB(210, 30, 30), CanCollide = true })
	sign(cab, Enum.NormalId.Back, "🧯 소화기", Color3.fromRGB(210, 30, 30), Color3.new(1, 1, 1))
	local pp = Instance.new("ProximityPrompt"); pp.ActionText = "새 소화기 받기"; pp.ObjectText = "🧯 소화기함"; pp.HoldDuration = 0.3; pp.MaxActivationDistance = 10; pp.RequiresLineOfSight = false; pp.Parent = cab
	pp.Triggered:Connect(function(p)
		local st = inside[p]; if not st then return end
		st.powder = 100; st.pin = false; equip(p); send(p, "powder", { v = 100 }); send(p, "msg", { t = "🧯 새 소화기! 다시 ① 안전핀부터 뽑아요" })
	end)
	-- 전등
	for _, x in ipairs({ -16, 16 }) do
		local lp = P({ Name = "Light", Size = Vector3.new(10, 0.3, 2), CFrame = at(x, H - 0.2, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
		local l = Instance.new("SurfaceLight"); l.Face = Enum.NormalId.Bottom; l.Range = 22; l.Brightness = 1.6; l.Angle = 120; l.Parent = lp
	end

	-- 불 키우기·꺼지기·대피 판정
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt; if acc < 0.1 then return end
		local step = acc; acc = 0
		local F = sess.fire
		for p, st in pairs(inside) do
			if st.spray then
				st.powder = math.max(0, st.powder - POWDER_USE * step)
				if st.powder <= 0 then st.spray = false; setSpray(p, false); send(p, "empty") end
				st.pt = (st.pt or 0) + step
				if st.pt > 0.5 then st.pt = 0; send(p, "powder", { v = st.powder }) end
			end
		end
		if not F or F.dead then return end
		F.grow = math.min(1, F.grow + step / 45)
		local k = 0.35 + 0.65 * F.grow
		F.fire.Size = 3 + 9 * k * (0.4 + 0.6 * F.hp / 100); F.fire.Heat = 6 + 12 * k
		F.smoke.Size = 3 + 6 * k; F.smoke.Opacity = 0.12 + 0.2 * k
		F.light.Brightness = 1.4 + math.sin(os.clock() * 17) * 0.4 + 1.2 * k
		F.fill.Size = UDim2.fromScale(math.max(0, F.hp / 100), 1)
		if F.grow >= 1 then
			F.bigT += step
			if F.bigT > 2 and not F.warned then F.warned = true; toAll("big", { name = F.spot.name }) end
		end
	end)
	return { inside = CFrame.lookAt(at(0, 3.5, D / 2 - 6).Position, at(0, 3.5, 0).Position), radius = 90, exitPart = door }
end

function A.enter(p)
	inside[p] = { pin = false, powder = 100, yelled = false, stars = 0, spray = false, lastHit = 0 }
	task.wait(0.3)
	equip(p)
	send(p, "menu", { playing = sess.state == "playing", n = sess.n, total = N_FIRES, fire = fireInfo(sess.fire) })
	send(p, "powder", { v = 100 })
end

function A.leave(p)
	inside[p] = nil
	sess.players[p] = nil
	setSpray(p, false)
	unequip(p)
	local any = next(inside) ~= nil
	if not any and sess.state == "playing" then
		sess.state = "idle"
		if sess.fire then sess.fire.part:Destroy(); sess.fire = nil end
	end
end

function A.onMsg(p, cmd, a, b)
	local st = inside[p]; if not st then return end
	if cmd == "start" then
		startGame(p)
	elseif cmd == "yell" then
		if sess.fire and not st.yelled then st.yelled = true; st.stars += 1; send(p, "yelled", {}) end
		for q in pairs(inside) do if q ~= p then send(q, "heard", { who = p.DisplayName }) end end
	elseif cmd == "pin" then
		if not st.pin then
			st.pin = true
			local m = p.Character and p.Character:FindFirstChild("Extinguisher")
			local pin = m and m:FindFirstChild("Pin"); if pin then pin:Destroy() end
			send(p, "pinned", {})
		end
	elseif cmd == "spray" then
		local on = a == true
		if on and (not st.pin or st.powder <= 0) then on = false end
		st.spray = on; setSpray(p, on)
	elseif cmd == "hit" then
		-- a = 이번에 맞힌 양(초), b = 쓸기 했는지
		local F = sess.fire; if not F or F.dead or not st.spray then return end
		local now = os.clock()
		local dt = math.clamp(now - (st.lastHit or 0), 0, 0.5); st.lastHit = now
		local amt = math.clamp(tonumber(a) or 0, 0, dt + 0.05)
		local h = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not h or (h.Position - F.part.Position).Magnitude > SPRAY_RANGE + 4 then return end
		local dmg = amt * 20 * (b and 1.6 or 1) * (1.15 - 0.5 * F.grow)
		F.hp -= dmg
		if F.hp <= 0 then putOut(F, p) end
	elseif cmd == "evac" then
		if sess.fire and sess.fire.grow >= 1 and not sess.fire.dead then
			st.evac = true; st.stars += 1
			send(p, "evacOk", {})
			-- 모두 대피 → 소방관이 끈 것으로
			local F = sess.fire
			task.delay(2.5, function() if sess.fire == F and not F.dead then F.hp = 0; putOut(F, nil) end end)
		end
	end
end

return A
]==]
m.Parent = ds
local sps = game.StarterPlayer.StarterPlayerScripts
local c = sps:FindFirstChild("FireDrillClient") or Instance.new("LocalScript"); c.Name = "FireDrillClient"
c.Source = [==[-- 🧯 불끄기 훈련장 화면: 📣 불이야 · ① 안전핀 · 💨 꾹 눌러 뿌리기 · 👁 1인칭/3인칭 · 🏃 대피 · 분말 게이지
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local plr = Players.LocalPlayer
local remote = RS:WaitForChild("DungeonRemote")
local cam = workspace.CurrentCamera

local function mk(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; o.Parent = parent; return o end
local function corner(o, r) mk("UICorner", { CornerRadius = r or UDim.new(0, 16) }, o) end
local function sfx(id, vol, pitch) local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 0.4; s.PlaybackSpeed = pitch or 1; s.Parent = SoundService; s:Play(); Debris:AddItem(s, 3) end
local PING = "rbxasset://sounds/electronicpingshort.wav"

local gui = mk("ScreenGui", { Name = "FireDrillGui", ResetOnSpawn = false, DisplayOrder = 17, Enabled = false }, plr:WaitForChild("PlayerGui"))
local function btn(text, pos, size, col, parent)
	local b = mk("TextButton", { Text = text, Position = pos, Size = size, BackgroundColor3 = col, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextScaled = true, AutoButtonColor = true }, parent or gui)
	corner(b, UDim.new(0, 18)); mk("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	mk("UITextSizeConstraint", { MaxTextSize = 28 }, b)
	return b
end

-- 위 안내판 + 4단계
local top = mk("Frame", { Size = UDim2.new(0.62, 0, 0, 92), Position = UDim2.new(0.19, 0, 0, 8), BackgroundColor3 = Color3.fromRGB(28, 32, 60), BackgroundTransparency = 0.12 }, gui); corner(top)
local msg = mk("TextLabel", { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 245, 225), Font = Enum.Font.GothamBold, TextScaled = true, Text = "" }, top)
local steps = mk("Frame", { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 56), BackgroundTransparency = 1 }, top)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }, steps)
local STEP = {}
for i, t in ipairs({ "📣 외치기", "① 핀", "② 겨누기", "③④ 꾹·쓸기" }) do
	local s = mk("TextLabel", { Size = UDim2.new(0.24, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(70, 76, 110), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextScaled = true, Text = t }, steps); corner(s, UDim.new(0, 10))
	STEP[i] = s
end
local function stepOn(i) for k, s in ipairs(STEP) do s.BackgroundColor3 = k < i and Color3.fromRGB(60, 170, 110) or (k == i and Color3.fromRGB(255, 140, 50) or Color3.fromRGB(70, 76, 110)) end end

-- 분말 게이지
local gauge = mk("Frame", { Size = UDim2.new(0, 26, 0, 180), Position = UDim2.new(1, -46, 0.5, -150), BackgroundColor3 = Color3.fromRGB(40, 40, 50) }, gui); corner(gauge, UDim.new(0, 10))
local gfill = mk("Frame", { Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(240, 240, 255) }, gauge); corner(gfill, UDim.new(0, 10))
mk("TextLabel", { Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(0.5, -30, 1, 4), BackgroundTransparency = 1, Text = "분말", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextScaled = true }, gauge)

-- 버튼
local bYell = btn("📣 불이야!", UDim2.new(1, -330, 1, -250), UDim2.new(0, 150, 0, 70), Color3.fromRGB(255, 150, 40))
local bPin = btn("① 안전핀\n뽑기", UDim2.new(1, -170, 1, -250), UDim2.new(0, 150, 0, 70), Color3.fromRGB(230, 180, 20))
local bSpray = btn("💨 꾹 눌러\n뿌리기", UDim2.new(1, -230, 1, -165), UDim2.new(0, 210, 0, 140), Color3.fromRGB(40, 140, 240))
local bView = btn("👁 1인칭", UDim2.new(0, 16, 0, 120), UDim2.new(0, 130, 0, 52), Color3.fromRGB(110, 90, 200))
local bEvac = btn("🏃 대피!", UDim2.new(0.5, -110, 0.5, -45), UDim2.new(0, 220, 0, 90), Color3.fromRGB(30, 170, 80)); bEvac.Visible = false
local bStart = btn("🔥 훈련 시작", UDim2.new(0.5, -130, 0.5, -45), UDim2.new(0, 260, 0, 90), Color3.fromRGB(255, 100, 60)); bStart.Visible = false

-- 결과판
local res = mk("Frame", { Size = UDim2.new(0, 420, 0, 260), Position = UDim2.new(0.5, -210, 0.5, -130), BackgroundColor3 = Color3.fromRGB(255, 248, 230), Visible = false }, gui); corner(res, UDim.new(0, 24))
local resT = mk("TextLabel", { Size = UDim2.new(1, -30, 0, 150), Position = UDim2.new(0, 15, 0, 12), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(80, 40, 20), Font = Enum.Font.GothamBlack, TextScaled = true, TextWrapped = true }, res)
local bAgain = btn("🔁 다시 하기", UDim2.new(0, 20, 1, -84), UDim2.new(0.5, -30, 0, 64), Color3.fromRGB(255, 120, 60), res)
local bClose = btn("닫기", UDim2.new(0.5, 10, 1, -84), UDim2.new(0.5, -30, 0, 64), Color3.fromRGB(130, 140, 160), res)

local S = { active = false, pin = false, yelled = false, fire = nil, spray = false, first = false, powder = 100, lastYaw = nil, sweepT = 0, sweepDir = 0, hitAcc = 0, sendT = 0 }

local function say(t) msg.Text = t end
local function setFirst(on)
	S.first = on
	plr:SetAttribute("CamFirst", on and true or nil)
	bView.Text = on and "👁 3인칭" or "👁 1인칭"
end
bView.MouseButton1Click:Connect(function() setFirst(not S.first) end)
bYell.MouseButton1Click:Connect(function() remote:FireServer("yell"); sfx(PING, 0.5, 0.8) end)
bPin.MouseButton1Click:Connect(function() remote:FireServer("pin"); sfx(PING, 0.5, 1.3) end)
bStart.MouseButton1Click:Connect(function() bStart.Visible = false; remote:FireServer("start") end)
bAgain.MouseButton1Click:Connect(function() res.Visible = false; remote:FireServer("start") end)
bClose.MouseButton1Click:Connect(function() res.Visible = false; bStart.Visible = true end)
bEvac.MouseButton1Click:Connect(function() bEvac.Visible = false; remote:FireServer("evac") end)

local function sprayOn(on)
	if on and not S.pin then say("먼저 ① 안전핀을 뽑아요!"); stepOn(2); return end
	if on and S.powder <= 0 then say("분말이 다 떨어졌어요! 문 옆 🧯 소화기함에서 새 소화기를 받아요"); return end
	if S.spray == on then return end
	S.spray = on; remote:FireServer("spray", on)
end
bSpray.MouseButton1Down:Connect(function() sprayOn(true) end)
bSpray.MouseButton1Up:Connect(function() sprayOn(false) end)
bSpray.MouseLeave:Connect(function() if not UIS.TouchEnabled then sprayOn(false) end end)
bSpray.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then sprayOn(false) end end)
UIS.InputBegan:Connect(function(i, gp) if gp or not S.active then return end; if i.KeyCode == Enum.KeyCode.F then sprayOn(true) elseif i.KeyCode == Enum.KeyCode.V then setFirst(not S.first) end end)
UIS.InputEnded:Connect(function(i) if S.active and i.KeyCode == Enum.KeyCode.F then sprayOn(false) end end)

remote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "enter" and a == "fire" then
		S.active = true; gui.Enabled = true; S.pin = false; S.yelled = false; res.Visible = false; bEvac.Visible = false
		say("🧯 소화기를 들었어요! 🔥 훈련 시작을 눌러요"); stepOn(1)
	elseif kind == "exit" and a == "fire" then
		S.active = false; gui.Enabled = false; setFirst(false); sprayOn(false)
	elseif kind == "fd" then
		local d = b or {}
		if a == "menu" then
			if d.playing then remote:FireServer("start") else bStart.Visible = true end
		elseif a == "start" then
			bStart.Visible = false; res.Visible = false; say("🔥 어딘가에서 불이 날 거예요… 잘 살펴봐요!")
		elseif a == "fire" then
			S.fire = d.fire; S.yelled = false; bEvac.Visible = false
			if d.fire then say(("🔥 불이야! %s에 불이 났어요 (%d/%d)  먼저 📣 불이야! 외쳐요"):format(d.fire.name, d.n, d.total)); stepOn(1); sfx(PING, 0.6, 0.6) end
		elseif a == "yelled" then
			S.yelled = true; say(S.pin and "잘했어요! 불 쪽으로 다가가 💨 꾹 누르고 좌우로 쓸어요" or "잘했어요! 이제 ① 안전핀을 뽑아요"); stepOn(S.pin and 3 or 2)
		elseif a == "heard" then
			say("📣 " .. tostring(d.who) .. ": 불이야!")
		elseif a == "pinned" then
			S.pin = true; say("핀을 뽑았어요! ② 불 쪽으로 겨누고 ③ 꾹 누르기, ④ 좌우로 쓸기"); stepOn(3)
		elseif a == "powder" then
			S.powder = d.v or 0; gfill.Size = UDim2.fromScale(1, math.clamp(S.powder / 100, 0, 1))
			if (d.v or 0) >= 100 then S.pin = false end
		elseif a == "empty" then
			S.spray = false; say("분말이 다 떨어졌어요! 문 옆 🧯 소화기함에서 새 소화기를 받아요")
		elseif a == "msg" then
			say(d.t or ""); if (d.t or ""):find("안전핀") then stepOn(2) end
		elseif a == "out" then
			S.fire = nil; bEvac.Visible = false; sprayOn(false)
			say(("✅ 불이 꺼졌어요! (%d/%d)  %s"):format(d.n, d.total, d.why or "")); sfx(PING, 0.7, 1.6)
		elseif a == "big" then
			bEvac.Visible = true; say("😮 불이 너무 커졌어요! 무리하지 말고 🏃 대피해요 (낮은 자세로 비상구)")
		elseif a == "evacOk" then
			say("👍 잘했어요! 불이 크면 대피가 정답이에요. 소방관 아저씨가 불을 끌 거예요")
		elseif a == "done" then
			sprayOn(false); setFirst(false)
			res.Visible = true
			resT.Text = ("🎉 훈련 완료!\n⭐ %d개 · 코인 +%d\n%s"):format(d.stars or 0, d.coins or 0, d.evac and "🏃 대피도 잘했어요!" or "불이야 · 핀 · 꾹 · 쓸기 완벽!")
		end
	end
end)

-- 맞히기: 카메라가 보는 쪽 원뿔 안 · 24스터드 이내. 쓸기 = 뿌리는 중 좌우로 고개 돌리기
local BODY = { "Head", "UpperTorso", "LowerTorso", "Torso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
RunService.RenderStepped:Connect(function(dt)
	if not S.active then return end
	local ch = plr.Character
	-- 1인칭이면 내 몸은 숨기고 소화기만 보이게
	if ch then
		for _, n in ipairs(BODY) do local p = ch:FindFirstChild(n); if p then p.LocalTransparencyModifier = S.first and 1 or 0 end end
		for _, a in ipairs(ch:GetChildren()) do if a:IsA("Accessory") then local h = a:FindFirstChild("Handle"); if h then h.LocalTransparencyModifier = S.first and 1 or 0 end end end
	end
	if not S.spray or not S.fire then S.lastYaw = nil; return end
	local h = ch and ch:FindFirstChild("HumanoidRootPart"); if not h then return end
	local look = cam.CFrame.LookVector
	local yaw = math.atan2(look.X, look.Z)
	if S.lastYaw then
		local d = (yaw - S.lastYaw + math.pi) % (2 * math.pi) - math.pi
		local dir = d > 0.004 and 1 or (d < -0.004 and -1 or 0)
		if dir ~= 0 and dir ~= S.sweepDir then S.sweepDir = dir; S.sweepT = 0.8 end
	end
	S.lastYaw = yaw; S.sweepT = math.max(0, S.sweepT - dt)
	local to = S.fire.pos - h.Position
	local flat = Vector3.new(to.X, 0, to.Z)
	local lf = Vector3.new(look.X, 0, look.Z)
	local ok = flat.Magnitude < 24 and lf.Magnitude > 0.1 and flat.Magnitude > 0.1 and lf.Unit:Dot(flat.Unit) > math.cos(math.rad(30))
	if ok then S.hitAcc += dt end
	S.sendT += dt
	if S.sendT > 0.2 then
		S.sendT = 0
		if S.hitAcc > 0 then remote:FireServer("hit", S.hitAcc, S.sweepT > 0); S.hitAcc = 0
		elseif flat.Magnitude >= 24 then say("불이 멀어요! 조금 더 다가가요 (너무 가까이는 위험)") end
	end
end)
]==]
c.Parent = sps
local g = sps.PlanetGravity
local src = g.Source
local n1, n2 = 0, 0
if not src:find("FaceCam", 1, true) then
  src, n1 = src:gsub("(\n(%s*)if dir%.Magnitude > 0%.1 then s%.look = dir%.Unit end)", "%1\n%2-- 소화기를 든 동안(불끄기 훈련장)은 몸이 카메라 쪽을 봐요\n%2if s.char and s.char:GetAttribute(\"FaceCam\") then s.look = fwd end", 1)
end
if not src:find("CamFirst", 1, true) then
  src, n2 = src:gsub("(\n(%s*)local camPos = focus %- look %* CAM_DIST %+ up %* 1%.5)", "\n%2-- 1인칭 보기(플레이어 속성 CamFirst): 눈 높이에서 바라보는 쪽으로\n%2if game.Players.LocalPlayer:GetAttribute(\"CamFirst\") then local eye = hrp.Position + up * 1.6; camera.CFrame = CFrame.lookAt(eye, eye + look, up); return end%1", 1)
end
g.Source = src
return "ok patch " .. n1 .. " " .. n2
