.nolist
#include "ti83plus.inc"
#define    ProgStart    $9D95

INT_MASK equ %00000010
.list
.org    ProgStart - 2
    .db t2ByteTok, tAsmCmp
	
	;Archive Program
    b_call(_ChkFindSym)
	b_call($4FDB)
	
	b_call(_RunIndicOff)
    b_call(_ClrLCDFull)
	di
	set textWrite,(iy+sGrFlags)
    ld a,0
    ld (curCol),a
	ld (curRow),a
    ld hl,eMsg1
    call print_line
	
	;Clean Out Upper Memory
	ld hl,$C000
clear_loop:
	ld (hl),0
	inc hl
	ld a,h
	cp 0
	jp nz,clear_loop
	
	ld hl,eMsg2
	call print_line
	
	;Unlock RAM
	call unlock
	
	ld hl,eMsg3
	call print_line
	
	;Sets up the interrupt jump table to jump to $9A9A
	ld a,$9A
	ld ($9900),a
	ld hl,$9900
	ld de,$9901
	ld bc,256
	ldir
	
	;Puts jump in $9A9A to interrupt routine
	ld a,$C3
	ld ($9A9A),a
	ld hl,interrupt_entry
	ld ($9A9B),hl
	
	;Prepares interrupt settings
	ld a,$99
	ld i,a
	ld a,INT_MASK
	out (3),a
	di
	;Enter Into Terminal
    jp terminal_entry

print_line:
	b_call(_PutS)
	b_call(_NewLine)
	ret
	
unlock:
	in a,($02)
	rla
	jr nc,ramunlock_83p
	xor a
	out ($25),a
	cpl
	out ($26),a
	ret
	
ramunlock_83p:
	ld a,%00000111
	out ($05),a
	xor a
	out ($16),a
	ret

eMsg1:
    .db "Clearing Top Of Memory", 0
eMsg2:
	.db "Unlocking RAM",0
eMsg3:
	.db "Prepared To BootEntering KERNEL...",0
counter:
	.db 0,0
	

.org 	$9F00

	;The two variables used to keep track of cursor location
termRow:
	.db 0
termCol:
	.db 0
	
textPointer:
	.db 0,0
	
	;Terminal Entry Point
terminal_entry:
	call terminal_reset
	jp init

	;Resets the terminal
terminal_reset:
	;b_call(_ClrLCDFull)
	ld hl,$0000
	ld (penCol),hl
	ld a,0
	ld (termRow),a
	ld (termCol),a
	ld a,$5F
	call v_put_char
	ret
	
	;Puts a character on the terminal (Reg A). 
put_char:
	cp 0
	ret z
	ld c,a
	ld a,$06
	call v_put_char
	ld a,c
	cp 10
	jp z,new_line_char
	cp 8
	jp z,back_space
	cp '['
	call z,fix_bracket
	ld a,c
	call v_put_char
	ld  a,(termCol)
	ld b,4
	add a,b
	ld (termCol),a
return_char:
	ld a,(termCol)
	cp 92
	call z,new_line
	ld a,$5F
	jp v_put_char
fix_bracket:
	ld c,$C1
	ret

	;Moves the cursor back a space, removing the character behind it
	;Will move up a line if at the left side of the screen
back_space:
	ld a,(termCol)
	cp 0
	jp z,back_space1
	ld b,4
	sub b
	ld (termCol),a
	jp return_char
back_space1:
	ld a,(termRow)
	cp 0
	jp z,return_char
	ld b,7
	sub b
	ld (termRow),a
	ld a,88
	ld (termCol),a
	jp return_char

new_line_char:
	call new_line
	jp return_char

	;Moves the cursor down a line and returns it to the left side of the screen
	;Will scroll if at the bottom of the screen
new_line:
	ld a,(termRow)
	ld b,7
	cp $38
	jp z,new_line2
	add a,b
	ld (termRow),a
new_line1:
	ld a,0
	ld (termCol),a
	ret
new_line2:
	call shift_up
	jp new_line1

	;Draws a char at termRow and termCol
v_put_char:
	ld b,a
	ld a,(termRow)
	ld (penRow),a
	ld a,(termCol)
	ld (penCol),a
	ld a,b
	b_call(_VPutMap)
	ret
	
	;Shifts the screen up 7 lines, then cleans up the garbage
shift_up:
	ld hl,$9394
	ld de,$9340
	ld bc,$02F4
	ldir
	ld hl,$95EC
	ld a,$54
shift_up1:
	ld (hl),0
	dec a
	inc hl
	cp 0
	jp nz,shift_up1
	ret
	
	;Draws the graphics buffer to the screen
update_screen:
	b_call(_GrBufCpy)
	ret
	
	;Scans key port for scancode
scan_key:
	ld e,%11111110
	ld b,%11111110
	ld c,1
scan_key1:
	ld a,e
	out (1),a
	in a,(1)
	cp b
	jp z,scan_key2
	inc c
	rlc b
	ld a,%11111110
	cp b
	jp nz,scan_key1
	rlc e
	cp e
	jp nz,scan_key1
	ld a,0
	ret
scan_key2:
	ld a,c
	ret
	


.org 	$A000
	;Scan Code To ASCII Table
	;    00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,'"','W','R','M','H',$08
	.db $00,$00,'#','V','Q','L','G',$00,$00,':','Z','U','P','K','F','C'
	.db $00,' ','Y','T','O','J','E','B','=',$00,'X','S','N','I','D','A'
	.db $00,$00,$00,$00,$00,$00,$FF,$1B,$08,$00,$00,$00,$00,$00,$00,$00
	
	;Shift Codes
	;    00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,'+','-','*','/','!',$08
	.db $00,$00,'3','6','9',']',$00,$00,$00,'.','2','5','8','[',$00,'>'
	.db $00,'0','1','4','7',',',$00,'<','=',$00,'X','Y',$00,$00,$00,'@'
	.db $00,$00,$00,$00,$00,$00,$FF,$1B,$08,$00,$00,$00,$00,$00,$00,$00
	
shiftOn:
	.db 0
	
lastKey:
	.db 0
	

	
	;Return a key press in Reg A
get_key:
	call scan_key
	cp 0
	jp z,get_key2
	ld b,a
	ld a,(lastKey)
	cp b
	jp z,get_key1
	ld a,b
	ld (lastKey),a
	ld h,$A0
	ld l,b
	ld a,(shiftOn)
	cp 0
	call nz,get_key6
	ld a,(hl)
	cp $FF
	jp z,get_key4
	ret

	
get_key6:
	ld a,64
	add a,l
	ld l,a
	ret

get_key5:
	ld a,255
	ret

get_key4:
	ld a,(shiftOn)
	cp 0
	ld a,0
	call z,get_key5
	ld (shiftOn),a
	
get_key1:
	ld a,0
	ret
	
get_key2:
	ld a,0
	ld (lastKey),a
	ret
	
get_key3:
	ld a,64
	
	add a,l
	ld l,a
	ld a,(hl)
	ret
	
	.db 0
interruptClock:
	.db 0
interruptChar:
	.db 33
	
	.db 0,0,0
	
interrupt_entry:
	push af
	di
	ld a,0
	out (3),a
	ld a,INT_MASK
	out (3),a
	ld a,(interruptClock)
	inc a
	cp 2
	jp nz,ignore_int
	ld a,0
	ld (interruptClock),a
	pop af
	jp on_int

ignore_int:
	ld (interruptClock),a
	pop af
	ei
	ret

	
	
	; Start Of KERNEL
.org 	$A100
;Variables
PID equ $A120
TEMP equ $A121
SPM equ $A123
INI equ $A125
CL1 equ $A126
CL2 equ $A127
CL3 equ $A128
CL4 equ $A129
PLS equ $A12A
PLM equ $A12B
PLE equ $A12C
PLL equ $A12D
ISC equ $A12E
PLP equ $A12F
NBR equ $A130
PLI equ $A131
BCS equ $A133
HLS equ $A135
;Memory Regions
SWAP equ $A200
MEMT equ $A300
PIPE equ $A400
KENT equ $A500
US equ $A900
;	A100-Program Start,Init
;	A120-Variable Area
;	A1**-Interrupt Address, Context SWAP
;	A200-Context Block Area
;   A300-Memory Allocation Table Area
;   A400-Pipe Marker Table Area
;   A500-Kernel Entry Point
;	A900-User Space
	

init:
	ld sp,0FFF0h
	ld a,0
	ld (PID),a
	ld hl,SWAP + 0Bh
	ld (HLS),hl
	ei
	jp start_proc0
	
.org 	$A120
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.db 0,0,0,0,0,0,0,0,0,0
	
	;Context Swap
	;Reg BC - Stored Context Block Address
	;Reg HL - Context Block Address Counter
on_int:
	ex af,af'
	ld a,(CL1)
	add a,17
	ld (CL1),a
	ld a,(CL2)
	adc a,0
	ld (CL2),a
	ld a,(CL3)
	adc a,0
	ld (CL3),a
	ld a,(CL4)
	adc a,0
	ld (CL4),a
	ld a,(INI)
	cp 0
	jp z,swap_proc
	ld a,0
	ld (INI),a
	ex af,af'
	ei
	ret
swap_proc:
	exx
	ld hl,(HLS)
	pop bc
	exx
	ld (TEMP),hl
	ld hl,0
	add hl,sp
	ld (SPM),hl
	ld hl,(TEMP)
	exx
	ld sp,hl
	push bc
	exx
	ex af,af'
	push hl
	push de
	push bc
	push af
	ex af,af'
	exx
	inc hl
	inc hl
	ld sp,hl
	ld (TEMP),hl
	ld hl,(SPM)
	push hl
	ld hl,(TEMP)
	
	;Context block check
check_end_marker:
	ld a,(hl)
	bit 0,a
	jp nz,move_next_block
	ld l,0dh
	ld a,0
	ld (PID),a
	jp check_status_byte
move_next_block:
	ld a,(PID)
	inc a
	ld (PID),a
	ld bc,16
	add hl,bc
check_status_byte:
	ld a,(hl)
	bit 1,a
	jp z,check_end_marker
	bit 2,a
	jp nz,check_end_marker
	
	;Load the next context block
	dec hl
	ld a,(hl)
	ld (SPM+1),a
	dec hl
	ld a,(hl)
	ld (SPM),a
	ld bc,0fff6h
	add hl,bc
	ld sp,hl
	ld bc,10
	add hl,bc
	exx
	ex af,af'
	pop af
	pop bc
	pop de
	pop hl
	exx
	ex af,af'
	pop bc
	ld sp,(SPM)
	push bc
	;Return to process
	ex af,af'
	ld (HLS),hl
	exx
	ei
	ret
	
	;Area of memory in which the context blocks are stored
.org	 SWAP
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000010b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	.db 0,0,0,0,0,0,0,0,0,0,0,0,0,00000000b,0,0
	
	;Area of memory in which the memory table is stored
.org 	MEMT
	
	;0EFh = Kernel Memory (Reserved)
	;000h = Process 0 Memory
	;001h = Process 1 Memory
	;0FFh = Unallocated Memory
	
	;    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh
	.db 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	
	;Area of memory in which the pipe markers are stored
.org	 PIPE
	
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	.db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	
	;Kernel Entry
.org 	KENT
	di
	call proc_com
	ei
	ret
	
proc_com:
	ld a,d
	cp 1dh
	jp z,write_prgloader
	cp 20h
	jp z,write_prgloader2
	cp 0
	jp z,forfit
	cp 1
	jp z,kill_proc
	cp 2
	jp z,change_proc
	cp 3
	jp z,get_proc
	cp 4
	jp z,get_time1
	cp 5
	jp z,get_time2
	cp 6
	jp z,get_time3
	cp 7
	jp z,get_time4
	cp 8
	jp z,reset_time
	cp 9
	jp z,get_pid
	cp 0ah
	jp z,dealloc_proc
	cp 0bh
	jp z,dealloc_mem
	cp 0ch
	jp z,alloc_proc
	cp 0dh
	jp z,alloc_mem
	cp 0eh
	jp z,get_mem
	cp 0fh
	jp z,get_seg
	cp 10h
	jp z,demark_proc
	cp 11h
	jp z,demark_pipe
	cp 12h
	jp z,mark_proc
	cp 13h
	jp z,mark_pipe
	cp 14h
	jp z,channel0_write
	cp 15h
	jp z,channel1_write
	cp 16h
	jp z,channel0_read
	cp 17h
	jp z,channel1_read
	cp 18h
	jp z,channel0_onwrite
	cp 19h
	jp z,channel1_onwrite
	cp 1ah
	jp z,channel0_onread
	cp 1bh
	jp z,channel1_onread
	cp 1ch
	jp z,init_prgloader
	cp 1eh
	jp z,skip_args
	cp 1fh
	jp z,finish_prgloader
	ret
	
	;Forfits the current process, and moves on to the next
	;All registers preserved
forfit:
	di
	ex af,af'
	ld a,0ffh
	ld (INI),a
	call swap_proc
	ret
	
	
get_status_block:
	ld d,2
	ld a,15
	cp e
	ret c
	ld d,0
	ld hl,SWAP+0dh
	sla e
	sla e
	sla e
	sla e
	ld a,l
	or e
	ld l,a
	ret
	
	;Kills the process specified by Reg E
	;All registers destroyed
kill_proc:
	call get_status_block
	ld a,(hl)
	and 11111001b
	ld (hl),a
	bit 0,a
	jp z,kill_proc1
	ret
kill_proc1:
	ld a,l
	sub 10h
	ld l,a
	ld a,(hl)
	and 11111110b
	ld (hl),a
	bit 1,a
	jp z,kill_proc1
	ret
	
	;Changes the sleep/wake status of the the process specified by Reg E, if Reg C is 0 the process will wake, otherwise it will sleep/wake
	;All registers destroyed
change_proc:
	call get_status_block
	ld a,e
	cp 0
	jp nz,change_proc3
	ld a,(hl)
	and 11111011b
	ld (hl),a
	ret
change_proc3:
	ld a,(hl)
	or 00000100b
	ld (hl),a
	ret


get_proc:
	call get_status_block
	ld a,0
	ld e,0
	cp d
	ret nz
	ld a,(hl)
	and 00000110b
	ld e,a
	ret

	;Get Uptime/Clock 1-4 return the indivdual bytes from the 32 byte long uptime counter in Reg E
	;Reg A destroyed
get_time1:
	ld a,(CL1)
	ld e,a
	ret
get_time2:
	ld a,(CL2)
	ld e,a
	ret
get_time3:
	ld a,(CL3)
	ld e,a
	ret
get_time4:
	ld a,(CL4)
	ld e,a
	ret
	
	;Resets Uptime
	;Reg A destroyed
reset_time:
	ld a,0
	ld (CL1),a
	ld (CL2),a
	ld (CL3),a
	ld (CL4),a
	ret

	;Get Current Process ID in Reg E
	;Reg A destroyed 
get_pid:
	ld a,(PID)
	ld e,a
	ret
	
	;Deallocates all memory from the process specified by Reg E
	;Destroys All Registers
dealloc_proc:
	ld a,15
	cp e
	ret c
	ld hl,MEMT
dealloc_proc1:
	ld a,(hl)
	cp e
	jp nz,dealloc_proc2
	ld (hl),0ffh
dealloc_proc2:
	inc l
	ret z
	jp dealloc_proc1
	
	;Deallocates Reg C number of blocks from pointer Reg E
	;Destroys All Registers
dealloc_mem:
	ld hl,MEMT
	ld l,e
dealloc_mem1:
	ld (hl),0ffh
	inc l
	ret z
	dec c
	ret z
	jp dealloc_mem1

	;Allocates memory for current process, amount specified by Reg C. Reg C returns start pointer, and Reg D returns 00h if successful
	;Destroys all registers
alloc_proc:
	ld a,(PID)
	ld e,a
	
	;Allocates memory for process specified by Reg E, amount specified by Reg C. Reg C returns start pointer, and Reg D returns 00h is successful
	;Destroys all registers
alloc_mem:
	ld a,15
	cp e
	ld d,02h
	ret c
	ld hl,MEMT
alloc_mem1:
	ld a,(hl)
	cp 0ffh
	jp z,alloc_mem2
	inc l
	jp nz, alloc_mem1
	ld d,01h
	ret
alloc_mem2:
	ld b,1
alloc_mem3:
	ld a,b
	cp c
	jp z,alloc_mem4
	inc b
	inc l
	ld d,01h
	ret z 
	ld a,(hl)
	cp 0ffh
	jp z,alloc_mem3
	jp alloc_mem1
alloc_mem4:
	dec b
	ld a,l
	sub b
	ld l,a
	ld c,a
	inc b
alloc_mem5:
	ld (hl),e
	inc l
	dec b
	jp nz,alloc_mem5
	ld d,0
	ret
	
	;Returns the number of free blocks in the memory table, value returned in Reg E
	;All registers destroyed
get_mem:
	ld hl,MEMT
	ld e,0
get_mem1:
	ld a,(hl)
	cp 0ffh
	jp nz,get_mem2
	inc e
get_mem2:
	inc l
	ret z
	jp get_mem1
	
	;Returns the size of the largest unallocated segment of memory, value returned in Reg E
	;All registers destroyed
get_seg:
	ld hl,MEMT
	ld e,0
	ld b,0
get_seg1:
	ld a,(hl)
	cp 0ffh
	jp nz,get_seg2
	inc b
	inc l
	jp nz,get_seg1
	dec l
	jp get_seg2
get_seg2:
	ld a,e
	cp b
	jp c,get_seg3
	jp get_seg4
get_seg3:
	ld e,b
get_seg4:
	ld b,0
	inc l
	ret z
	jp get_seg1
	
	;Demarks all of the pipes from the process specified by Reg E
	;All registers destroyed
demark_proc:
	ld hl,PIPE
demark_proc1:
	ld a,(hl)
	cp e
	jp nz,demark_proc2
	ld (hl),0ffh
demark_proc2:
	inc l
	ret z
	jp dealloc_proc1
	
	;Demarks the pipe specified by Reg C
	;All registers destroyed
demark_pipe:
	ld hl,PIPE
	ld l,c
	ld (hl),0ffh
	ret
	
	;Marks a pipe for the current process on the memory pointer specified by Reg C, Reg C returns the Pipe ID if successful, and Reg D will return 00h
	;All registers destroyed
mark_proc:
	ld a,(PID)
	ld e,a
	
	;Marks a pipe for the process specified by Reg E on the memory pointer specified by Reg C, Reg C returns the Pipe ID if successful, and Reg D will return 00h
	;All registers destroyed
mark_pipe:
	ld hl,PIPE
	ld l,c
	ld a,(hl)
	cp 0ffh
	ld d,06h
	ret nz
	ld (hl),e
	ld d,00h
	call init_pipe
	ret
	
	;Pipe Init, specified by Reg C
	;To be used after marking a pipe, Reg HL destroyed
init_pipe:
	ld l,0
	ld h,c
	ld (hl),08h
	inc hl
	ld (hl),08h
	inc hl
	ld (hl),0ffh
	inc hl
	ld (hl),0ffh
	inc hl
	ld (hl),84h
	inc hl
	ld (hl),84h
	inc hl
	ld (hl),0ffh
	inc hl
	ld (hl),0ffh
	ret
	
	;Checks if pipe is valid, if so Reg D returns 00h
	;To be used before read/write, Reg HL destroyed 
pipe_valid:
	ld hl,PIPE
	ld l,c
	ld a,(hl)
	ld d,03h
	cp 0ffh
	ret z
	cp 0feh
	ret z
	ld d,00h
	ret
	
	;Writes a value specified by Reg E into pipe channel 0 specified by Reg C, Reg D returned 00h if successful
	;Destroys all registers
channel0_write:
	call pipe_valid
	ld a,0
	cp d
	ret nz
	ld h,c
	ld l,1
	ld b,(hl)
	inc b
	ld a,b
	cp 84h
	jp nz,channel0_write1
	ld b,08h
channel0_write1:
	ld l,0
	ld a,(hl)
	cp b
	ld d,04h
	ret z
	ld l,1
	ld l,(hl)
	ld (hl),e
	ld l,1
	ld (hl),b
	ld d,00h
	ld l,03h
	ld a,(hl)
	cp 0ffh
	ret z
	ld d,e
	ld e,a
	ld c,0
	call change_proc
	ld e,d
	ret
	
	;Writes a value specified by Reg E into pipe channel 1 specified by Reg C, Reg D returned 00h if successful
	;Destroys all registers
channel1_write:
	call pipe_valid
	ld a,0
	cp d
	ret nz
	ld h,c
	ld l,5
	ld b,(hl)
	inc b
	ld a,b
	cp 00h
	jp nz,channel1_write1
	ld b,84h
channel1_write1:
	ld l,4
	ld a,(hl)
	cp b
	ld d,04h
	ret z
	ld l,5
	ld l,(hl)
	ld (hl),e
	ld l,5
	ld (hl),b
	ld d,00h
	ld l,07h
	ld a,(hl)
	cp 0ffh
	ret z
	ld d,e
	ld e,a
	ld c,0
	call change_proc
	ld e,d
	ret
	
	;Reads a value from pipe channel 0 specified by Reg C into Reg E, Reg D returned 00h is successful
	;Destroys all registers
channel0_read:
	call pipe_valid
	ld a,0
	cp d
	ret nz
	ld h,c
	ld l,0
	ld b,(hl)
	ld l,1
	ld a,b
	cp (hl)
	ld d,05h
	ret z
	ld l,0
	inc b
	ld a,84h
	cp b
	jp nz,channel0_read1
	ld b,08h
channel0_read1:
	ld l,(hl)
	ld e,(hl)
	ld l,0
	ld (hl),b
	ld d,00h
	ld l,02h
	ld a,(hl)
	cp 0ffh
	ret z
	ld d,e
	ld e,a
	ld c,0
	call change_proc
	ld e,d
	ret
	
	;Reads a value from pipe channel 1 specified by Reg C into Reg E, Reg D returned 00h if successful
	;Destroys all registers
channel1_read:
	call pipe_valid
	ld a,0
	cp d
	ret nz
	ld h,c
	ld l,4
	ld b,(hl)
	ld l,5
	ld a,b
	cp (hl)
	ld d,05h
	ret z
	ld l,4
	inc b
	ld a,00h
	cp b
	jp nz,channel1_read1
	ld b,84h
channel1_read1:
	ld l,(hl)
	ld e,(hl)
	ld l,4
	ld (hl),b
	ld d,00h
	ld l,06h
	ld a,(hl)
	cp 0ffh
	ret z
	ld d,e
	ld e,a
	ld c,0
	call change_proc
	ld e,d
	ret
	
	;Sets the pipe/channel specified by Reg C to wake the process specified by Reg E on read/write. Reg D returned 00h if successful
	;All registers destroyed
channel0_onwrite:
	;call pipe_valid
	;ld a,0
	;cp d
	;ret nz
	;ld d,0
	;ld h,c
	;ld l,3
	;ld (hl),e
	ret
	
channel0_onread:
	;call pipe_valid
	;ld a,0
	;cp d
	;ret nz
	;ld d,0
	;ld h,c
	;ld l,2
	;ld (hl),e
	ret
	
channel1_onwrite:
	;call pipe_valid
	;ld a,0
	;cp d
	;ret nz
	;ld d,0
	;ld h,c
	;ld l,7
	;ld (hl),e
	ret
	
channel1_onread:
	;call pipe_valid
	;ld a,0
	;cp d
	;ret nz
	;ld d,0
	;ld h,c
	;ld l,6
	;ld (hl),e
	ret
	
	;Writes a byte (Reg E) to the PRGLOADER
	;All registers destroyed
	;-ISC = Issued Command?
	;-PLI = Program loader address index
	;-PLM = Program loader base memory block
	;-PLL = Program loader byte offset
	;-PLP = Program loader new program ID

	;Starts up the PRGLOADER, the total amount of blocks to be allocated is defined by Reg E. Returns Reg D with 00h is successful
	;All registers destroyed

	
init_prgloader:
	ld c,e
	ld e,0
	ld d,07h
	ld hl,SWAP + 0dh
init_prgloader1:
	ld a,(hl)
	bit 1,a
	jp z,init_prgloader2
	inc e
	ld a,l
	add a,10h
	ld l,a
	cp 0dh
	ret z
	jp init_prgloader1
init_prgloader2:
	ld a,e
	ld (PLP),a
	call alloc_mem
	ld a,d
	cp 0
	ret nz
	ld a,(PLP)
	ld e,a
	call get_status_block
	dec l
	inc c
	ld (hl),c
	dec l
	ld (hl),0
	dec l
	ld (hl),c
	dec l
	ld (hl),0
	dec c
	ld a,c
	ld (PLM),a
	inc c
	ld h,c
	ld l,0
	ld (PLI),hl
	ld d,0
	ld a,0
	ld (ISC),a
	ret

	;Writes the value Reg E to the PRGLOADER, Reg D returns FFh if has requests next byte
write_prgloader:
	ld d,0ffh
	ld a,(ISC)
	cp 0
	jp z,write_prgloader1
	ld a,e
	cp 0
	jp z,write_prgloader4
	cp 03h
	jp z,finish_prgloader
	cp 41h
	jp z,write_prgloader5
	cp 42h
	jp z,write_prgloader6
	ret
	
write_prgloader1:
	ld a,e
	cp 1bh
	jp z,write_prgloader3
write_prgloader2:
	ld hl,(PLI)
	ld a,(PLL)
	add a,e
	ld (hl),a
	ld a,0
	ld (PLL),a
	inc hl
	ld (PLI),hl
	ret
write_prgloader3:
	ld a,0ffh
	ld (ISC),a
	ret
write_prgloader4:
	ld e,1bh
	ld a,0
	ld (ISC),a
	jp write_prgloader2
write_prgloader5:
	ld a,(PLM)
	ld (PLL),a
	ld a,0
	ld (ISC),a
	ret
write_prgloader6:
	ld hl,KENT
	ld e,l
	call write_prgloader2
	ld hl,KENT
	ld e,h
	ld a,0
	ld (ISC),a
	jp write_prgloader2

	;Indicates that the args section of memory is to be skipped
	;All registers destroyed
skip_args:
	ld hl,(PLI)
	ld bc,100h
	add hl,bc
	ld (PLI),hl
	ret
	
	;Finishes up the PRGLOADER, the program ID defined in (PLP) will be validaded and start
	;All registers destroyed
finish_prgloader:
	ld a,(PLP)
	cp 0ffh
	ret z
	ld e,a
	call get_status_block
	ld a,(hl)
	and 11111011b
	or 00000010b
	ld (hl),a
	bit 0,a
	ret nz
	ld a,l
	sub 10h
	ld l,a
	ld a,(hl)
	or 00000001b
	ld (hl),a
	ld d,0ffh
	ld a,0
	ld (ISC),a
	ld a,(PLP)
	ld d,a
	ret
	
trap:
	jp trap
.org 	US
	.db 0
	
.org 	US+32
msg1:
	.db "Z80 SKERN V1.0",10,"PPL IN PROG",10,0
msg2:
	.db "OK",10,0
siop:
	.db 0
sysp:
	.db 0
sysr:
	.db 0
syst:
	.db 0
it:
	.db 252
update:
	.db 0
start_proc0:
	ld sp,US+32
	ld hl,msg1
	ld d,0
	;call KENT
	im 2
	ei
p_loop:
	ld e,(hl)
	cp e
	jp z,ppl
	ld a,e
	push hl
	call put_char
	pop hl
	inc hl
	jp p_loop
ppl:	
	call update_screen

	;Alloc 1 Block
	ld c,1
	ld d,0ch
	call KENT
	
	;Mark as pipe
	ld d,12h
	call KENT
	ld a,c
	ld (siop),a
	
	;Init PRGLOADER
	call read_src
	ld d,1ch
	call KENT
	
	;Write JMP to PRGLOADER
	ld d,1dh
	ld e,18h
	call KENT
	ld d,1dh
	ld e,6
	call KENT
	
	;Write #SIO to PRGLOADER
	ld d,1dh
	ld a,(siop)
	ld e,a
	call KENT
	ld d,1dh
	ld e,0
	call KENT
	
	;Write #SYS to PRGLOADER
	ld d,1dh
	ld a,0
	ld e,a
	call KENT
	ld d,1dh
	ld e,0
	call KENT
	
	;Write #COM to PRGLOADER
	ld d,1dh
	ld e,0
	call KENT
	ld d,1dh
	ld e,0
	call KENT
	
load_prg:
	call read_src
	ld d,1dh
	call KENT
	ld a,255
	cp d
	jp z,load_prg
	
	ld hl,msg2
	ld c,2
	ld a,0
ok_loop:
	ld e,(hl)
	cp e
	jp z,enter_loop
	push hl
	ld a,e
	call put_char
	pop hl
	inc hl
	jp ok_loop
	
enter_loop:
	call update_screen
main_loop:
	call check_sio
	ld d,0
	call KENT
	jp main_loop
	
check_sio:
	call write_sio
	call read_sio
	ld a,(update)
	cp 0
	ret z
	ld a,0
	ld (update),a
	call update_screen
	ret
	
write_sio:
	ld d,17h
	ld a,(siop)
	ld c,a
	call KENT
	ld a,d
	cp 0
	ret nz
	ld a,e
	call put_char
	ld a,1
	ld (update),a
	jp write_sio

read_sio:
	call get_key
	ld e,a
	cp 0
	ret z
	ld d,14h
	ld a,(siop)
	ld c,a
	call KENT
	jp read_sio
	
	
src_cnt:
	.db 0,$B0
read_src:
	ld hl,(src_cnt)
	ld e,(hl)
	inc hl
	ld (src_cnt),hl
	ret

.org $B000

testSRC:
	.db $02,$C3,$0D,$1B,$41,$01,$00,$00,$3A,$02,$1B,$41,$01,$4F,$16,$16,$CD,$1B,$42,$7A,$43,$32,$0C,$1B,$41,$01,$78,$32,$0B,$1B,$41,$01,$3A,$0C,$1B,$41,$01,$47,$3E,$00,$B8,$DA,$47,$1B,$41,$01,$3A,$0B,$1B,$41,$01,$5F,$3A,$02,$1B,$41,$01,$4F,$16,$15,$CD,$1B,$42,$7A,$32,$0C,$1B,$41,$01,$3A,$0C,$1B,$41,$01,$47,$3E,$00,$B8,$DA,$4F,$1B,$41,$01,$C3,$0D,$1B,$41,$01,$16,$00,$CD,$1B,$42,$C3,$0D,$1B,$41,$01,$16,$00,$CD,$1B,$42,$C3,$29,$1B,$41,$01,$1B,$03
	;.db $02,$C3,$1D,$1B,$41,$01,$00,$00,$48,$45,$4C,$4C,$4F,$20,$57,$4F,$52,$4C,$44,$0A,$00,$00,$00,$00,$3A,$0B,$1B,$41,$01,$21,$0D,$1B,$41,$01,$5F,$16,$00,$19,$7E,$5F,$3A,$02,$1B,$41,$01,$4F,$16,$15,$CD,$1B,$42,$7A,$32,$0C,$1B,$41,$01,$3A,$0C,$1B,$41,$01,$47,$3E,$00,$B8,$DA,$1D,$1B,$41,$01,$21,$0B,$1B,$41,$01,$34,$3A,$0B,$1B,$41,$01,$21,$0D,$1B,$41,$01,$5F,$16,$00,$19,$7E,$47,$3E,$00,$B8,$DA,$1D,$1B,$41,$01,$16,$00,$CD,$1B,$42,$C3,$56,$1B,$41,$01,$1B,$03
	
.end
.end