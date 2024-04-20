function love.load()
	love.window.setTitle("Space Enemies")

	love.graphics.setDefaultFilter("nearest","nearest")
	love.window.setMode(600, 600)

	game_running = false 
	menu_list = {"Start","Exit"}
	selected_text  = "Start";
	anim8 = require "anim8"
	
	--sound
	shoot_sound = love.audio.newSource("assets/shoot.mp3","static")
	playingsounds = {}

	player = {}
	player.speed = 3 
	player.sprite = love.graphics.newImage("assets/spaceship.png")
	player.x = love.graphics.getWidth()  / 2 - player.sprite:getWidth() 
	player.y = 500
	
	background = love.graphics.newImage("assets/bg.png")
	background_scale_x = 600 / background:getWidth()
	background_scale_y = 600 / background:getHeight()
	
	bullets = {}
	bullet_speed = 5;
	bullet_sprite = love.graphics.newImage("assets/fireball.png")

	enemy_speed = 0.5

	current_enemies = {}

	newEnemy()
	newEnemy()
	
	Score = 0
end

local spawnTimer = 0
local difficultyTimer = 0
local spawn_delay = math.random(1,3)
local difficulty_delay = 10 --after every n secons game gets faster and harder
local no_of_enemies_spawn = 2

function newEnemy()
	local enemy =  {}
	enemy.x = math.random(30,500)
	enemy.y = math.random(0,200)
	local rand = math.random(1,4)
	if rand == 1 then 
		enemy.sprite_sheet =  love.graphics.newImage("assets/enemy_1.png")
		enemy.grid  = anim8.newGrid(16,16,enemy.sprite_sheet:getWidth() ,enemy.sprite_sheet:getHeight() )
		enemy.animation = anim8.newAnimation(enemy.grid("1-4",1),0.2)
	elseif rand == 2 then
		enemy.sprite_sheet =  love.graphics.newImage("assets/enemy_2.png")
		enemy.grid  = anim8.newGrid(16,16,enemy.sprite_sheet:getWidth() ,enemy.sprite_sheet:getHeight() )
		enemy.animation = anim8.newAnimation(enemy.grid("1-4",1),0.2)
	else
		enemy.sprite_sheet =  love.graphics.newImage("assets/enemy_3.png")
		enemy.grid  = anim8.newGrid(16,16,enemy.sprite_sheet:getWidth() ,enemy.sprite_sheet:getHeight() )
		enemy.animation = anim8.newAnimation(enemy.grid("1-5",1),0.2)
	end
	enemy.width = 16*3
	enemy.height = 16*3
	table.insert(current_enemies,enemy)
end

function love.update(dt)
	--game input 
	if love.keyboard.isDown("right") or love.keyboard.isDown("d") and game_running then
		if not (player.x + player.speed >= 500) then
			player.x = player.x + player.speed
		end
	end
	if love.keyboard.isDown("left") or love.keyboard.isDown("a") and game_running then
		if not (player.x - player.speed <= 40) then
		 player.x = player.x - player.speed
	 end
	end

	for i = 1, #current_enemies do
		current_enemies[i].animation:update(dt)
	end 

	spawnTimer = spawnTimer + dt  -- Accumulate time elapsed
	difficultyTimer = difficultyTimer + dt  -- Accumulate time elapsed
	if difficultyTimer >= difficulty_delay and game_running then
		if not (enemy_speed == 1.75) then 
			enemy_speed = enemy_speed + 0.25
		else
			difficulty_delay = 30
			no_of_enemies_spawn = no_of_enemies_spawn + 1;
		end
		difficultyTimer = 0
	end
	if spawnTimer >= spawn_delay and game_running then
		newEnemy() --spawn new enemeies at random x and y pos
		newEnemy() --spawn new enemeies at random x and y pos
		spawn_delay = math.random(1,3)
		spawnTimer = 0
	end
	update_enemy_positions() --update enemy position
	check_collision()
	update_bullets_position()
	--check if sound is closed
	for i = #playingsounds, 1, -1 do
        local source = playingsounds[i]
        if not source:isPlaying() then
            table.remove(playingsounds, i)
        end
    end
end


--get the index of a value in table
function indexOf(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil -- return nil if the value is not found
end

function love.keypressed(key)
	--menu input stuff
	if not game_running then
		local current_index = indexOf(menu_list , selected_text)
		if key == "down" or key == "s" then 
			if not (current_index == #menu_list) then
				current_index = current_index + 1
				selected_text = menu_list[current_index]
				showMenu()
			end 
		end
		if key == "up" or key == "w" then 
			if not (current_index == 1 ) then 
				current_index = current_index - 1
				selected_text = menu_list[current_index]
				showMenu()
			end
		end
	end
	--game input
	if key == "space" and game_running and #playingsounds <= 0 then 
		local bullet = {
			speed = 15,
			x = player.x ,
			y = player.y ,
			width = 16*3,
			height= 16*3,
		}
		shoot_sound:play()
		table.insert(playingsounds,shoot_sound)
		table.insert(bullets,bullet)
	end
	if key == "return" and not game_running then 
		if selected_text == "Start" then
			game_running = true
		end
		if selected_text == "Exit" then
			love.event.quit()
		end
	end 
end

function update_enemy_positions()
	if game_running and current_enemies then
		for i = 1, #current_enemies do
			if current_enemies[i].y >= player.y + 0.5 then
				gameover()
				break
			else
				current_enemies[i].y = current_enemies[i].y + enemy_speed; 
			end
		end
	end 
end

function gameover()
	game_running= false;
	enemy_speed = 0.5
	current_enemies = {}
	bullets = {}
end
function update_bullets_position()	
	local bulletsToRemove= {}
	for i = 1, #bullets do
		bullets[i].y = bullets[i].y - bullet_speed
	end
	for i = #bulletsToRemove, 1, -1 do
			table.remove(bullets, bulletsToRemove[i])
	end
end 

function love.draw()
	love.graphics.draw(background,0,0,nil,background_scale_x,background_scale_y)
	if not game_running then
		showMenu()
		--love.graphics.setFont(love.graphics.newFont(44)) -- Set the font and its size
		--love.graphics.print(Score,280,300)
		--love.graphics.print("GAME OVER",170,250)
		--love.graphics.setFont(love.graphics.newFont(25)) -- Set the font and its size
		--love.graphics.print("press <enter> to restart again",120,370)
	else
		love.graphics.draw(player.sprite,player.x,player.y,nil,5)
		--drawing the bullets
		for i = 1, #bullets do
			love.graphics.draw(bullet_sprite,bullets[i].x,bullets[i].y,nil,4)
		end

		for i = 1, #current_enemies do
			current_enemies[i].animation:draw(current_enemies[i].sprite_sheet,current_enemies[i].x,current_enemies[i].y,nil,3)
		end 
		love.graphics.setFont(love.graphics.newFont(24)) -- Set the font and its size
		love.graphics.print(Score,0,0)
	end
end

function showMenu()
	start_text = "Start"
	exit_text = "Exit"
	font = love.graphics.newFont("assets/Mathlete-Bulky.otf",45)
	love.graphics.setFont(font)

	local y_cor = 200
	for i=1,#menu_list do
		text = menu_list[i]
		if text == selected_text then
			setSelectedColorText(text,love.graphics.getWidth()/2 - font:getWidth(text)/2,y_cor)
		else
			love.graphics.print(text, love.graphics.getWidth()/2 - font:getWidth(text)/2 ,y_cor)
		end
		y_cor = y_cor + 50
	end

	--print the footer
	footer_text = "Made with love by tervicke"
	footer_font = love.graphics.newFont("assets/Mathlete-Bulky.otf",25)
	love.graphics.setFont(footer_font)
	love.graphics.print(footer_text, love.graphics.getWidth()/2 - footer_font:getWidth(footer_text)/2 ,500)
end

function setSelectedColorText(text,x,y) --this sets the text according to the green color which indicatd the selected color
		love.graphics.setColor(0,1,0)
		love.graphics.print(text,x,y)
		love.graphics.setColor(1,1,1)
end

function check_collision()
	for i, enemy in ipairs(current_enemies) do
        for j, bullet in ipairs(bullets) do
            if checkCollision(enemy.x, enemy.y, enemy.width, enemy.height,
                              bullet.x, bullet.y, bullet.width, bullet.height) then
                -- Handle collision here, for example:
								table.remove(bullets, j)
                table.remove(current_enemies, i)
								Score = Score + 1
								--
                -- Remove the bullet and enemy
            end
        end
    end
end 
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    -- Calculate the sides of the rectangles
    local left1, right1, top1, bottom1 = x1, x1 + w1, y1, y1 + h1
    local left2, right2, top2, bottom2 = x2, x2 + w2, y2, y2 + h2
    
    -- Check for intersection along the x-axis
    if right1 < left2 or left1 > right2 then
        return false
    end
    
    -- Check for intersection along the y-axis
    if bottom1 < top2 or top1 > bottom2 then
        return false
    end
    
    -- If both x-axis and y-axis intersections occur, rectangles overlap
    return true
end
