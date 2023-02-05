;
; SPI_Softverski_Flash.asm
;
; Created: 17.11.2022. 08:40:54
; Author : Aleksandar Bogdanovic
;



// SPI_Softverski_Flash_memorija

.include "m328pdef.inc"

.dseg

;-----------------------------------------------------------------------------
// Pin layout

.equ SS		= 2				// CS, PB2, D10, PortB
.equ MOSI	= 3				// DI, PB3, D11, PortB
.equ MISO	= 4				// DO, PB4, D12, PortB
.equ SCK	= 5				// CLK, PB5, D13, PortB

;*---------------------------------------------------------------------------*

;-----------------------------------------------------------------------------
// Definitions 

.def spi_low	= r16
.def spi_high	= r17
.def temp		= r18
;*---------------------------------------------------------------------------*

;-----------------------------------------------------------------------------
// Macros

.macro SS_active
	cbi PORTB, SS
.endm

.macro SS_inactive
	sbi PORTB, SS
.endm
;*********************
.macro SCK_high
	sbi PORTB, SCK
.endm

.macro SCK_low
	cbi PORTB, SCK
.endm
;*********************
.macro MOSI_high
	sbi PORTB, MOSI
.endm


.macro MOSI_low
	cbi PORTB, MOSI
.endm
;*********************
.macro addi
	subi @0, -@1
.endm

.macro set_delay
	subi @0, (@1 << 5)
.endm

.macro inc_delay
	subi @0, -(1 << 5)
.endm
;*---------------------------------------------------------------------------*

.cseg

.org 0x00
;-----------------------------------------------------------------------------
	rjmp init

init:
	rcall spi_init
	rjmp main
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
main:
	;rcall write_enable
	;-------------------------------
	;rcall enable_reset
	;-------------------------------
	;rcall reset_device
	;-------------------------------
	;rcall read_jedec_id
	;-------------------------------
	;rcall read_flash_id
	;-------------------------------
	;rcall write_enable
	;rcall write_disable
	;-------------------------------
	;rcall block_erase
	;-------------------------------
	;rcall sector_erase
	;-------------------------------
	;rcall page_program
	;-------------------------------
	;rcall chip_erase
	;-------------------------------
	;rcall w_status_register1
	;rcall w_status_register2
	;rcall w_status_register3
	;-------------------------------
	;rcall status_register1
	;rcall status_register2
	;rcall status_register3
	;-------------------------------
	rcall read_data
	;-------------------------------
	;rcall fast_read
	;-------------------------------
end:
	rjmp end
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
spi_init:
	SS_inactive
	sbi DDRB, SS
	
	SCK_low
	sbi DDRB, SCK

	MOSI_low
	sbi DDRB, MOSI

	cbi DDRB, MISO
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
enable_spi:
	SCK_low
	MOSI_low
	SS_active
	ret
;*********************
disable_spi:
	SS_inactive
	ret
;*---------------------------------------------------------------------------*
write_spi:
	;ldi temp, 16
	ldi temp, 8
;*********************
spi_loop:
	lsl spi_low
	;rol spi_high

	brcc low_mosi
	MOSI_high
	rjmp mosi_done
;*********************
low_mosi:
	MOSI_low
;*********************	
mosi_done:
	SCK_high
	
	set_delay temp, 5
;*********************
time_hi:
	inc_delay temp
	brcs time_hi

	SCK_low
	set_delay temp, 5
;*********************
time_lo:
	inc_delay temp
	brcs time_lo

	sbic PINB, MISO
	inc spi_low

	dec temp
	brne spi_loop
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
use_spi_receive:
	out PORTD, r22
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
write_enable:
	rcall enable_spi
	ldi r22, 0x06
	mov spi_low, r22
	rcall write_spi
	rcall disable_spi
	ret
;*********************
write_disable:
	rcall enable_spi
	ldi r22, 0x04
	mov spi_low, r22
	rcall write_spi
	rcall disable_spi
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
sector_erase:
	rcall	enable_spi		
	ldi	r22,0x20	
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	
	mov	spi_low,r22	
	rcall	 write_spi
	ldi	r22,0x00	
	mov	spi_low,r22	
	rcall	 write_spi
	ldi	r22,0x00	
	mov	spi_low,r22	
	rcall	 write_spi
	rcall	disable_spi	
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
chip_erase:
	rcall	enable_spi		
	ldi	r22,0xC7	
	mov	spi_low,r22	
	rcall	 write_spi
	rcall	disable_spi	
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
status_register1:
	rcall	enable_spi		
	ldi	r22,0x05	
	mov	spi_low,r22	
	rcall	 write_spi
	ldi	r22,0x00	
	mov	spi_low,r22	
	rcall	 write_spi
	rcall	disable_spi	
	ret
;*********************
status_register2:
	rcall	enable_spi		
	ldi	R22,0x35	;register data
	mov	spi_low,R22	
	rcall	write_spi	
	ldi	R22,0x00	;register data
	mov	spi_low,R22	
	rcall	write_spi	;send/receive 16 bits (or 8 bits)
	rcall	disable_spi	;deactivate /SS
	ret
;*********************
status_register3:
	rcall	enable_spi		;activate /SS
	ldi	R22,0x15	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi 
	ldi	R22,0x00	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi
	rcall	disable_spi	;deactivate /SS
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
w_status_register1:
	rcall	enable_spi		;activate /SS
	ldi	R22,0x01	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi	
	ldi	R22,0x00	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi
	;***
	ldi	R22,0x02	; Data to be send
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi
	;***	
	rcall	disable_spi	;deactivate /SS
	ret
;*********************
w_status_register2:
	rcall	enable_spi		;activate /SS
	ldi	R22,0x31	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi
	ldi	R22,0x00	;register data
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi		
	;***
	ldi	R22,0x00	; Data to be send
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi	
	;***
	rcall	disable_spi	
	ret
;*********************
w_status_register3:
	rcall	enable_spi		
	ldi	r22,0x11	;register data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;register data
	mov	spi_low,r22	;set up information to be sent
	rcall	write_spi	
	rcall	disable_spi	;deactivate /SS
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
page_program:
	rcall enable_spi
	ldi	r22,0x02	;register data
	mov	spi_low,r22	
	rcall write_spi
	;*****
	ldi	r22,0x20	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi 
	ldi	r22,0x00	;address data
	mov	spi_low,r22
	rcall	write_spi 	
	;*****
	ldi	R22,0x41	; Data to be send
	mov	spi_low,r22	;set up information to be sent
	rcall	write_spi
	ldi	R22,0x63	; Data to be send
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi	
	ldi	R22,0x61	; Data to be send
	mov	spi_low,R22	;set up information to be sent
	rcall	write_spi			
	;*******
	rcall disable_spi	
	ret	
;*********************
	;test data
	ldi	r22, 0x87	;address data
	mov	spi_low,r22	
	rcall write_spi  
	rcall disable_spi	
	ret
;*---------------------------------------------------------------------------*
;-----------------------------------------------------------------------------
read_data:
	rcall	enable_spi		
;*********************
	ldi	r22,0x03	;register data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x20	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi
;*********************
	;read data
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi  
	/*ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi 
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi 
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi*/	
;*********************
	rcall	disable_spi	
	ret

fast_read:
	ldi	r22,0x0B	;register data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x20	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi
	;******
	ldi	r22,0x00	;address data
	mov	spi_low,r22	
	rcall	write_spi
	rcall	disable_spi	
	ret
;*---------------------------------------------------------------------------*
read_flash_id:
	rcall	enable_spi		
;*********************
; write request code
	ldi	r22,0x4B	;register data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	 write_spi
	ldi	r22,0xFF	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0xFF	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0xFF	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0xFF	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
; get unique id
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
;*********************
	rcall	disable_spi	
	ret

read_jedec_id:
	rcall	enable_spi
	ldi	r22,0x9F	;register data
	mov	spi_low,r22	
	rcall	write_spi	
	// Get jedec id
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall write_spi	
	rcall disable_spi	
	ret

enable_reset:
	rcall enable_spi
	ldi	r22,0x66	;register data
	mov	spi_low,r22	
	rcall write_spi
	rcall disable_spi	
	ret	

reset_device:
	rcall enable_spi
	ldi	r22,0x99	;register data
	mov	spi_low,r22	
	rcall write_spi
	rcall disable_spi	
	ret
	
block_erase:
	rcall enable_spi
	ldi	r22,0xD8	;register data
	mov	spi_low,r22	
	rcall write_spi
	ldi	r22,0x20	
	mov	spi_low,r22	
	rcall write_spi
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi	
	ldi	r22,0x00	;misc data
	mov	spi_low,r22	
	rcall	write_spi
	rcall disable_spi	
	ret	
	
;----------------------------------END-------------------------------------
