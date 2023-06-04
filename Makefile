NAME = TOOLSDEMO
ASSEMBLER6502 = cl65
ASFLAGS = -t cx16 -l $(NAME).list

PROG = $(NAME).PRG
LIST = $(NAME).list
MAIN = main.asm
SOURCES = $(MAIN) \
		  x16.inc \
		  vera.inc

RESOURCES = TILES.BIN \
			PAL.BIN \
			L0MAP.BIN

all: $(PROG)

resources: $(RESOURCES)

$(PROG): $(SOURCES)
	$(ASSEMBLER6502) $(ASFLAGS) -o $(PROG) $(MAIN)

TILES.BIN: mytiles.xcf
	gimp -i -d -f -b '(export-vera "mytiles.xcf" "TILES.BIN" 0 8 16 16 0 1 1)' -b '(gimp-quit 0)'

PAL.BIN: TILES.BIN
	cp TILES.BIN.PAL PAL.BIN

L0MAP.BIN: mymap.tmx
	tmx2vera mymap.tmx -l terrain L0MAP.BIN

run: all resources
	x16emu -prg $(PROG) -run -scale 2 -debug

clean:
	rm -f $(PROG) $(LIST)
	
clean_resources:
	rm -f $(RESOURCES)

cleanall: clean clean_resources
