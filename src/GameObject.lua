--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def, x, y)
    -- string identifying this object type
    self.type = def.type

    self.texture = def.texture
    self.frame = def.frame or 1

    -- whether it acts as an obstacle or not
    self.solid = def.solid

    self.defaultState = def.defaultState
    self.state = self.defaultState
    self.states = def.states or {}

    -- dimensions
    self.x = x
    self.y = y
    self.width = def.width
    self.height = def.height

    -- default empty collision callback
    self.onCollide = function() end
    
    -- consumable or not
    self.consumable = def.consumable or false
    self.onConsume = function() end
    
    self.movable = def.movable or false
    self.onTouchingWall = function() end
    
    self.destroyable = def.destroyable or false
    self.onDestruction = function() end

	-- flags for flashing the entity when hit
    self.flashing = false
    self.flashingDuration = 0
    self.flashTimer = 0
    
    -- we will use it in case if we want interrupt function moteToXY
    self.tween = nil
end

function GameObject:update(dt)
    if self.flashing then
        self.flashTimer = self.flashTimer + dt

        if self.flashTimer > self.flashingDuration then
            self.flashing = false
            self.flashTimer = 0
            self.flashingDuration = 0
        end
    end
    
	if self.movable then
		local tochedWall = false
	
		if self.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then 
			self.x = MAP_RENDER_OFFSET_X + TILE_SIZE
			tochedWall = true
		end
		if self.x + self.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
			self.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.width
			tochedWall = true
		end

		if self.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2 then 
			self.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2
			tochedWall = true
		end

		local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
			+ MAP_RENDER_OFFSET_Y - TILE_SIZE

		if self.y + self.height >= bottomEdge then
			self.y = bottomEdge - self.height
			tochedWall = true
		end
		
		if tochedWall then
			self.onTouchingWall()	
		end
	end
end

function GameObject:moveToXY(newX,newY,time,callback)
	self.tween = Timer.tween(time, {
		-- Vehicle's fuel is depleted as it moves from left to right
		[self] = { x = newX, y = newY },
	}):finish(function()
		-- call function from current object when timer finish
		callback()
		self.tween = nil
	end)
end

function GameObject:flashingOn(duration)
    self.flashing = true
    self.flashingDuration = duration
end

function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    if self.flashing and self.flashTimer > 0.06 then
        self.flashTimer = 0
        love.graphics.setColor(255, 255, 255, 64)
    end
    
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.state and self.states[self.state].frame or self.frame],
        self.x + adjacentOffsetX, self.y + adjacentOffsetY)
end