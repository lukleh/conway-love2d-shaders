
CONWAY_DIM = 100

function love.load()

	love.window.setMode(800, 600, {resizable = true})
	love.graphics.setPointStyle("rough")
	compute_scale()

	myShader = make_shader()

	start_random()

	love.graphics.setBackgroundColor(64, 64, 64)

 	myShader:send('res', 1 / CONWAY_DIM)

	canvas = love.graphics.newCanvas(CONWAY_DIM, CONWAY_DIM, 'hdr')
	canvas:setFilter( 'nearest', 'nearest' )

	canvas2 = love.graphics.newCanvas(CONWAY_DIM, CONWAY_DIM, 'hdr')
	canvas2:setFilter( 'nearest', 'nearest' )

	love.graphics.setCanvas(canvas)
	seed_conway()
	love.graphics.setCanvas()

	paused = false
	stopstep = false
	generation = 0

end


function love.resize( w, h )
	compute_scale()
end


function seed_conway()
	love.graphics.setColor(255, 255, 255, 255)
	local x = CONWAY_DIM * CONWAY_DIM / 5
	local i
    for i = 0, x do
        local x = math.random(0, CONWAY_DIM)
        local y = math.random(0, CONWAY_DIM)
        love.graphics.point(x + 0.5, y + 0.5)
    end
end


function love.mousepressed(x, y, button)
	local can_x = -1
	local can_y = -1
    if x >= con_pos_x and x < con_pos_x + CONWAY_DIM * scale then
    	can_x = (x - con_pos_x) / scale
    end
    if y >= con_pos_y and y < con_pos_y + CONWAY_DIM * scale then
    	can_y = (y - con_pos_y) / scale
    end
    can_x = math.floor(can_x)
    can_y = math.floor(can_y)
    print(can_x, can_y)
    if can_y > -1 and can_x > -1 then
    	love.graphics.setCanvas(canvas)

    	r, g, b, a = canvas:getPixel( can_x, can_y )
    	print(r, g, b, a)
    	if r == 0 then
    		love.graphics.setColor(255, 255, 255)
    	else
    		love.graphics.setColor(0, 0, 0)
    	end
    	love.graphics.point(can_x, can_y)
    	love.graphics.setCanvas()
    end
end


function love.keypressed(key)
	key_down = key
    if key_down == 'f' then
    	fullscreen, fstype = love.window.getFullscreen()
   		love.window.setFullscreen(not fullscreen, "desktop")
   	end
    
   	if key_down == 'r' then
	    canvas:clear(0, 0, 0, 255)
	    love.graphics.setCanvas(canvas)
		seed_conway()
		love.graphics.setCanvas()
		generation = 0
	end

	if key_down == 'q' then
		love.event.quit()
	end

	if key_down == 'c' then
		canvas:clear(0, 0, 0, 255)
		generation = 0
	end

	if key_down == ' ' then
		paused = not paused
	end

	if key_down == 'return' then
		paused = false
		stopstep = true
	end

    print('pressed:', key_down)
end

function love.update(dt)
	fps = love.timer.getFPS()
end

function love.draw()

	love.graphics.setColor(255,255,255,255)
	love.graphics.print("FPS: " .. fps, 10, 10)
	love.graphics.print("gen " .. generation, 10, 30)
	love.graphics.print("f: fullscreen", 10, 50)
	love.graphics.print("q: quit", 10, 70)
	love.graphics.print("c: clear", 10, 90)
	love.graphics.print("r: reset", 10, 110)
	love.graphics.print("space: pause", 10, 130)
	love.graphics.print("enter: step", 10, 150)

	if paused then
		love.graphics.draw( canvas, con_pos_x, con_pos_y, 0, scale, scale)
		return
	end
	generation = generation + 1
	love.graphics.setCanvas(canvas2)
	love.graphics.setShader(myShader)
	love.graphics.draw( canvas )
	love.graphics.setShader()
	love.graphics.setCanvas()

	canvas:clear(0, 0, 0, 255)

	love.graphics.setCanvas(canvas)
	love.graphics.draw( canvas2 )
	love.graphics.setCanvas()

	love.graphics.draw( canvas, con_pos_x, con_pos_y, 0, scale, scale)

	if stopstep then
		paused = true
		stopstep = false
	end
end


function compute_scale()
	local width, height = love.graphics.getDimensions() 
	scale = math.floor(math.min(width / CONWAY_DIM, height / CONWAY_DIM))
	con_pos_x = width / 2 - scale * CONWAY_DIM / 2
	con_pos_y = height /2 - scale * CONWAY_DIM / 2
end


function start_random()
	math.randomseed( os.time() )
	math.random()
	math.random()
	math.random()
end


function make_shader()
	return love.graphics.newShader[[
		extern number res;

	    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	      vec4 pixel;
	      pixel = Texel(texture, texture_coords ); //This is the current pixel color
	      // vec4 pout = vec4(screen_coords.x / love_ScreenSize.x , screen_coords.x / love_ScreenSize.x, screen_coords.x / love_ScreenSize.x, 1.0);
	      vec4 pout;
	      // pout = vec4(sin(texture_coords.x + pixel.r), sin(texture_coords.y + pixel.g), cos(texture_coords.x + pixel.b), 1.0);
	      // pout = color;
	      float x_plus = 0.0;
	      float y_plus = 0.0;
	      float x_minus = 0.0;
	      float y_minus = 0.0;
	      int neighbours = 0;
	      bool alive = pixel.r > 0;

	      if (texture_coords.x + res > 1.0) {
	      	x_plus = res / 2;
	      } else {
	      	x_plus = texture_coords.x + res;
	  	  }

	  	  if (texture_coords.y + res > 1.0) {
	      	y_plus = res / 2;
	      } else {
	      	y_plus = texture_coords.y + res;
	  	  }

	  	  if (texture_coords.x - res < 0.0) {
	      	x_minus = 1.0 - (res / 2);
	      } else {
	      	x_minus = texture_coords.x - res;
	  	  }

	  	  if (texture_coords.y - res < 0.0) {
	      	y_minus = 1.0 - (res / 2);
	      } else {
	      	y_minus = texture_coords.y - res;
	  	  }

	  	  pixel = Texel(texture, vec2(x_minus, y_minus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(texture_coords.x, y_minus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(x_plus, y_minus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(x_minus, texture_coords.y) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }



	  	  pixel = Texel(texture, vec2(x_plus, texture_coords.y) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(x_minus, y_plus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(texture_coords.x, y_plus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  pixel = Texel(texture, vec2(x_plus, y_plus) );
	  	  if (pixel.r > 0) {
	  	  	neighbours += 1;
	  	  }

	  	  if (alive) {
	  	  	if (neighbours < 2) {
	  	  		alive = false;
	  	  	} else if (neighbours > 3) {
	  	  		alive = false;
	  	  	}
	  	  } else {
	  	  	if (neighbours == 3 || neighbours == 6) {
	  	  		alive = true;
	  	  	}
	  	  }

	  	  // return vec4(1.0, 1.0, 1.0, 1.0);

	  	  if (alive) {
	  	  	return vec4(1.0, 1.0, 1.0, 1.0);
	  	  }
	      return vec4(0.0, 0.0, 0.0, 1.0);
	    }
	  ]]

end