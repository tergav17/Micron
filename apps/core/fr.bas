SHORT M = 0
BYTE A = 0
BYTE B = 0
BYTE C = 0
BYTE E = 0
@START
	FREEMEM M
	GOSUB PRINTSRT
	FREESEC M
	GOSUB PRINTSRT
	GETPID A
	LET #COM[1] = A
	LET #COM[0] = 255
HALT:
	GOTO HALT
	
PRINTSRT:
	LET C = M[1]
	GOSUB PRINTB
	LET C = M[0]
	GOSUB PRINTB
	LET C = 10
	GOTO PUTC
	
PRINTB:
	SPLIT C,B,A
	LET C = A
	GOSUB PRINTH
	LET C = B
	GOTO PRINTH
PRINTH:
	LET C =+ 48
	IF C > 57 GOSUB PRINTH1
	GOSUB PUTC
	RETURN
PRINTH1:
	LET C =+ 7
	RETURN
PUTC:
	WRITE #SIO,C,E
	IF E > 0 GOTO PERR
	RETURN
PERR:
	FORFIT
	GOTO PUTC