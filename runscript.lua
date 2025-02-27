-- Get the local player and its character
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Create and load the running animation
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://" -- Insert animation ID here
local runAnimation = humanoid:LoadAnimation(anim)

-- Define movement speeds and timing for boosts and cooldowns
local defaultWalkSpeed = 16
local runWalkSpeed = 35
local boostedRunWalkSpeed = 53
local boostDuration = 5  -- Time before speed boost activates
local cooldownDuration = 3 -- Cooldown after stopping running

humanoid.WalkSpeed = defaultWalkSpeed -- Set default walking speed

-- Camera settings for FOV changes during running
local camera = game.Workspace.CurrentCamera
local defaultFOV = camera.FieldOfView
local targetFOV = defaultFOV + 20
local boostedFOV = defaultFOV + 50

-- Services required for animations and user input handling
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Track running state and cooldowns
local isRunning = false
local isCooldownActive = false
local lastRunTime = 0

-- Creates parameters for the running particle effect
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
		Rate = 16
	}
end

local params = createParticleParams()
local particle1, particle2

-- Creates a particle emitter attached to the player's character
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
	return emitter
end

-- Starts the running animation, increases speed, creates particles, and changes FOV
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

-- Stops the running animation, resets speed, removes particles, and resets FOV
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

-- Detects when the Left Shift key is pressed and starts running
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		if not isRunning and not isCooldownActive and humanoid.MoveDirection.Magnitude > 0 then
			playRunAnimation()
		end
	end
end)

-- Detects when the Left Shift key is released and stops running
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		stopRunAnimation()
	end
end)

-- Continuously checks running state, applies boost after duration, and resets FOV if needed
RunService.Stepped:Connect(function(deltaTime)
	if isRunning then
		local elapsed = tick() - lastRunTime
		if elapsed > boostDuration then
			humanoid.WalkSpeed = boostedRunWalkSpeed
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local fovTween = TweenService:Create(camera, tweenInfo, {FieldOfView = boostedFOV})
			fovTween:Play()
		end
	end

	-- Stops running if the player stops moving
	if humanoid.MoveDirection.Magnitude == 0 and isRunning then
		stopRunAnimation()
	end

	-- Resets FOV when not running
	if not isRunning and camera.FieldOfView ~= defaultFOV then
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fovResetTween = TweenService:Create(camera, tweenInfo, {FieldOfView = defaultFOV})
		fovResetTween:Play()
	end
end)
