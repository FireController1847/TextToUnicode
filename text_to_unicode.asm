INCLUDELIB kernel32.lib

; Constants
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11

; Prototypes
GetStdHandle PROTO
WriteConsoleW PROTO
ReadConsoleW PROTO
ExitProcess PROTO
GetLastError PROTO

.DATA
UnicodeNumbers  WORD    30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h
TextToDecode    WORD    54h, 65h, 78h, 74h, 20h, 74h, 6Fh, 20h, 44h, 65h, 63h, 6Fh, 64h, 65h, 3Ah, 20h, 00h
TextNewline     WORD    0Dh, 0Ah, 00h
TextToPrint     WORD    00h, 00h, 68h, 2Ch, 20h
TextToExit      WORD    0Dh, 0Ah, 50h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh, 20h, 65h, 78h, 69h, 74h, 2Eh
StdOutHandle    QWORD   ?
StdInBuffer     WORD    128 DUP (?)
StdInHandle     QWORD   ?
StdInCharsWritten   BYTE    ?

.CODE
ParseNumber PROC
    MOV R8, RBP
    MOV R9, RSI
    LEA RBP, UnicodeNumbers
    XOR RSI, RSI
    MOV SIL, BL
    MOV DL, [RBP + (2 * RSI)]
    MOV RBP, R8
    MOV RSI, R9
    RET
ParseNumber ENDP

main PROC
    ; Clear registers
    XOR RAX, RAX
    XOR RCX, RCX
    XOR RDX, RDX
    XOR R8, R8
    XOR R9, R9

    ; Fetch console handles
    MOV RCX, STD_OUTPUT_HANDLE
    CALL GetStdHandle
    MOV StdOutHandle, RAX
    MOV RCX, STD_INPUT_HANDLE
    CALL GetStdHandle
    MOV StdInHandle, RAX

    ; Print initial text
    MOV RCX, StdOutHandle
    LEA RDX, TextToDecode
    MOV R8, LENGTHOF TextToDecode
    CALL WriteConsoleW

    ; Read text input
    MOV RCX, StdInHandle
    LEA RDX, StdInBuffer
    MOV R8, LENGTHOF StdInBuffer
    LEA R9, StdInCharsWritten
    CALL ReadConsoleW

    ; Insert newline
    MOV RCX, StdOutHandle
    LEA RDX, TextNewline
    MOV R8, LENGTHOF TextNewline
    CALL WriteConsoleW

    ; Prepare for text processing
    LEA R12, StdInBuffer
    XOR R13, R13
    XOR R14, R14
    XOR RAX, RAX
    XOR RBX, RBX
    MOV R14B, StdInCharsWritten
    DEC R14
    DEC R14

process_loop:
    ; Load next character
    MOV AX, [R12 + (2 * R13)]

    ; Parse first number
    MOV BX, AX
    AND BL, 11110000b
    SHR BL, 4
    XOR DX, DX
    CALL ParseNumber
    MOV TextToPrint[0], DX

    ; Parse second number
    MOV BX, AX
    AND BL, 00001111b
    XOR DX, DX
    CALL ParseNumber
    MOV TextToPrint[2], DX

    ; Since all uses of R13 are done, increment it
    INC R13

    ; Check if this is the last one
    CMP R13, R14
    JNE process_loop_continue

    ; If it is, remove comma and space
    MOV TextToPrint[6], 00h
    MOV TextTOPrint[8], 00h
process_loop_continue:
    ; Print number
    MOV RCX, StdOutHandle
    LEA RDX, TextToPrint
    MOV R8, LENGTHOF TextToPrint
    CALL WriteConsoleW

    ; Loop check
    CMP R13, R14
    JNE process_loop

    ; Insert newline
    MOV RCX, StdOutHandle
    LEA RDX, TextNewline
    MOV R8, LENGTHOF TextNewline
    CALL WriteConsoleW

    ; Write exit line
    MOV RCX, StdOutHandle
    LEA RDX, TextToExit
    MOV R8, LENGTHOF TextToExit
    CALL WriteConsoleW

    ; Read text input
    MOV RCX, StdInHandle
    LEA RDX, StdInBuffer
    MOV R8, LENGTHOF StdInBuffer
    LEA R9, StdInCharsWritten
    CALL ReadConsoleW

    ; Exit
    CALL ExitProcess
main ENDP
END