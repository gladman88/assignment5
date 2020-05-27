--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerWalkWithPotState = Class{__includes = EntityWalkState}

function PlayerWalkWithPotState:init(player, room)
    self.entity = player
    self.room = room

    -- render offset for spaced character sprite
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerWalkWithPotState:enter(params)
	self.pot = params.pot
end

function PlayerWalkWithPotState:update(dt)
    if love.keyboard.isDown('left') then
        self.entity.direction = 'left'
        self.entity:changeAnimation('walk-with-pot-left',{
        	['pot'] = self.pot
        })
    elseif love.keyboard.isDown('right') then
        self.entity.direction = 'right'
        self.entity:changeAnimation('walk-with-pot-right',{
        	['pot'] = self.pot
        })
    elseif love.keyboard.isDown('up') then
        self.entity.direction = 'up'
        self.entity:changeAnimation('walk-with-pot-up',{
        	['pot'] = self.pot
        })
    elseif love.keyboard.isDown('down') then
        self.entity.direction = 'down'
        self.entity:changeAnimation('walk-with-pot-down',{
        	['pot'] = self.pot
        })
    else
        self.entity:changeState('pot-idle',{
        	['pot'] = self.pot
        })
    end
    
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        self.entity:changeState('pot-drop',{
        	['pot'] = self.pot
        })
    end

    -- perform base collision detection against walls
    EntityWalkState.update(self, dt)
    self:updateXYofPot(x,y)
    
    -- shift player down to the pot's height
    if self.entity.direction == 'up' then
        if self.entity.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2 + self.pot.height then 
            self.entity.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2 + self.pot.height
        end
    end
end

function PlayerWalkWithPotState:updateXYofPot()
	if self.pot then
		self.pot.x = self.entity.x
		self.pot.y = self.entity.y - self.pot.height + 7
	end
end