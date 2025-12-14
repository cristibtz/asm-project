include "emu8086.inc"
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h
    ;Open test.txt file to read and print its contents
    mov dx, offset filename ; filename
    mov al, 0 ; access mode read
    mov ah, 3dh ; interrupt open file
    int 21h ; call interrupt
    jc open_failed ;  jump if condition is met; use for error
    mov [handle], ax ;  save file handle
    
    ;if we get here, its good
    ;PRINTN 'File opened successfully'

    ; Read from file
    mov bx, [handle] ; set file handle
    mov cx, 128 ; no of bytes read
    mov dx, offset buffer ; data buffer
    mov ah, 3fh ; read from file interrupt
    int 21h ; call interrupt
    jc read_failed; use for read failure
    
    mov [bytes_read], ax  ; AX = no of bytes read
    
    ;PRINTN 'File opened and read successfully'
    ;PRINTN 'Bytes read: '
        
    cmp ax, pass_len ; compare bytes read with password length
    jb password_too_long ;  error is password length < text read
    
    mov si, 0; prepare index to iterate through buffer
    mov cx, [bytes_read] ; counter
    mov di, 0 ; iterate through password
    
    print_n_xor_loop:
        mov al, [buffer+si] ; prepare for xor
        xor al, [password+di]; xor
        inc di ; increment password index
        
        cmp di, pass_len ; compare password length to index
        jb skip_reset ; jump if di < pass_len
        mov di, 0 ; if not jump di becomes zero and we use xor repeating key
 
    skip_reset:
        
        
        putc al ; write character to screen
        mov [buffer+si], al ; move xored byte back to buffer
        
        inc si  ; go to next byte of word        
        
        loop print_n_xor_loop ; repeat
            
    
    ; Create encrypted file
    mov dx, offset out_filename ; set filename
    mov cx, 0 ; normal file, no attributes
    mov ah, 3Ch  ; create file
    int 21h ;  call interrupt
    jc create_output_file_failed ;  file creation error
    mov [out_handle], ax ; save output file hand;e
    
    ; Write xored bytes to file
    mov bx, [out_handle]
    mov dx, offset buffer
    mov cx, [bytes_read]
    mov ah, 40h
    int 21h
    jc write_failed
    
    ; Close output file
    mov bx, [out_handle]
    mov ah, 3Eh
    int 21h
    
    ; Close read file
    mov bx, [handle]
    mov ah, 3Eh
    int 21h
    
    jmp done

; Error handlers    
open_failed:
    PRINTN 'Error: couldnt open file'
    jmp done

read_failed:
    PRINTN 'Error: cant read file'
    jmp done      

password_too_long:
    PRINTN 'Text cant be shorter than password'
    jmp done       

create_output_file_failed: 
    PRINTN 'Failed to create output file'
    jmp done

write_failed:
    PRINTN 'Failed to write to output file'
    jmp done
        
done:
    ret

; Variables
filename db "test.txt.xored",0 ; end name with 0
out_filename db "test.txt.xored",0 ; end name with 0
handle dw ? ; file handle returned by dos
out_handle dw ? ; file handle for output file
buffer db 128 dup(?)
bytes_read dw 0                   
password db "secret12"; xor secret byte
pass_len equ $ - password ; calculate password length(current address - address of first character in pass)


