-- Normal Ground

P_GROUND =  Class("ground", P_PHYSICSOBJ)

function P_GROUND:initialize(map, x, y, w, h, semi)
    P_PHYSICSOBJ.initialize(self, map, x, y, w, h, {static=true})

    self.category = "ground"

    self.platformup, self.platformdown = (semi == "up"), (semi == "down")
    self.platformleft, self.platformright = (semi == "left"), (semi == "right")
end

-- Breakable

P_BREABALE =  Class("breakable", P_PHYSICSOBJ)

function P_BREABALE:initialize(map, x, y, w, h, semi)
    P_PHYSICSOBJ.initialize(self, map, x, y, w, h, {static=true})

    self.category = "ground"
end

function P_BREABALE:collide(a, b, side)
    if a == "cannonball" then
        for x = 1, self.w/16 do
            for y = 1, self.h/16 do
                local tx, ty = self.map:objectToTile(self.x+((x-1)*16), self.y+((y-1)*16))
                local tsn, tid = self.map:getTile(tx,ty,"main")
                if tid then -- nice
                    self.map:clearTile(tx,ty,"main")
                    neweffect("brickl", self.x+((x-1)*16)+4,  self.y+((y-1)*16)+4)
                    neweffect("brickl", self.x+((x-1)*16)+4,  self.y+((y-1)*16)+12)
                    neweffect("brickr", self.x+((x-1)*16)+12, self.y+((y-1)*16)+4)
                    neweffect("brickr", self.x+((x-1)*16)+12, self.y+((y-1)*16)+12)
                end
            end
        end
        self.map:generateSpritebatch()
        self._delete = true
        b.disable = true
        playsound(Breaksound)
    end
end
function P_BREABALE:leftcollide(a, b)
    self:collide(a, b, "left")
    return false
end
function P_BREABALE:rightcollide(a, b)
    self:collide(a, b, "right")
    return false
end
function P_BREABALE:floorcollide(a, b)
    self:collide(a, b, "floor")
    return false
end
function P_BREABALE:ceilcollide(a, b)
    self:collide(a, b, "ceil")
    return false
end

-- Platform

P_PLATFORM =  Class("platform", P_PHYSICSOBJ)

function P_PLATFORM:initialize(map, x, y, w, h, semi)
    P_PHYSICSOBJ.initialize(self, map, x, y, w, h)

    self.category = "ground"

    self.platformup, self.platformdown = (semi == "up"), (semi == "down")
    self.platformleft, self.platformright = (semi == "left"), (semi == "right")

    self.vy = -64
    self.checktable = {"player"}

    self:generateSpritebatch()
end

function P_PLATFORM:generateSpritebatch()
    self.spritebatch = love.graphics.newSpriteBatch(Platformimg, math.ceil(self.w/16))
    for i = 1, math.ceil(self.w/16) do
        self.spritebatch:add((i-1)*16, 0, 0, 1, 1)
    end
end

function P_PLATFORM:update(dt)
    local xdiff, ydiff = self.vx*dt, self.vy*dt
    local includesemi = (ydiff > 0)
    for _, og in pairs(self.checktable) do
        for i, v in pairs(self.map.objects[og]) do
            -- between left and right side, same y or between y+1 and y-1, not jumping and not moving away from eachover
            if (v.x > self.x-v.w and v.x < self.x+self.w) and ((v.y == self.y-v.h) or (self.vy ~= 0 and v.y+v.h >= self.y-2 and v.y+v.h < self.y+2)) and (not v.jumping) and (not (self.vy > 0 and v.vy < 0)) then
                -- check collision with ground
                if #collidecheck(self.map, v, {"ground"}, includesemi, v.x+xdiff, self.y-v.h) == 0 then
                    v.x, v.y = v.x+xdiff, self.y-v.h
                    v.vy = self.vy
                    v.falling = false
                end
            end
            -- pushing from sides
            if xdiff ~= 0 then
                if v.y+v.h/2 > self.y and v.y+v.h/2 < self.y+self.h then
                    -- check collision with walls
                    if xdiff > 0 and v.x < self.x+self.w and v.x+v.w > self.x+self.w then
                        if #collidecheck(self.map, v, {"ground"}, includesemi, self.x+self.w, v.y) == 0 then
                            v.x = self.x+self.w
                        end
                    elseif xdiff < 0 and v.x+v.w > self.x and v.x < self.x then
                        if #collidecheck(self.map, v, {"ground"}, includesemi, self.x-v.w, v.y) == 0 then
                            v.x = self.x-v.w
                        end
                    end
                end
            end
        end
    end

    if self.y <= -self.h then
        self.y = MAPHEIGHT*16
    end
end

function P_PLATFORM:draw()
    love.graphics.draw(self.spritebatch, self.x, self.y)
end

function P_PLATFORM:floorcollide(a, b)
    if a == "player" then
        return false
    end
    return true
end
function P_PLATFORM:ceilcollide(a, b)
    if a == "player" then
        return false
    end
    return true
end
function P_PLATFORM:leftcollide(a, b)
    if a == "player" then
        return false
    end
    return true
end
function P_PLATFORM:rightcollide(a, b)
    if a == "player" then
        return false
    end
    return true
end