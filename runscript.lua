local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local anim = Instance.new("Animation")
anim.AnimationId = "" -- Insert your running/boosting animation here

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

local function playRunAnimation()
	print("Playing run animation")
	isRunning = true
	lastRunTime = tick()

	humanoid.WalkSpeed = runWalkSpeed
	runAnimation:Play()

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fovTween = TweenService:Create(camera, tweenInfo, {FieldOfView = targetFOV})

	fovTween:Play()
end

local function stopRunAnimation()
	isRunning = false
	runAnimation:Stop()

	if not isCooldownActive then
		isCooldownActive = true
		humanoid.WalkSpeed = defaultWalkSpeed

		task.wait(cooldownDuration)
    
		isCooldownActive = false
	end
end

UserInputService.InputBegan:Connect(
	function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
			if not isRunning and not isCooldownActive and humanoid.MoveDirection.Magnitude > 0 then
				playRunAnimation()
			end
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
			stopRunAnimation()
		end
	end
)

RunService.Heartbeat:Connect(
	function()
		if isRunning then
			local elapsed = tick() - lastRunTime
			print("Elapsed time: " .. elapsed)

			if elapsed > boostDuration then
				humanoid.WalkSpeed = boostedRunWalkSpeed

				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local fovTween = TweenService:Create(camera, tweenInfo, {FieldOfView = boostedFOV})

				fovTween:Play()
			end
		else
	
			runAnimation:Stop()
		end
		if humanoid.MoveDirection.Magnitude == 0 and isRunning then
			stopRunAnimation()
		end


		if not isRunning and camera.FieldOfView ~= defaultFOV then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local fovResetTween = TweenService:Create(camera, tweenInfo, {FieldOfView = defaultFOV})
			fovResetTween:Play()
		end
	end
)
