#jat402 Jacob Tapper
.include "constants.asm"
.include "macros.asm"

.data
dmg_incurred: .word 0
heart_sprite: .byte 
0,0,1,1,0,0,1,1,0,0
0,1,2,2,1,1,2,2,1,0
1,2,2,2,2,2,2,3,2,1
1,2,2,2,2,2,2,2,2,1
1,2,2,2,2,2,2,2,2,1
0,1,2,2,2,2,2,2,1,0
0,0,1,2,2,2,2,1,0,0
0,0,0,1,2,2,1,0,0,0
0,0,0,0,1,1,0,0,0,0

grass_sprite: .byte
13,13,13,13,13
10,13,10,13,13
10,15,10,10,10
10,10,10,15,10
15,10,10,10,10

map: .byte
0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,1,0,0,1,0,0,0
0,1,0,0,0,0,1,1,0,0,0,0
0,0,0,1,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,1,1,1,1,0,0,0,0
0,0,1,0,0,0,0,0,0,1,0,0
0,0,0,0,0,0,0,0,0,0,0,0
0,1,1,1,1,1,1,1,1,1,1,0

cloud1: .byte
-1,-1,-1,-1,-1
-1,-1,-1,-1,-1
-1,7,7,7,-1
7,7,7,7,7
-1,-1,-1,-1,-1

cloud2: .byte
-1,-1,-1,-1,-1
-1,-1,7,-1,-1
-1,7,7,7,7
7,7,7,7,7
-1,-1,-1,-1,-1
						#will add clouds if i can finish in time
cloud3: .byte
-1,-1,-1,-1,-1
-1,-1,7,7,-1
-1,7,7,7,7
7,7,7,7,7
-1,-1,-1,-1,-1

cloud4: .byte
-1,-1,-1,-1,-1
-1,-1,7,7,-1
-1,7,7,7,7
7,7,7,7,-1
-1,7,7,7,7

player_sprite: .byte
0,-1,-1,-1,0
0,0,0,0,0
0,5,0,6,0
0,0,0,0,0
-1,15,-1,15,-1

enemy_sprite: .byte
10,10,10,10,10
10,-1,-1,-1,10
10,-1,-1,-1,10
10,-1,-1,-1,10
10,-1,-1,-1,10

enemy_locations_x: .byte
42, 13, 29, 37, 6
enemy_locations_y: .byte
45, 35, 30, 15, 15

player_props: .word 27,45,0,0
enemies: .word 0,-20,0,0,0,-20,0,0,0,-20,0,0,0,-20,0,0,0,-20,0,0
proj_props: .word 0, 0, -1, 0
gravity: .byte 1
can_jump: .byte 1
jump_time: .word 0
jump_speed: .byte 4
bullet_cooldown: .word 0
invinc_frames: .word 0
enemy_count: .word 5
score: .word 0
game_over: .byte 0
game_started: .byte 0
move_cooldown: .word 0
move_for: .word 30

debug: .byte 0

.eqv pnum 2
.eqv psz 12
.eqv px 0
.eqv py 4
.eqv lastdir 8
.eqv invinc 12

.globl game
.text


game:
	enter
_game_while:

	jal	handle_input
	#jal start_game
	
	lb t0, game_over
	beq t0, 1, _ended
	#applying gravity to objects
	jal apply_gravity
	#drawing the blue background
	jal draw_background
	#creating the blocks on the map
	jal draw_map
	#drawing the player on screen at its coordinates
	jal draw_player
	#drawing the bullet
	jal draw_bullet
	#applying bullet physics
	jal bullet_physics
	#draw the enemies on screen and handle collision
	#jal draw_enemies
	#jal handle_enemy_collision
	#jal random_enemy_movements 
	#i couldnt get hte movements to work properly
	# all of the other stuff like gravity should work, but i couldnt get htem to move left and right in time
	#drawing the UI
	jal draw_game_area
	#drawing the heart sprite onto the UI
	jal draw_lives
	#handling the player controls and things
	jal handle_player
	#make sure the player is invincible when hit
	jal player_invincibility
	#making the map wrap back around for the player
	jal wrap_map
	li a0, 1
	jal inc_final_score
	
	lw t0, dmg_incurred
	blt t0, 8, _died
	j _else_died
	_died:
	lw t0, enemy_count
	bgt t0, 0, _skip_end
	_else_died:
	li t0, 1
	sb t0, game_over
	_ended:

	li	a0, 5
	li	a1, 5
	# This is a macro defined in macros.asm
	lstr	a2, "Press x"
	jal	display_draw_text

	li	a0, 11
	li	a1, 11
	# This is a macro defined in macros.asm
	lstr	a2, "to exit"
	jal	display_draw_text
	
	li	a0, 6
	li	a1, 30
	# This is a macro defined in macros.asm
	lstr	a2, "score"
	jal	display_draw_text
	
	li a0, 38
	li a1, 30
	lw a2, score
	jal display_draw_int
	
	_skip_end:

	# Must update the frame and wait
	jal	display_update_and_clear
	jal	wait_for_next_frame


	# Leave if x was pressed
	lw	t0, x_pressed
	bnez	t0, _game_end

	j	_game_while

_game_end:
	# Clear the screen
	jal	display_update_and_clear
	jal	wait_for_next_frame

	leave
	
inc_final_score:
	enter
		lw t0, score
		add t0, t0, a0
		sw t0, score
	leave

get_enemy_element:
	enter s0, s1
		move s1, a0
		la s0, enemies
		
		mul s1, s1, 16
		add s1, s0, s1
		move v0, s1
		
	leave s0, s1
	
start_game:
	enter
		jal	input_get_keys_held #starts the game
		beq v0, 0, _dont_initialize
		lb t0, game_started
		beq t0, 1, _dont_initialize
		li t0, 1
		sb t0, game_started
		jal initialize_enemies
		_dont_initialize:
	leave
	# currently not working
random_enemy_movements:
	enter s0, s1, s2, s3
		lb t0, game_started
		beq t0, 0, _dont_move_random
		li s0, 0
		_random_enemy_moves_forloop_enter:
		bge s0, 5, _random_enemy_moves_forloop_end
		
		move a0, s0 # loops through and tries to make it move
		jal get_enemy_element
		move s1, v0
		lw s2, px(s1)
		
		lw t0, frame_counter
		li t1, 60
		div t0, t1
		mfhi t1
		bne t1, 1, _random_enemy_moves_forloop_end
		li a0, 0
		li a1, 2
		li v0, 42
		syscall
		li s3, 0
		_move_inner_loop_start:
		bge s3, 30, _move_inner_loop_end
		li t0, 2
		lw t1, frame_counter
		div t1, t0
		mfhi t1
		beq t1, 0, _skip_iter_move
		beq v0, 1, _move_left # i cant get this to work 
		addi s2, s2, 1
		j _move_right
		_move_left:
		subi s2, s2, 1
		_move_right:
		sw s2, px(s1)
		addi s3,s3,1
		_skip_iter_move:
		
		j _move_inner_loop_start
		_move_inner_loop_end:
		
		addi s0, s0, 1
		j _random_enemy_moves_forloop_enter
		_random_enemy_moves_forloop_end:
		_dont_move_random:
	leave s0, s1, s2
	
initialize_enemies:
	enter s0
		li s0, 0
		_ie_forloop_start:
		bge s0, 5, _ie_forloop_end # places the enemies in the map using an array of preset locations
		move a0, s0
		jal get_enemy_element
		la t0,  enemy_locations_x
		add t0, t0, s0
		lb t0, 0(t0)
		la t1,  enemy_locations_y
		add t1, t1, s0
		lb t1, 0(t1)
		
		sw t0, px(v0)
		sw t1, py(v0)
		
		addi s0, s0, 1
		j _ie_forloop_start
		_ie_forloop_end:
	leave s0
	
draw_enemies:
	enter s0
		li s0, 0
		_de_forloop_start:
		bge s0, 5, _de_forloop_end# just draws the enemies on the screen using a loop
		move a0, s0
		jal get_enemy_element
		lw t0, invinc(v0)
		beq t0, 1, _skip_display_enemy
		
		lw a0, px(v0)
		lw a1, py(v0)
		la a2, enemy_sprite
		jal display_blit_5x5_trans
		
		_skip_display_enemy:
		
		addi s0, s0, 1
		j _de_forloop_start
		_de_forloop_end:
	leave s0
	
handle_enemy_collision:
	enter s0, s1
		li s0, 0
		_collide_enemy_player_forloop_start:
		bge s0, 5, _collide_enemy_player_forloop_end #uses the functions i made to go through and check if the enemies are colliding with the player
		
		move a0, s0
		jal get_enemy_element
		move s1, v0
		lw a0, px(s1)
		lw a1, py(s1)
		li a2, 5
		la s1, player_props
		lw a3, px(s1)
		lw v0, py(s1)
		li v1, 5
		jal entity_collision_check # checking collision
		beq v0, 0, _skip_collide_enemy_player
		
		jal damage_player
		
		_skip_collide_enemy_player:
		
		addi s0, s0, 1
		j _collide_enemy_player_forloop_start
		_collide_enemy_player_forloop_end:
	leave

handle_bullet_collision:
	enter s0, s1, s2
		la s2, proj_props
		lw s0, px(s2)
		lw s1, py(s2)
		
		move a0, s0
		move a1, s1
		jal whos_pixel
		move a0, v0
		move a1, v1
		jal inside_wall
		beq v0, 0, _skip_bullet_collision_wall
		li t0, 0
		sw t0, invinc(s2)
		
		_skip_bullet_collision_wall: # uses the inwall function to check whether the bullet is inside of a wall
		move a0, s0
		move a1, s1
		li a2, 1
		la s2, player_props
		lw s0, px(s2)
		lw s1, py(s2)
		move a3, s0
		move v0, s1
		li v1, 5
		jal entity_collision_check
		beq v0, 0, _skip_bullet_collision_player
		jal damage_player
		la s1, proj_props
		li t0, 0
		sw t0, invinc(s1)
		_skip_bullet_collision_player: # checks if the bullet is in the player and will hurt the player if so
		
		li s0, 0
		_ec_forloop_start: # loop to go through and check every enemy and use a function to tell whether its inside the player
		bge s0, 5, _ec_forloop_end
		move a0, s0
		jal get_enemy_element
		move s1, v0
		lw t0, invinc(s1)
		beq t0, 1, _skip_kill_entity
		lw a3, px(s1)
		lw v0, py(s1)
		li v1, 5
		la t0, proj_props
		lw a0, px(t0)
		lw a1, py(t0)
		li a2, 1
		jal entity_collision_check
		beq v0, 0, _skip_kill_entity
		li t0, 1
		sw t0, invinc(s1)
		
		lw t0, enemy_count
		subi t0, t0, 1
		sw t0, enemy_count
		
		li t0, -20
		sw t0, px(s1) #moves the enemy off screen to avoid further collisions
		sw t0, py(s1)
		
		li a0, 25
		jal inc_final_score # adds 25 points to score for enemy kills
		
		la s1, proj_props
		li t0, 0
		sw t0, invinc(s1)
		
		_skip_kill_entity:
		
		addi s0, s0, 1
		j _ec_forloop_start # loop end
		_ec_forloop_end:
		_skip_bullet_collision_enemy:
	
	leave s0, s1, s2
	
#takes a0 and a1 (x and y) and a2 (size) first entity
#also takes a3, v0, and v1 (x, y and size) for the second entity
#returns v0: 0 for no collision, 1 for collision
entity_collision_check:
	push ra
	push s0 #x1
	push s1 #y1
	push s2 #size1
	push s3 #x2
	push s4 #y2
	push s5 #size2
	
	move s0, a0
	move s1, a1
	move s2, a2
	move s3, a3
	move s4, v0
	move s5, v1
	
	subi s2, s2, 1
	subi s5, s5, 1
	
	add t0, s0, s2 #moved x and y's by size (to temporary)
	add t1, s1, s2
	add t2, s3, s5
	add t3, s4, s5
	# return true if a collision happens
	blt t0, s3, _return_collided
	blt t2, s0, _return_collided
	blt t1, s4, _return_collided
	blt t3, s1, _return_collided
	li v0, 1
	j _collision_end
	_return_collided:
	li v0, 0
	_collision_end:
	pop s5
	pop s4
	pop s3
	pop s2
	pop s1
	pop s0
	pop ra
jr ra

damage_player:
	enter
		la t0, player_props
		lw t1, invinc(t0)
		beq t1, 1, _skip_damage # just hurts the player and gives invincibility frames
		li t1, 1
		sw t1, invinc(t0)
		li t1, 35
		sw t1, invinc_frames
		lw t1, dmg_incurred
		addi t1, t1, 3
		sw t1, dmg_incurred
		
		_skip_damage:
	leave

player_invincibility:
	enter
		la t0, player_props
		lw t1, invinc(t0)
		beq t1, 0, _skip_invinc # handles the invincibility and decrements the cooldown for them
		lw t1, invinc_frames
		bgt t1, 0, _cooldown_dec
		li t2, 0
		sw t2, invinc(t0)
		
		_cooldown_dec:
		subi t1, t1, 1
		sw t1, invinc_frames
		_skip_invinc:
		
	leave

bullet_physics:
	enter
		la t0, proj_props
		lw t1, px(t0)
		lw t2, lastdir(t0) #using last dir of bullet to check which direction to move in
		mul t2, t2, 2
		add t1, t1, t2
		lw t2, invinc(t0)
		beq t2, 0, _skip_bullet_physics # if the bullet doesnt exist dont apply physics
		sw t1, px(t0)
		jal handle_bullet_collision
		_skip_bullet_physics:
	leave
	
draw_bullet:
	enter
		la t0, proj_props # draw the bullet on the screen using the display set pixel function
		lw t1, invinc(t0)
		bne t1, 1, _skip_draw_bullet
		lw a0, px(t0)
		lw a1, py(t0)
		li a2, COLOR_RED
		jal display_set_pixel
		_skip_draw_bullet:
	leave
	
handle_projectile:
	enter s0, s1, s2, s3
		la s3, player_props
		lw s0, px(s3)
		lw s1, py(s3) #loading player props
		lw s2, lastdir(s3)
		
		la s3, proj_props
		lw t1, invinc(s3) #loading projectile props
		beq t1, 1, _skip_shoot
		li t1, 1
		sw t1, invinc(s3)

		bne s2, 1, _shoot_right
		addi s0, s0, 5
		addi s1, s1, 2 #spawning bullet
		sw s0, px(s3)
		sw s1, py(s3)
		li t0, 1
		sw t0, lastdir(s3) #setting the last dir of the bullet to the last dir of the player to keep it moving in the same direction
		
		j _shoot_left
		_shoot_right:
		
		subi s0, s0, 1
		addi s1, s1, 2
		sw s0, px(s3)
		sw s1, py(s3) #spawning bullet
		li t0, -1
		sw t0, lastdir(s3)
		
		_shoot_left:
		
		_skip_shoot:
	
	leave s0, s1, s2, s3
	
jump_cancel:
	enter
	li t0, 0
	sb t0, can_jump # reset all of the jump stuff to stop when hitting head
	li t0, 0
	sw t0, jump_time
	li t0, 4
	sb t0, jump_speed
	
	leave
	
wrap_map:
	enter s0, s1, s2
		#player wrap around start
		la s2, player_props
		lw s0, px(s2)
		lw s1, py(s2)
		
		bgt s0, -2, _wrap_left
		addi s0, s0, 64
		sw s0, px(s2)
		j _wrap_down
		_wrap_left:
		blt s0, 64, _wrap_right # just checking whether the pixels are too far in any direction (except for up)
		subi s0, s0, 64
		sw s0, px(s2)
		_wrap_right:
		
		blt s1, 55, _wrap_down
		subi s1, s1, 68
		sw s1, py(s2)
		_wrap_down:
		
		#player wrap around end
		
		la s2, proj_props
		lw s0, px(s2)
		lw s1, py(s2)
		
		bgt s0, -2, _wrap_left_proj
		addi s0, s0, 64
		sw s0, px(s2)
		j _wrap_down_proj
		_wrap_left_proj:
		blt s0, 64, _wrap_right_proj
		subi s0, s0, 64
		sw s0, px(s2)
		_wrap_right_proj:
		
		blt s1, 55, _wrap_down_proj
		subi s1, s1, 68
		sw s1, py(s2)
		_wrap_down_proj:
		
		jal enemy_wrap_around
		
	leave s0, s1, s2
	
enemy_wrap_around:
	enter s0, s1, s2, s3
		li s3, 0
		_enemy_wrap_around_for_start:
		bge s3, 5, _enemy_wrap_around_for_end # goes through and checks every enemy to see if theyre off screen and moves them
		
		move a0, s3
		jal get_enemy_element
		move s2, v0
		lw s0, px(s2)
		lw s1, py(s2)
		
		bgt s0, -2, _wrap_left_enemy
		addi s0, s0, 64
		sw s0, px(s2)
		j _wrap_down_enemy
		_wrap_left_enemy:
		blt s0, 64, _wrap_right_enemy
		subi s0, s0, 64
		sw s0, px(s2)
		_wrap_right_enemy:
		blt s1, 55, _wrap_down_enemy
		subi s1, s1, 68
		sw s1, py(s2)
		_wrap_down_enemy:
		
		addi s3, s3, 1
		j _enemy_wrap_around_for_start
		_enemy_wrap_around_for_end:
	leave s0, s1, s2, s3
	
enemy_gravity:
	enter s0, s1, s2, s3
		li s0, 0
		_enemy_gravity_forloop_start:
		bge s0, 5, _enemy_gravity_forloop_end # checks whether each entity is on the ground if not then lower the y coordinate
		move a0, s0
		jal get_enemy_element
		move s1, v0
		lw s2, px(s1)
		lw s3, py(s1)
		
		addi a1, s3, 1
		move a0, s2
		jal inside_wall #check if enemy touching floor
		beq v0, 1, _skip_enemy_gravity
		addi s3, s3, 1
		sw s3, py(s1)
		_skip_enemy_gravity:
		
		addi s0, s0, 1
		j _enemy_gravity_forloop_start
		_enemy_gravity_forloop_end:
		
	leave s0, s1, s2, s3
	
apply_gravity:
	enter s0, s1, s2
		lb t0, gravity #checking if gravity is enabled
		beq t0, 0, _end_gravity
		
		la s2, player_props
		lw s0, px(s2) #loading player properties
		lw s1, py(s2)
		
		subi a1, s1, 0
		move a0, s0
		jal inside_wall
		beq v0, 1, _skip_floor_check #check if player head bonking
		addi a1, s1, 1
		move a0, s0
		jal inside_wall #check if player touching floor
		beq v0, 1, _if_gravity
		j _skip_jump_cancel
		_skip_floor_check:
		jal jump_cancel	#when head bonking cancel jump
		_skip_jump_cancel:
		
		addi s1, s1, 1 #applying gravity
		sw s1, py(s2)
		j _skip_jump_reset
		_if_gravity:
		lw t0, jump_time
		bgt t0, 0, _skip_jump_reset #if player touches floor, allow them to jump again
		li t0, 1
		sb t0, can_jump
		_skip_jump_reset:
		
		
		la s2, proj_props #loading proj properties
		lw s1, py(s2)
		lw s0, invinc(s2)
		beq s0, 0, _end_gravity
		li t0, 24
		lw t1, frame_counter
		div t1, t0
		mfhi t0
		bne t0, 1, _end_gravity
		
		addi s1, s1, 1
		sw s1, py(s2)
		
		_end_gravity:
		lb t0, game_started
		beq t0, 0, _no_enemy_gravity
		jal enemy_gravity # custom entity gravity function when the the game has started
		_no_enemy_gravity:

	leave s0, s1, s2
	
draw_player:
	enter s0, s1
	la t0, player_props
	lw s0, px(t0) #getting player properties
	lw s1, py(t0)
	
	lw t1, invinc_frames
	li t2, 5
	div t1, t2
	mfhi t2
	beq t2, 1, _skip_draw_player
	move a0, s0
	move a1, s1
	la a2, player_sprite #drawing the player on screen
	jal display_blit_5x5_trans
	_skip_draw_player:
	
	leave s0, s1
	
handle_player:
	enter s0, s1, s2
	la s2, player_props
	lw s0, px(s2) #loading player properties
	lw s1, py(s2)
	
	lw t1, bullet_cooldown
	subi t1, t1, 1
	sw t1, bullet_cooldown
	bgt t1, 0, _b_pressed_if
	
	lw t1, b_pressed
	beq t1, 0, _b_pressed_if
	li t1, 30
	sw t1, bullet_cooldown
	
	jal handle_projectile
	_b_pressed_if:
	
	lw t1, right_pressed
	beq t1, 0, _right_pressed_if
	li t1, 1
	sw t1, lastdir(s2)
	addi a0, s0, 1 #allowing right movement in the case there is no wall to the right
	move a1, s1
	jal inside_wall
	bne v0, 0, _right_pressed_if
	
	addi s0, s0, 1
	sw s0, px(s2)
	_right_pressed_if:
	
	lw t1, left_pressed
	beq t1, 0, _left_pressed_if
	li t1, -1
	sw t1, lastdir(s2)
	subi a0, s0, 1 #allowing left movement in the case there is no wall to the left
	move a1, s1
	jal inside_wall
	bne v0, 0, _left_pressed_if
	
	subi s0, s0, 1
	sw s0, px(s2)
	_left_pressed_if:
	
	lb t1, can_jump
	beq t1, 0, _skip_up_check
	
	lw t1, up_pressed # if the player is jumping, then it will hold down the up arrow for the player
	beq t1, 0, _up_pressed_if
	
	_skip_up_check:
	
	subi a1, s1, 1
	move a0, s0
	jal inside_wall #check if player is touching ceiling
	beq v0, 1, _up_pressed_if
	addi a1, s1, 1
	move a0, s0
	jal inside_wall #check if player touching floor
	beq v0, 0, _skip_can_jump
	
	lb t1, can_jump
	beq t1, 0, _skip_can_jump #letting the player jump again
	sb zero, can_jump
	li t1, 12
	sw t1, jump_time
	_skip_can_jump:
	lw t1, jump_time
	ble t1, 0, _skip_jump # if the player currently has air time then it increments the players y coord
	li t2, 3
	div t1, t2
	mfhi t2
	beq t2, 0, _dec_speed
	lb t2, jump_speed	#to make the jump a little more realistic, the speed at which the jump starts is faster than when it ends
	ble t2, 2, _dec_speed
	subi t2, t2, 1
	sb t2, jump_speed
	_dec_speed:
	subi t1, t1, 1
	sw t1, jump_time #decreasing the allowed air time
	lb t1, jump_speed #actually changing the players y coord
	sub s1, s1, t1
	sw s1, py(s2)
	j _up_pressed_if
	_skip_jump:
	li t1, 4
	sb t1, jump_speed #resetting the speed
	_up_pressed_if:
		
	leave s0, s1, s2

inside_wall:
	enter s0, s1, s2, s3, s4

	#jal whos_pixel
	move s3, a0
	move s4, a1
	
	#debug graphic
	lb t0, debug
	beq t0, 0, _debug_c_if
	move a0, s3
	move a1, s4
	li a2, COLOR_ORANGE
	jal display_set_pixel
	move a0, s3
	move a1, s4
	addi a0, a0, 4
	addi a1, a1, 4
	li a2, COLOR_ORANGE
	jal display_set_pixel
	_debug_c_if:
	#
	
	li s0, 0
	_inside_wall_forloop_enter:
	beq s0, 12, _inside_wall_forloop_exit #iterating through the map matrix
	
	li s1, 0
		_inside_wall_forloop_enter_2:
		beq s1, 11, _inside_wall_forloop_exit_2
	
		la t0, map
		add t0, t0, s0
		mul t1, s1, 12 #checking the value at the current iteration
		add t0, t0, t1
		lb t0, 0(t0)
		
		bne t0, 1,_inside_wall_if_skip # if iteration is a 1, then it will check for collision (dont want to collide with nothing)
			move a0, s0
			move a1, s1
			jal find_coords
			
			addi t1, s3, 5 #x1
			addi t2, s4, 5 #y1
			addi t3, v0, 5 #x2
			addi t4, v1, 5 #y2
			
			ble t1, v0, _collide #checking for collision of 2 blocks
			ble t3, s3, _collide
			ble t2, v1, _collide
			ble t4, s4, _collide
			li v0, 1 # returing true if collided
			j _exit_inwall
			_collide:
			
			#debug graphic
			lb t0, debug
			beq t0, 0, _debug_d_if
			move a0, v0
			move a1, v1
			li a2, COLOR_RED
			jal display_set_pixel
			move a0, v0
			move a1, v1
			addi a0, a0, 4
			addi a1, a1, 4
			li a2, COLOR_RED
			jal display_set_pixel
			_debug_d_if:
			#
			
		_inside_wall_if_skip:
	
		addi s1, s1, 1
		j _inside_wall_forloop_enter_2
		_inside_wall_forloop_exit_2:
	
	addi s0, s0, 1
	j _inside_wall_forloop_enter
	_inside_wall_forloop_exit:
	li v0, 0 # returning false if no collision
	_exit_inwall:
	
	leave s0, s1, s2, s3, s4

find_coords:
	enter s0, s1
	move s0, a0
	move s1, a1
	
	mul v0, s0, 5 # just turns it into a 5 wide and high,then adjusting for game area offset
	mul v1, s1, 5
	addi v0, v0, 2
	
	leave s0, s1

whos_pixel:
	enter s0, s1
	move s0, a0
	move s1, a1
	
	li t0, 5
	subi s0, s0, 2 #checking which block a pixel belongs to using math
	div s0, t0
	mflo t1
	mul v0, t1, 5 #adjusts offset then turns it into a smaller matrix of pixels (which represents the map)
	addi v0, v0, 2 #then turning it back into the larger 5x5 block map, but the pixel will now be the first in the block
	div s1, t0
	mflo t1
	mul v1, t1, 5
	
	leave s0, s1

draw_map:
	enter s0, s1
	
	li s0, 0
	_draw_map_forloop_enter:
	beq s0, 12, _draw_map_forloop_exit
	
	li s1, 0
		_draw_map_forloop_enter_2:
		beq s1, 11, _draw_map_forloop_exit_2
	
		la t0, map
		add t0, t0, s0
		mul t1, s1, 12 #iterating through the map
		add t0, t0, t1
		lb t0, 0(t0)
		
		bne t0, 1,_draw_map_if_skip
		mul a0, s0, 5
		mul a1, s1, 5 # if there is a 1 then place the grass sprite
		addi a0, a0, 2
		la a2, grass_sprite
		jal display_blit_5x5
		_draw_map_if_skip:
	
		addi s1, s1, 1
		j _draw_map_forloop_enter_2
		_draw_map_forloop_exit_2:
	
	addi s0, s0, 1
	j _draw_map_forloop_enter
	_draw_map_forloop_exit:
	
	leave s0, s1

draw_lives:
	enter s0, s1, s3, s4
	li s0, 27
	li s1, 55
	li s3, 0
	li s4, 0
	
	_lives_forloop_enter:
	beq s3, 90, _lives_forloop_exit
	
	la t0, heart_sprite
	add t0, t0, s3
	lb t0, 0(t0)
	
	li a0, 0
	add a0, a0, s0 #this is a custom 10x9 pixel display function
	li t2, 10
	div s3, t2
	mfhi t1
	add a0, a0, t1
	
	li a1, 0
	add a1, a1, s1
	add a1, a1, s4	
	
	bne t1, 9, _heart_if
	addi s4, s4, 1
	_heart_if:
	
	li a2, 1
	li a3, 1
	
	beq t0, 0, _heart_color_skip
	bne t0, 3, _heart_color_if 
	li v1, COLOR_WHITE
	jal display_fill_rect
	j _heart_color_skip
	_heart_color_if:
	bne t0, 2, _heart_color_else # all of this is just checking which color it should put
	lw t0, dmg_incurred # this is making it skip to the else when damage is incurred, allowing for the health bar to decrease
	blt s4, t0, _heart_color_else
	li v1, COLOR_RED
	jal display_fill_rect
	j _heart_color_skip
	_heart_color_else:
	li v1, COLOR_BRICK
	jal display_fill_rect
	_heart_color_skip:
	
	addi s3, s3, 1
	j _lives_forloop_enter
	_lives_forloop_exit:
	
	leave s0, s1, s3, s4

draw_game_area:
	enter s0
		
		li a0, 0
		li a1, 0
		li a2, 1
		li a3, 63
		li v1, COLOR_MAGENTA
		jal display_fill_rect
		
		li a0, 1
		li a1, 0
		li a2, 1
		li a3, 55
		li v1, COLOR_PURPLE #mostly manually making the outer edges of the game area
		jal display_fill_rect
		
		li a0, 63
		li a1, 0
		li a2, 1
		li a3, 63
		li v1, COLOR_MAGENTA
		jal display_fill_rect
		
		li a0, 62
		li a1, 0
		li a2, 1
		li a3, 55
		li v1, COLOR_PURPLE
		jal display_fill_rect
		
		li a0, 0
		li a1, 63
		li a2, 64
		li a3, 1
		li v1, COLOR_MAGENTA
		jal display_fill_rect
		
		li a0, 1
		li a1, 55
		li a2, 62
		li a3, 1
		li v1, COLOR_PURPLE
		jal display_fill_rect
		
		li s0, 1
		_area_forloop_enter:
		bgt s0, 61, _area_forloop_exit
		
		move a0, s0
		li a1, 56
		li a2, 2
		li a3, 7
		li v1, COLOR_PURPLE # a for loop that displays the interchanging pattern at the bottom
		jal display_fill_rect
		
		addi s0, s0, 4
		
		subi t0, s0, 2
		move a0, t0
		li a1, 56
		li a2, 2
		li a3, 7
		li v1, COLOR_MAGENTA
		jal display_fill_rect
		
		j _area_forloop_enter
		_area_forloop_exit:
		
	leave s0
	
	draw_background:
	enter
		li a0, 2
		li a1, 0
		li a2, 60 #makes the background blue
		li a3, 55
		li v1, COLOR_BLUE
		jal display_fill_rect
		
	leave
