P_SPIKES =  Class("spikes", P_PHYSICSOBJ)

function P_SPIKES:initialize(map, x, y, w)
    P_PHYSICSOBJ.initialize(self, map, x, y, w, 8, {static=true})

    self.category = "spikes"

    self:generateSpritebatch()
end

function P_SPIKES:generateSpritebatch()
    self.spritebatch = love.graphics.newSpriteBatch(Spikesimg, math.ceil(self.w/16))
    for i = 1, math.ceil(self.w/16) do
        self.spritebatch:add((i-1)*16, 0, 0, 1, 1)
    end
end

function P_SPIKES:draw()
    love.graphics.draw(self.spritebatch, self.x, self.y)
end

-- collision handled by player