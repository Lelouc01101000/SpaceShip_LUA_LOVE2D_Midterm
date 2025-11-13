--[[
game is a space shooter, it uses assets from or inspired by manga called Shimeji Simulation, written by author named Tsukumizu

press SPACE key to destroy meteors by shooting laser before they collide with you, use arrow keys to move

There are four classes, Player which is main sprite controller by play, Meteor which are obsticles that kill player on collision,
Laser which is projectile shot by player that destroys meteor on collision, AnimatedExplosion which is animation that
plays when meteor is exploded.

game also has score system which gets incremented based on time and based on meteors destroyed.

collision system is pixel exact, this is to better handle player sprite which is not rectangular shape, instead being T shaped,
and to better handle rotating meteors which also are not rectangular or circular, and are rotating.

game also has game over screen where score and survival time is displayed along with restart button which just restarts the game


requirments:
1)A playable character that can move(Don’t forget to normalize the diagonal movement!). --> implemented, diagonal movement is normalised
2)At least 3 different objects(make sure you define them as separate classes).          --> implemented, Player, Laser, Meteor, AnimatedExplosion classes
3)An animation made with a split multiple-frame sprite.                                 --> implemented, AnimatedExplosion class uses multiple frames for explosion animation
4)Collisions between at least two different objects.                                    --> implemented, player vs meteor collision kills player, laser vs meteor collision kills meteor, player also cant leave borders of the screen
]]




------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Player = {}
Player.__index = Player

function Player:new(x, y, img, imgData)
    --[[
    this class defines player, it should be able to move based on inputs and to shoot laser
    Parameters:
        x - X coordinate
        y - Y coordinate
        img - image which should be displayed as player sprite
        imgData - information about each pixel of png img which will be used in pixel precise collision
    Variables:
        width - width of img sprite, used to check rectangular collision before moving to pixel precise one
        height - height of img sprite, used to check rectangular collision before moving to pixel precise one
        speed - speed at which player will move
        canShoot - control boolean variable, it will be false when shooting is on cooldown, must be defined as true
        cooldownDuration - cooldown for laser shot, player should wait that amount of time after each shot to shoot again
        laserShootTime - control variable, will be ticked down each delta time untill cooldownDuration passes, must be defined as 0
    ]]
    local self = setmetatable({}, Player)
    self.image = img
    self.imageData = imgData 
    self.x = x
    self.y = y
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.speed = 300

    -- cooldown for laser shot
    self.canShoot = true
    self.cooldownDuration = 0.35 -- 350 ms
    self.laserShootTime = 0
    
    return self
end

function Player:update(dt) -- will update Player sprite and execute each delta time
    -- movement logic
    local dx, dy = 0, 0
    if love.keyboard.isDown('right') then dx = 1 end
    if love.keyboard.isDown('left') then dx = -1 end
    if love.keyboard.isDown('down') then dy = 1 end
    if love.keyboard.isDown('up') then dy = -1 end
    --------------------------------------------------

    -- normalizing diagonal movement
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
        dx = dx / length
        dy = dy / length
    end
    --------------------------------------------------

    -- applying movement by modifying class variables
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
    --------------------------------------------------

    -- making sure player stays on screen, so they dont leave borders of the game
    self.x = math.max(self.width / 2, math.min(WINDOW_WIDTH - self.width / 2, self.x))
    self.y = math.max(self.height / 2, math.min(WINDOW_HEIGHT - self.height / 2, self.y))
    ---------------------------------------------------------------------------------------

    -- check for cooldown if its on cooldown (meaning if canShoot is false)
    if not self.canShoot then 
        self.laserShootTime = self.laserShootTime - dt -- decrement laserShootTime each delta time
        if self.laserShootTime <= 0 then -- when laserShootTime is 0 we can shoot
            self.canShoot = true
        end
    end
end

function Player:shoot()
    if self.canShoot then
        -- creating new laser infront of player
        table.insert(lasers, Laser:new(self.x, self.y - self.height / 2, laserSurf, laserImageData))
        self.canShoot = false -- we cant shoot now
        self.laserShootTime = self.cooldownDuration -- give control variable laserShootTime cooldownDuration as value, it will be decremented by dt each dt untill its 0 in Player:update(dt) and when its 0 canShoot will be set to true
   
        laserSound:clone():play() -- clone and play sound
    end
end

function Player:draw()
    -- self.image - image which will be drawn
    -- self.x - at what x coordinate image will be drawn, by default origin of the image is on top left so top left of image will be drawn at this x coordinate (but this will be altered by upcoming arguments)
    -- self.y - at what y coordinate image will be drawn, by default origin of the image is on top left so top left of image will be drawn at this y coordinate (but this will be altered by upcoming arguments)
    -- 0 - rotation of image
    -- 1 - x scale of image
    -- 1 - y scale of image
    -- self.width / 2 - this is offset for x coordinate, meaning now instead of origin x being at top left of the image, its in the center of image
    -- self.height / 2 - this is offset for y coordinate, meaning now instead of origin y being at top left of the image, its in the center of image

    love.graphics.draw(self.image, self.x, self.y, 0, 1, 1, self.width / 2, self.height / 2)
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Laser = {}
Laser.__index = Laser

function Laser:new(x, y, img, imgData) 
    --[[
    this class defines Laser, it should be moved vertically infront of player and collide with meteor and destroy it at collision and destroy itself as well
    Parameters:
        x - X coordinate
        y - Y coordinate
        img - image which should be displayed as laser sprite
        imgData - information about each pixel of png img which will be used in pixel precise collision
    Variables:
        width - width of img sprite, used to check rectangular collision before moving to pixel precise one
        height - height of img sprite, used to check rectangular collision before moving to pixel precise one
        speed - speed at which laser will move
        dead - boolean flag, wheen true laser will be destroyed, must be initialised as false
    ]]
    local self = setmetatable({}, Laser)
    self.image = img
    self.imageData = imgData 
    self.x = x
    self.y = y 
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.speed = 400
    self.dead = false 
    
    return self
end

function Laser:update(dt)
    -- each delta time will increase y coordinate of laser and if it leaves the screen it will be marked as dead
    self.y = self.y - self.speed * dt
    if self.y < 0 - self.height then
        self.dead = true
    end
end

function Laser:draw() -- same logic as Player:draw()
    love.graphics.draw(self.image, self.x, self.y, 0, 1, 1, self.width / 2, self.height / 2)
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Meteor = {}
Meteor.__index = Meteor

function Meteor:new(x, y, img, imgData) 
    --[[
    this class defines Meteor, it should be able to move from top to bottom, tilted at random angle, rotating at random angle and having random speed
    Parameters:
        x - X coordinate
        y - Y coordinate
        img - image which should be displayed as meteor sprite
        imgData - information about each pixel of png img which will be used in pixel precise collision
    Variables:
        width - width of img sprite, used to check rectangular collision before moving to pixel precise one
        height - height of img sprite, used to check rectangular collision before moving to pixel precise one
        speed - speed at which meteor will move
        direction - table containing x and y direction components, x is random between -0.5 to 0.5, y is 1, so it will go down always and x coordinate will decide way diagonal direction will go
        rotation - control variable should be 0 by default, will be incremented every time meteor rotates
        rotationSpeed - degree at which meteor will rotate every second
        dead - boolean flag, wheen true laser will be destroyed, must be initialised as false
    ]]
    local self = setmetatable({}, Meteor)
    self.image = img
    self.imageData = imgData
    self.x = x
    self.y = y
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.speed = love.math.random(350, 550)
    
    -- Direction (x is random, y is 1)
    local dirX = love.math.random() - 0.5 -- love.math.random() gives 0-1, so this is -0.5 to 0.5
    self.direction = { x = dirX, y = 1 }
    
    self.rotation = 0 
    self.rotationSpeed = love.math.random(20, 50)
    self.dead = false
    return self
end

function Meteor:update(dt)
     -- each delta time will move meteor and if it leaves the screen it will be marked as dead, also each delta time we update rotation
    self.x = self.x + self.direction.x * self.speed * dt
    self.y = self.y + self.direction.y * self.speed * dt
    
    if self.y > WINDOW_HEIGHT + self.height then
        self.dead = true
    end

    -- update rotation
    self.rotation = self.rotation + self.rotationSpeed * dt
end

function Meteor:draw() -- same as Player:Draw() but with rotation which is taken in radians
    love.graphics.draw(self.image, self.x, self.y, math.rad(self.rotation), 1, 1, self.width / 2, self.height / 2)
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AnimatedExplosion = {}
AnimatedExplosion.__index = AnimatedExplosion
ExplosionImageCount = 8

function AnimatedExplosion:new(x, y, frames)
    --[[
    this class defines Meteor, it should be able to move from top to bottom, tilted at random angle, rotating at random angle and having random speed
    Parameters:
        x - X coordinate
        y - Y coordinate
        frames - table containing all frames of explosion animation
    Variables:
        frameIndex - control variable, will be incremented each delta time when animation is playing, must be initialised at 1
        animationSpeed - speed at which animation will play
        dead - boolean flag, wheen true laser will be destroyed, must be initialised as false
    ]]
    local self = setmetatable({}, AnimatedExplosion)
    self.frames = frames
    self.x = x
    self.y = y
    self.frameIndex = 1
    self.animationSpeed = 20 -- From original code
    self.dead = false
    return self
end

function AnimatedExplosion:update(dt) -- each delta time we will play animation and when frameIndex is more than number of frame we have we mark explosion as dead
    self.frameIndex = self.frameIndex + self.animationSpeed * dt
    if self.frameIndex > #self.frames then
        self.dead = true
    end
end

function AnimatedExplosion:draw()
    local currentFrame = self.frames[math.floor(self.frameIndex)] 
    if currentFrame then
        local w = currentFrame:getWidth()
        local h = currentFrame:getHeight()
        love.graphics.draw(currentFrame, self.x, self.y, 0, 0.25, 0.25, w / 2, h / 2)
    end
end



------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function checkPixelCollision(a, b) -- PIXEL PERFECT COLLISION FUNCTION 
    -- get rectangular hitbox
    local ax1 = a.x - a.width / 2
    local ay1 = a.y - a.height / 2
    local ax2 = a.x + a.width / 2
    local ay2 = a.y + a.height / 2

    -- this is for unrotated state
    local bx1 = b.x - b.width / 2
    local by1 = b.y - b.height / 2
    local bx2 = b.x + b.width / 2
    local by2 = b.y + b.height / 2

    -- rectangular hitbox check
    if not (ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1) then
        return false -- they are not touching so they are not colliding
    end
    


    -- if rectangular hitboxes are touching we will check if pixels are touching 
    
    -- overlapping rectangle in world coordinates
    local overlapX1 = math.max(ax1, bx1)
    local overlapY1 = math.max(ay1, by1)
    local overlapX2 = math.min(ax2, bx2)
    local overlapY2 = math.min(ay2, by2)

    -- calculate inverse rotation for object b (meteor)
    local angleRad = math.rad(-b.rotation) -- negative for inverse rotation
    local cos_t = math.cos(angleRad)
    local sin_t = math.sin(angleRad)

    -- loop over every pixel in the overlapping rectangle
    -- We round to check discrete pixels
    for x = math.floor(overlapX1), math.ceil(overlapX2) do
        for y = math.floor(overlapY1), math.ceil(overlapY2) do
            
            -- checking for object A
            -- convert world (x,y) to A's local texture coordinate
            local localAx = math.floor(x - ax1)
            local localAy = math.floor(y - ay1)

            -- check if this local coordinate is inside A's bounds
            if localAx >= 0 and localAx < a.width and localAy >= 0 and localAy < a.height then
            
                -- sample A's pixel alpha (now safe)
                local _, _, _, a_alpha = a.imageData:getPixel(localAx, localAy)

                -- if A's pixel is visible then:
                if a_alpha > 0 then
                    
                    -- checking for object V
                    -- convert world (x,y) to B's origin-relative coordinate
                    local relativeBx = x - b.x
                    local relativeBy = y - b.y
                    
                    -- apply inverse rotation to the coordinate
                    local unrotatedBx = relativeBx * cos_t + relativeBy * sin_t
                    local unrotatedBy = -relativeBx * sin_t + relativeBy * cos_t

                    -- convert from origin-relative to B's local texture coordinate (top-left)
                    local localBx = unrotatedBx + b.width / 2
                    local localBy = unrotatedBy + b.height / 2

                    -- check if this point is inside B's texture bounds
                    if localBx >= 0 and localBx < b.width and localBy >= 0 and localBy < b.height then
                        
                        -- sample B's pixel alpha
                        local _, _, _, b_alpha = b.imageData:getPixel(math.floor(localBx), math.floor(localBy))

                        -- if B's pixel is also visible then
                        if b_alpha > 0 then
                            return true -- they are colliding
                        end
                    end
                end
            end
        end
    end
    return false -- they arenot colliding
end



function spawnMeteor() 
    local x = love.math.random(0, WINDOW_WIDTH)
    local y = love.math.random(-200, -100)
    table.insert(meteors, Meteor:new(x, y, meteorSurf, meteorImageData))
end



function checkAllCollisions()
    -- Player vs. Meteors
    for i = #meteors, 1, -1 do -- for every meteor check collision of player and meteor
        local meteor = meteors[i]
        if checkPixelCollision(player, meteor) then
            gameState = "gameOver"
        end
    end

    -- Lasers vs. Meteors
    for i = #lasers, 1, -1 do -- for every laser
        local laser = lasers[i]
        for j = #meteors, 1, -1 do -- check collision with every meteor
            local meteor = meteors[j]
            
            if checkPixelCollision(laser, meteor) then
                laser.dead = true
                meteor.dead = true
                
                table.insert(explosions, AnimatedExplosion:new(meteor.x, meteor.y, explosionFrames))
                explosionSound:clone():play()
                
                meteorsDestroyed = meteorsDestroyed + 1
                
                break
            end
        end
    end
end



function displayScore() -- will display score on bottom middle
    local score = math.floor(timeAlive * 10 + meteorsDestroyed * 50) -- score is times alive in seconds * 10 + 50 points per meteor destroyed
    local scoreText = tostring(score)
    
    local text = love.graphics.newText(font, scoreText)
    local textWidth = text:getWidth()
    local textHeight = text:getHeight()
    local x = WINDOW_WIDTH / 2
    local y = WINDOW_HEIGHT - 50

    -- draw rextangle around score
    local paddingX = 10
    local paddingY = 5
    love.graphics.setColor(240/255, 240/255, 240/255)
    love.graphics.rectangle("line", x - textWidth/2 - paddingX, y - textHeight/2 - paddingY, textWidth + paddingX*2, textHeight + paddingY*2, 10, 10)
    
    -- draw the text
    love.graphics.printf(scoreText, 0, y - textHeight/2, WINDOW_WIDTH, "center")
    
    love.graphics.setColor(1, 1, 1)
end



function drawGameOver()
    -- draw background when game is over
    love.graphics.draw(gameOverBackgroundSurf, 0, 0)
    
    -- I will desplay score and time survived
    local score = math.floor(timeAlive * 10 + meteorsDestroyed * 50)
    local time = math.floor(timeAlive)

    love.graphics.setColor(200/255, 200/255, 200/255)
    love.graphics.printf("GAME OVER", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
    love.graphics.printf("Score: " .. score, 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, "center")
    love.graphics.printf("You survived for: " .. time .. " seconds", 0, WINDOW_HEIGHT / 2 + 50, WINDOW_WIDTH, "center")

    -- replay button logic:
    -- check for mouse hover
    local mx, my = love.mouse.getPosition()
    local isHovering = mx > (replayButton.x - replayButton.width / 2) and
                       mx < (replayButton.x + replayButton.width / 2) and
                       my > (replayButton.y - replayButton.height / 2) and
                       my < (replayButton.y + replayButton.height / 2)

    -- draw button rectangle
    if isHovering then
        love.graphics.setColor(0.9, 0.9, 0.9) -- lighter grey when hovering
    else
        love.graphics.setColor(0.5, 0.5, 0.5) -- dark grey otherwise
    end
    love.graphics.rectangle("fill", replayButton.x - replayButton.width / 2, replayButton.y - replayButton.height / 2, replayButton.width, replayButton.height, 10, 10)
    
    -- draw button text
    if isHovering then
        love.graphics.setColor(0, 0, 0) -- black text when hovering
    else
        love.graphics.setColor(1, 1, 1) -- white text
    end
    love.graphics.printf(replayButton.text, replayButton.x - replayButton.width / 2, replayButton.y - font:getHeight()/2, replayButton.width, "center")

    love.graphics.setColor(1, 1, 1)
end



-- reseting the game, it will also be used to initiate the game
function resetGame()
    gameState = "playing" -- contorl variable

    -- initialise at 0 so score resets when game is reset
    timeAlive = 0 
    meteorsDestroyed = 0

    -- intiliase tables as empty so all entities are removed when game is reset
    lasers = {}
    meteors = {}
    explosions = {}
    
    -- construct Player
    player = Player:new(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 1.5, playerSurf, playerImageData)

    meteorSpawnRate = 0.3 -- 300ms
    meteorSpawnTimer = 0 -- control variable for spawning meteors, should be initialised at 0
end


function love.load()
    WINDOW_WIDTH, WINDOW_HEIGHT = 1200, 630
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true
    })
    love.window.setTitle("spaceow")

    -- loading image assets
    backgroundSurf = love.graphics.newImage('images/background1.jpg')
    gameOverBackgroundSurf = love.graphics.newImage('images/background.jpg')
    playerSurf = love.graphics.newImage('images/shimeji.png')
    meteorSurf = love.graphics.newImage('images/egg_one.png')
    laserSurf = love.graphics.newImage('images/fish1.png')

    -- ImageData for pixel precise collision
    playerImageData = love.image.newImageData('images/shimeji.png')
    meteorImageData = love.image.newImageData('images/egg_one.png')
    laserImageData = love.image.newImageData('images/fish1.png')
    
    -- font for text
    font = love.graphics.newFont("images/Oxanium-Bold.ttf", 20)
    love.graphics.setFont(font)

    -- initializing explosion frames
    explosionFrames = {}
    for i = 0, ExplosionImageCount do
        table.insert(explosionFrames, love.graphics.newImage("images/explosion/" .. i .. ".png"))
    end

    -- loading audio assets
    laserSound = love.audio.newSource("audio/mewo.mp3", "static")
    explosionSound = love.audio.newSource("audio/eggsplotion.mp3", "static")
    gameMusic = love.audio.newSource("audio/gamesong1.mp3", "stream")

    -- adjusting volume of audio assets
    laserSound:setVolume(0.3)
    explosionSound:setVolume(0.4)
    gameMusic:setVolume(0.1)
    
    -- playing game music on loop
    gameMusic:setLooping(true)
    gameMusic:play()

    -- creating replay button which will be used on game over screen
    replayButton = {
        x = WINDOW_WIDTH / 2,
        y = WINDOW_HEIGHT / 2 + 150, -- below the other text thats on game over screen
        width = 150,
        height = 50,
        text = "Replay"
    }

    resetGame() -- resetGame gets called when game is reset and also when game first starts
end

function love.update(dt)
    if gameState == "playing" then
        timeAlive = timeAlive + dt -- update timeAlive variable which is used for scroe and displayed when game is over

        -- meteor Spawning
        meteorSpawnTimer = meteorSpawnTimer + dt
        if meteorSpawnTimer >= meteorSpawnRate then
            meteorSpawnTimer = 0
            spawnMeteor()
        end

        -- updating all entities
        player:update(dt) -- player is one so doesnt need loop
        
        for i = #lasers, 1, -1 do
            local laser = lasers[i]
            laser:update(dt)
            if laser.dead then
                table.remove(lasers, i)
            end
        end

        for i = #meteors, 1, -1 do
            local meteor = meteors[i]
            meteor:update(dt)
            if meteor.dead then
                table.remove(meteors, i)
            end
        end

        for i = #explosions, 1, -1 do
            local explosion = explosions[i]
            explosion:update(dt)
            if explosion.dead then
                table.remove(explosions, i)
            end
        end


        -- check collisions
        checkAllCollisions()

    elseif gameState == "gameOver" then
        -- if gameState is not playing than nothing is updated and we wait for player to restart
    end
end

function love.draw()
    if gameState == "playing" then
        love.graphics.draw(backgroundSurf, 0, 0) -- draw background
        
        -- draw all entities
        for i, meteor in ipairs(meteors) do
            meteor:draw()
        end
        
        for i, laser in ipairs(lasers) do
            laser:draw()
        end

        for i, explosion in ipairs(explosions) do
            explosion:draw()
        end

        player:draw() -- player doesnt need loop cause there is only one

        displayScore() -- draw score ui

    elseif gameState == "gameOver" then
        drawGameOver() -- draw game over screen
    end
end

function love.keypressed(key) -- keypress for space when player is "playing"
    if gameState == "playing" then
        if key == "space" then
            player:shoot()
        end
    end
end

function love.mousepressed(x, y, button) -- for reseting the game
    -- check if player is on the game over screen and the left mouse button is pressed
    if gameState == "gameOver" and button == 1 then
        
        -- check if the click (x, y) is inside the button's bounds
        local isHovering = x > (replayButton.x - replayButton.width / 2) and
                           x < (replayButton.x + replayButton.width / 2) and
                           y > (replayButton.y - replayButton.height / 2) and
                           y < (replayButton.y + replayButton.height / 2)
        
        if isHovering then -- because of button == 1 it also means mouse isHovering and is currently pressed
            resetGame()
        end
    end
end