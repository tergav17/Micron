BYTE A = 128
BYTE B = 0
BYTE C = 0
BYTE I = 0
BYTE E = 0
STRING FILE[17] = ""
@START
LOADFILE:
	IF #COM[A] < 33 GOTO OPEN
	LET FILE[I] = #COM[A]
	INC A
	INC I
	IF I > 17 GOTO KILL
	GOTO LOADFILE
OPEN:
	LET A = 0
	LET I = 1
	IF FILE[3] = 58 GOTO HASFSD
NOFSD:
	LET #COM[I] = 255
	INC I
	IF I < 4 GOTO NOFSD
	LET I = 0
	GOTO PUTSEC
TODEC:
	LET FILE[A] =- 48
	RETURN
HASFSD:
	IF A = 2 GOSUB TODEC
	LET #COM[I] = FILE[A]
	INC I
	INC A
	IF A < 3 GOTO HASFSD
	LET I = A
	INC I
PUTSEC:
	LET #COM[4] = 0
	LET #COM[5] = 0
	LET A = 6
PUTFILE:
	LET #COM[A] = FILE[I]
	INC A
	INC I
	IF FILE[I] = 0 GOTO GOCOM
	IF A < 18 GOTO PUTFILE
GOCOM:
	LET #COM[A] = 0
	LET #COM[0] = 3
	GOSUB WAIT
	IF #COM[126] > 0 GOTO KILL
	LET C = 42 
	GOSUB PUTC
STARTLIN:
	LET I = 128
LINLOOP:
	GOSUB PULLC
	GOSUB PUTC
	IF C = 27 GOTO WRITEOUT
	LET #COM[I] = C
	INC I
	IF I > 0 GOTO LINLOOP
WRITE:
	LET #COM[0] = 2
	GOSUB WAIT
	LET #COM[4] =+ 1
	IF #COM[4] > 0 GOTO CHECKERR
	LET #COM[5] =+ 1
CHECKERR:
	IF #COM[126] = 0 GOTO STARTLIN
KILL:
	GETPID A
	LET #COM[1] = A
	LET #COM[0] = 255
HALT:
	GOTO HALT
WRITEOUT:
	LET #COM[I] = 0
	INC I
	IF I > 0 GOTO WRITEOUT
	LET #COM[0] = 2
	GOSUB WAIT
	GOTO KILL

	
WAIT:
	FORFIT
	IF #COM[0] > 0 GOTO WAIT
	RETURN
PUTC:
	WRITE #SIO,C,E
	IF E > 0 GOTO PERR
	RETURN
PERR:
	FORFIT
	GOTO PUTC
PULLC:
	READ #SIO,C,E
	IF E > 0 GOTO PULLERR
	RETURN
PULLERR:
	FORFIT
	GOTO PULLC