-- 🧯 불끄기 훈련장 화면: 📣 불이야 · ① 안전핀 · 💨 꾹 눌러 뿌리기 · 👁 1인칭/3인칭 · 🏃 대피 · 분말 게이지
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
