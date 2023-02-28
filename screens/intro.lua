local intro = {}

local letter = Class("introletter")
function letter:initialize(x, y, i)
    self.x, self.y, self.i = x, y, i
    self.starty = y
    self.fy = self.y-20
    self.vy = -128
    self.static = false
end
function letter:update(dt)
    if not self.static then 
        self.vy = self.vy + 256*dt -- gravity
        self.y = self.y + self.vy*dt
        if self.vy > 0 and self.y >= self.fy then
            self.y = self.fy
            self.static = true
        end
    end
end
function letter:draw()
    love.graphics.draw(intro.titleimage, intro.titlequads[self.i], self.x, self.y)
end
function letter:allign()
    self.x = ((WIDTH/2)-48)+((self.i-1)*16)
    local changey = self.y-self.starty
    self.y = (HEIGHT/2)+10
    self.starty = self.y
    self.fy = self.y-20
    self.y = self.y+changey
end

--

function intro.load(last)
    love.graphics.setBackgroundColor(0,0,0)

    intro.titleimage = love.graphics.newImage(ENV.imagespath .. "/titleimage.png")
    intro.titlequads = {
        love.graphics.newQuad(0,  0,  14, 20, 96, 25),
        love.graphics.newQuad(16, 0,  14, 20, 96, 25),
        love.graphics.newQuad(32, 0,  14, 20, 96, 25),
        love.graphics.newQuad(48, 0,  14, 20, 96, 25),
        love.graphics.newQuad(64, 0,  14, 20, 96, 25),
        love.graphics.newQuad(80, 0,  16, 20, 96, 25),
        love.graphics.newQuad(0,  22, 96, 3,  96, 25),
    }
    
    intro.titlebg = love.graphics.newImage(ENV.imagespath .. "/titlebg.png")
    intro.generateSpriteBatch()

    intro.timer = 0
    intro.letters = {}
    intro.loading = false

    intro.state = "menu" --"game"
end

function intro.update(dt)
    intro.timer = intro.timer + dt
    local newest = math.ceil(intro.timer*6)
    if newest <= 6 then
        if newest > #intro.letters then
            table.insert(intro.letters, letter:new(((WIDTH/2)-48)+((newest-1)*16), (HEIGHT/2)+10, newest))
        end
    end
    for i, v in pairs(intro.letters) do
        v:update(dt)
    end
    if intro.timer >= 2 and (not intro.loading) then
        Screen:changeState(intro.state, {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
        intro.loading = true
    end
end

function intro.draw()
    local clock = (intro.timer*16) % 32
    love.graphics.draw(intro.titlebgspritebatch, -clock, -clock)
    love.graphics.draw(intro.titleimage, intro.titlequads[7], (WIDTH/2)-48, (HEIGHT/2)+12)
    love.graphics.setScissor(0, 0, WIDTH*SCALE, ((HEIGHT/2)+10)*SCALE)
    for i, v in pairs(intro.letters) do
        v:draw()
    end
    love.graphics.setScissor()
end

function intro.mousepressed(x, y, b)
    Screen:changeState(intro.state, {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
    intro.loading = true
end
function intro.keypressed(x, y, b)
    Screen:changeState(intro.state, {"fade", 0.5, {0,0,0}}, {"fade", 0.5, {0,0,0}})
    intro.loading = true
end

function intro.generateSpriteBatch()
    intro.titlebgspritebatch = love.graphics.newSpriteBatch(intro.titlebg, 1000)
    for x = 1, math.ceil(WIDTH/32)+1 do
        for y = 1, math.ceil(HEIGHT/32)+1 do
            intro.titlebgspritebatch:add((x-1)*32, (y-1)*32)
        end
    end
end

function intro.resize()
    intro.generateSpriteBatch()
    for i, v in pairs(intro.letters) do
        v:allign()
    end
end

return intro, true