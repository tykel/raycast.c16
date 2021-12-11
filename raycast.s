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

include defs.s

CHAR_OFFS         equ   32

importbin font.bin 0 3072 d_font

init:             ldi ra, 0x4000          ; position (8.0,8.0)
                  ldi rb, 0x4000
                  ldi rc, 0x0000          ; angle (0.0) (north)
                  ldi re, 0
                  ldi rf, DEF_COLW
                  pal d_palette
                  bgc 15

main:             call handle_inp
                  call drw_columns
                  jmp main

handle_inp:       ldm r0, 0xfff0
                  tsti r0, 4              ; left
                  jz handle_inpR
                  subi rc, 400 ;511
handle_inpR:      tsti r0, 8              ; right
                  jz handle_inpU
                  addi rc, 400 ;511
handle_inpU:      tsti r0, 1              ; up
                  jz handle_inpD
                  call move_fwd
handle_inpD:      tsti r0, 2              ; down
                  jz handle_inpZ
                  call move_bwd
handle_inpZ:      ret

move_fwd:         push r0
                  mov r0, rc 
                  shr r0, 6                  ; 2^(16-6) entries
                  shl r0, 2                  ; entry pairs 2*2=4B, so *4.
                  addi r0, d_lut_sincos_div8
zzzzz:            ldm r1, r0
                  ;shl r1, 1
                  add ra, r1
                  addi r0, 2
                  ldm r1, r0
                  ;shl r1, 1
                  sub rb, r1
                  pop r0
                  ret

move_bwd:         push r0
                  mov r0, rc 
                  shr r0, 6                  ; 2^(16-6) entries
                  shl r0, 2                  ; entry pairs 2*2=4B, so *4.
                  addi r0, d_lut_sincos_div8
                  ldm r1, r0
                  ;shl r1, 1
                  sub ra, r1
                  addi r0, 2
                  ldm r1, r0
                  ;shl r1, 1
                  add rb, r1
                  pop r0
                  ret

drw_columns:      xor rd, rd
drw_columnsL:     cmpi rd, DEF_COLUMNS
                  jz drw_columnsZ
                 
                  ;jmp drw_columnsCast

                  spr DEF_COLSPRHW
                  mov r0, rd
                  muli r0, DEF_COLW
                  drw r0, re, d_color_table_f
                  ldi r1, 120
                  drw r0, r1, d_color_table_c
drw_columnsCast:  mov r0, rd
                  call cast_ray
                  mov r4, r0
                  cmpi r0, 0
                  jz drw_columnsY
                  call dist_to_size
                  mov r3, r0
                  shl r0, 8
                  andi r0, 0xff00
                  addi r0, DEF_COLSPRW 
                  ldi r2, drw_columnsSpr
                  stm r0, r2
S:                db 0x04,0x00
drw_columnsSpr:   db 0x00,0x00
                  mul rd, rf, r0
                  shr r3, 1
                  andi r3, 0x7f
                  ldi r2, 120
                  sub r2, r3
drw_columnsV:     divi r4, 8
                  muli r4, 480
                  addi r4, d_color_table_0
D:                drw r0, r2, r4 
drw_columnsY:     addi rd, 1
                  jmp drw_columnsL
drw_columnsZ:     ret

;------------------------------------------------------------------------------
; Cast a ray from (ra,rb) at angle (rc) for screen column (r0).
; The actual ray angle ends up being (rc) + ((r0) - 40)*(0.5*PI/180))
; March it in a loop until either:
; a) the ray is in a non-zero map cell, or
; b) we reach 255 steps.
;
; Each step in ray cast is 0.1 map unit length.
; sin(theta) = O/H, cos(theta) = A/H
; => O = H * sin(theta) = 0.1 * sin(theta)
; => A = H * cos(theta) = 0.1 * cos(theta)
; A 1024-entry LUT of these pairs is available (d_lut_sincos_div10, 4096 bytes).
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
                  addi r1, d_lut_sincos_div8
                  ldm r2, r1                 ; sin
                  addi r1, 2
                  ldm r3, r1                 ; cos
                  mov r4, ra
                  mov r5, rb
cast_rayll:       ldi r9, 255
cast_rayL:        add r4, r2                 ; x + N * cos(theta)
                  sub r5, r3                 ; y + N * sin(theta)
cast_rayL_:       cmpi r4, 0
                  jz cast_rayX
                  cmpi r5, 0
                  jz cast_rayX
                  tsti r4, 0x8000            ; 16 in FP 5.11
                  jnz cast_rayX
                  tsti r5, 0x8000
                  jnz cast_rayX
                  
 crm:             mov r6, r5
                  shr r6, 8 ;11
                  muli r6, 128 ;16
                  
                  mov r7, r4
                  shr r7, 8 ;11
                  add r6, r7
                  addi r6, d_map
                  ldm r6, r6
                  andi r6, 1
                  jnz cast_rayZ

                  subi r9, 1
                  jnz cast_rayL
cast_rayX:        ldi r0, 0                  ; No hit.
                  ret
cast_rayZ:
                  ldi r0, 256
                  sub r0, r9
                  ret

;------------------------------------------------------------------------------
; Translate a distance to a map wall (r0), to a vertical height on screen.
; Returns:
; r0 - height in pixels
dist_to_size:     ldi r1, 1920 ;480
                  divi r0, 2
                  addi r0, 1
dist_to_sizeZ:    div r1, r0, r0
                  ret
;------------------------------------------------------------------------------
; Display a string, accounting for newlines too. 
sub_drwstr:       spr 0x0804                 ; Font sprite size is 8x8
                  flip 0,0                   ; Reset flip state
                  ldm r3, r0
                  andi r3, 0xff
                  cmpi r3, 0
                  jz .sub_drwstrZ
                  cmpi r1, 320
                  jl .sub_drwstrA
                  ldi r1, 0
                  addi r2, 12
.sub_drwstrA:     subi r3, CHAR_OFFS
                  muli r3, 32
                  addi r3, d_font
                  drw r1, r2, r3
                  addi r0, 1
                  addi r1, 8
                  jmp sub_drwstr
.sub_drwstrZ:     ret
;------------------------------------------------------------------------------
; Output the contents of r0 to given BCD string - up to 999 supported
sub_r2bcd3:    mov r2, r0
               divi r2, 100
               muli r2, 100               ; r2 contains the 100's digit, x100
               mov r3, r0
               sub r3, r2
               divi r3, 10
               muli r3, 10                ; r3 contains the 10's digit, x10
               mov r4, r3
               divi r4, 10
               cmpi r3, 0
               jnz .sub_r2bcd3A
               cmpi r2, 0
               jz .sub_r2bcd3B
.sub_r2bcd3A:  addi r4, 0x10
.sub_r2bcd3B:  addi r4, CHAR_OFFS
               shl r4, 8
               mov r5, r2
               divi r5, 100
               cmpi r2, 0
               jz .sub_r2bcd3C
               addi r5, 0x10
.sub_r2bcd3C:  add r4, r5
               addi r4, CHAR_OFFS         ; Shift and combine 100's & 10's
               stm r4, r1                 ; Store to string's first 2 bytes
               addi r1, 2
               sub r0, r2                 ; Subtract 100's from original
               sub r0, r3                 ; Then subtract 10's
               addi r0, 0x10
               addi r0, CHAR_OFFS
               stm r0, r1                 ; Store to string's last 2 bytes
               ret

;------------------------------------------------------------------------------
; Data
;------------------------------------------------------------------------------

; Lookup tables:
; - scaled sin & cos for ray stepping
; - column index to radian angle offset (atan)

include lut.s

; Graphics data:
; - 240-line sprites of each color. Used to draw wall spans.
; - map/playield. 16x16 in FP 13.3 so 128x128. 1=wall, 0=empty.

include data.s

data.str_bcd3:       db 0,0,0,0

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
