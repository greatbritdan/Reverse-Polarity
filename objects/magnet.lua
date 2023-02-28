P_MAGNET =  Class("magnet", P_PHYSICSOBJ)

function P_MAGNET:initialize(map, x, y, w, h, north, oneside, range, win)
    P_PHYSICSOBJ.initialize(self, map, x, y, w, h, {static=true})

    self.category = "magnet"
    self.mask = {}

    self.north = north
    self.south = reverseMagnet(north)

    self.range = range or 56
    self.oneside = oneside or false
    self.checktable = {"player", "cannonball"}

    self.win = win or false

    self:generateSpritebatch()
end

function P_MAGNET:update(dt)
    self:magnetupdate(dt)
end

function P_MAGNET:draw()
    love.graphics.draw(self.spritebatch, self.x, self.y)
    local icon = 1
    if self.win then icon = 2 end
    love.graphics.draw(Magneticonimg, Magneticonquads[icon], self.x+(self.w/2)-6, self.y+(self.h/2)-6)
end

function P_MAGNET:generateSpritebatch()
    local start, starty = false, 1
    -- ugh
    if self.north == "up"    then start = 1  end
    if self.north == "left"  then start = 4  end
    if self.north == "down"  then start = 7  end
    if self.north == "right" then start = 10 end
    if self.oneside == "south" then starty = 4 end
    if self.oneside == "north" then starty = 7 end

    -- TODO: many magnets use the same polarity/size, add a cache for magnet spritebatches for reuse?
    local w, h = math.ceil(self.w/8), math.ceil(self.h/8)
    self.spritebatch = love.graphics.newSpriteBatch(Magnetimg, w*h)

    for x = 1, w do
        for y = 1, h do
            local q = Magnetquads[start+1][starty+1]
            if x == 1 and y == 1 then
                q = Magnetquads[start][starty]
            elseif x == w and y == 1 then
                q = Magnetquads[start+2][starty]
            elseif x == 1 and y == h then
                q = Magnetquads[start][starty+2]
            elseif x == w and y == h then
                q = Magnetquads[start+2][starty+2]
            elseif y == 1 then
                q = Magnetquads[start+1][starty]
            elseif y == h then
                q = Magnetquads[start+1][starty+2]
            elseif x == 1 then
                q = Magnetquads[start][starty+1]
            elseif x == w then
                q = Magnetquads[start+2][starty+1]
            end
            self.spritebatch:add(q, (x-1)*8, (y-1)*8, 0, 1, 1)
        end
    end
end