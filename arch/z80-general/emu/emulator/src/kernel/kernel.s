SIO equ 5
;Variables
PID equ 20h
TEMP equ 21h
SPM equ 23h
INI equ 25h
CL1 equ 26h
CL2 equ 27h
CL3 equ 28h
CL4 equ 29h
PLS equ 2ah
PLM equ 2bh
PLE equ 2ch
PLL equ 2dh
ISC equ 2eh
PLP equ 2fh
NBR equ 30h
PLI equ 31h
;Memory Regions
SWAP equ 100h
MEMT equ 200h
PIPE equ 300h
KENT equ 400h
KENTH equ 4h
KENTL equ 0h
US equ 800h

;	0000-Program Start,Init
;	0020-Variable Area
;	0038-Interrupt Address, Context SWAP
;	0100-Context Block Area
;   0200-Memory Allocation Table Area
;   0300-Pipe Marker Table Area
;   0400-Kernel Entry Point
;	0800-User Space
	
	
	;Program start
	org 00h
	jp init
	
	;Entry point for emulated I/O
	org 05h
	ret
	;Init for context swapper
init:
	ld sp,0FFF0h
	ld a,0
	ld (PID),a
	exx
	im 1
	ld hl,SWAP + 0Bh
	exx
	ei
	jp start_proc0
	
	org 20h
	;Variable Init
	defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	defb 0,0
	
	;Context Swap
	;Reg BC - Stored Context Block Address
	;Reg HL - Context Block Address Counter
	org 38h
on_int:
	ex af,af'
	ld a,(CL1)
	add 17
	ld (CL1),a
	ld a,(CL2)
	adc 0
	ld (CL2),a
	ld a,(CL3)
	adc 0
	ld (CL3),a
	ld a,(CL4)
	adc 0
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
	exx
	ei
	ret
	
	;Area of memory in which the context blocks are stored
	org SWAP
	defb 0,0,0,0,0,0,0,0,0,0,0,0,0,00000010b,0,0
	
	;Area of memory in which the memory table is stored
	org MEMT
	
	;0EFh = Kernel Memory (Reserved)
	;000h = Process 0 Memory
	;001h = Process 1 Memory
	;0FFh = Unallocated Memory
	
	;    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	defb 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	
	;Area of memory in which the pipe markers are stored
	org PIPE
	
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	
	;Kernel Entry
	org KENT
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
	cp 21h
	ret nz
	ld c,9
	call SIO
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
	add 10h
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
	add e
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
	org US
	defb 0
	
	org US+8
msg1:
	defb "Z80 SKERN V1.0",10,"PPL IN PROG",10,0
msg2:
	defb "OK",10,0
siop:
	defb 0
sysp:
	defb 0
sysr:
	defb 0
syst:
	defb 0
it:
	defb 252
start_proc0:
	ld sp,US+8
	ld hl,msg1
	ld c,2
	ld a,0
p_loop:
	ld e,(hl)
	cp e
	jp z,ppl
	call SIO
	inc hl
	jp p_loop
ppl:	
	;Alloc 1 Block
	ld c,1
	ld d,0ch
	call KENT
	
	;Mark as pipe
	ld d,12h
	call KENT
	ld a,c
	ld (siop),a
	
	;Alloc 1 Block
	ld c,1
	ld d,0ch
	call KENT
	
	;Mark as pipe
	ld d,12h
	call KENT
	ld a,c
	ld (sysp),a
	
	;Get size of PRG
	ld c,3
	call SIO
	
	;Init PRGLOADER
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
	ld a,(sysp)
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
	
	;Set CoreWatch
	ld a,(sysp)
	ld e,a
	ld c,4
	call SIO
	;Fill the rest of the args with 0ffh
	;args_ff:
	;ld d,1dh
	;ld e,0ffh
	;call KENT
	;ld hl,it
	;dec (hl)
	;jp nz,args_ff
	
	;Load the PRG
load_prg:
	ld c,3
	call SIO
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
	jp z,main_loop
	call SIO
	inc hl
	jp ok_loop
	
main_loop:
	call check_sio
	call check_sys
	ld d,0
	call KENT
	jp main_loop

check_sio:
	call write_sio
	call read_sio
	ret
	
check_sys:
	call write_sys
	call read_sys
	ret

write_sio:
	ld d,17h
	ld a,(siop)
	ld c,a
	call KENT
	ld a,d
	cp 0
	ret nz
	ld c,2
	call SIO
	jp write_sio

read_sio:
	ld c,1
	call SIO
	ld a,e
	cp 0
	ret z
	ld d,14h
	ld a,(siop)
	ld c,a
	call KENT
	jp read_sio

write_sys:
	ld c,6
	call SIO
	ld a,e
	cp 0
	ret z
	ld d,17h
	ld a,(sysp)
	ld c,a
	call KENT
	ld a,d
	cp 0
	ret nz
	ld c,5
	call SIO
	jp write_sys
	
read_sys:
	ld a,(sysr)
	cp 0
	jp nz,read_sys2
	ld c,8
	call SIO
	ld a,e
	cp 0
	ret z
	ld c,7
	call SIO
read_sys1:
	ld d,14h
	ld a,e
	ld (syst),a
	ld a,(sysp)
	ld c,a
	call KENT
	ld a,d
	cp 0
	jp z,read_sys
	ld a,1
	ld (sysr),a
	ret
read_sys2:
	ld a,(syst)
	jp read_sys1
	

	
	