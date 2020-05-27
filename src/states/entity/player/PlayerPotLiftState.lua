--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerPotLiftState = Class{__includes = BaseState}

function PlayerPotLiftState:init(player, room)
    self.player = player
    self.room = room
    
    -- get the pot from room's objects
    self.pot = nil
    for k, obj in pairs(room.objects) do
    	if obj.type == 'pot' then
    		self.pot = obj
    	end
    end

    -- render offset for spaced character sprite
    self.player.offsetY = 5
    self.player.offsetX = 0
end

function PlayerPotLiftState:enter(params)
    --gSounds['sword']:stop()
    --gSounds['sword']:play()

    -- restart sword swing animation
    --self.player.currentAnimation:refresh()
    
    local direction = self.player.direction
    local potNear = false
    
    -- if pot close to player set flag potNear
	if self.pot then
		if direction == 'left' and self.player.x == self.pot.x + self.pot.width then
			potNear = true
		elseif direction == 'right' and self.player.x == self.pot.x - self.player.width then
			potNear = true
		elseif direction == 'up' and self.player.y == self.pot.y + self.pot.height - self.player.height / 2 then
			potNear = true
		elseif self.player.y == self.pot.y - self.player.height then
			potNear = true
		end	
	end

--    self.swordHitbox = Hitbox(hitboxX, hitboxY, hitboxWidth, hitboxHeight)
	if potNear then
    	self.player:changeAnimation('pot-lift-' .. self.player.direction)
    	self.pot.x = self.player.x
    	self.pot.y = self.player.y - self.pot.height + 7
    	self.pot.solid = false
    else
    	self.player:changeState('idle')
    end
end

function PlayerPotLiftState:update(dt)
    -- check if hitbox collides with any entities in the scene
    --for k, entity in pairs(self.room.entities) do
--        if entity:collides(self.swordHitbox) then
--            entity:damage(1)
--            gSounds['hit-enemy']:play()
--        end
--    end

    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('pot-idle',{
        	['pot'] = self.pot
        })
    end

    --if love.keyboard.wasPressed('space') then
--        self.player:changeState('swing-sword')
--    end
end

function PlayerPotLiftState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end