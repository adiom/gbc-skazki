; Minimal Game Boy demo (RGBDS)
; Builds a ROM that shows a background, a movable sprite, sound, and text.

SECTION "Header", ROM0[$100]
    nop
    jp Start

    ; Nintendo logo (required)
    db $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    db $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    db $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

    ; Title (15 bytes) + CGB flag (1 byte)
    db "GBC-SKAZKI DEMO"
    db $00        ; CGB flag
    db $00,$00    ; New licensee code
    db $00        ; SGB flag
    db $00        ; Cartridge type (ROM only)
    db $00        ; ROM size
    db $00        ; RAM size
    db $01        ; Destination code (non-JPN)
    db $00        ; Old licensee code
    db $00        ; Mask ROM version
    db $00        ; Header checksum (patched by rgbfix)
    dw $0000      ; Global checksum (patched by rgbfix)

; --- Hardware registers ---

DEF rLCDC EQU $FF40
DEF rSCY  EQU $FF42
DEF rSCX  EQU $FF43
DEF rLY   EQU $FF44
DEF rBGP  EQU $FF47
DEF rOBP0 EQU $FF48
DEF rP1   EQU $FF00
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26

SECTION "Main", ROM0[$150]
Start:
    di
    ld sp, $FFFE

    xor a
    ld [rSCX], a
    ld [rSCY], a

    ; Disable LCD to safely write VRAM
    ld a, [rLCDC]
    res 7, a
    ld [rLCDC], a

    ; Set DMG palettes (white -> black)
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a

    ; Enable sound
    ld a, $80
    ld [rNR52], a
    ld a, $77
    ld [rNR50], a
    ld a, $FF
    ld [rNR51], a

    ; Copy tiles to VRAM
    ld hl, TileData
    ld de, $8000
    ld bc, TileDataEnd - TileData
    call MemCopy

    ; Fill BG map with checkerboard tile
    ld hl, $9800
    ld bc, 32 * 32
    ld a, 1
    call MemSet

    ; Write "adiom" in the center
    ld hl, $9800 + (32 * 6) + 12
    ld a, 3
    ld [hl+], a
    inc a
    ld [hl+], a
    inc a
    ld [hl+], a
    inc a
    ld [hl+], a
    inc a
    ld [hl], a

    ; Clear OAM
    ld hl, $FE00
    ld bc, 160
    xor a
    call MemSet
    ld [Joypad], a
    ld [PrevJoypad], a

    ; Sprite start position
    ld a, 80
    ld [SpriteX], a
    ld a, 72
    ld [SpriteY], a

    ; Turn LCD back on (BG + OBJ enabled, tile data at $8000, map at $9800)
    ld a, %10010011
    ld [rLCDC], a

MainLoop:
    call WaitVBlank
    call ReadJoypad
    call UpdateSprite
    call HandleSound
    jr MainLoop

; --- Routines ---

WaitVBlank:
.wait_start:
    ld a, [rLY]
    cp 144
    jr c, .wait_start
.wait_end:
    ld a, [rLY]
    cp 144
    jr nc, .wait_end
    ret

ReadJoypad:
    ; Bits: 0 Right, 1 Left, 2 Up, 3 Down, 4 A, 5 B, 6 Select, 7 Start
    ld a, $10
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    and $0F
    ld b, a

    ld a, $20
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    and $0F
    swap a
    or b
    cpl
    ld [Joypad], a

    ld a, $30
    ld [rP1], a
    ret

UpdateSprite:
    ld a, [Joypad]
    ld b, a
    bit 0, b
    jr z, .no_right
    ld a, [SpriteX]
    inc a
    ld [SpriteX], a
.no_right:
    bit 1, b
    jr z, .no_left
    ld a, [SpriteX]
    dec a
    ld [SpriteX], a
.no_left:
    bit 2, b
    jr z, .no_up
    ld a, [SpriteY]
    dec a
    ld [SpriteY], a
.no_up:
    bit 3, b
    jr z, .no_down
    ld a, [SpriteY]
    inc a
    ld [SpriteY], a
.no_down:
    ; Write sprite 0 to OAM
    ld hl, $FE00
    ld a, [SpriteY]
    add a, 16
    ld [hl+], a
    ld a, [SpriteX]
    add a, 8
    ld [hl+], a
    ld a, 8
    ld [hl+], a
    xor a
    ld [hl], a
    ret

HandleSound:
    ld a, [Joypad]
    ld b, a
    ld a, [PrevJoypad]
    cpl
    and b
    ld c, a
    ld a, b
    ld [PrevJoypad], a
    bit 4, c
    call nz, PlayBeep
    ret

PlayBeep:
    ld a, $00
    ld [rNR10], a
    ld a, $80
    ld [rNR11], a
    ld a, $F3
    ld [rNR12], a
    ld a, $00
    ld [rNR13], a
    ld a, $C3
    ld [rNR14], a
    ret

MemCopy:
    ; HL = src, DE = dst, BC = len
    ld a, b
    or c
    ret z
.copy_loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copy_loop
    ret

MemSet:
    ; A = value, HL = dst, BC = len
    ld d, a
.set_loop:
    ld a, b
    or c
    ret z
    ld a, d
    ld [hl+], a
    dec bc
    jr .set_loop

; --- Data ---

SECTION "Tiles", ROM0
TileData:
    ; Tile 0: blank
    db $00,$00
    db $00,$00
    db $00,$00
    db $00,$00
    db $00,$00
    db $00,$00
    db $00,$00
    db $00,$00

    ; Tile 1: checkerboard (color 1)
    db $AA,$00
    db $55,$00
    db $AA,$00
    db $55,$00
    db $AA,$00
    db $55,$00
    db $AA,$00
    db $55,$00

    ; Tile 2: solid dark (color 3)
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF
    db $FF,$FF

    ; Tile 3: 'a'
    db $00,$00
    db $00,$00
    db $3C,$00
    db $06,$00
    db $3E,$00
    db $66,$00
    db $3E,$00
    db $00,$00

    ; Tile 4: 'd'
    db $00,$00
    db $06,$00
    db $06,$00
    db $3E,$00
    db $66,$00
    db $66,$00
    db $3E,$00
    db $00,$00

    ; Tile 5: 'i'
    db $00,$00
    db $18,$00
    db $00,$00
    db $18,$00
    db $18,$00
    db $18,$00
    db $3C,$00
    db $00,$00

    ; Tile 6: 'o'
    db $00,$00
    db $00,$00
    db $3C,$00
    db $66,$00
    db $66,$00
    db $66,$00
    db $3C,$00
    db $00,$00

    ; Tile 7: 'm'
    db $00,$00
    db $00,$00
    db $6C,$00
    db $7E,$00
    db $6A,$00
    db $62,$00
    db $62,$00
    db $00,$00

    ; Tile 8: sprite (color 3)
    db $3C,$3C
    db $42,$42
    db $A5,$A5
    db $81,$81
    db $A5,$A5
    db $99,$99
    db $42,$42
    db $3C,$3C
TileDataEnd:

SECTION "WRAM", WRAM0
Joypad:
    ds 1
PrevJoypad:
    ds 1
SpriteX:
    ds 1
SpriteY:
    ds 1
