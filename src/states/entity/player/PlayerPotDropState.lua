--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerPotDropState = Class{__includes = BaseState}

function PlayerPotDropState:init(player, room)
    self.player = player
    self.room = room

    -- render offset for spaced character sprite
    self.player.offsetY = 5
    self.player.offsetX = 0
end

function PlayerPotDropState:enter(params)
	self.pot = params.pot
    
    self.player:changeAnimation('pot-drop-' .. self.player.direction)

    -- create hitbox based on where the player is and facing
    local direction = self.player.direction
    
	if direction == 'left' then
		newX = self.pot.x - TILE_SIZE * 4
		newY = self.pot.y
    elseif direction == 'right' then
		newX = self.pot.x + TILE_SIZE * 4
		newY = self.pot.y
    elseif direction == 'up' then
		newX = self.pot.x
		newY = self.pot.y - TILE_SIZE * 4
    else
		newX = self.pot.x
		newY = self.pot.y + TILE_SIZE * 4
    end
    
    self.pot:moveToXY(newX,newY,1,function() self.pot.onDestruction() end)
    --gSounds['sword']:stop()
    --gSounds['sword']:play()

    -- restart sword swing animation
    --self.player.currentAnimation:refresh()
end

function PlayerPotDropState:update(dt)

    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('idle')
    end

    --if love.keyboard.wasPressed('space') then
--        self.player:changeState('swing-sword')
--    end
end

function PlayerPotDropState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end