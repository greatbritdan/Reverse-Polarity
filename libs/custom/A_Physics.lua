-- MADE BY AIDAN
-- A_Physics - a lightweight, simple physics system for platformers.
-- Requires: A_Utils

-- for spawning enemies when the come on camera
P_SPAWNER = Class("spawner")

function P_SPAWNER:initialize(map, x, y, w, h, obj, leniency)
    self.map = map
    self.x, self.y, self.w, self.h = x, y, w, h

    self.obj = obj
    self.leniency = leniency or 32
end

function P_SPAWNER:update(dt)
    if self.map:onCamera(self.x, self.y, self.w, self.h, self.leniency, self.leniency) then
        self.map:spawnObject(self.obj)
        self._delete = true
    end
end

--

-- all physics based objects are 
P_PHYSICSOBJ = Class("physicsobj")

function P_PHYSICSOBJ:initialize(map, x, y, w, h, e)
    self.map = map
    self.x, self.y, self.w, self.h = x, y, w, h
    self.vx, self.vy = 0, 0

    e = self:fixExtra(e)
    self.active, self.static, self.gravity = e.active, e.static, e.gravity
    self.category = "basic"
end

function P_PHYSICSOBJ:fixExtra(e)
    e = e or {}
    if not e.static  then e.static = false  end
    if not e.active  then e.active = true   end
    if not e.gravity then e.gravity = false end
    return e
end

function P_PHYSICSOBJ:magnetupdate(dt)
    for _, og in pairs(self.checktable) do
        if self.map.objects[og] then
            for i, v in pairs(self.map.objects[og]) do
                if (not v.dead) then
                    local ud, lr = (self.north == "up" or self.north == "down"), (self.north == "left" or self.north == "right")

                    -- calculates the range
                    local data, tx, ty, bx, by, w, h
                    if ud then
                        tx, ty, bx, by, w, h = self.x, self.y-self.range, self.x, self.y+self.h, self.w, self.range
                    else
                        tx, ty, bx, by, w, h = self.x-self.range, self.y, self.x+self.w, self.y, self.range, self.h
                    end

                    -- get direction, surface and movment from magnet and target
                    -- TODO: simplify more!
                    if aabb(tx, ty, w, h, v.x, v.y, v.w, v.h) then
                        if ud then
                            if (self.oneside ~= "south" and (self.north == "up" and (v.south == "down" or v.south == "all"))) or (self.oneside ~= "north" and (self.south == "up" and (v.north == "down" or v.north == "all"))) then
                                data = {dir="attract", surface="top", movement="down"}
                            elseif (self.oneside ~= "south" and (self.north == "up" and (v.north == "down" or v.north == "all"))) or (self.oneside ~= "north" and (self.south == "up" and (v.south == "down" or v.south == "all"))) then
                                data = {dir="repel", surface="top", movement="up"} 
                            end
                        else
                            if (self.oneside ~= "south" and (self.north == "left" and (v.south == "right" or v.south == "all"))) or (self.oneside ~= "north" and (self.south == "left" and (v.north == "right" or v.north == "all"))) then
                                data = {dir="attract", surface="left", movement="right"}
                            elseif (self.oneside ~= "south" and (self.north == "left" and (v.north == "right" or v.north == "all"))) or (self.oneside ~= "north" and (self.south == "left" and (v.south == "right" or v.south == "all"))) then
                                data = {dir="repel", surface="left", movement="left"} 
                            end
                        end
                    elseif aabb(bx, by, w, h, v.x, v.y, v.w, v.h) then
                        if ud then
                            if (self.oneside ~= "south" and (self.north == "down" and (v.south == "up" or v.south == "all"))) or (self.oneside ~= "north" and (self.south == "down" and (v.north == "up" or v.north == "all"))) then
                                data = {dir="attract", surface="bottom", movement="up"}
                            elseif (self.oneside ~= "south" and (self.north == "down" and (v.north == "up" or v.north == "all"))) or (self.oneside ~= "north" and (self.south == "down" and (v.south == "up" or v.south == "all"))) then
                                data = {dir="repel", surface="bottom", movement="down"} 
                            end
                        else
                            if (self.oneside ~= "south" and (self.north == "right" and (v.south == "left" or v.south == "all"))) or (self.oneside ~= "north" and (self.south == "right" and (v.north == "left" or v.north == "all"))) then
                                data = {dir="attract", surface="right", movement="left"}
                            elseif (self.oneside ~= "south" and (self.north == "right" and (v.north == "left" or v.north == "all"))) or (self.oneside ~= "north" and (self.south == "right" and (v.south == "left" or v.south == "all"))) then
                                data = {dir="repel", surface="right", movement="right"} 
                            end
                        end
                    end

                    -- if in a magnet
                    if data then
                        local speed = 1024
                        if data.dir == "repel" and data.surface ~= "bottom"  then
                            speed = 384
                        end
                        if data.movement == "left" then
                            v.vx = v.vx - speed*dt
                        elseif data.movement == "right" then
                            v.vx = v.vx + speed*dt
                        elseif data.movement == "up" then
                            v.vy = v.vy - speed*dt
                        elseif data.movement == "down" then
                            v.vy = v.vy + speed*dt
                        end
                        if self.win and v.win and (not v.won) and (not v.rotdir) and data.dir == "attract" then
                            v:win(self, data)
                        end
                    end
                    
                    -- handles entering, exiting and passive magnet behaviour
                    if (not v.inmagnet) and data then
                        if v.enteredmagnet then
                            v:enteredmagnet(self, data)
                        end
                        v.inmagnet = self
                    elseif v.inmagnet == self and (not data) then
                        v.inmagnet = false
                        if v.exitedmagnet then
                            v:exitedmagnet(self)
                        end
                    elseif v.passivemagnet and data then
                        v:passivemagnet(self, data)
                    end
                end
            end
        end
    end
end

function P_PHYSICSOBJ:magnetchanged() -- e.g. player changes rotation
    for _, og in pairs(self.checktable) do
        if self.map.objects[og] then
            for i, v in pairs(self.map.objects[og]) do
                if (not v.dead) and v.inmagnet == self then
                    v.inmagnet = false
                    if v.exitedmagnet then
                        v:exitedmagnet(self)
                    end
                end
            end
        end
    end
end

--

P_GROUND = Class("ground", P_PHYSICSOBJ)

function P_GROUND:initialize(map, x, y, w, h, semi)
    P_PHYSICSOBJ.initialize(self, map, "ground", x, y, w, h, {static = true})
    self.category = "ground"
    self.mask = {}

    if semi == "down" then
        self.platformdown = true 
    end
end

-- All ugly down here, don't look...

local objnamelist = {"magnet","spikes","cannon","cannonball","player","ground"}
local collisionCheck, collisionCheckPassive, collisionCheckBoth, collisionCheckHor, collisionCheckVer, collisionHandlePassive, collisionHandleHor, collisionHandleVer
function physicsUpdate(map, dt)
    local ogdt = dt
    for _, og1 in pairs(objnamelist) do
        if map.objects[og1] then
            for i1, v1 in pairs(map.objects[og1]) do
                if (not v1.static) and v1.active then
                    -- iterate multiple times to avoid clipping
                    local iter = v1.iter or math.max(2, math.ceil(((math.abs(v1.vx)+math.abs(v1.vy))/2)/100)) -- generates number of iterations based on average speed
                    if VSYNC then iter = iter*4 end
                    local dt = ogdt*(1/iter) -- modifies dt to be relative to iter
                    for t = 1, iter do
                        -- gravity
                        if v1.gravity then
                            v1.vy = v1.vy + v1.gravity * dt
                        end

                        -- handle collision
                        local horcol, vercol = false, false
                        for __, og2 in pairs(objnamelist) do
                            if map.objects[og2] then
                                for i2, v2 in pairs(map.objects[og2]) do
                                    if v1 ~= v2 and v2.active and (v1.mask == nil or v1.mask[v2.category] ~= true) and (v2.mask == nil or v2.mask[v1.category] ~= true) then
                                        local horcheck, vercheck = collisionCheck(og1, i1, v1, og2, i2, v2, dt)
                                    end
                                    if horcheck then horcol = true end
                                    if vercheck then vercol = true end
                                end
                            end
                        end

                        -- apply velocity & friction
                        -- x
                        if v1.horfriction then
                            if v1.vx > 0 then
                                v1.vx = math.max(0, v1.vx-v1.horfriction*dt)
                            else
                                v1.vx = math.min(0, v1.vx+v1.horfriction*dt)
                            end
                        end
                        if not horcol then
                            v1.x = v1.x + v1.vx*dt
                        end
                        
                        -- y
                        if v1.verfriction then
                            if v1.vy > 0 then
                                v1.vy = math.max(0, v1.vy-v1.verfriction*dt)
                            else
                                v1.vy = math.min(0, v1.vy+v1.verfriction*dt)
                            end
                        end
                        if not vercol then
                            v1.y = v1.y + v1.vy*dt
                            if v1.gravity and v1.vy == v1.gravity*dt and v1.startfall then
                                v1:startfall()
                            end
                        end

                        if horcol or vercol then
                            break
                        end
                    end
                end
            end
        end
    end
end

function collisionCheck(og1, i1, v1, og2, i2, v2, dt)
    -- are they far enough appart? don't bother
    if math.abs(v1.x - v2.x) > math.max(v1.w, v2.w)+1 or math.abs(v1.y - v2.y) > math.max(v1.h, v2.h)+1 then
        return false, false
    end

    local horcheck, vercheck = false, false
    if collisionCheckPassive(v1, v2) then
        vercheck = collisionHandlePassive(og1, i1, v1, og2, i2, v2, dt)

    elseif collisionCheckBoth(v1, v2, dt) then
        if collisionCheckHor(v1, v2, dt) then
            horcheck = collisionHandleHor(og1, i1, v1, og2, i2, v2, dt)

        elseif collisionCheckVer(v1, v2, dt) then
            vercheck = collisionHandleVer(og1, i1, v1, og2, i2, v2, dt)

        else 
            local g = v1.gravity or 0
            if math.abs(v1.vy-g*dt) < math.abs(v1.vx) then
                vercheck = collisionHandleVer(og1, i1, v1, og2, i2, v2, dt)
            else 
                horcheck = collisionHandleHor(og1, i1, v1, og2, i2, v2, dt)
            end
        end
    end
    return horcheck, vercheck
end

function collisionCheckPassive(v1, v2)
    return aabb(v1.x, v1.y, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h)
end
function collisionCheckBoth(v1, v2, dt)
    return aabb(v1.x+v1.vx*dt, v1.y+v1.vy*dt, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h)
end
function collisionCheckHor(v1, v2, dt)
    return aabb(v1.x+v1.vx*dt, v1.y, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h)
end
function collisionCheckVer(v1, v2, dt)
    return aabb(v1.x, v1.y+v1.vy*dt, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h)
end

function collisionHandlePassive(og1, i1, v1, og2, i2, v2, dt)
    if v2.platformup or v2.platformdown or v2.platformleft or v2.platformright then
        return false
    end
    if v1.passivecollide then
        v1:passivecollide(og2,v2)
        if v2.passivecollide then
            v2:passivecollide(og1,v1)
        end
    end
    return false
end
function collisionHandleHor(og1, i1, v1, og2, i2, v2, dt)
    if (v2.platformup or v2.platformdown) and not (v2.platformleft or v2.platformright) then
        return false
    end
    if v1.vx < 0 then
        if (not v2.rightcollide) or v2:rightcollide(og1,v1) then
            v2.vx = math.min(v2.vx, 0)
        end

        if v2.platformleft and (not v2.platformright) then
            return false
        end
        if (not v1.leftcollide) or v1:leftcollide(og2,v2) then
            v1.vx = math.max(0, v1.vx)
            v1.x = v2.x + v2.w
            return true
        end
    else
        if (not v2.leftcollide) or v2:leftcollide(og1,v1) then
            v2.vx = math.max(0, v2.vx)
        end

        if v2.platformright and (not v2.platformleft) then
            return false
        end
        if (not v1.rightcollide) or v1:rightcollide(og2,v2) then
            v1.vx = math.min(v1.vx, 0)
            v1.x = v2.x - v1.w
            return true
        end
    end
    return false
end
function collisionHandleVer(og1, i1, v1, og2, i2, v2, dt)
    if (v2.platformleft or v2.platformright) and not (v2.platformup or v2.platformdown) then
        return false
    end
    if v1.vy < 0 then
        if (not v2.floorcollide) or v2:floorcollide(og1,v1) then
            v2.vy = math.min(v2.vy, 0)
        end

        if v2.platformdown and (not v2.platformup) then
            return false
        end
        if (not v1.ceilcollide) or v1:ceilcollide(og2,v2) then
            v1.vy = math.max(0, v1.vy)
            v1.y = v2.y + v2.h
            return true
        end
    else
        if (not v2.ceilcollide) or v2:ceilcollide(og1,v1) then
            v2.vy = math.max(0, v2.vy)
        end

        if v2.platformup and (not v2.platformdown) then
            return false
        end
        if (not v1.floorcollide) or v1:floorcollide(og2,v2) then
            v1.vy = math.min(v1.vy, 0)
            v1.y = v2.y - v1.h
            return true
        end
    end
    return false
end

-- check for collisons, useful for predicting the future. :mmaker:
function collidecheck(map, v, list, inclidesemi, x, y, w, h)
    x, y, w, h = x or v.x, y or v.y, w or v.w, h or v.h
    local out = {}
    
    for og1, ol1 in pairs(map.objects) do
        local contains = false
        if list and list ~= "all" then	
            contains = tablecontains(list, og1)
        end

        if list == "all" or contains then
            for i1, v1 in pairs(ol1) do
                if (v ~= v1) and v1.active and ((not v1.static) or list ~= "all") then
                    if aabb(x, y, w, h, v1.x, v1.y, v1.w, v1.h) and (inclidesemi or (not (v1.platformup or v1.platformdown or v1.platformleft or v1.platformright))) then
                        table.insert(out, {og1, v1})
                    end
                end
            end
        end
    end

    return out
end