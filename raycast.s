;------------------------------------------------------------------------------
; raycast.s
;
; Copyright 2021 Tim Kelsall. All rights reserved.
;------------------------------------------------------------------------------
; Memory layout:
; ra - player.x      (5.11 FP)
; rb - player.y      (5.11 FP)
; rc - player.angle  (3.13 FP)
;------------------------------------------------------------------------------

N_COLUMNS   equ   80

init:             ldi ra, 0x4000          ; position (8.0,8.0)
                  ldi rb, 0x3800
                  ldi rc, 0x0000          ; angle (0.0) (north)
                  ldi re, 0
                  ldi rf, 4
                  pal d_palette
                  bgc 15

main:             call drw_columns
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  ;vblnk
                  cls
                  jmp main

drw_columns:      xor rd, rd
drw_columnsL:     cmpi rd, N_COLUMNS
                  jz drw_columnsZ
                  mov r0, rd
                  call cast_ray
                  mov r4, r0
                  cmpi r0, 0
                  jz drw_columnsY
                  call dist_to_size
                  mov r3, r0
                  shl r0, 8
                  andi r0, 0xff00
                  addi r0, 2
                  ldi r2, drw_columnsSpr
                  stm r0, r2
S:                db 0x04,0x00
drw_columnsSpr:   db 0x00,0x00
                  mul rd, rf, r0
                  shr r3, 1
                  andi r3, 0x7f
                  ldi r2, 120
                  sub r2, r3
                  muli r4, 5
                  divi r4, 6
                  muli r4, 960
                  addi r4, d_color_table_0
D:                drw r0, r2, r4 
drw_columnsY:     addi rd, 1
                  addi rc, 5
                  jmp drw_columnsL
drw_columnsZ:     ret

;------------------------------------------------------------------------------
; Cast a ray from (ra,rb) at angle (rc) for screen column (r0).
; The actual ray angle ends up being (rc) + ((r0) - 80)*(0.5*PI/180))
; March it in a loop until either:
; a) the ray is in a non-zero map cell, or
; b) we reach 255 steps.
;
; Each step in ray cast is 0.1 map unit length.
; sin(theta) = O/H, cos(theta) = A/H
; => O = H * sin(theta) = 0.1 * sin(theta)
; => A = H * cos(theta) = 0.1 * cos(theta)
; Hence a 1024-entry LUT of these pairs is available (d_lut_Nsincos, 4096 bytes)
;
; Returns:
; r0 - intersection distance
; r1 - intersection color
cast_ray:         mov r8, r0
                  shl r0, 1
                  addi r0, d_lut_col2radoffs
                  ldm r1, r0
                  add r1, rc
                  shr r1, 6                  ; 2^(16-6) entries
                  shl r1, 2                  ; entry pairs 2*2=4B, so *4.
                  addi r1, d_lut_Nsincos
                  ldm r2, r1                 ; sin
                  addi r1, 2
                  ldm r3, r1                 ; cos
                  mov r4, ra
                  mov r5, rb
cast_rayll:       ldi r9, 255
cast_rayL:        add r4, r2                 ; x + N * cos(theta)
                  add r5, r3                 ; y + N * sin(theta)
cast_rayL_:       cmpi r4, 0
                  jz cast_rayX
                  cmpi r5, 0
                  jz cast_rayX
                  tsti r4, 0x8000            ; 16 in FP 5.11
                  jnz cast_rayX
                  tsti r5, 0x8000
                  jnz cast_rayX
                  
 crm:             mov r6, r5
                  shr r6, 11
                  muli r6, 16
                  
                  mov r7, r4
                  shr r7, 11
                  add r6, r7
                  addi r6, d_map
                  ldm r6, r6
                  andi r6, 1
                  jnz cast_rayZ

                  subi r9, 1
                  jnz cast_rayL
cast_rayX:        ldi r0, 0                  ; No hit.
cr0:              ret
cast_rayZ:
                  ldi r0, 256
                  sub r0, r9
                  divi r0, 10
                  ldi r1, 0xf
cr1:              ret

;------------------------------------------------------------------------------
; Translate a distance to a map wall (r0), to a vertical height on screen.
; Returns:
; r0 - height in pixels
dist_to_size:     ldi r1, 480
                  ;shr r0, 11              ; 5.11 FP -> integer
                  ;jnz dist_to_sizeZ
                  ;ldi r0, 240
                  addi r0, 1
dist_to_sizeZ:    div r1, r0, r0
                  ret

;------------------------------------------------------------------------------
; Data
;------------------------------------------------------------------------------

; Lookup tables:
; - scaled sin & cos for ray stepping
; - column index to radian angle offset

include lut.s

; Graphics data:
; - 240-line sprites of each color. Used to draw wall spans.

include data.s

; Palette in use. Grayscale.

d_palette:
db 0x00,0x00,0x00
db 0xf0,0xf0,0xf0
db 0xe0,0xe0,0xe0
db 0xd0,0xd0,0xd0
db 0xc0,0xc0,0xc0
db 0xb0,0xb0,0xb0
db 0xa0,0xa0,0xa0
db 0x90,0x90,0x90
db 0x80,0x80,0x80
db 0x70,0x70,0x70
db 0x60,0x60,0x60
db 0x50,0x50,0x50
db 0x40,0x40,0x40
db 0x30,0x30,0x30
db 0x20,0x20,0x20
db 0x10,0x10,0x10

; Playield definition. 16x16.
; 0 = empty, 1 = wall.

d_map:
db 0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
db 0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
db 0x00,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
