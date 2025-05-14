;*****************************************************************************
; Author: Nick Bailey
; Date: 5/14/2025
; Revision: 1.0
;
; Description:
; LC-3 Calculator program
; Notes:
; Capable of Addition
; Enter exits program
; Capable of accepting extremely large numbers as arguments
;
; Register Usage:
; R0 used for input
; R1 used to check for operator inputs
; R2 used to store operator values
; R3 used to access numbers from 2nd input for calculations
; R4 used to store next operator after exiting a function
; R5 reserved for TempStack/second input stack
; R6 reserved for stack
; R7 used to return from functions
;********************************************************************************************



.ORIG x3000
    LD R6, STACK ;add enter value to the front of both stacks (to check if at end of stack to stop calculations)
    AND R0, R0, #0
    ADD R0, R0, #10
    STR R0, R6, #0
    ADD R6, R6, #-1
    LD R5, TEMPSTACK
    AND R0, R0, #0
    ADD R0, R0, #10
    STR R0, R5, #0
    ADD R5, R5, #-1
    AND R4, R4, #0
LOOP
    ADD R4, R4, #0 ;if R4 = 0 then skip checking R4 for operator
    BRz SkipCheck ;if R4 contains an operator then jump to that function call or if enter jump to program end
    ADD R6, R6, #1
    LD R2, Operator+
    ADD R1, R4, R2
    BRz AdditionJmp
    LD R2, Operator-
    ADD R1, R4, R2
    BRz SubtractionJmp
    ADD R1, R4, #-10
    BRz Enter
SkipCheck
    TRAP x20
    LD R2, Operator+ ;add an enter character to the stack to allow for detection of the end of the stack
    ADD R1, R0, R2
    BRz AdditionJmp
    LD R2, Operator-
    ADD R1, R0, R2
    BRz SubtractionJmp
    ADD R1, R0, #-10
    BRz Enter
    LD R2, UpperBound
    ADD R1, R0, R2
    BRzp LOOP ;if input is not a number then ignore
    LD R2, LowerBound
    ADD R1, R0, R2
    BRnz LOOP
    TRAP x21
    LD R1, AscToDec
    ADD R0, R0, R1 ;conv input to ASCII
    STR R0, R6, #0
    ADD R6, R6, #-1
    Br LOOP
AdditionJmp
    ADD R4, R4, #0
    BRp SkipDisplay
    TRAP x21
SkipDisplay
    ADD R6, R6, #0 ;store enter char in stack
    AND R0, R0, #0
    ADD R0, R0, #10
    STR R0, R6, #0
    ADD R6, R6, #1
    JSR Addition
    Br Display
SubtractionJmp
    ADD R4, R4, #0
    BRp SkipDisplay2
    TRAP x21
SkipDisplay2
    ADD R6, R6, #0
    AND R0, R0, #0
    ADD R0, R0, #10
    STR R0, R6, #0
    ADD R6, R6, #1
    JSR Subtraction
    Br Display
MultiplicationJmp
    TRAP x21
    ADD R6, R6, #-1
    AND R0, R0, #0
    ADD R0, R0, #10
    STR R0, R6, #0
    ADD R6, R6, #1
    JSR Multiplication
    Br Display
Display
    LD R6, STACK
    LDR R0, R6, #0
    ADD R1, R0, #-10
    BRz SkipFirst
    Trap x21
SkipFirst
    ADD R6, R6, #-1
    AND R0, R0, #0
    ADD R0, R0, #10
    TRAP x21
DisplayLoop
    LDR R0, R6, #0
    ADD R6, R6, #-1
    ADD R1, R0, #-10
    BRz DisplayDone
    LD R2, DecToAsc
    ADD R0, R0, R2
    TRAP x21
    BR DisplayLoop
DisplayDone
    ADD R0, R4, #0
    TRAP x21
    BR LOOP
Enter
    HALT
    
    







ReturnAddress .BLKW #1
Operator+ .FILL #-43
Operator- .FILL #-45
Operator* .FILL #-42
UpperBound .Fill #-58
LowerBound .Fill #-47
AscToDec .Fill #-48
DecToAsc .Fill #48
STACK .Fill xFD50
TEMPSTACK .Fill xEE00
;****************Addition************
;Subroutine to process user input and complete the operations
;
;R0 - current first input char
;R1 - operator check result
;R2 - stores current operator check
;R3 - current second input char
;R4 - stores next operator
;R5 - second stack pointer to store second input for calculations
;R6 - result/first input stack pointer
;R7 - used to store return address and add extra number to next input
;**************************************** 
Addition:
    ST R7, ReturnAddress
    LD R5, TEMPSTACK ;stack for 2nd input to use in functions
    ADD R5, R5, #-1
    AND R7, R7, #0
    ADD R6, R6, #0
    ;R6 stack is first input R5 stack is 2nd input
    ;Add latest number of both stacks together and if > 10 then add 1 to next number loop untill current number 
    ;is < 10, PA6 code has a similar check
    ;check for other operators or enter (must make it pass to main such as setting r0 to the operator)
AddLOOP
    TRAP x20
    LD R2, Operator+
    ADD R1, R0, R2
    BRz AddInputs
    LD R2, Operator-
    ADD R1, R0, R2
    BRz AddInputs
    ADD R1, R0, #-10
    BRz AddInputs
    LD R2, UpperBound
    ADD R1, R0, R2
    BRzp AddLOOP
    LD R2, LowerBound
    ADD R1, R0, R2
    BRnz AddLOOP
    TRAP x21
    LD R2, AscToDec
    ADD R0, R0, R2 ;conv input to Dec
    STR R0, R5, #0
    ADD R5, R5, #-1
    Br AddLOOP
AddInputs
    ADD R4, R0, #0 ;R4 = R0 will be used to check for another operator to call another function or end program
    ADD R5, R5, #1
AddinputsLoop
    LDR R0, R6, #0
    ADD R1, R0, #-10
    BRn EnterKey
    ADD R0, R0, #-10
EnterKey
    LDR R3, R5, #0
    ADD R1, R3, #-10 ;if R3 is an enter char then end loop
    BRz AddDone
    ADD R0, R0, R7 ;add extra number (will add 0 if there wasn't)
    ADD R0, R0, R3
    ADD R1, R0, #-10 ;if R1 + R3 > 10
    BRzp Overload
    AND R7, R7, #0
    BR Store
Overload
    ADD R0, R0 #-10
    AND R7, R7, #0
    ADD R7, R7, #1 ;R7 = 1 to add to next R6 stack value
Store
    STR R0, R6, #0 ;store new R0 value in R6 stack
    ADD R6, R6, #1
    ADD R5, R5, #1
    BR AddInputsLoop
AddDone
    ADD R7, R7, #0
    BRz Skip
    AND R0, R0, #0
    ADD R0, R0, R7
    STR R0, R6, #0
    ADD R6, R6, #1
Skip
    ADD R6, R6, #1
    LDR R0, R6, #0
    ADD R0, R0, #0
    BRp Complete
    ADD R0, R0, #10
    STR R0, R6, #0
    ADD R6, R6, #-1
    ST R6, STACK
Complete
    ADD R6, R6, #-1
    LD R7, ReturnAddress
    RET
    
    
;****************Subtraction************
;Subroutine to process user input and complete the operations
;
;R0 - current input char
;R1 - operator check result
;R2 - stores current operator check
;**************************************** 
Subtraction:
    ST R7, ReturnAddress
    
    LD R7, ReturnAddress
    RET
    
    
;****************Multiplication************
;Subroutine to process user input and complete the operations
;
;R0 - current input char
;R1 - operator check result
;R2 - stores current operator check
;**************************************** 
Multiplication:
    ST R7, ReturnAddress
    
    LD R7, ReturnAddress
    RET


    .END