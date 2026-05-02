local stator, rotor

local cx, cy
local angle = 0
local angularVelocity = 0

local dragging = false
local lastMouseAngle = 0

-- valeurs par défaut
local config = {
    friction = 1.5,
    snapSpeed = 10,
    fullscreen = false,
--  stator:getWidth(), stator:getHeight() ?

    width =  794;
    height = 1123,
    stretch = true
}

local snapSegments = 32

-- =========================
-- Lecture config ASCII
-- =========================
local function parseValue(v)
    if v == "true" then return true end
    if v == "false" then return false end
    local n = tonumber(v)
    if n then return n end
    return v
end

local function loadConfig(filename)
    if not love.filesystem.getInfo(filename) then
        print("Config file not found, using defaults")
        return
    end

    for line in love.filesystem.lines(filename) do
        local key, value = line:match("^(%w+)%s*=%s*(.+)$")
        if key and value then
            config[key] = parseValue(value)
        end
    end
end

-- =========================
-- Utils angle souris
-- =========================
local function getMouseAngle(x, y)
    return math.atan2(y - cy, x - cx)
end

-- =========================
-- LOVE LOAD
-- =========================
function love.load()
    loadConfig("config.cfg")

    love.window.setMode(
        config.width,
        config.height,
        { fullscreen = config.fullscreen }
    )

    stator = love.graphics.newImage("stator.jpg")
    rotor  = love.graphics.newImage("rotor.png")

    cx = love.graphics.getWidth() / 2
--cx=386
  cy = 0+love.graphics.getHeight() / 2
 -- cy= 432
end

-- =========================
-- INPUT
-- =========================
function love.mousepressed(x, y, button)
    if button == 1 then
        dragging = true
        angularVelocity = 0
        lastMouseAngle = getMouseAngle(x, y)
    end
end


function love.keypressed(key, unicode)
	if key == "escape" then
		love.event.quit()
	end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        dragging = false
    end
end

-- =========================
-- UPDATE
-- =========================
function love.update(dt)
    local mx, my = love.mouse.getPosition()

    if dragging then
        local currentAngle = getMouseAngle(mx, my)
        local delta = currentAngle - lastMouseAngle

        if delta > math.pi then delta = delta - 2 * math.pi end
        if delta < -math.pi then delta = delta + 2 * math.pi end

        angle = angle + delta
        angularVelocity = delta / dt

        lastMouseAngle = currentAngle
    else
        if math.abs(angularVelocity) > 0.005 then
            angle = angle + angularVelocity * dt
            angularVelocity = angularVelocity * math.exp(-config.friction * dt)
        else
            angularVelocity = 0

            local segmentAngle = (2 * math.pi) / snapSegments
            local target = math.floor((angle / segmentAngle) + 0.5) * segmentAngle

            angle = angle + (target - angle) * math.min(config.snapSpeed * dt, 1)
        end
    end
end

-- =========================
-- DRAW
-- =========================
function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    local sw, sh = stator:getWidth(), stator:getHeight()
    local rw, rh = rotor:getWidth(), rotor:getHeight()

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local scaleX, scaleY = 1, 1

    if config.stretch then
        scaleX = screenW / sw
        scaleY = screenH / sh
    end

    -- stator
    love.graphics.draw(
        stator,
       -- cx, cy +1.5, pour OK.
        cx, cy +0,
        0,
        scaleX, scaleY,
        sw / 2,
        sh / 2
    )

    -- rotor (même scale que stator pour cohérence)
    love.graphics.draw(
        rotor,
        cx, cy-0,
        angle,
        scaleX, scaleY,
        rw / 2,
        -2+rh / 2
    )
end