.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

	jmp main

.include "x16.inc"
.include "vera.inc"

tilefile: .literal "TILES.BIN"
end_tilefile:

palettefile: .literal "PAL.BIN"
end_palettefile:

l0_mapfile: .literal "L0MAP.BIN"
end_l0_mapfile:

default_irq			= $8000
zp_vsync_trig		= $30

vram_tiledata		= $00000
vram_mapdata		= $10000
vram_palette		= $1fa00

main:

	; set video mode
	lda #%00000001		; Nothing enabled
	sta veradcvideo

	; set video scale to 2x
	lda #64
	sta veradchscale
	sta veradcvscale

	; set the l0 tile mode	
	lda #%00000011 	; height (2-bits) - 0 (32 tiles)
					; width (2-bits) - 0 (32 tiles
					; T256C - 0
					; bitmap mode - 0
					; color depth (2-bits) - 3 (8bpp)
	sta veral0config

	lda #(<(vram_tiledata >> 9) | (1 << 1) | 1)
								;  height    |  width
	sta veral0tilebase

	; set the tile map base address
	lda #<(vram_mapdata >> 9)
	sta veral0mapbase

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_tilefile-tilefile)
	ldx #<tilefile
	ldy #>tilefile
	jsr SETNAM
	lda #(^vram_tiledata + 2)
	ldx #<vram_tiledata
	ldy #>vram_tiledata
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_l0_mapfile-l0_mapfile)
	ldx #<l0_mapfile
	ldy #>l0_mapfile
	jsr SETNAM
	lda #(^vram_mapdata + 2)
	ldx #<vram_mapdata
	ldy #>vram_mapdata
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_palettefile-palettefile)
	ldx #<palettefile
	ldy #>palettefile
	jsr SETNAM
	lda #(^vram_palette + 2)
	ldx #<vram_palette
	ldy #>vram_palette
	jsr LOAD

	; set video mode
	lda #%00010001		; l0 enabled
	sta veradcvideo

	jsr init_irq

;==================================================
; mainloop
;==================================================
mainloop:
	wai
	jsr check_vsync
	jmp mainloop  ; loop forever

	rts

;==================================================
; init_irq
; Initializes interrupt vector
;==================================================
init_irq:
	lda IRQVec
	sta default_irq
	lda IRQVec+1
	sta default_irq+1
	lda #<handle_irq
	sta IRQVec
	lda #>handle_irq
	sta IRQVec+1
	rts

;==================================================
; handle_irq
; Handles VERA IRQ
;==================================================
handle_irq:
	; check for VSYNC
	lda veraisr
	and #$01
	beq @end
	sta zp_vsync_trig
	; clear vera irq flag
	sta veraisr

@end:
	jmp (default_irq)

;==================================================
; check_vsync
;==================================================
check_vsync:
	lda zp_vsync_trig
	beq @end

	; VSYNC has occurred, handle

	jsr tick

@end:
	stz zp_vsync_trig
	rts

;==================================================
; tick
;==================================================
tick:
	inc veral0hscrolllo
	inc veral0vscrolllo
	rts



