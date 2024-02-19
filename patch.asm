; Build params: ------------------------------------------------------------------------------

CHEATS	set 1

; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:			equ $0003F7FA
	MD_PLUS_CMD_PORT:				equ $0003F7FE
	MD_PLUS_RESPONSE_PORT:			equ $0003F7FC

	OFFSET_RESET_VECTOR:			equ $4
	OFFSET_LEVEL_SELECT_HANDLER:	equ $0000B678
	OFFSET_MUSIC_TIMER_1:			equ $0000FE64
	OFFSET_MUSIC_TIMER_2:			equ $00010254
	OFFSET_DAMAGE_HANDLER:			equ	$00021E1A
	OFFSET_DAMAGE_HANDLER2:			equ	$00021EA0
	OFFSET_SOUND_DRIVER_HANDLER:    equ $000697A0
	OFFSET_COMMAND_HANLDER:			equ $00069D22

	RAM_OFFSET_CDDA_PLAYING:		equ	$FFFFFF00
	RAM_OFFSET_CDDA_COUNTER:		equ $FFFFFF02

	RESET_VECTOR_ORIGINAL:			equ $00000320

	TRACK_INDEX_HORSE_GALOPPING:	equ	$0D
	TRACK_FADE_OUT:					equ $7B
	TRACK_STOP:						equ	$7E

	POINTER_BASE_OFFSET:			equ $81

; Overrides: ---------------------------------------------------------------------------------

	org OFFSET_MUSIC_TIMER_1 ; Comparator before intro
	move.b	(RAM_OFFSET_CDDA_COUNTER+1).l,D0
	cmpi.b	#$C0,D0

	org OFFSET_MUSIC_TIMER_2 ;Comparator after intro
	move.b	(RAM_OFFSET_CDDA_COUNTER+1).l,D0
	cmpi.b	#$60,D0

	org OFFSET_SOUND_DRIVER_HANDLER
	jsr CDDA_COUNTER

	org OFFSET_RESET_VECTOR
	dc.l DETOUR_RESET_VECTOR

	org	OFFSET_COMMAND_HANLDER
	jsr	COMMAND_HANDLER_DETOUR

	if	CHEATS
		org OFFSET_DAMAGE_HANDLER									; Disables most damage
		rts

		org OFFSET_DAMAGE_HANDLER2
		jmp $21EBA

		org OFFSET_LEVEL_SELECT_HANDLER
		rept 4
			nop														; Allows selecting a level by pressing A when paused
		endr
	endif

; Detours: -----------------------------------------------------------------------------------

	org $000FF2B0
CDDA_COUNTER:
	cmpi.b	#$01,(RAM_OFFSET_CDDA_PLAYING)
	bne		.no_further_counting
	addi.w	#$01,(RAM_OFFSET_CDDA_COUNTER)
.no_further_counting
	lea		$fff800,A6
	rts



COMMAND_HANDLER_DETOUR:
	movem.l	D0,-(A7)
	cmpi.b	#TRACK_STOP,D0										; Check for stop command
	beq		CDDA_STOP_LOGIC
	cmpi.b	#TRACK_FADE_OUT,D0									; Check for fade out command
	beq		CDDA_FADE_OUT_LOGIC
	cmpi.b	#$1A,D0												; Check for SFX play command
	bgt		RETURN_FROM_DETOUR_LOGIC
	cmpi.b	#TRACK_INDEX_HORSE_GALOPPING,D0						; Check for horse galopping SFX play command
	beq		RETURN_FROM_DETOUR_LOGIC
	bgt		.over_horse_galopping_track
	addi.b	#$01,D0												; All tracks below TRACK_INDEX_HORSE_GALOPPING ($0D) need to be incremented by 1
.over_horse_galopping_track										; This ensures that track indexing starts at 1 and fills the hole left by the SFX.
	move.b	LOOP_LIST-.over_horse_galopping_track-3(PC,D0),D2
	lsl.w	#$8,D2
	or.b	D0,D2
	jsr		WRITE_MD_PLUS_FUNCTION
	move.b	#$01,(RAM_OFFSET_CDDA_PLAYING)
	clr.w	(RAM_OFFSET_CDDA_COUNTER)
	move.l	#TRACK_STOP,(A7)									; Override track id we left on the stack with the stop command
	move.b	#POINTER_BASE_OFFSET+TRACK_STOP,D1					; D1 at this point contains the pointer for the current track id. For the pointer value the track ids always have a base offset of $81.
	jmp		RETURN_FROM_DETOUR_LOGIC							; For TRACK_STOP ($7E) this would result in a value of $FF. This is necessary to mute the original music.
	
CDDA_STOP_LOGIC
	move.b	#$00,(RAM_OFFSET_CDDA_PLAYING)
	move.w	#$1300,D2
	jsr		WRITE_MD_PLUS_FUNCTION
	jmp		RETURN_FROM_DETOUR_LOGIC

CDDA_FADE_OUT_LOGIC
	move.b	#$00,(RAM_OFFSET_CDDA_PLAYING)
	move.w	#$1396,D2											; Fadeout with 150 sectors (2 seconds)
	jsr		WRITE_MD_PLUS_FUNCTION
	jmp		RETURN_FROM_DETOUR_LOGIC

RETURN_FROM_DETOUR_LOGIC
	movem.l	(A7)+,D0
	move.b	(A0,D0.w),D2
	cmp.b	D3,D2
	rts

LOOP_LIST
	dc.b $12 ; $01 - He Runs          - LOOP
	dc.b $12 ; $02 - Ninja Soul       - LOOP
	dc.b $12 ; $03 - Shadows          - LOOP
	dc.b $12 ; $04 - Idaten           - LOOP
	dc.b $12 ; $05 - Hassou!          - LOOP
	dc.b $11 ; $06 - Sakura           - NO LOOP
	dc.b $12 ; $07 - Inner Darkside   - LOOP
	dc.b $12 ; $08 - Shinobi Walk     - LOOP
	dc.b $12 ; $09 - Rush and Beat    - LOOP
	dc.b $11 ; $0A - Storm Wind       - NO LOOP
	dc.b $12 ; $0B - Getufu           - LOOP
	dc.b $11 ; $0C - Wabi             - NO LOOP
	dc.b $11 ; $0D - Sabi             - NO LOOP
	dc.b $11 ; $0E - Shinobi          - NO LOOP
	dc.b $12 ; $0F - Trap Boogie      - LOOP
	dc.b $11 ; $10 - Round Clear      - NO LOOP
	dc.b $11 ; $11 - Game Over        - NO LOOP
	dc.b $12 ; $12 - Japonesque       - LOOP
	dc.b $12 ; $13 - Solitary         - LOOP
	dc.b $12 ; $14 - Izayoi           - LOOP
	dc.b $12 ; $15 - Whirlwind        - LOOP
	dc.b $12 ; $16 - My Dear D        - LOOP
	dc.b $11 ; $17 - Stage Clear      - NO LOOP
	dc.b $12 ; $18 - Mandara          - LOOP
	dc.b $12 ; $19 - Ground Zero      - LOOP
	dc.b $12 ; $1A - Shadow Master    - LOOP
	even

DETOUR_RESET_VECTOR
	move.w	#$1300,D0								; Move MD+ stop command into d1
	jsr		WRITE_MD_PLUS_FUNCTION
	incbin	"intro.bin"								; Show MD+ intro screen
	jmp		RESET_VECTOR_ORIGINAL					; Return to game's original entry point

; Helper Functions: --------------------------------------------------------------------------

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)			; Open interface
	move.w  D2,(MD_PLUS_CMD_PORT)					; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)			; Close interface
	rts