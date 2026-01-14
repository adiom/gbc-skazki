RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix

ROM = demo.gb

all: $(ROM)

$(ROM): main.o
	$(RGBLINK) -o $@ $<
	$(RGBFIX) -v -p 0 $@

main.o: main.asm
	$(RGBASM) -o $@ $<

clean:
	rm -f main.o $(ROM)

.PHONY: all clean
