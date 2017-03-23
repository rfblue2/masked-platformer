--------------------------------------------------------------------------------
--
-- player.lua
--
--------------------------------------------------------------------------------

local M = {}

function M.new(options)

  local instance = display.newGroup()

  local options = options or {}
  instance.speed = options.speed or 10
  instance.state = "idle" -- idle, run, jump_up, in_air, jump_down
  instance.dir = "right" -- facing left or right

  local imgPath = "assets/img/playerSheet.png"
  local imgData = require("assets.img.playerSheet").sheetData

  -- describes what frames belong to which animation sequence
  local spriteData = {
    {
      name = "idle_left",
      frames = { 1 }, -- TODO make a more interesting idle state with mult frames
      time = 500,
      loopCount = 0
    },
    {
      name = "idle_right",
      frames = { 2 }, -- TODO make a more interesting idle state with mult frames
      time = 500,
      loopCount = 0
    },
    {
      name = "jump_left_up",
      frames = { 3, 4, 5 },
      time = 500,
      loopCount = 1
    },
    {
      name = "jump_right_up",
      frames = { 8, 9, 10 },
      time = 500,
      loopCount = 1
    },
    {
      name = "in_air_left",
      frames = { 5 },
      time = 500,
      loopCount = 0
    },
    {
      name = "in_air_right",
      frames = { 10 },
      time = 500,
      loopCount = 0
    },
    {
      name = "jump_left_down",
      frames = { 5, 6, 7 },
      time = 500,
      loopCount = 1
    },
    {
      name = "jump_right_down",
      frames = { 10, 11, 12 },
      time = 500,
      loopCount = 1
    },
    {
      name = "push", -- TODO also needs a left/right
      frames = { 13, 14, 15, 16, 17, 18, 19, 20 },
      time = 500,
      loopCount = 0
    },
    {
      name = "run_left",
      frames = { 21, 22, 23, 24, 25, 26, 27, 28 },
      time = 500,
      loopCount = 0
    },
    {
      name = "run_right",
      frames = { 29, 30, 31, 32, 33, 34, 35, 36 },
      time = 500,
      loopCount = 0
    }
  }

  -- create the sprite and add it to the group
  local imgSheet = graphics.newImageSheet( imgPath, imgData )
  instance.sprite = display.newSprite( imgSheet, spriteData)
  instance:scale(0.75, 0.75) -- TODO scale actual sprite size, not in code
  instance:insert(instance.sprite)

  -- move "left" or "right"
  function instance:move(dir)
    if not dir then return end
    print("moving " .. dir)
    local vx, vy = instance:getLinearVelocity()
    if dir == "left" then--and math.abs(vx) < instance.speed then
      instance.dir = "left"
      instance:setLinearVelocity(-instance.speed, vy)
      instance:applyForce(-10000, 0, instance.x, instance.y)
    elseif dir == "right" then--and math.abs(vx) < instance.speed then
      instance.dir = "right"
      instance:setLinearVelocity(instance.speed, vy)
      instance:applyForce(10000, 0, instance.x, instance.y)
    end
    if instance.state ~= "in_air" and instance.state ~= "jump_up" then
      instance.state = "run"
    end
  end

  -- causes player to jump
  function instance:jump()
    print("jumping")
    instance.state = "jump_up"
    instance:applyLinearImpulse(0, -500, instance.x, instance.y)
  end

  local function spriteListener( event )

    local sprite = event.target  -- get the sprite

    -- jump ended
    if ( instance.state == "jump_up" and event.phase == "ended" ) then
      print("jump should end")
      instance.state = "in_air"
    elseif ( instance.state == "jump_down" and event.phase == "ended" ) then
      instance.state = "idle"
    end

  end
  instance.sprite:addEventListener( "sprite", spriteListener )

  -- update sprite sequences if necessary
  local update = function( event )
    local currentSeq = instance.sprite.sequence -- current sequence playing

    if instance.dir == "right" then
      if instance.state == "idle" and currentSeq ~= "idle_right" then
        instance.sprite:setSequence("idle_right")
      elseif instance.state == "run" and currentSeq ~= "run_right" then
        instance.sprite:setSequence("run_right")
      elseif instance.state == "jump_up" and currentSeq ~= "jump_right_up" then
        instance.sprite:setSequence("jump_right_up")
      elseif instance.state == "in_air" and currentSeq ~= "in_air_right" then
        instance.sprite:setSequence("in_air_right")
      elseif instance.state == "jump_down" and currentSeq ~= "jump_right_down" then
        instance.sprite:setSequence("jump_right_down")
      end
    elseif instance.dir == "left" then
      if instance.state == "idle" and currentSeq ~= "idle_left" then
        instance.sprite:setSequence("idle_left")
      elseif instance.state == "run" and currentSeq ~= "run_left" then
        instance.sprite:setSequence("run_left")
      elseif instance.state == "jump_up" and currentSeq ~= "jump_left_up" then
        instance.sprite:setSequence("jump_left_up")
      elseif instance.state == "in_air" and currentSeq ~= "in_air_left" then
        instance.sprite:setSequence("in_air_left")
      elseif instance.state == "jump_down" and currentSeq ~= "jump_left_down" then
        instance.sprite:setSequence("jump_left_down")
      end
    end

    instance.sprite:play()
  end
  Runtime:addEventListener( "enterFrame", update )

  -- TODO figure out what this does
  function instance:finalize()
    transition.cancel(self)
  end
  instance:addEventListener("finalize")

  return instance

end

return M
