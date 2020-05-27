--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)

    -- reference to player for collisions, etc.
    self.player = player
    
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    self.tiles = {}
    self:generateWallsAndFloors()

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects()

    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

--[[
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()
    local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

    for i = 1, 10 do
        local type = types[math.random(#types)]
        
		while (not entityX and not entityY) or 
				(entityX >= self.player.x - TILE_SIZE and entityY >= self.player.y - TILE_SIZE and 
				entityX <= self.player.x + self.player.width + TILE_SIZE and 
				entityY <= self.player.y + self.player.height + TILE_SIZE) do
		
			entityX = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
						VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
			entityY = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
						VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
		end

        table.insert(self.entities, Entity {
            animations = ENTITY_DEFS[type].animations,
            walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

            -- ensure X and Y are within bounds of the map
            x = entityX,
            y = entityY,
            
            width = 16,
            height = 16,

            health = 1
        })

        self.entities[i].stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(self.entities[i],self) end,
            ['idle'] = function() return EntityIdleState(self.entities[i]) end
        }

        self.entities[i]:changeState('walk')
        
        entityX = nil
        entityY = nil
    end
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects()

	while (not switchX and not switchY) or 
    		(switchX >= self.player.x - TILE_SIZE * 2 and switchY >= self.player.y - TILE_SIZE * 2 and 
    		switchX <= self.player.x + TILE_SIZE * 3 and 
    		switchY <= self.player.y + TILE_SIZE * 3) do
    	
    	switchX = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
    	switchY = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    end

	local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        switchX,
        switchY
    )
    -- define a function for the switch that will open all doors in the room
    switch.onCollide = function(entity)
    	if entity == self.player then
			if switch.state == 'unpressed' then
				switch.state = 'pressed'
			
				-- open every door in the room if we press the switch
				for k, doorway in pairs(self.doorways) do
					doorway.open = true
				end

				gSounds['door']:play()
			end
        end
    end
	
    table.insert(self.objects, switch)
    
    while (not potX and not potY) or 
    		(potX >= switch.x and potY >= switch.y and 
    		potX <= switch.x + TILE_SIZE and potY <= switch.y + TILE_SIZE) or 
    		(potX >= self.player.x - TILE_SIZE * 2 and potY >= self.player.y - TILE_SIZE * 2 and 
    		potX <= self.player.x + TILE_SIZE * 3 and 
    		potY <= self.player.y + TILE_SIZE * 3) do
    	potX = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
    	potY = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    end
    
	local pot = GameObject(
        GAME_OBJECT_DEFS['pot'],
        potX,
        potY
    )
    -- define a function for the pot if needed
    pot.onCollide = function(entity)
    	if pot.tween then
    		if entity ~= self.player then
				entity:damage(1)
				gSounds['hit-enemy']:play()
				pot.onDestruction()
				pot.tween:remove()
				pot.tween = nil
			end
	   	end
    end
    
    -- define a function for the pot if needed
    pot.onDestruction = function()
        if pot.state == 'unbroken' then
            pot.state = 'broken'
            gSounds['hit-enemy']:play()
            pot:flashingOn(1)
            Timer.after(1, function()
				for k,obj in pairs(self.objects) do
					if obj == pot then
						table.remove(self.objects,k)
					end
				end            	
            end)
        end        
    end
    -- define a function for the pot if needed
    pot.onTouchingWall = function()
    	pot.onDestruction()
    end
	
    table.insert(self.objects, pot)
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateHeart(x,y)
	if self.player.direction == "down" then
        y = self.player.y + self.player.height
    elseif self.player.direction == "up" then
        y = self.player.y - 1 - GAME_OBJECT_DEFS['heart'].height
    elseif self.player.direction == "left" then
        x = self.player.x - 1 - GAME_OBJECT_DEFS['heart'].width
    elseif self.player.direction == "right" then
        x = self.player.x + self.player.width
    end
    
	local heart = GameObject(
        GAME_OBJECT_DEFS['heart'],
        x,
        y
    )
    
    -- define a function for the heart that will restore 2 health of player
    heart.onConsume = function()
    	self.player:heal(2)
    end
    
    table.insert(self.objects, heart)
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:update(dt)
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 then
        	if not entity.dead then
            	entity.dead = true
            	if math.random(5) == 1 then
            		self:generateHeart(entity.x,entity.y)
            	end
            end
        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
        
        
    end

    for k, object in pairs(self.objects) do
        object:update(dt)
    end
end

function Room:flyingPotHandler()

end

function Room:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

	local pot = nil
	
    for k, object in pairs(self.objects) do
    	if object.type == "pot" then
    		 pot = object
    	end
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - 6,
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()
    
    if pot and (self.player.currentAnimation.texture == "character-pot-lift" or  
    	self.player.currentAnimation.texture == "character-walk-with-pot") then
        pot:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end
end