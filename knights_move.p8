pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
//system core loop
function _init()
 create_game_manager()
 create_color_manager()
end

function _update()
 gm.update()
 cm.update()
end

function _draw()
 cls()
 gm.draw()
 cm.draw()
end
-->8
//game

function create_game_manager()
 gm = {}
 gm.state = 'menu'
 gm.menu_manager = create_menu_manager()
 gm.game_player = create_game_player()
 gm.start_game = function()
  gm.state = 'game'
 end
 gm.update = function()
  if gm.state == 'menu' then
   gm.menu_manager.update()
  elseif gm.state == 'game' or gm.state == 'over' then
   gm.game_player.update()
  end
 end
 gm.draw = function()
  if gm.state == 'menu' then
   gm.menu_manager.draw()
  elseif gm.state == 'game' or gm.state == 'over' then
   gm.game_player.draw()
  end
 end
end


-->8
//menu manager
function create_menu_manager()
 menu = {}
 menu.index = 1
 menu.x_pos = 64
 menu.y_pos = 80
 menu.options = {}
 add(menu.options, play_option())
 add(menu.options, difficulty_option())
 add(menu.options, color_scheme_option())
 menu.update = function()
  if btnp(2) then
   menu.index -= 1
  elseif btnp(3) then
   menu.index += 1
  elseif btnp(5) then
   menu.options[menu.index].action()
  end
   menu.index = mod_1(menu.index, #menu.options)
 end
 menu.draw = function()
  local x_mid = menu.x_pos
  local y_mid = menu.y_pos
  local line_height = 10
  local char_height = 6
  local char_width = 4
  local y_start = y_mid - (char_height+(line_height*#menu.options))/2
  local y_cur = y_start
  local x_cur
  rectfill(0,0,128,128,cm.get('primary_2'))
  for i = 1, #menu.options do
   string = menu.options[i].get_draw()
   string_color = menu.options[i].get_color()
   x_cur =  x_mid-(#string*char_width)/2
   print(string, x_cur, y_cur, string_color)
   if (menu.index == i) then
    rect(x_cur-2, y_cur-2, x_cur+(char_width*#string), y_cur+char_height, cm.get('extra_1'))
   end
   y_cur+=line_height
  end
 end
 return menu
end

function color_scheme_option()
 local item = {}
 item.get_draw = function()
  return 'color_scheme: '..cm.get_scheme_name()
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  cm.iterate_scheme()
 end
 return item
end

function play_option()
 local item = {}
 item.get_draw = function()
  return 'play'
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  gm.start_game()
 end
 return item
end

function difficulty_option()
 local item = {}
 if difficulty_manager then
  return difficulty_manager
 end
 item.difficulty = {}
 item.difficulties = {}
 add(item.difficulties,{name='easy', speed = 100})
 add(item.difficulties,{name='med', speed = 40})
 add(item.difficulties,{name='hard', speed = 20})
 item.difficulty_index = 1
 item.get_draw = function()
  return 'difficulty: '..item.get_difficulty_string()
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  item.increment_difficulty()
 end
 item.get_difficulty_string = function()
  return item.difficulties[item.difficulty_index].name
 end
 item.increment_difficulty = function()
  item.difficulty_index += 1
  item.difficulty_index = mod_1(item.difficulty_index, #item.difficulties)
 end
 item.get_speed = function()
  return item.difficulties[item.difficulty_index].speed
 end
 difficulty_manager = item
 return item
end
-->8
//game_player

function create_game_player()
 gp = {}
 gp.workers = {}
 add(gp.workers, create_game_controller())
 add(gp.workers, create_timer())
 add(gp.workers, create_player())
 add(gp.workers, create_score_keeper())
 add(gp.workers, create_enemy_spawner())
 gp.update = function()
  for item in all(gp.workers) do
   item.update()
  end
 end
 gp.draw = function()
  for item in all(gp.workers) do
   item.draw()
  end
 end
 return gp
end

function create_game_controller()
	local this = {}
	board = {}
	width = 16
	height = 16
	num_rows = 8
	num_cols = 8

 for row = 1, num_rows do
  board[row] = {}
  for column = 1, num_cols do
   board[row][column] = {player = 0, pawn = 0}
 	end
 end
 this.draw = function()
  for x = 0, num_rows-1 do
   for y = 0, num_cols-1 do
   	if mod(x+y, 2) == 1 then
    	rectfill(x*width, y*height, x*width+width-1, y*height+height-1, cm.get('primary_2')) 
   	else 
   	 rectfill(x*width, y*height, x*width+width-1, y*height+height-1, cm.get('primary_3')) 
   	end
   	if board[x+1][y+1].target == 1 then
     draw_target(x, y)
   	end
   	if board[x+1][y+1].moveable == 1 then
     draw_movable(x, y)
    end
    if board[x+1][y+1].pawn >= 1 then
     draw_enemy(x*width,y*width)
    end
    line(0,112,128,112,7)
   end
  end
 end
 this.update = function()
 end
 return this
end

function create_timer()
 local this = {}
 this.external_time = 1
 this.internal_time = 1
 this.draw = function() 
  --print(this.external_time, 120, 0, cm.get('secondary_1'))
 end
 this.update = function()
  this.internal_time += 1
  if this.internal_time >= 8 then
   this.internal_time = 0
   this.external_time += 1
  end
 end
 return this
end

function create_player()
 local this = {}
 this.x = 4
 this.y = 8
 this.target = nil
 this.target_index = nil
 this.moves = nil
 this.move = function()
  this.tear_down()  
  this.x = this.target.x
  this.y = this.target.y
  this.target = nil	 
	 this.setup()
 end
 this.tear_down = function()
  board[this.x][this.y].player = 0
  for move in all(get_moves(this.x, this.y)) do
	  if(move.x <= num_rows and move.x > 0 and move.y <= num_cols and move.y > 0) then
 	  board[move.x][move.y].moveable = 0
 	 end
	 end
 end
 this.setup = function()
  this.moves = get_moves(this.x, this.y)
  board[this.x][this.y].player = 1
  for move in all(this.moves) do
	  if(move.x <= num_rows and move.x > 0 and move.y <= num_cols and move.y > 0) then
 	  board[move.x][move.y].moveable = 1
 	  if not this.target then
	    this.target = move --todo: this should be somewhere else?
	    this.target_index = 1
	    board[this.target.x][this.target.y].target = 1
	   end
 	 else 
 	  del(this.moves, move) 
 	 end
	 end
 end
 this.update = function()
  if gm.state == 'over' then
   if btnp(4) then
    enemy_spawner = {}
    board = {}
    _init()
   end
   return
  end
  if btnp(0) then
			if this.target then
    board[this.target.x][this.target.y].target = 0
   end
   this.target_index-=1
   this.target_index = mod_1(this.target_index, #this.moves)
   this.target = this.moves[this.target_index]
   board[this.target.x][this.target.y].target = 1
  end
  if btnp(1) then
   if this.target then
    board[this.target.x][this.target.y].target = 0
   end
   this.target_index+=1
   this.target_index = mod_1(this.target_index, #this.moves)
   this.target = this.moves[this.target_index]
   board[this.target.x][this.target.y].target = 1
  end
  if btnp(5) then
   //board[this.x][this.y].target = 0
   this.move()
   board[this.x][this.y].target = 0
   //enemy_spawner.cycle()
  end
 end
 this.draw = function()
  spr(2, (this.x-1)*width, (this.y-1)*height, 2, 2)
 end
 this.setup()
 return this
end

function create_score_keeper()
 local this = {}
 this.score = 0
 this.draw = function()
  print(difficulty_manager.get_difficulty_string(),0,8,cm.get('secondary_1'))
  if gm.state == 'game' then
   print(this.score,0,0,cm.get('secondary_1'))
  elseif gm.state == 'over' then
   rectfill(32, 48, 106, 86, 0)
   rect(32, 48, 106, 86, 7)
   print('a pawn escaped',40,50,cm.get('secondary_1'))
   print('you lose',50,60,cm.get('secondary_1'))
   print('final score:'..this.score,40,70,cm.get('secondary_1'))
   print('press z to restart',34, 80,cm.get('secondary_1'))
  end
 end
 this.increment_score = function(score)
  if not score then
   score = 1
  end
  this.score += score
 end
 this.update = function()

 end
 score_keeper = this
 return this
end

function create_enemy_spawner()
 local this = {}
 this.enemies = {}
 this.cool_down = 2
 this.turns_to_spawn = 0
 this.setup = false
 this.turn_timer = 0
 this.draw = function()
 end
 this.update = function()
  if not this.setup then
   this.initial_timer = difficulty_manager.get_speed()
   this.setup = true
  end
  if gm.state == 'over' then
   return
  end
  this.turn_timer -= 1
  if this.turn_timer <= 0 then
   this.initial_timer = max(this.initial_timer, 1)
   this.turn_timer = this.initial_timer
   this.cycle()
   this.initial_timer *= .98
  end
  for piece in all(this.enemies) do
   piece.update()
  end
 end
 this.cycle = function()
  for piece in all(this.enemies) do
   piece.move()
  end
  if this.turns_to_spawn == 0 then
   this.spawn_pawn()
   this.turns_to_spawn = this.cool_down
  else
   this.turns_to_spawn -= 1
  end
 end
 this.spawn_pawn = function()
  local x_loc = rand_int(1,8)
  local y_loc = 1
  add(this.enemies, create_pawn(x_loc, y_loc))
 end
 enemy_spawner = this
 return this
end

function create_pawn(x, y)
 local this = {}
 this.x = x
 this.y = y
 board[this.x][this.y].pawn += 1
 this.piece = 'pawn'
 this.update = function()
  if board[this.x][this.y].player == 1 then
   board[this.x][this.y].pawn -= 1
   del(enemy_spawner.enemies, this)
   score_keeper.increment_score()
   return
  end
 end
 this.move = function()
  if gm.state == 'over' then
   return
  end
  board[this.x][this.y].pawn -= 1
  if this.y+1 <= 8 and board[this.x][this.y+1].player == 0 then
   this.y += 1
   if this.y >= 8 then
    gm.state = 'over'
   end
  end
  board[this.x][this.y].pawn += 1
 end
 return this
end
-->8
function get_moves(kx, ky)
 local moves = {}
 add(moves, {x=kx-2, y=ky-1})
 add(moves, {x=kx-1, y=ky-2})
 add(moves, {x=kx+1, y=ky-2})
 add(moves, {x=kx+2, y=ky-1})
 add(moves, {x=kx+2, y=ky+1})
 add(moves, {x=kx+1, y=ky+2})
 add(moves, {x=kx-1, y=ky+2})
 add(moves, {x=kx-2, y=ky+1})
 return moves
end

function draw_movable(x, y)
 rect(x*width, y*height, x*width+width-1, y*height+height-1, cm.get('secondary_2'))
end

function draw_target(x, y)
 rectfill(x*width, y*height, x*width+width-1, y*height+height-1, cm.get('primary_1'))
end

function draw_enemy(x,y)
 spr(10, x, y, 2, 2)
end
-->8
//domain agnostic helpers

function mod(a, b) 
 return a - (flr(a/b)*b)
end

function mod_1(a, b)
 local result = mod(a,b)
 if result == 0 then
  result = b
 end
 return result
end

function wrap(int)
 if int > 128 then
  int = 0
 end
 if int < 0 then
  int = 128
 end
 return int
end

function pick(list)
 return list[rand_int(0, #list)]
end

function rand_int(lo,hi)
 return flr(rnd(hi-lo+1))+lo
end

function sqr(x)
 return x*x
end

function point_in_circle(blt, atd)
 return sqr(atd.x - blt.x)+sqr(atd.y-blt.y) <= sqr(atd.size)
end

function log_n(n, b) 
 if (n > 1) then
  return 1 + log_n(n / b,b)
 else
  return 0
 end
end

-->8
//color manager
function create_color_manager()
 if cm then
  return cm
 end
 cm = {}
 cm.options = {}
 add(cm.options, create_full_color())
 add(cm.options, create_gray_scale())
 add(cm.options, create_blinding())
 add(cm.options, create_pleasant())
 cm.scheme = 1
 cm.iterate_scheme = function()
  cm.scheme += 1
  cm.scheme = mod_1(cm.scheme, #cm.options)
 end
 cm.get_scheme_name = function()
  return cm.options[cm.scheme].name
 end
 cm.get = function(color_name) 
  return cm.options[cm.scheme][color_name]
 end
 cm.update = function()
 
 end
 cm.draw = function()
 
 end
end

function create_full_color()
 color_scheme = {}
 color_scheme.name = 'full_color'
 color_scheme['primary_1'] = 15
 color_scheme['primary_2']= 3
 color_scheme['primary_3'] = 2
 color_scheme['secondary_1'] = 7
 color_scheme['secondary_2'] = 11
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 8
 color_scheme['extra_2'] = 12
 color_scheme['extra_3'] = 10
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_gray_scale()
 color_scheme = {}
 color_scheme.name = 'gray_scale'
 color_scheme['primary_1'] = 6
 color_scheme['primary_2']= 5
 color_scheme['primary_3'] = 0
 color_scheme['secondary_1'] = 6
 color_scheme['secondary_2'] = 7
 color_scheme['secondary_3'] = 5
 color_scheme['extra_1'] = 7
 color_scheme['extra_2'] = 6
 color_scheme['extra_3'] = 5
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_blinding()
 color_scheme = {}
 color_scheme.name = 'blinding'
 color_scheme['primary_1'] = 9
 color_scheme['primary_2']= 12
 color_scheme['primary_3'] = 8
 color_scheme['secondary_1'] = 10
 color_scheme['secondary_2'] = 7
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 11
 color_scheme['extra_2'] = 15
 color_scheme['extra_3'] = 13
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_pleasant()
 color_scheme = {}
 color_scheme.name = 'pleasant'
 color_scheme['primary_1'] = 4
 color_scheme['primary_2'] = 1
 color_scheme['primary_3'] = 5
 color_scheme['secondary_1'] = 6
 color_scheme['secondary_2'] = 2
 color_scheme['secondary_3'] = 7
 color_scheme['extra_1'] = 13
 color_scheme['extra_2'] = 3
 color_scheme['extra_3'] = 15
 color_scheme['extra_4'] = 0
 return color_scheme
end
__gfx__
000000000011dd000000000500000000000000000000000000000000000088000008000000800800000000000000000000000000000000000000000000000000
00000000011111d10000555d55550000000000000000880000000000080080000088800008800000000000055000000000000000000000000000000000000000
00700700114444410005655d55550000000000000800800000800000880000000080800008080000000000566500000000000000000000000000000000000000
00077000d1440440000565dddddd5000800000008800000000800000808000000000000000000000000000566500000000000000000000000000000000000000
000770000d144444005655dddd7dd500800800008080000008080000000000000000000080000000000055555555000000000000000000000000000000000000
0070070001d44444055655ddddddd500000800080000080008080008000000000008000800800800000056666665000000000000000000000000000000000000
0000000001d44e0005655dddddddd500008080000080080000000000080008000800000008000880000005555550000000000000000000000000000000000000
00000000000000000565dddddd555500008080800000880000800080000088000080808000808800000000566500000000000000000000000000000000000000
00000000000000000565ddddd5000000000008000088888000880888888888800800088888888080000000566500000000000000000000000000000000000000
00000000000000000565ddddd5000000080008888888088008080800088808800008080008880080000000566500000000000000000000000000000000000000
000000000000000005655ddddd500000088088800000088008008800000008800808880000000880000005666650000000000000000000000000000000000000
0000000000000000005655ddddd50000088800000000088008800000000008800880000000000880000056666665000000000000000000000000000000000000
0000000000000000000565ddddd50000088000000000088008000000000008800800000000000880000056666665000000000000000000000000000000000000
00000000000000000055555555555500080000000000088008000000000008800800000000000880005555555555550000000000000000000000000000000000
000000000000000005dddddddddddd50008000000000880000800000000088000080000000008800056666666666665000000000000000000000000000000000
00000000000000005555555555555555008800000000800000880000000080000088000000008000555555555555555500000000000000000000000000000000
