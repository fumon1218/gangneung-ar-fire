-- 🧯 불끄기 훈련장 던전 (사회별): 교실에 불이 나면 📣 불이야 → ① 안전핀 → ② 겨누기 → ③④ 꾹 눌러 좌우로 쓸기
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
