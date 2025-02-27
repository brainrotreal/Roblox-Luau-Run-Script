local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local anim = Instance.new("Animation")
anim.AnimationId = "" -- Insert Own Animation Id Here

local runAnimation = humanoid:LoadAnimation(anim)

local defaultWalkSpeed = 16
local runWalkSpeed = 35
local boostedRunWalkSpeed = 53
local boostDuration = 5
local cooldownDuration = 3

humanoid.WalkSpeed = defaultWalkSpeed

local camera = game.Workspace.CurrentCamera
local defaultFOV = camera.FieldOfView
local targetFOV = defaultFOV + 20
local boostedFOV = defaultFOV + 50

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local isRunning = false
local isCooldownActive = false
local lastRunTime = 0
local bobbingTime = 0
local update = Vector3.new(0, 0, 0)

local Angle = 1.5 -- Screen tilt intensity
local BobbingAmount = 0.05 -- Walk bobbing intensity
local TimeScale = math.clamp(humanoid.WalkSpeed / 16, 0.5, 2) -- Bobbing speed

local function lerp(a, b, c)
	return a + (b - a) * c
end

local function updateCamera(deltaTime)
	if humanoid.Health <= 0 then return end

	local MouseDelta = UserInputService:GetMouseDelta().X

	-- Apply camera tilt based on mouse movement
	update = lerp(update, Vector3.new(math.clamp(MouseDelta, -Angle, Angle), math.random(-Angle, Angle), math.random(-Angle, Angle)), 0.25 * deltaTime * 60)

	-- Walk bobbing effect
	local Walking = humanoid.MoveDirection.Magnitude > 0.01
	local WalkBobbing = Walking and Vector3.new(
		math.sin(time() * humanoid.WalkSpeed * 0.5) * BobbingAmount * TimeScale,
		math.sin(time() * humanoid.WalkSpeed * 0.3) * BobbingAmount * TimeScale,
		math.sin(time() * humanoid.WalkSpeed * 0.7) * BobbingAmount * TimeScale
	) or Vector3.new(0, 0, 0)

	-- Apply bobbing and tilt without locking camera movement
	camera.CFrame = camera.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(WalkBobbing.X), math.rad(WalkBobbing.Y), math.rad(WalkBobbing.Z)) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(update.X))
end

local function createParticleParams()
	return {
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.9375, 0), 
			NumberSequenceKeypoint.new(1, 0.25, 0)
		},
		Color1 = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.513726, 0.513726, 0.513726))
		},
		Color2 = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.new(0.513726, 0.513726, 0.513726))
		},
		Texture = "rbxassetid://14198026924",
		EmissionDirection = Enum.NormalId.Back,
		Rotation = 180,
		Lifetime = NumberRange.new(0.9),
		Rate = 16,
		LightEmission = 0,
		LightInfluence = 1,
		Speed = NumberRange.new(5),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		TimeScale = 1
	}
end

local params = createParticleParams()
local particle1, particle2

local function createParticleEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	local part = Instance.new("Part")
	part.Parent = character
	part.Size = Vector3.new(4, 5.074, 3.391)
	part.CFrame = character:WaitForChild("HumanoidRootPart").CFrame
	part.Transparency = 1
	part.CanCollide = false
	part.Massless = true

	local weld = Instance.new("WeldConstraint")
	weld.Parent = character:WaitForChild("HumanoidRootPart")
	weld.Part0 = character:WaitForChild("HumanoidRootPart")
	weld.Part1 = part

	emitter.Orientation = params.Orientation
	emitter.Size = params.Size
	emitter.Color = color
	emitter.Texture = params.Texture
	emitter.EmissionDirection = params.EmissionDirection
	emitter.Rotation = NumberRange.new(params.Rotation)
	emitter.Lifetime = params.Lifetime
	emitter.Rate = params.Rate
	emitter.Parent = part
	emitter.LightEmission = params.LightEmission
	emitter.LightInfluence = params.LightInfluence
	emitter.Speed = params.Speed
	emitter.Shape = params.Shape
	emitter.ShapeInOut = params.ShapeInOut
	emitter.ShapeStyle = params.ShapeStyle
	emitter.TimeScale = params.TimeScale
	return emitter
end

local function playRunAnimation()
	isRunning = true
	lastRunTime = tick()

	humanoid.WalkSpeed = runWalkSpeed
	runAnimation:Play()

	if not particle1 then particle1 = createParticleEmitter(params.Color1) end
	if not particle2 then particle2 = createParticleEmitter(params.Color2) end

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fovTween = TweenService:Create(camera, tweenInfo, {FieldOfView = targetFOV})
	fovTween:Play()
end

local function stopRunAnimation()
	isRunning = false
	runAnimation:Stop()

	if particle1 then particle1:Destroy() particle1 = nil end
	if particle2 then particle2:Destroy() particle2 = nil end

	if not isCooldownActive then
		isCooldownActive = true
		humanoid.WalkSpeed = defaultWalkSpeed
		task.wait(cooldownDuration)
		isCooldownActive = false
	end
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		if not isRunning and not isCooldownActive and humanoid.MoveDirection.Magnitude > 0 then
			playRunAnimation()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		stopRunAnimation()
	end
end)

RunService.Stepped:Connect(function(deltaTime)
	if isRunning then
		local elapsed = tick() - lastRunTime
		if elapsed > boostDuration then
			humanoid.WalkSpeed = boostedRunWalkSpeed
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local fovTween = TweenService:Create(camera, tweenInfo, {FieldOfView = boostedFOV})
			fovTween:Play()
		end

		-- View Bobbing Effect
		updateCamera(deltaTime)
	end

	-- Stop animation if not moving
	if humanoid.MoveDirection.Magnitude == 0 and isRunning then
		stopRunAnimation()
	end

	-- Reset FOV when stopping
	if not isRunning and camera.FieldOfView ~= defaultFOV then
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fovResetTween = TweenService:Create(camera, tweenInfo, {FieldOfView = defaultFOV})
		fovResetTween:Play()
	end
end)

for i = 1, 10 do
	print("Initializing run system... Step " .. i)
	task.wait(0.1)
end
