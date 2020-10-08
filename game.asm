;; game state memory location
.equ T_X, 0x1000                  ; falling tetrominoe position on x
.equ T_Y, 0x1004                  ; falling tetrominoe position on y
.equ T_type, 0x1008               ; falling tetrominoe type
.equ T_orientation, 0x100C        ; falling tetrominoe orientation
.equ SCORE,  0x1010               ; score
.equ GSA, 0x1014                  ; Game State Array starting address
.equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
.equ LEDS, 0x2000                 ; LED address
.equ RANDOM_NUM, 0x2010           ; Random number generator address
.equ BUTTONS, 0x2030              ; Buttons addresses

;; type enumeration
.equ C, 0x00
.equ B, 0x01
.equ T, 0x02
.equ S, 0x03
.equ L, 0x04

;; GSA type
.equ NOTHING, 0x0
.equ PLACED, 0x1
.equ FALLING, 0x2

;; orientation enumeration
.equ N, 0
.equ E, 1
.equ So, 2
.equ W, 3
.equ ORIENTATION_END, 4

;; collision boundaries
.equ COL_X, 4
.equ COL_Y, 3

;; Rotation enumeration
.equ CLOCKWISE, 0
.equ COUNTERCLOCKWISE, 1

;; Button enumeration
.equ moveL, 0x01
.equ rotL, 0x02
.equ reset, 0x04
.equ rotR, 0x08
.equ moveR, 0x10
.equ moveD, 0x20

;; Collision return ENUM
.equ W_COL, 0
.equ E_COL, 1
.equ So_COL, 2
.equ OVERLAP, 3
.equ NONE, 4

;; start location
.equ START_X, 6
.equ START_Y, 1

;; game rate of tetrominoe falling down (in terms of game loop iteration)
.equ RATE, 5

;; standard limits
.equ X_LIMIT, 12
.equ Y_LIMIT, 8



;; TODO Insert your code here
main:
    addi  sp, zero, 0x2000

    loop2:
      call  reset_game

      loop3:
        add		s1, zero, zero

        loop4:                    ; while i < RATE
          cmpeqi  s0, s1, RATE
          bne     s0, zero, next4
          call    draw_gsa
          call    display_score
          addi    a0, zero, NOTHING
          call    draw_tetromino
          call    wait
          call    get_input
          beq	  v0, zero, not_pressed
          add	  a0, v0, zero
          call    act

        not_pressed:
          addi    a0, zero, FALLING
          call    draw_tetromino
          addi    s1, s1, 1
          br	  loop4

        next4:
          addi    a0, zero, NOTHING
          call    draw_tetromino
          addi	  a0, zero, moveD
          call    act
          addi    a0, zero, FALLING
          call    draw_tetromino
          beq     v0, zero, loop3
          addi    a0, zero, PLACED
          call    draw_tetromino

        insideloop2:
          call    detect_full_line
          cmpeqi  s0, v0, Y_LIMIT
          bne     s0, zero, next7
          add     a0, v0, zero
          call    remove_full_line
          call    increment_score
          br	  insideloop2

        next7:
        call        generate_tetromino
        addi	    a0, zero, OVERLAP
        call        detect_collision
        cmpeqi      s6, v0, NONE
        bne		    s6, zero, draw         ; check for collision
        br		    loop2
        draw:
          addi    a0, zero, FALLING
          call    draw_tetromino
          br      loop3
      ret


;;#####################################################################
;;        PART 3
;;#####################################################################
  ; BEGIN:clear_leds
  clear_leds:
    stw		zero, LEDS+0(zero)
    stw		zero, LEDS+4(zero)
    stw		zero, LEDS+8(zero)
  ret
  ; END:clear_leds

  ; BEGIN:set_pixel
  set_pixel:
    addi    t0, zero, 3
    addi	t1, zero, 7
    addi    t7, zero, LEDS

    blt		t0, a0, second
  	add     t2, a0, zero
    br      next

  second:
    blt		t1, a0, third
    addi    t2, a0, -4
    addi	t7, t7, 4
    br      next

  third:
    addi    t2, a0, -8
    addi	t7, t7, 8

  next:
    slli    t2, t2, 3
    add		t2, a1, t2
    addi    t3, zero, 1
    sll		t3, t3, t2
    ldw		t4, 0(t7)
    or		t3, t3, t4
    stw		t3, 0(t7)
    ret
  ; END:set_pixel

  ; BEGIN:wait
  wait:
    addi    t0, zero, 1
    slli    t0, t0, 0x14
  loop:
    beq	    t0, zero, exit
    addi    t0, t0, -1
    br loop
  exit:
    ret
  ; END:wait


;;#####################################################################
;;        PART 4
;;#####################################################################
  ; BEGIN:in_gsa
  in_gsa:
  addi	sp, sp, -24
  stw		a0, 0(sp)
  stw		a1, 4(sp)
  stw		t0, 8(sp)
  stw		t1, 12(sp)
  stw		t2, 16(sp)
  stw		t3, 20(sp)

    addi		t1, zero, 11
    addi		t3, zero, 7
    cmplti	t0, a0, 0
    cmplt		t1, t1, a0
    cmplti	t2, a1, 0
    cmplt		t3, t3, a1
    or		  t1, t1, t0
    or		  t3, t3, t2
    or	  	t1, t1, t3
    add		  v0, zero, t1

    ldw		a0, 0(sp)
    ldw		a1, 4(sp)
    ldw		t0, 8(sp)
    ldw		t1, 12(sp)
    ldw		t2, 16(sp)
    ldw		t3, 20(sp)
    addi	sp, sp, 24
    ret
  ; END:in_gsa

; BEGIN:get_gsa
get_gsa:
  addi	sp, sp, -12
  stw		a0, 0(sp)
  stw		a1, 4(sp)
  stw		t0, 8(sp)

    slli	t0, a0, 3
    add		t0, t0, a1
    slli  t0, t0, 2
    addi	t0, t0, GSA
    ldw   v0, 0(t0)

    ldw		a0, 0(sp)
    ldw		a1, 4(sp)
    ldw		t0, 8(sp)
    addi	sp, sp, 12
    ret
;   END:get_gsa

; BEGIN:set_gsa
set_gsa:
    addi	sp, sp, -16
    stw		a0, 0(sp)
    stw		a1, 4(sp)
    stw   a2, 8(sp)
    stw		t0, 12(sp)

    slli	t0, a0, 3
    add		t0, t0, a1
    slli    t0, t0, 2
    addi	t0, t0, GSA
    stw     a2, 0(t0)

    ldw		a0, 0(sp)
    ldw		a1, 4(sp)
    ldw   a2, 8(sp)
    ldw		t0, 12(sp)
    addi	sp, sp, 16
    ret
; END:set_gsa


;;#####################################################################
;;        PART 5
;;#####################################################################
; BEGIN:draw_gsa
draw_gsa:
    addi t0, zero, 0
    addi t1, zero, 96

  loop_offset:
    beq t0, t1, end_here

    srli t2, t0, 5
    slli t2, t2, 2
    ldw t3, LEDS(t2)

    andi t4, t0, 31
    addi t5, zero, 1
    sll t5, t5, t4

    slli t4, t0, 2
    ldw t6, GSA(t4)
    bne t6, zero, led_on
    addi t6, zero, -1
    xor t5, t5, t6
    and t6, t5, t3
    br one_more_step

  led_on:
    or t6, t3, t5

  one_more_step:
    stw t6, LEDS(t2)
    addi t0,t0, 1
    br loop_offset

  end_here:
ret
; END:draw_gsa

;;#####################################################################
;;        PART 6
;;#####################################################################

;BEGIN: draw_tetromino
draw_tetromino:
    addi	sp, sp, -48
    stw		s0, 44(sp)
    stw		s1, 40(sp)
    stw		s2, 36(sp)
    stw		s3, 32(sp)
    stw		s4, 28(sp)
    stw		s5, 24(sp)
    stw		s6, 20(sp)
    stw		s7, 16(sp)
    stw		t0, 12(sp)
    stw		t1, 8(sp)
    stw		t2, 4(sp)
    stw		ra, 0(sp)

    addi	s0, zero, T_type
    addi	s1, zero, T_orientation
    addi	s2, zero, T_X
    addi	s3, zero, T_Y

    ldw		s0, 0(s0)
    ldw		s1, 0(s1)
    ldw		s2, 0(s2)
    ldw		s3, 0(s3)

    addi	t0, zero, 1
    addi	t1, zero, 2

    slli	s4, s0, 4
    slli  s1, s1, 2
    add		s4, s4, s1
    ldw		s5, DRAW_Ax(s4)
    ldw		t2, DRAW_Ay(s4)

    add		s6, zero, a0

    add		a0, zero, s2
    add		a1, zero, s3
    add		a2, zero, s6

    call  set_gsa

    ldw		s7, 0(s5)
    add   a0, s2, s7
    ldw		s7, 0(t2)
    add   a1, s3, s7
    call  set_gsa

    ldw		s7, 4(s5)
    add   a0, s2, s7
    ldw		s7, 4(t2)
    add   a1, s3, s7
    call  set_gsa

    ldw		s7, 8(s5)
    add   a0, s2, s7
    ldw		s7, 8(t2)
    add   a1, s3, s7
    call  set_gsa

    ldw		s0, 44(sp)
    ldw		s1, 40(sp)
    ldw		s2, 36(sp)
    ldw		s3, 32(sp)
    ldw		s4, 28(sp)
    ldw		s5, 24(sp)
    ldw		s6, 20(sp)
    ldw		s7, 16(sp)
    ldw		t0, 12(sp)
    ldw		t1, 8(sp)
    ldw		t2, 4(sp)
    ldw		ra, 0(sp)
    addi	sp, sp, 48
    ret

;END: draw_tetromino


;;#####################################################################
;;        PART 7
;;#####################################################################
;BEGIN:generate_tetromino
  generate_tetromino:
    addi sp, sp, -4
	  stw ra, 0(sp)

    addi t1, zero, 5
  tryGenerateNumber:
    add t0, zero, zero
    ldw t0, RANDOM_NUM(zero)
	  slli t0, t0, 29
	  srli t0, t0, 29
    bge t0, t1, tryGenerateNumber

    addi t2, zero, START_X
    addi t3, zero, START_Y
    addi t4, zero, N

	  stw t2, T_X(zero)
	  stw t3, T_Y(zero)
	  stw t4, T_orientation(zero)
	  stw t0, T_type(zero)

	  ldw ra, 0(sp)
    addi sp, sp, 4
  ret
; END:generate_tetromino

;;#####################################################################
;;        PART 8
;;#####################################################################

; BEGIN:detect_collision
  detect_collision:
    addi sp, sp, -60
    stw ra, 0(sp)
    stw a0, 4(sp)
    stw t0, 8(sp)
    stw t1, 12(sp)
    stw t2, 16(sp)
    stw t3, 20(sp)
    stw t4, 24(sp)
    stw s0, 28(sp)
    stw s1, 32(sp)
    stw s2, 36(sp)
    stw s3, 40(sp)
    stw s4, 44(sp)
    stw s5, 48(sp)
    stw s6, 52(sp)
    stw s7, 56(sp)

    add s0, zero, a0
    addi v0, zero, NONE ;; =4

    ldw s1, T_type(zero)
    addi t0, zero, C
    addi t1, zero, B
    addi t2, zero, T
    addi t3, zero, S
    addi t4, zero, L

  find_type_0:
    bne s1, t0, find_type_1
    addi t0, zero, 0
    br typeComparisonDone

  find_type_1:
    bne s1, t1, find_type_2
    addi t0, zero, 4
    br typeComparisonDone

  find_type_2:
    bne s1, t2, find_type_3
    addi t0, zero, 8
    br typeComparisonDone

  find_type_3:
    bne s1, t3, find_type_4
    addi t0, zero, 12
    br typeComparisonDone

  find_type_4:
    bne s1, t4, typeComparisonDone
    addi t0, zero, 16

  typeComparisonDone:
    slli t7, t0, 2


    ldw s1, T_orientation(zero)
    addi t0, zero, N
    addi t1, zero, E
    addi t2, zero, So
    addi t3, zero, W

  find_orientation_N:
    bne s1, t0, find_orientation_E
    addi t1, zero, N
    br orientationComparisonDone

  find_orientation_E:
    bne s1, t1, find_orientation_So
    addi t1, zero, E
    br orientationComparisonDone

  find_orientation_So:
    bne s1, t2, find_orientation_W
    addi t1, zero, So
    br orientationComparisonDone

  find_orientation_W:
    bne s1, t3, orientationComparisonDone
    addi t1, zero, W

  orientationComparisonDone:
    slli t1, t1, 2


  add t0, t7, t1

  addi s4, t0, DRAW_Ax
  ldw s4, 0(s4)

  addi s5, t0, DRAW_Ay
  ldw s5, 0(s5)

  ldw s6, T_X(zero)
  ldw s7, T_Y(zero)

  addi t0, zero, W_COL
  addi t1, zero, E_COL
  addi t2, zero, So_COL
  addi t3, zero, OVERLAP
  addi t4, zero, NONE

  find_west_col:
    bne a0, t0, find_east_col
    addi s6, s6, -1
    br end_col_orientation

  find_east_col:
    bne a0, t1, find_south_col
    addi s6, s6, 1
    br end_col_orientation

  find_south_col:
    bne a0, t2, end_col_orientation
    addi s7, s7, 1

  end_col_orientation:

    add s1, zero, zero
    addi s3, zero, X_LIMIT

    addi s2, zero, 1

  loop_here:
    beq s1, s3, endLoop
    add t0, s4, s1
    ldw t1, 0(t0)
    add a0, t1, s6

    add t0, s5, s1
    ldw t1, 0(t0)
    add a1, t1, s7

    call in_gsa
    beq v0, zero, in_gsa_OK
    ldw v0, 4(sp)
    br end_of_detect_col

  in_gsa_OK:
    call get_gsa
    bne v0, s2, no_col_detected
    ldw v0, 4(sp)
    br end_of_detect_col

  no_col_detected:
    addi s1, s1, 4
    br loop_here

  endLoop:
    add a0, zero, s6
    add a1, zero, s7

    call get_gsa
    bne v0, s2, nothing_happened
    ldw v0, 4(sp)
    br end_of_detect_col

  nothing_happened:
    addi v0, zero, 4
  end_of_detect_col:

  ldw ra, 0(sp)
  ldw a0, 4(sp)
  ldw t0, 8(sp)
  ldw t1, 12(sp)
  ldw t2, 16(sp)
  ldw t3, 20(sp)
  ldw t4, 24(sp)
  ldw s0, 28(sp)
  ldw s1, 32(sp)
  ldw s2, 36(sp)
  ldw s3, 40(sp)
  ldw s4, 44(sp)
  ldw s5, 48(sp)
  ldw s6, 52(sp)
  ldw s7, 56(sp)
  addi sp, sp, 60
  ret
;   END:detect_collision


;;#####################################################################
;;        PART 9
;;#####################################################################

;BEGIN: rotate_tetromino
rotate_tetromino:
    addi  sp, sp, -24
    stw		t0, 0(sp)
    stw		t1, 4(sp)
    stw		t2, 8(sp)
    stw		t3, 12(sp)
    stw		t4, 16(sp)
    stw		ra, 20(sp)

    addi	t0, zero, T_orientation
    addi  t1, zero, rotR
    addi  t2, zero, rotL
    ldw   t3, 0(t0)

    beq		a0, t1, right
    beq		a0, t2, left
    br end

  right:
    addi    t3, t3, 1
    andi		t3, t3, 3
    br      end

  left:
    addi    t3, t3, 3
    andi		t3, t3, 3

  end:
    stw		t3, 0(t0)

    ldw		t0, 0(sp)
    ldw		t1, 4(sp)
    ldw		t2, 8(sp)
    ldw   t3, 12(sp)
    ldw		t4, 16(sp)
    ldw   ra, 20(sp)
    addi  sp, sp, 24
    ret
;   END:rotate_tetromino

;   BEGIN:act
act:
    addi  sp, sp, -68
    stw		t0, 0(sp)
    stw		t1, 4(sp)
    stw		t2, 8(sp)
    stw		t3, 12(sp)
    stw		t4, 16(sp)
    stw		t5, 20(sp)
    stw		t6, 24(sp)
    stw		t7, 28(sp)
    stw		s0, 32(sp)
    stw		s1, 36(sp)
    stw		ra, 40(sp)
    stw		s2, 44(sp)
    stw		s3, 48(sp)
    stw		s4, 52(sp)
    stw		s5, 56(sp)
    stw		s6, 60(sp)
    stw		s7, 64(sp)

    addi	t0, zero, W_COL
    addi	t1, zero, E_COL
    addi	t2, zero, So_COL
    addi	t3, zero, OVERLAP
    addi	t4, zero, moveL
    addi  t5, zero, rotL
    addi  t6, zero, reset
    addi	t7, zero, moveR
    addi  s0, zero, rotR
    addi  s1, zero, moveD
    addi  s2, zero, T_X
    addi  s3, zero, T_Y
    add		s6, zero, zero
    addi  s7, zero, 3
    add		v0, zero, zero

    beq		a0, t4, move_l
    beq		a0, t5, rot_l
    beq		a0, t6, game_reset
    beq		a0, t7, move_r
    beq		a0, s0, rot_r
    beq   a0, s1, move_d
    br    end1

  rot_l:
    addi	sp, sp, -4
    stw		a0, 68(sp)
    addi	a0, zero, rotL
    call  rotate_tetromino
    addi	a0, zero, OVERLAP
    call  detect_collision
    ldw   a0, 68(sp)
    addi	sp, sp, 4
    beq		v0, t3, rot_overlap
    addi  v0, zero, 0
    br		end1
  rot_overlap:
    addi	  sp, sp, -4
    stw		  a0, 68(sp)
    addi		a0, zero, rotR
    call    rotate_tetromino
    ldw     a0, 68(sp)
    addi	  sp, sp, 4
    ldw     s0, 0(s2)
    addi    s5, zero, 6
    bge     s0, s5, left_center
    addi    s4, s0, 1
    br      next2
  left_center:
    addi    s4, s0, -1
  next2:
    stw		  s4, T_X(zero)
    addi    s6, s6, 1
    beq	    s6, s7, failed_rot
    br	    rot_l

  rot_r:
    addi	sp, sp, -4
    stw		a0, 68(sp)
    addi	a0, zero, rotR
    call  rotate_tetromino
    addi	a0, zero, OVERLAP
    call  detect_collision
    ldw   a0, 68(sp)
    addi	sp, sp, 4
    beq		v0, t3, rot_overlap1
    addi  v0, zero, 0
    br		end1
  rot_overlap1:
    addi	  sp, sp, -4
    stw		  a0, 68(sp)
    addi		a0, zero, rotL
    call    rotate_tetromino
    ldw     a0, 68(sp)
    addi	  sp, sp, 4
    ldw     s0, 0(s2)
    addi    s5, zero, 6
    bge     s0, s5, left_center1
    addi    s4, s0, 1
    br      next3
  left_center1:
    addi    s4, s0, -1
  next3:
    stw		  s4, T_X(zero)
    addi    s6, s6, 1
    beq	    s6, s7, failed_rot
    br	    rot_r

  failed_rot:
    stw		  s0, T_X(zero)
    br		  failed

  move_l:
    addi	sp, sp, -8
    stw		a0, 68(sp)
    stw		t0, 72(sp)
    add		a0, zero, t0
    call    detect_collision
    ldw     a0, 68(sp)
    ldw     t0, 72(sp)
    addi	sp, sp, 8
    beq		v0, t0, failed
    ldw     s4, 0(s2)
    addi    s4, s4, -1
    stw		s4, 0(s2)
    addi    v0, zero, 0
    br      end1


  move_r:
    addi	sp, sp, -8
    stw		a0, 68(sp)
    stw		t1, 72(sp)
    add		a0, zero, t1
    call    detect_collision
    ldw     a0, 68(sp)
    ldw		t1, 72(sp)
    addi	sp, sp, 8
    beq		v0, t1, failed
    ldw     s4, 0(s2)
    addi    s4, s4, 1
    stw		s4, 0(s2)
    addi    v0, zero, 0
    br      end1


  move_d:
    addi	sp, sp, -4
    stw		a0, 68(sp)
    add		a0, zero, t2
    call    detect_collision
    ldw     a0, 68(sp)
    addi	sp, sp, 4
    beq		v0, t2, failed
    ldw     s4, 0(s3)
    addi    s4, s4, 1
    stw	    s4, 0(s3)
    addi    v0, zero, 0
    br      end1

  failed:
    addi  v0, zero, 1
    br      end1

  game_reset:
    ldw		t0, 0(sp)
    ldw		t1, 4(sp)
    ldw		t2, 8(sp)
    ldw		t3, 12(sp)
    ldw		t4, 16(sp)
    ldw		t5, 20(sp)
    ldw		t6, 24(sp)
    ldw		t7, 28(sp)
    ldw		s0, 32(sp)
    ldw		s1, 36(sp)
    ldw     ra, 40(sp)
    ldw		s2, 44(sp)
    ldw		s3, 48(sp)
    ldw		s4, 52(sp)
    ldw		s5, 56(sp)
    ldw		s6, 60(sp)
    ldw		s7, 64(sp)
    addi    sp, sp, 68
    br      reset_game

  end1:
    ldw		t0, 0(sp)
    ldw		t1, 4(sp)
    ldw		t2, 8(sp)
    ldw		t3, 12(sp)
    ldw		t4, 16(sp)
    ldw		t5, 20(sp)
    ldw		t6, 24(sp)
    ldw		t7, 28(sp)
    ldw		s0, 32(sp)
    ldw		s1, 36(sp)
    ldw     ra, 40(sp)
    ldw		s2, 44(sp)
    ldw		s3, 48(sp)
    ldw		s4, 52(sp)
    ldw		s5, 56(sp)
    ldw		s6, 60(sp)
    ldw		s7, 64(sp)
    addi  sp, sp, 68
    ret
;END : act

;;#####################################################################
;;        PART 10
;;#####################################################################

;BEGIN: get_input
get_input:
    addi  sp, sp, -44
    stw		t0, 0(sp)
    stw		t1, 4(sp)
    stw		t2, 8(sp)
    stw		t3, 12(sp)
    stw		t4, 16(sp)
    stw		t5, 20(sp)
    stw		t6, 24(sp)
    stw		t7, 28(sp)
    stw		s0, 32(sp)
    stw		s1, 36(sp)
    stw		ra, 40(sp)

    addi    t0, zero, BUTTONS
    ldw     t1, 4(t0)          ; t1 = button_value
    addi    t2, zero, 6
    add		t3, zero, zero
    addi    t5, zero, 1
    addi    t7, zero, rotR
    addi    s1, zero, 4

  loop1:
    beq		t3, t2, no_press    ; while i < 6
    sll 	t6, t5, t3          ; t6 = 1 << i
    and 	s0, t1, t6          ; s0 = button_value & 1 << i
    addi    t3, t3, 1           ; i++
    bne		s0, zero, pressed   ; (button_value  & (1 << i)) != 0 => pressed
    br      loop1

  pressed:
    add		v0, zero, t6
    stw		zero, 4(t0)
    br      end3

  no_press:
    add		v0, zero, zero
    br      end3

  end3:
    ldw		t0, 0(sp)
    ldw		t1, 4(sp)
    ldw		t2, 8(sp)
    ldw		t3, 12(sp)
    ldw		t4, 16(sp)
    ldw		t5, 20(sp)
    ldw		t6, 24(sp)
    ldw		t7, 28(sp)
    ldw     s0, 32(sp)
    ldw		s1, 36(sp)
    ldw     ra, 40(sp)
    addi    sp, sp, 44
    ret

;END: get_input

;BEGIN:detect_full_line
detect_full_line:
  addi sp, sp, -28
  stw ra, 0(sp)
  stw s0, 4(sp)
  stw s1, 8(sp)
  stw s6, 12(sp)
  stw s7, 16(sp)
  stw s5, 20(sp)
  stw s3, 24(sp)

  addi s5, zero, 8
  addi s6, zero, -1
  addi s7, zero, X_LIMIT

  add s1, zero, zero
  add s0, zero, zero

  addi v0, zero, 8

  while_line:
    beq s1, s5, no_full_line

    loop_over_columns:
      beq s0, s7, end_check_line
      add a0, zero, s0
      add a1, zero, s1
      call get_gsa
      addi s0, s0, 1
      beq v0, zero, go_to_next_line
      br loop_over_columns

    go_to_next_line:
      add s0, zero, zero
      addi s1, s1, 1
      br while_line

  no_full_line:
      add v0, zero, s5

  end_check_line:
      add v0, zero, s1

  ldw ra, 0(sp)
  ldw s0, 4(sp)
  ldw s1, 8(sp)
  ldw s6, 12(sp)
  ldw s7, 16(sp)
  ldw s5, 20(sp)
  ldw s3, 24(sp)
  addi sp, sp, 28
  ret
;END:detect_full_line


;BEGIN:remove_full_line
remove_full_line:
  addi  sp, sp, -32
  stw   ra, 0(sp)
  stw		a0, 4(sp)
  stw		a1, 8(sp)
  stw		a2, 12(sp)
  stw   s7, 16(sp)
  stw   s6, 20(sp)
  stw   s5, 24(sp)
  stw   s0, 28(sp)


  add a1, zero, a0
  addi s7, zero, -1

  addi a2, zero, NOTHING
  call remove_aux
  addi a2, zero, PLACED
  call remove_aux
  addi a2, zero, NOTHING
  call remove_aux
  addi a2, zero, PLACED
  call remove_aux
  addi a2, zero, NOTHING
  call remove_aux


addi s0, zero, X_LIMIT
addi s6, zero, -1

while_line_y:
  beq a1, s7, clear_and_draw

  add a0,zero, zero
  while_columns_x:
    beq	a0, s0, max_nb_columns_reached

    call get_gsa
    bne v0, zero, set_gsa_next_line

    addi a0, a0, 1
    br while_columns_x

    set_gsa_next_line:
      addi a2, zero, NOTHING
      call set_gsa
      addi a2, zero, PLACED
      addi a1, a1, 1
      call set_gsa
      addi a1, a1, -1
      addi a0, a0, 1
      br while_columns_x

    max_nb_columns_reached:
      addi a1, a1, -1
      br while_line_y

  addi s5, zero, SEVEN_SEGS
  addi s5, s3, -4

  clear_and_draw:
    call clear_leds
    call draw_gsa

  ldw   ra, 0(sp)
  ldw		a0, 4(sp)
  ldw		a1, 8(sp)
  ldw		a2, 12(sp)
  ldw   s7, 16(sp)
  ldw   s6, 20(sp)
  ldw   s5, 24(sp)
  ldw   s0, 28(sp)
  addi  sp, sp, 32
ret
; END:remove_full_line

; BEGIN:helper
remove_aux:
  addi sp, sp, -20
  stw s7, 0(sp)
  stw a0, 4(sp)
  stw a1, 8(sp)
  stw a2, 12(sp)
  stw ra, 16(sp)

  ;; Maximum number of colunms
  addi s7, zero, X_LIMIT
  add a0, zero, zero

  loop_switch_pixel_state:
    beq a0, s7, end_switch_pixel_state
    call set_gsa
    addi a0, a0, 1
    br loop_switch_pixel_state
  end_switch_pixel_state:
    call clear_leds
    call draw_gsa
    call wait

  	ldw s7, 0(sp)
  	ldw a0, 4(sp)
  	ldw a1, 8(sp)
  	ldw a2, 12(sp)
  	ldw ra, 16(sp)
  	addi sp, sp, 20
  	ret
; END:helper

;;#####################################################################
;;        PART 12
;;#####################################################################
; BEGIN:increment_score
increment_score:
  addi  sp, sp, -16
  stw		ra, 0(sp)
  stw		s0, 4(sp)
  stw		s1, 8(sp)
  stw		s2, 12(sp)

  addi s0, zero, 9999

  ldw s1, SCORE (zero)
  cmpne s2, s1, s0
  beq s2, zero, end_score
  addi s1, s1, 1
  stw s1, SCORE (zero)

  end_score:
  ldw		ra, 0(sp)
  ldw		s0, 4(sp)
  ldw		s1, 8(sp)
  ldw		s2, 12(sp)
  addi  sp, sp, 16
  ret
; END:increment_score


; BEGIN:display_score
display_score:
  addi  sp, sp, -52
  stw		s1, 0(sp)
  stw		s2, 4(sp)
  stw		s3, 8(sp)
  stw		s4, 12(sp)
  stw		s5, 16(sp)
  stw		t0, 20(sp)
  stw		t1, 24(sp)
  stw		t2, 28(sp)
  stw		t3, 32(sp)
  stw		t4, 36(sp)
  stw   t7, 40(sp)
  stw   ra, 44(sp)
  stw		s0, 48(sp)

  add t0, zero, zero
  add t1, zero, zero
  add t2, zero, zero
  add t3, zero, zero

  ldw s5, SCORE(zero)

check_1000:
  beq s5, zero, end_here_1
  cmpltui t4, s5, 0x3E8
  bne t4, zero, end_here_1000
  addi s5, s5, -0x3E8
  addi t0, t0, 1
  br check_1000
end_here_1000:

check_100:
  beq s5, zero, end_here_1
  cmpltui t4, s5, 0x64
  bne t4, zero, end_here_100
  addi s5, s5, -0x64
  addi t1, t1, 1
  br check_100
end_here_100:

check_10:
  beq s5, zero, end_here_1
  cmpltui t4, s5, 0xA
  bne t4, zero, end_here_10
  addi s5, s5, -0xA
  addi t2, t2, 1
  br check_10
end_here_10:

check_1:
  beq s5, zero, end_here_1
  addi s5, s5, -1
  addi t3, t3, 1
  br check_1

end_here_1:
  add s0, t0, zero
  slli s0, s0, 2
  ldw s3, font_data(s0)
  stw s3, SEVEN_SEGS (zero)

  add s0, t1, zero
  slli s0, s0, 2
  ldw s3, font_data(s0)
  stw s3, SEVEN_SEGS+4(zero)

  add s0, t2, zero
  slli s0, s0, 2
  ldw s3, font_data(s0)
  stw s3, SEVEN_SEGS+8(zero)

  add s0, t3, zero
  slli s0, s0, 2
  ldw s3, font_data(s0)
  stw s3, SEVEN_SEGS+12(zero)


  ldw		s1, 0(sp)
  ldw		s2, 4(sp)
  ldw		s3, 8(sp)
  ldw		s4, 12(sp)
  ldw		s5, 16(sp)
  ldw		t0, 20(sp)
  ldw		t1, 24(sp)
  ldw		t2, 28(sp)
  ldw		t3, 32(sp)
  ldw		t4, 36(sp)
  ldw       t7, 40(sp)
  ldw       ra, 44(sp)
  ldw		s0, 48(sp)
  addi      sp, sp, 52
	ret
; END:display_score


;;#####################################################################
;;        PART 13
;;#####################################################################

;   BEGIN:reset_game
reset_game:
    addi	sp, sp, -20
    stw		s0, 0(sp)
    stw		s1, 4(sp)
    stw		s2, 8(sp)
    stw		s3, 12(sp)
    stw		ra, 16(sp)

    stw		zero, SCORE(zero)
    call  display_score

    addi	s0, zero, 0

  iterate_over_x:
    cmpnei  s1, s0, X_LIMIT
    beq     s1, zero, end_reset

    addi	  s1, zero, 0
  iterate_over_y:
    cmpnei  s2, s1, Y_LIMIT
    beq     s2, zero, looping1
    add		  a1, zero, s1
    add		  a0, zero, s0
    addi	  a2, zero, NOTHING
    call    set_gsa
    addi    s1, s1, 1
    br      iterate_over_y

  looping1:
    addi	s0, s0, 1
    br    iterate_over_x

  end_reset:
    call  generate_tetromino
    addi  a0, zero, FALLING
    call  draw_tetromino
    call  clear_leds
    call  draw_gsa

    ldw		ra, 16(sp)
    ldw		s3, 12(sp)
    ldw		s2, 8(sp)
    ldw		s1, 4(sp)
    ldw		s0, 0(sp)
    addi	sp, sp, 20
    ret
;   END:reset_game

;;#####################################################################
;;										END OF CODE															                                              #
;;#####################################################################

font_data:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y
