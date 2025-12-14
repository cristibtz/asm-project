
	org 100h
	
	OPEN_FILE:
    	mov al, 2    ; access mode RW
    	
    	mov dx, offset filename ; set filename
    	
    	mov ah, 3dh  ; open file
    	
    	int 21h      ; call interrupt 
    	
    	jc err       ; CF=1 means file does not exist OR cannot be opened
    	
    	mov handle, ax ; AX = file handle
    	
    	jmp k
	
	    
	CLOSE_FILE:
    	mov bx, handle           ; file handle to close
        mov ah, 3Eh              ; AH = 3Eh ? close file
        int 21h
        
        jc err           ; CF=1 ? close failed (rare)
        
    
    filename db "test.txt", 0  ; delcare filename and end with 0
	
	handle dw ?                ; declare handle
	
	err:
	    ; .... 
	k:
	    ret
	      