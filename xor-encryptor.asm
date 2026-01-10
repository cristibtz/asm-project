include "emu8086.inc"
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

    ;CMDLINE arguments
    mov si, 81h     ;start of cmdline
    mov cl, [80h]   ; store length of cmdline in cl
    cmp cl, 0       ; compare cmdline length to zero
    je show_usage   ; if cmdline length == 0, show usage instructions
    
    ; skip leading spaces
    skip_spaces:
        cmp byte ptr [si], ' '  ; check if character is a space
        jne found_filename      ; if not a space, process filename
        inc si      ; go to next char
        dec cl      ; decrement remaining length
        jz show_usage       ;if cl became zero, show instructions
        jmp skip_spaces     ; check next character
        
    found_filename:
        mov di, offset filename
        mov bx, 0       ; filename length counter
        
    copy_filename:
        cmp byte ptr [si], ' '
        je filename_done        ; check if we reached the filename end
        
        cmp byte ptr [si], 0dh      ; check carriage return = end of cmdline args ; if si is carriage return, its end
        je filename_done
                      
        cmp cl, 0
        je filename_done        ; Check if we processed all chars from cmdline
                      
        mov al, [si]
        mov [di], al        ; copy one char from cmdline to filename buffer
        
        inc si
        inc di
        inc bx
        dec cl      ; increment/decrement pointers accordingly
        
        cmp bx, 20
        jb copy_filename        ; copy chars until 8.3 rule
    
    filename_done:
        mov byte ptr [di], 0    ; null terminate filename
            
        
    ; Parse password
    skip_spaces2:
        cmp cl, 0
        je show_usage   ; if no chars, then incomplete cmdline args
        cmp byte ptr [si], ' ' ; check if character is a space
        jne found_password     ; if not a space, process password
        inc si                 ; go to next char
        dec cl                 ; decrement remaining length
        jmp skip_spaces2       ; check next character
        
    found_password:
        mov di, offset password
        mov bx, 0       ; password length counter
        
    copy_password:
        cmp byte ptr [si], 0dh  ; if si is carriage return, its end
        je password_done                                             
        
        cmp cl, 0
        je password_done     ; Check if we processed all chars from cmdline 
        
        mov al, [si]
        mov [di], al         ; copy one char from cmdline to filename buffer
        
        inc si
        inc di
        inc bx
        dec cl              ; increment/decrement pointers accordingly
        
        cmp bx, 20  ; max pass length
        jb copy_password
        
    password_done:
        mov [pass_len], bx  ; store actual password length
        jmp continue_program
        
    show_usage:
        PRINTN 'Usage: program filename password'
        PRINTN 'Output will be filename.xored'
        jmp done
        
    arg_error:
        PRINTN 'Error: invalid arguments'
        jmp show_usage
        
    create_output_name:
        ; Copy input filename to output filename
        mov si, offset filename
        mov di, offset out_filename
 
    copy_name:
        mov al, [si]
        cmp al, 0
        je add_extension    ; copy chars from input filename one by one until zero       
        mov [di], al
        inc si
        inc di
        jmp copy_name       ; repeat copy loop
        
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
        mov byte ptr [di], 0    ; terminate output filename
        ret
     
    continue_program:       
    
        call create_output_name
        
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
            
        cmp ax, [pass_len] ; compare bytes read with password length
        jb password_too_long ;  error is password length < text read
        
        mov si, 0; prepare index to iterate through buffer
        mov cx, [bytes_read] ; counter
        mov di, 0 ; iterate through password
        
        print_n_xor_loop:
            mov al, [buffer+si] ; prepare for xor
            xor al, [password+di]; xor
            inc di ; increment password index
            
            cmp di, [pass_len] ; compare password length to index
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
filename db 20 dup(0) ; input filename buffer
out_filename db 90 dup(0) ; output filename buffer
handle dw ? ; file handle returned by dos
out_handle dw ? ; file handle for output file
buffer db 128 dup(?)
bytes_read dw 0                   
password db 21 dup(0) ;input password buffer
pass_len dw 0 ; variable to store password length


