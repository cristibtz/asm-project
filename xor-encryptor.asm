include "emu8086.inc"

; Basic XOR File Encryptor
                
org 100h

    ;CMDLINE arguments
    mov si, 81h                     ; start of cmdline
    mov cl, [80h]                   ; store length of cmdline in cl
    cmp cl, 0                       ; compare cmdline length to zero
    je show_usage                   ; if cmdline length == 0, show usage instructions
    
    ; Skip leading spaces
    skip_spaces:
        cmp byte ptr [si], ' '      ; check if character is a space
        jne found_filename          ; if not a space, process filename
        inc si                      ; go to next char
        dec cl                      ; decrement remaining length
        jz show_usage               ; if cl became zero, show instructions
        jmp skip_spaces             ; check next character
    
    ; Found filename    
    found_filename:
        mov di, offset filename
        mov bx, 0                   ; filename length counter
    
    ; Copy filename from cmdline into variable    
    copy_filename:
        cmp byte ptr [si], ' '      ; check if space char between args
        je filename_done            ; check if we reached the filename end
        
        cmp byte ptr [si], 0dh      ; check carriage return = end of cmdline args ; if si is carriage return, its end
        je show_usage
                      
        cmp cl, 0                   ; check if filename length is zero ; check if we processed all chars from cmdline
        je filename_done        
                                    
        mov al, [si]                ; move char from cmdline to al
        mov [di], al                ; copy one char from cmdline to filename buffer ; mov char from al into di
        
        inc si                      ; increment si to go to next character
        inc di                      ; increment di to go to next space in the variable
        inc bx                      ; increment the filename length counter
        dec cl                      ; decrement cmdline length counter
        
        cmp bx, 20                  ; maximum filename length
        jb copy_filename            ; copy filename until reaching maximum length or stop if cl reaches zero above
    
    ; End of filename
    filename_done:
        mov byte ptr [di], 0        ; null terminate filename
                            
    ; Parse password
    skip_spaces2:                   
        cmp cl, 0                   ; check if cmdline length is zero
        je show_usage               ; if no chars, then incomplete cmdline args   
        
        cmp byte ptr [si], ' '      ; check if character is a space
        jne found_password          ; if not a space, process password
        
        inc si                      ; go to next char in cmdline
        dec cl                      ; decrement remaining cmdline length
        jmp skip_spaces2            ; check next character
    
    ; Found password    
    found_password:
        mov di, offset password     ; first position in variable password moved in di
        mov bx, 0                   ; password length counter
    
    ; Copy password from cmdline into variable    
    copy_password:
        cmp byte ptr [si], 0dh      ; if si is carriage return, its end of cmdline
        je password_done                                             
        
        cmp cl, 0                   ; if we reached length of cmdline zero, we finish processing
        je password_done         
        
        mov al, [si]                ; move password char from cmdline to al
        mov [di], al                ; move from al to filename buffer
        
        inc si                      ; go to next char in cmdline
        inc di                      ; go to next position in variable
        inc bx                      ; increment password length
        dec cl                      ; decrement command line length
        
        cmp bx, 20                  ; max pass length
        jb copy_password            ; copy password until reaching maximum length or if cl reaches zero above
    
    ; End of password    
    password_done:
        mov [pass_len], bx          ; store actual password length
        jmp continue_program        ; continue to XORing
    
    ; Instructions on how to use the program    
    show_usage:
        PRINTN 'Usage: program filename password'
        PRINTN 'Output will be filename.xored'
        jmp done
        
    ; Errors    
    arg_error:
        PRINTN 'Error: invalid arguments'
        jmp show_usage
    
    ; Creating output filename    
    create_output_name:
        ; Copy input filename to output filename
        mov si, offset filename
        mov di, offset out_filename
                                              
    ; Copy initial filename and add extension to it
    copy_name:
        mov al, [si]                ; mov first char of filename in al
        cmp al, 0                   ; check if we reached filename end
        je add_extension            ; when null byte is reached, start adding extension 
              
        mov [di], al                ; put char from filename into output filename    
        
        inc si                      ; go to next char
        inc di                      ; go to next position    
        
        jmp copy_name               ; repeat copy loop
        
    add_extension:
        ; Add .xored extension
        mov byte ptr [di], '.'
        inc di
        mov byte ptr [di], 'x'
        inc di
        mov byte ptr [di], 'o'
        inc di
        mov byte ptr [di], 'r'
        inc di
        mov byte ptr [di], 'e'
        inc di
        mov byte ptr [di], 'd'
        inc di
        mov byte ptr [di], 0        ; terminate output filename
        ret
     
    continue_program:       
    
        call create_output_name 
        
        ; Open file                 
        mov dx, offset filename     ; filename
        mov al, 0                   ; access mode read
        mov ah, 3dh                 ; interrupt of open file
        int 21h                     ; call interrupt
        jc open_failed              ;  jump if condition is met; use for error
        mov [handle], ax            ;  save file handle
        
        ;if we get here, its good
        ;PRINTN 'File opened successfully'
    
        ; Read from file
        mov bx, [handle]            ; set file handle
        mov cx, 128                 ; no of bytes read
        mov dx, offset buffer       ; data buffer
        mov ah, 3fh                 ; read from file interrupt
        int 21h                     ; call interrupt
        jc read_failed              ; use for read failure
        
        mov [bytes_read], ax        ; AX = no of bytes read
        
        ;PRINTN 'File opened and read successfully'
        ;PRINTN 'Bytes read: '
            
        cmp ax, [pass_len]          ; compare bytes read with password length
        jb password_too_long        ; error if password length < text read
        
        mov si, 0                   ; prepare index to iterate through buffer
        mov cx, [bytes_read]        ; counter
        mov di, 0                   ; iterate through password
                 
        ; XOR operation
        print_n_xor_loop:
            mov al, [buffer+si]     ; mov (buffer address + si) to al for xoring
            xor al, [password+di]   ; xor al with (password buffer + di)
            inc di                  ; increment password index
            
            cmp di, [pass_len]      ; compare password length to index
            jb continue_xor           ; jump if di < pass_len
            mov di, 0               ; if not jump di becomes zero and we use xor repeating key
        
        ; Write xored byte to buffer and go to next char
        continue_xor:
            putc al                 ; write character to screen
            mov [buffer+si], al     ; move xored byte back to buffer
            
            inc si                  ; go to next byte of word        
            
            loop print_n_xor_loop ; repeat
                
        
        ; Create encrypted file
        mov dx, offset out_filename ; set filename
        mov cx, 0                   ; normal file, no attributes
        mov ah, 3Ch                 ; create file
        int 21h                     ; call interrupt
        jc create_output_file_failed; file creation error
        mov [out_handle], ax        ; save output file handle
        
        ; Write xored bytes to file
        mov bx, [out_handle]        ; put output_file handle in bx
        mov dx, offset buffer       ; put buffer address in dx
        mov cx, [bytes_read]        ; put number of bytes read in cx to write them
        mov ah, 40h                 ; write to file interrupt
        int 21h                     ; call interrupt
        jc write_failed             ; failed write
        
        ; Close output file
        mov bx, [out_handle]        ; move output file handle to bx
        mov ah, 3Eh                 ; file close interrupt
        int 21h                     ; call interrupt
        
        ; Close read file           ; initial input file handle
        mov bx, [handle]            ; file close interrupt
        mov ah, 3Eh                 ; call interrupt
        int 21h
        
        jmp done                    ; finish program

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
filename db 20 dup(0)               ; input filename buffer
out_filename db 90 dup(0)           ; output filename buffer
handle dw ?                         ; file handle returned by dos
out_handle dw ?                     ; file handle for output file
buffer db 128 dup(?)                ; buffer for initial rad bytes
bytes_read dw 0                     ; bytes read variable
password db 21 dup(0)               ;input password buffer
pass_len dw 0                       ; variable to store password length


