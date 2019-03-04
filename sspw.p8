pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--multiplayer boxing game
--by @rithain at #leetgamejam
--------------init--------------
----------------------------------
players={}
winner={}
score={0,0}
winner.name = ''
winner.col = 0
winner.time = 0
debug=''
frame=0
screenstate='intro'
winscreenwaittime=60
countdown=0
starttime=120

function initarm(x,y,col,initdir)
  local a={}
  a.state = 0 --0: inactive, 1: active, 2:retracting
  a.x=nil
  a.y=nil
  a.rad=2
  a.dir=initdir
  a.col=col
  a.trail={}
  return a
end

function initplayer(id,x,y,rad,col, rcol, lcol)
  local p={}
  p.id = id
  p.x = x
  p.y = y
  p.col = col
  p.rad = rad
  p.hp = 3
  p.hover = 1
  p.invultime = starttime --120
  p.knockbackspeed = 0
  p.knockbackdir = 0
  p.arms = {initarm(x,y,rcol,(id-1)*0.5+0.5), initarm(x,y,lcol,(id-1)*0.5+0.5)}
  
  add(players, p)
end

function initgame()
  screenstate = 'game'
  countdown=5
  frame=0
  initplayer(1,64,84,4, 2, 2, 2)
  initplayer(2,64,34,4,13, 13, 13)
end

function reset_game(p)
  players = {}
  winner.time = 0
  initgame()
end

function _init()
  cls()
  screenstate='intro'
end

-->8
--------functions--------
-------------------------

function hcenter(s)
  return 64-#s*2
end

function go_to_intro()
  screenstate='intro'
end

function push(list,v)
	local k=#list
	for i=k,1,-1 do
		list[i+1]=list[i]
	end
	list[1]=v
end

-- camershake
-- credit to @elastiskalinjen
shake=0
function camerashake()
  local shakex=16-rnd(32)
  local shakey=16-rnd(32)
 
	shakex*=shake
	shakey*=shake

	camera(shakex,shakey)
	shake=shake*0.95
	if(shake < 0.02)shake=0
end
-----

function addtotrail(a)
	local t={}
	t.x = a.x
	t.y = a.y
  t.rad = 1
	push(a.trail,t)
end

function reset_arm(arm)
  sfx(4)
  arm.state=2
end

function reset_all_arms(p)
  for i=1, #p.arms do
    reset_arm(p.arms[i])
  end
end

function is_out_of_bounds(arm)
  if (arm.x and arm.y) then
    if (arm.x>128 or arm.x<0 or arm.y>128 or arm.y<0) then
      return true
    end
  end
  return false
end

function check_bounds(p)
  if (is_out_of_bounds(p.arms[2]) or is_out_of_bounds(p.arms[1])) then
    reset_all_arms(p)
  end
end

function distance(a,b)
	return sqrt(((b.x-a.x)/10)^2+((b.y-a.y)/10)^2)*10
end

function circcoll(a,b)
  if (not a.x or not a.y or not b.x or not b.y) then
    return false
  end
	if distance(a,b) < a.rad+b.rad then 
		return true 
	else 
		return false 
	end
end

function set_winner(p)
  screenstate='winscreen'
  winner.name=p.id
  score[p.id]+=1
  winner.col=p.col
end

function reduce_hp(p, amount, dir)
  if (p.invultime == 0) then
    sfx(0)
    knockback(p, dir)
    p.hp-=amount
    shake+=0.1
    for i=0, 20 do initparticle(p.x, p.y, 2+rnd(4),7,0,0) end
    p.invultime = 120
    if (p.hp <= 0) then
      set_winner(players[(p.id%2)+1])
    end
  end
end

function knockback(p, dir)
  reset_all_arms(p)
  p.state = 4
  p.knockbackspeed = 3
  p.knockbackdir = dir
  initparticle(p.x, p.y, 2+rnd(4),7,0,0)
end

function lengthen_trail(p, arm)
  if (arm.state >= 1) then
    local t={}
    t.x = p.x
    t.y = p.y
    t.rad = 1
    add(arm.trail,t)
  end
end

function knockback_move(p)
  local ox = p.x
  local oy = p.y
  p.x += sin(p.knockbackdir)*(p.knockbackspeed)
  p.y += cos(p.knockbackdir)*(p.knockbackspeed)
  if (p.y<2 or p.y>126) then
    p.y = oy
  end
  if (p.x<2 or p.x>126) then
    p.x = ox
  end
  p.knockbackspeed -= 0.2
  lengthen_trail(p, p.arms[1])
  lengthen_trail(p, p.arms[2])

  if (p.knockbackspeed <= 0) then
    p.state = 0
  end
end

-- circle particles
-- credit to @elastiskalinjen
particles={}
function initparticle(x,y,rad,col,dx,dy)
	local p={}
	p.x=x
	p.y=y
	p.dx=dx
	p.dy=dy
	-- default parameters
	if(dx == 0)p.dx = rnd(2)-1
	if(dy == 0)p.dy = rnd(2)-1
	p.rad=rad
	p.col=col
	
	add(particles,p)
end

function updateparticle(p)
	p.dx*=0.9
	p.dy*=0.9
 	p.x+=p.dx
 	p.y+=p.dy
 	
 	if p.rad > 10 then
 		p.rad -= 0.75
 	else 
		p.rad -= 0.09
	end
	if p.rad <=0 then 
		del(particles,p)
	end
end

function drawparticle(p)
	circfill(p.x,p.y,p.rad,p.col)
end
--------

function toggle_arm(arm, pl, shift, dist)
  if (arm.state == 0) then
    sfx(1)
    shake+=0.03
    arm.state = 1
    arm.x = pl.x + (sin(arm.dir-shift)*dist)
    arm.y = pl.y + (cos(arm.dir-shift)*dist)
    for i=0, 1 do initparticle(arm.x, arm.y, 2+rnd(1),7,sin(arm.dir),cos(arm.dir)) end
    arm.trail = {}
  else
    arm.state = 0
    reset_all_arms(pl)
  end
end

-->8
-------------gameloop-------------
--------------------------------
function updatearm(arm)
  local armspeed = 2
  local deacceleration = 50
  if (arm.state == 1) then
    if ((armspeed-(#arm.trail/deacceleration)) <= 0) then
      reset_arm(arm)
      return
    end
    arm.x += sin(arm.dir)*(armspeed-(#arm.trail/deacceleration))
    arm.y += cos(arm.dir)*(armspeed-(#arm.trail/deacceleration))
    addtotrail(arm)

  elseif (arm.state == 2) then
    -- retract arm --
    local retractspeed = 3
    for i=1, retractspeed do
      del(arm.trail,arm.trail[1])
    end
    if (arm.trail[1]) then
      arm.x = arm.trail[1].x
      arm.y = arm.trail[1].y
    end
    
    if (#arm.trail <= 0) then
      arm.state=0
      arm.x = nil
      arm.trail={}
    end
  end
end

function playerbounce(dir, p, op)
  sfx(5)
  knockback(players[p.id], dir+0.5)
  knockback(players[op], dir)
end

function updateplayer(p)
  local cntrl_id = p.id -1
  local speed = 0.5
  local otherp = (p.id%2)+1
  local ox = p.x
  local oy = p.y

  if (p.arms[2].state == 0 and p.arms[1].state == 0) then
    -------------- player active --------------

    local newdir = {}
    if (btn(0,cntrl_id) and p.x>0+p.rad+2) then
      p.x=p.x-speed
      add(newdir,0.25)
    end
    if (btn(1,cntrl_id) and p.x<128-p.rad-2) then
      p.x=p.x+speed
      add(newdir,0.75)
    end
    if (btn(2,cntrl_id) and p.y>0+p.rad+2) then
      p.y=p.y-speed
      add(newdir,0.5)
    end
    if (btn(3,cntrl_id) and p.y<128-p.rad-2) then
      p.y=p.y+speed
      if (btn(1,cntrl_id)) then
        add(newdir, 1)
      else
        add(newdir, 0)
      end
    end
    
    if (#newdir > 0) then
      local newdirsum=0
      for i=1, #newdir do
        newdirsum += newdir[i]
      end
      local newdiravg=newdirsum/#newdir
      p.arms[1].dir=newdiravg
      p.arms[2].dir=newdiravg

      if (circcoll(players[1], players[2])) then
        playerbounce(p.arms[1].dir, p, otherp)
      end
    end

  else
    -------------- arm active --------------
    local steeringf = 0.015
    if (btn(0,cntrl_id)) then 
      p.arms[1].dir-=steeringf
      p.arms[2].dir-=steeringf
    end
    if (btn(1,cntrl_id)) then
      p.arms[1].dir+=steeringf
      p.arms[2].dir+=steeringf
    end
    ------------ arm collision ------------
    check_bounds(p)

    function arm_player_collision(arm)
      if (circcoll(arm, players[otherp] )) then
        reduce_hp(players[otherp], 1, arm.dir)
        reset_all_arms(p)
      end
    end

    arm_player_collision(p.arms[1])
    arm_player_collision(p.arms[2])

    ----arm trail collision----
    function arm_trail_collision(arm, p)
      for i=0,#arm.trail do
        if (arm.trail[i]) then
          if (circcoll(p.arms[1], arm.trail[i]) 
            or circcoll(p.arms[2], arm.trail[i]) 
          ) then
            reset_all_arms(p)
            -- if clash, reset both players arm --
            if (i<3) then
              sfx(5)
              reset_all_arms(players[otherp])
            end

          end
        end
      end
    end
    arm_trail_collision(players[otherp].arms[1], p)
    arm_trail_collision(players[otherp].arms[2], p)
  end

  ------------arm launching--------------
  local armspawndist = p.rad+2
  local dist = 4

  if (btnp(4, cntrl_id)) then    
    toggle_arm(p.arms[2], p, 0.15, dist)
  end

  if (btnp(5, cntrl_id)) then
    toggle_arm(p.arms[1], p, -0.15, dist)
  end

  updatearm(p.arms[1])
  updatearm(p.arms[2])


  -- counters and animations
  if (p.invultime > 0) then
    p.invultime -= 1
  end

  if ( p.state==4 ) then
    knockback_move(p)
  end

  p.hover = sin((frame+p.id*10)/100)*3
end

function updatewinscreen()
  winner.time+=1
  if ((btnp(4,0) or btnp(5,0) or btnp(4,1) or btnp(5,1)) and winner.time > winscreenwaittime) then
    reset_game()
  end
end

function updatecountdown()
  if (frame % (120/3) == 0 and countdown > 0) then
    countdown-=1
  end
end

function _update60()
  frame += 1
  if(screenstate=='intro') then
    updatemenu()
  elseif (screenstate=='game') then
    foreach(players, updateplayer)
    updatecountdown()
  else
    updatewinscreen()
  end
  foreach(particles, updateparticle)

end
-->8
--------------draw--------------
--------------------------------
function drawtrail(t, col)
  circfill(t.x,t.y,t.rad,col)
end

function drawarm(arm)
  circfill(arm.x, arm.y,2,arm.col)
  for t in all(arm.trail) do drawtrail(t, arm.col) end
end

function draw_eye(p, dir, shift, dist, hover)
  pset(p.x + (sin(dir+shift)*dist),
    p.y +(cos(dir+shift)*dist) + hover, 6)
  pset(p.x + (sin(dir+shift)*dist),
    p.y +(cos(dir+shift)*dist) + hover-1, 7)
end

function drawplayer(p)
  local shift = 0.15
  local dist = 5
  -- body --
  local dontdraw = false
  if (p.invultime % 15 > 10) then
    dontdraw = true
  end
  local temphover = p.hover
  if (p.arms[1].state >= 1 or p.arms[2].state >= 1) then
    temphover = 0
  end

  -- sweat
  if (p.hp <= 1) then
    if (rnd(30) < 2) then
      initparticle(p.x+rnd(6)-3, p.y+rnd(1)-1, 1+rnd(2),p.col,0,0)
    end
  end

  -- shadow
  local shadowsize = 3.5-(temphover+4)/4
  circfill(p.x+1,p.y+5, shadowsize ,5)
  circfill(p.x-1,p.y+5, shadowsize ,5)

  -- body
  if (not dontdraw) then
    circfill(p.x,p.y+temphover,p.rad-1,0)
    circ(p.x,p.y+temphover,p.rad,p.col)
      -- eyes --
    draw_eye(p, p.arms[1].dir, shift-0.07, 3, temphover)
    draw_eye(p, p.arms[1].dir, -shift+0.07, 3, temphover)
  end
  
  -- arms
  function draw_arm(arm, pl, s)
    if (arm.state >= 1) then
      drawarm(arm)
    else
      local dontdrawarm = false
      if (p.invultime % 15 > 10) then
        dontdrawarm = true
      end
      if (not dontdrawarm) then
        circfill(
          pl.x + (sin(arm.dir+s)*dist),
          pl.y + (cos(arm.dir+s)*dist) + temphover/3,
          arm.rad,arm.col)

        circfill(
          pl.x + (sin(arm.dir+(s*1.5))*dist),
          pl.y + (cos(arm.dir+(s*1.5))*dist) + temphover/3,
          arm.rad-1,arm.col)
      end

    end
  end

  draw_arm(p.arms[1], p, shift)
  draw_arm(p.arms[2], p, shift*-1)
end

function repeatchar(amount, char)
  local repeatstring = ''
  while #repeatstring < amount do
    repeatstring = repeatstring..char
  end
  return repeatstring
end

function drawui()
  -- hp --
  if (players[1]) then
    print(repeatchar(players[1].hp, '♥'),5,5, players[1].col)
  end
  if (players[2]) then
    print(repeatchar(players[2].hp, '♥'), 124 - players[2].hp * 8, 5, players[2].col)
  end
  -- score --
  if (score[1] < 15) then
    print(repeatchar(score[1], 'i'),5,118, players[1].col)
  else
    print(score[1],5,118, players[1].col)
  end
  if (score[2] < 15) then
    print(repeatchar(score[2], 'i'),124 - score[2] * 4,118 , players[2].col)
  else
    print(score[2], 116 ,118, players[2].col)
  end
  
  if (countdown>0) then
    if (countdown>2) then
      local offset = abs(((sin(frame/80))^-1)*5)*-1
      print(countdown-2, hcenter('1')+5+offset,60,7)
    else
      local offset = abs((sin((frame+120)/160)^-1)*4.1)*-1
      print('fight!', hcenter('fight!')+5+offset,60,7)
    end
  end
end

function updatemenu()
  if (btnp(4,0) or btnp(5,0) or btnp(4,1) or btnp(5,1)) then
    initgame()
    shake=0.01
  end
end

function drawlogo()
  print('super punch', hcenter('super punch')-3, 42+ sin((frame)/100)*3 , 13)
  print('warriors',hcenter('warriors')-3, 50+ sin((frame+20)/100)*3, 13)
  if ((sin((frame)/100)*3)+2 >= 0) then
    print('punch to start 🅾️❎', hcenter('punch to start 🅾️❎')-8, 80, 7)
  end
  -- initparticle(rnd(128), 10, 2+rnd(3),1,0,0)
  initparticle(rnd(128), 15, 2+rnd(3),1,0,0)
  initparticle(10, 15+rnd(83), 2+rnd(3),1,0,0)
  initparticle(115, 15+rnd(83), 2+rnd(3),1,0,0)
  -- initparticle(rnd(128), 115, 2+rnd(3),1,0,0)
  initparticle(rnd(128), 98, 2+rnd(3),1,0,0)
  print("by: @rithain", 5, 115,6)
  print("thanks to: @elastiskalinjen", 5, 122, 6)
end


function draw_winscreen()
  local winflavor ='a winner is you!'
  local ypos1 = 0
  local ypos2 = 0
  if (winner.time == 15) then
    shake=0.1
    for i=0, 30 do initparticle(rnd(#winflavor*4)+(64-#winflavor*4/2), 64, 1+rnd(2),7,0,1) end
  end
  if (winner.time < 15) then
    ypos1 = winner.time*4-10 + (sin((frame)/100)*3)
    ypos2 = winner.time*4 + (sin((frame+20)/100)*3)
  else
    ypos1 = 50+sin((frame)/100)*3
    ypos2 = 60+sin((frame+20)/100)*3
  end
  print('player '..winner.name, hcenter('player '..winner.name),ypos1, winner.col)
  print(winflavor, hcenter(winflavor),ypos2, winner.col)

  if ((sin((frame)/100)*3)+2 >= 0 and winner.time > winscreenwaittime) then
    print('punch for rematch 🅾️❎', hcenter('punch for rematch 🅾️❎')-8, 80, 7)
  end

end

function _draw()
  cls()
  if (screenstate=='intro') then
    map(16,0,0,0,128,128)
    drawlogo()
  elseif(screenstate=='game') then
    map(0,0,0,0,128,128)
    foreach(players, drawplayer)
    drawui()
  elseif(screenstate=='winscreen') then
    map(0,0,0,0,128,128)
    draw_winscreen()
    drawui()
  end
  camerashake()
  foreach(particles, drawparticle)
  print(debug,10,10,8)
end
__gfx__
00000000000000001122112211221122112211221122112211221122112211222222222222222222222222222222222222200022222222222222222222222222
00000000000000001122112211221122112211221122112211221122112211222222222222222222222222222222222222220022222222222222222222222222
00700700000000002200000000000000000000112233d5553333d5553333d5112200000000022000220000022200002222220022220000002200000000022000
00077000000000002200000000000000000000112233dddd3333dddd3333dd112222222200022000222222222200002222022022220222222222220000022000
000770000000000011000000000000000000002211553333d5553333d55533222222222200022000222222222200002222022222220222222222220000022000
007007000000000011000000000000000000002211553333d5553333d55533220000002200022000222222002200002222022222220000022200000000022000
000000000000000022000000000000000000001122553333d5553333d55533112222222200022000220222222222222222000222222222222222222200022000
000000000000000022000000000000000000001122dd3333dddd3333dddd33112222222200022000220002222222222222000222222222222222222200022000
00000000000000001100000000000000000000221133d5553333d5553333d5228800008800000000000000000000000000000000000000000000000000000000
00000000000000001100000000000000000000221133d5553333d5553333d5228800008808880880000880000800088000888800088888800088888000000000
00000000000000002200000000000000000000112233d5553333d5553333d5118800008808080880000880000800088000880000080008800080000008080800
00000000000000002200000000000000000000112233dddd3333dddd3333dd118800008808088880000880000800088000888000080008800080000080808080
000000000000000011000000000000000000002211553333d5553333d55533228800008808008880000880000080880000880000088888800088888008080800
000000000000000011000000000000000000002211553333d5553333d55533228888888808000880000880000008800000880000080880000000088080808080
000000000000000022000000000000000000001122553333d5553333d55533110888888008000880000880000008800000888800080088800088888000000000
000000000000000022000000000000000000001122dd3333dddd3333dddd33110088880000000000000000000000000000000000000000000000000000000000
00000000000000001100000000000000000000221133d5553333d5553333d5220000000000000000000000000000000000000000000000000000000000000000
00000000000000001100000000000000000000221133d5553333d5553333d5220000000000000000000000000000000000000000000000000000000000000000
00000000000000002200000000000000000000112233d5553333d5553333d5110000000000000000000000000000000000000000000000000000000000000000
00000000000000002200000000000000000000112233dddd3333dddd3333dd110000000000000000000000000000000000000000000000000000000000000000
000000000000000011000000000000000000002211553333d5553333d55533220000000000000000000000000000000000000000000000000000000000000000
000000000000000011000000000000000000002211553333d5553333d55533220000000000000000000000000000000000000000000000000000000000000000
00000000000000002211221122112211221122112211221122112211221122110000000000000000000000000000000000000000000000000000000000000000
00000000000000002211221122112211221122112211221122112211221122110000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010000000000000000000000111000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000001110000000000000001111100000000000001000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000011111000000000000111111110000000000000000000000000000000000000000000000000000011100
00000000000000000000000000000000000000000000011111000000000001111111111000000000011100000000000000000000000000000000000000111110
00000000000000000000000000000100000000000000011111000000000001111111111100000001111111000000000000000000000000000000000001111111
00000000000000000000000000001110000000000000001110000000000001111111111100000001111111000000000000001000000000000000000001111111
00000000001011100000000000000100000000000000000000000000000000111111111100000011111111100000000000011110000000011100000001111111
00000000011111111111000000000000000000000000000000000000000001001111111000000011111111100000100000001000000000111110000000111111
00000000111111111111100000000000000000000000000000000000000011111111110000000111111111100001110000000000000101111111000000011111
00010001111111111111100000001000000000000000000000000000000001011111110000000011111111000000100000000000000001111111000000011111
00000000111111111111100000011100000000000000000000000000000000011111110000000001111111000101000000000000000001111111100000001110
00000000011111111111000000001000000000000000000011100000000000011111100000000000011100000000000010000000000000111111100000000000
00000000001111111000000000000000000000000000000111110000000000011111000000000000000000000000000111000000000000111111100000000000
00000000001111111000000000000000000000000000000111110000011100011111000000000000000010000000000010000000000001011111000010000000
00000000000011110000000000000000010000000000000111110000111110001110000000000000000111000000000000000000000000001110000000000000
00000000000000100000000000000000111000000000000011100000111110000000000000000000000010000000000000000000000001111000001100000000
00000000000000000000000010000000010000000000000000000000111110000000000000000000000000000000000000000000000011111000011100000000
00000000011100000000000111000000000000000000000000000000011100000000000000000000000000000000000000000000000111111100001000000000
00000000111110000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000000
00000001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000000
00001111111111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111000000000000000
00111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110011100000000000
00011111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000
00011111011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000
00001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000
00000000000001000000000022222222222222222222222222222222222000222222222222222222222222222222222200000000000001000111110011100000
00000000000111100000000022222222222222222222222222222222222200222222222222222222222222222222222200000000000011100011100111110000
00000001001111100000000022000000000220002200000222000022222200222200000022000000220000000002200000000000000001000000000111110000
00000011111111110000000022222222000220002222222222000022220220222202222222222200222222220002200000000000000000011100000111110000
00000001011111110000000022222222000220002222222222000022220222222202222222222200222222220002200000000000000100111110000011100000
00000000011111110000000000000022000220002222220022000022220222222200000222000000000000220002200000000000000000111110010000000000
00000000001111100000000022222222000220002202222222222222220002222222222222222222222222220002200000000000000001111110111100000000
0000000000011100000000002222222200022000dd0d0d2ddd2ddd2ddd00022ddd2d2d2dd222dd2d2d2222220002200000000000000000111100111110000000
000001000000001000000000000000000000000d000d0d0d0d0d000d0d00000d0d0d0d0d0d0d000d0d0000000000000000000000000000000000111111000000
000011100000000000000000000000000000000ddd0d0d0ddd0dd00dd000000ddd0d0d0d0d0d000ddd0000000000000000000000000000000000111111100000
00000100000000000000000000000000000000000d0d0d0d000d000d0d00000d000d0d0d0d0d000d0d0000000000000000000000000000000000011101000000
000000011100000000000000000000000000000dd000dd0d000ddd0d0d00000d0000dd0d0d00dd0d0d0000000000000000000000000000000000011100000000
00000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000
00000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000
00000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000
00011111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000
00011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110100000
001111111110000000000000000000000000000000000d0d0ddd0ddd0ddd0ddd00dd0ddd00dd0000000000000000000000000000000000000000011101110000
001111111110000000000000000000000000000000000d0d0d0d0d0d0d0d00d00d0d0d0d0d000000000000000000000000000000000000000000000100100000
001111111110001000000000000000000000000000000d0d0ddd0dd00dd000d00d0d0dd00ddd0000000000000000000000000000000000011111101110000000
000111111100000000000000000000000000000000000ddd0d0d0d0d0d0d00d00d0d0d0d000d0000000000000000000000000000000000111111111100000000
000111111110000000000000000000000000000000000ddd0d0d0d0d0d0d0ddd0dd00d0d0dd00000000000000000000000000000000001111111111000000000
00001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111100000000
00000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111100000000
00000011111110000000000000000000880000880000000000000000000000000000000000000000000000000000000000000000000000111111111100000000
00000011111110000000000000000000880000880888088000088000080008800088880008888880008888800088880000000000000000011111111000000000
00000011111100000000000008080800880000880808088000088000080008800088000008000880008000000088000000000000000001111111111000000000
00000111111000000000000080808080880000880808888000088000080008800088800008000880008000000088800000000000000011111011100000000000
00001111111000000000000008080800880000880800888000088000008088000088000008888880008888800088000000000000000011111001110000000000
00001111111101000000000080808080888888880800088000088000000880000088000008088000000008800088000000000000000011111011111000000000
00001111111111100000000000000000088888800800088000088000000880000088880008008880008888800088880000000000000011110011111000000000
00000111111111000000000000000000008888000000000000000000000000000000000000000000000000000000000000000000000111110011111000000000
00000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110001110000000000
00000001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110111000000000000
00000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011101111100000000000
00000000011101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000000000
00000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111101110000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010111111111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111000000
00000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111110000000
00000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000
00000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100011100000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000000000
01110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000000
00100000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000000
00000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000000
00000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000000000
00000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000111000000
00000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000
00000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111110000
00010000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111110000
00000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111110000
00010000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111100000
00111011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000
00010011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000
00000111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000
00001111111111100000001000000000000000000000000000000000000000011100000000000000000000000000000000000000000000111001111111000000
00111111111111100000011100000000000000000000000000000000000000111110000000000000000000000000000000000000000001111101111111000000
01111111111111000100001000000000000000000000000000000010000000111110000111110000000000000000000000000000000011111110111110000000
11111111111111001110000000000000000000000000000000000111000000111110001111111000100000000000000000000000000011111110011100000000
11111111111111000100000000000000000000000000000000000010000000011100011111111000000000000000000000000000000011111111000000000000
11111111111111000000000000000001110000100000000000000000000000010000011111111100000000000000000000000000000001111111100000000000
01111111111110111000000000000011111001110000000011100000000000000000011111111110000000011100000000000000000000111111100000000000
00111111011101111100000000000111111100100000000111110011100000000000001111100111010000111110000000000000000000001111100000000000
00000000000001111100011101000111111100000000111111111111110000000000000111111111111000111110000000000000000000000111000000111000
00000000000001111100111110000111111100000001111111111111111000000001001111111111110010111110000000000000000011100000000001111100
00000000000000111001111111000111111000000001111111111111111010000011101111111111111000011100000000000000000111110000000001111100
00000000000000000001111111000011110000000001111111111111111000000001001111111111111000000000000000000000000111110000000001111100
00000000000000000001111111000000000000000000111011100111111000000000000111111111111000000000000000000000000111110000000000111000
00000000011100000000111111110000000000000000000000000011110000000000001011111111110001000000000000000000000011100000000000000001
00000000111110000000111111111000000000000000000000000000000000000000000000011111110011100000000000000000000000000000000000000011
00000000111110000000000011111000000000000000000000000000000000000000000000000111000001000000000000000000000000000000000000000001
00000000111110000000000011111000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011100000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000666060600000000006006660666066606060666066606600000000000000000000000000000000000000000000000000000000000000000000000000000
00000606060600600000060606060060006006060606006006060000000000000000000000000000000000000000000000000000000000000000000000000000
00000660066600000000060606600060006006660666006006060000000000000000000000000000000000000000000000000000000000000000000000000000
00000606000600600000060006060060006006060606006006060000000000000000000000000000000000000000000000000000000000000000000000000000
00000666066600000000006606060666006006060606066606060000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000666060606660660060600660000066600660000000000600666060006660066066606660066060606660600066606600666066606600000000000000000
00000060060606060606060606000000006006060060000006060600060006060600006000600600060606060600006006060060060006060000000000000000
00000060066606660606066006660000006006060000000006060660060006660666006000600666066006660600006006060060066006060000000000000000
00000060060606060606060600060000006006060060000006000600060006060006006000600006060606060600006006060060060006060000000000000000
00000060060606060606060606600000006006600000000000660666066606060660006006660660060606060666066606060660066606060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0203030303030303030303030303030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000008090a0b0c0d0e080f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121313131313131313131313131313140000001f18191a1b1c1d1e1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000001010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000020202020202020202001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2223232323232323232323232323232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011e00002962500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011400002b72300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703
011000002872300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b72100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
011000002b72100204002040020400204002040020400204002040020400204002040020400204002040020400204002040020400204002040020400204002040020400204002040020400204002040020400204
011d00003f21500704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704
011a00002953400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504
012800003153400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040000000000
