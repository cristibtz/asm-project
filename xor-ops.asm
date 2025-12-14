include "emu8086.inc"

; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

; xor al
    ;mov al, 5            ; AL = 00000101b
    ;xor al, 3            ; AL = AL XOR 00000011b  (result = 00000110b)

; xor byte in memory
    ;byte_value db 25     ; decimal 25, stored in memory
    ;key db 7             ; XOR key
    
    ;mov al, byte_value   ; load byte
    ;xor al, key          ; xor with key
    ;mov byte_value, al   ; write in variable new value
 
; xor buffer(infinite loop, just proof of concept)
     
     mov si, 0 ; index into buffer
     mov cx, 16 ;  AX holds number of bytes read (from INT 21h / 3Fh)
     
     xor_loop:
        printn "loop"
        mov al, [buffer+si] ; put read byte from buffer into al
        xor al, key         ; xor
        mov [buffer+si], al ; put xored byte in buffer
        
        inc si ; increment si with 1 and go to next byte
        loop xor_loop ; repeat ; decrement CX, loop while not zero
     
 
ret
     buffer db 16 dup(8); read buffer
     key db 5       ; xor key



