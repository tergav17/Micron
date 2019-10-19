BYTE A = 128
BYTE B = 0
BYTE C = 1
BYTE I = 0
BYTE E = 0
@START
	LET #COM[130] =- 48
	IF #COM[128] = 0 GOTO KILL
	IF #COM[129] = 0 GOTO KILL
LOOP:
	LET #COM[C] = #COM[A]
	INC C
	INC A
	IF C < 4 GOTO LOOP
	IF #COM[131] = 58 GOTO GOCOM
KILL:
	GETPID A
	LET #COM[1] = A
	LET #COM[0] = 255
HALT:
	GOTO HALT
WAIT:
	FORFIT
	IF #COM[0] > 0 GOTO WAIT
	RETURN
GOCOM:
	LET #COM[0] = 10
	GOSUB WAIT
	GOTO KILL