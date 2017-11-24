--------------------------------------------------------------------------------
--
-- level1.lua
--
--------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
local playerFactory = require "player"
local player

--------------------------------------------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local keyUpDown = false
local keyLeftRightDown = false

--
-- Check that the current platform provides key events
--
if not system.hasEventSource( "key" ) then
	msg = display.newText( "Key events not supported on this platform", centerX, centerY - 100, native.systemFontBold, 13 )
	msg.x = display.contentWidth/2      -- center title
	msg:setFillColor( 1,0,0 )
end

--------------------------------------------------------------------------------
-- The Key Event Listener
-- For computer debugging
--------------------------------------------------------------------------------
local function onKeyEvent( event )
	-- Print which key was pressed down/up to the log.
	-- Check event.keyName and event.phase (eg up, down)

	-- up/down/left/right up/down
	if event.keyName == "up" then
		if event.phase == "down" and player.canJump > 0 then -- check > 0 so doesn't jump in air
			keyUpDown = true
			player:jump()
		elseif event.phase == "up" then
			keyUpDown = false
		end
	elseif event.keyName == "left" or event.keyName == "right" then
		if event.phase == "down" then
			keyLeftRightDown = true
			player:move(event.keyName)
		elseif event.phase == "up" then
			keyLeftRightDown = false
		end
		if not keyLeftRightDown then
	    if player.state ~= "in_air" then
	      player.state = "idle"
	    end
			local vx, vy = player:getLinearVelocity()
			player:setLinearVelocity(0, vy)
		end
	end

	-- Return false to indicate that this app is *not* overriding the received key.
	-- This lets the operating system execute its default handling of this key.
	return false
end

--------------------------------------------------------------------------------
-- Called when the scene's view does not exist.
--------------------------------------------------------------------------------
function scene:create( event )

	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view

	-- We need physics started to add bodies, but we don't want the simulaton
	-- running until the scene is on the screen.
	physics.start()
	physics.pause()
	physics.setDrawMode("hybrid") -- Allows viewing outlines for collision
	physics.setGravity(0, 20)

--------------------------------------------------------------------------------
	-- create a grey rectangle as the backdrop
	-- the physical screen will likely be a different shape than our defined content area
	-- since we are going to position the background from it's top, left corner, draw the
	-- background at the real top, left corner.
	local background = display.newRect( display.screenOriginX, display.screenOriginY, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( .5 )
--------------------------------------------------------------------------------
	-- make a crate (off-screen), position it, and rotate slightly
	local crate = display.newImageRect( "assets/img/crate.png", 90, 90 )
	crate.x, crate.y = 200, -100
	crate.rotation = 15

	-- add physics to the crate
	physics.addBody( crate, { density=1.0, friction=0.5, bounce=0.3 } )
--------------------------------------------------------------------------------
	-- create a grass object and add physics (with custom shape)
	local grass = display.newImageRect( "assets/img/grass.png", screenW, 82 )
	grass.anchorX = 0
	grass.anchorY = 1
	--  draw the grass at the very bottom of the screen
	grass.x, grass.y = display.screenOriginX, display.actualContentHeight + display.screenOriginY

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local grassShape = { -halfW,-34, halfW,-34, halfW,34, -halfW,34 }
	physics.addBody( grass, "static", { friction=0.5, shape=grassShape } )
--------------------------------------------------------------------------------
	-- make crates to block player from falling
	local crate1 = display.newImageRect( "assets/img/crate.png", 90, 90 )
	crate1.x, crate1.y = display.screenOriginX - 45, grass.y - grass.height/2 - 90
	physics.addBody( crate1, "static", { friction=0.7 })
	local crate2 = display.newImageRect( "assets/img/crate.png", 90, 90 )
	crate2.x, crate2.y = display.screenOriginX + screenW + 45, grass.y - grass.height/2 - 90
	physics.addBody( crate2, "static", { friction=0.7 })
--------------------------------------------------------------------------------
	player = playerFactory.new({
		speed = 300
	})
	player.x, player.y = 30, 50

	-- also adds a foot sensor
	local playerW, playerH = player.width, player.height
	physics.addBody( player, "dynamic", {
		density = 2.0,
		friction = 0.5,
		bounce = 0.1,
		shape = {
			-playerW/2*3/4, -playerH/2*3/4,
			-playerW/2*3/4, playerH/2 - 10,
			playerW/2*3/4, -playerH/2*3/4,
			playerW/2*3/4, playerH/2 - 10
		}
	}, {
		shape = {20,0,20,playerH/2+10,-20,playerH/2+10,-20,0},
		isSensor = true
	} )
	player.isFixedRotation = true -- ensures player does not rotate dynamically
	player.canJump = 0

	player.collision = function( self, event )
		if ( event.selfElement == 2 ) then -- foot sensor is element 2
      if ( event.phase == "began" ) then
				print("begin collision")
				if player.state == "in_air" then
					player.state = "jump_down"
				end
        self.canJump = self.canJump + 1
      elseif ( event.phase == "ended" ) then
        self.canJump = self.canJump - 1
				print("end collision, canjump " .. self.canJump)
				if self.canJump == 0 and player.state ~= "jump_up" then
					print("should be falling through air")
					player.state = "in_air"
				end
      end
    end
		-- if (event.phase == "began" and event.other == grass) then
		-- 	player.state = "landing"
		-- end
	end

	player:addEventListener("collision")
--------------------------------------------------------------------------------
	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert( grass )
	sceneGroup:insert( player )
	-- sceneGroup:insert( crate )
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		-- Add the key callback
		Runtime:addEventListener( "key", onKeyEvent );
		physics.start()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function scene:hide( event )
	local sceneGroup = self.view

	local phase = event.phase

	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view

	package.loaded[physics] = nil
	physics = nil
end

--------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

--------------------------------------------------------------------------------

return scene
