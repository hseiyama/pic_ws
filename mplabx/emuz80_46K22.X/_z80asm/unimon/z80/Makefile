#
# Makefile
#   Universal Monitor for Z80
#

.SUFFIXES: .asm .p .hex .sr .bin

devs :=	dev/dev_8251.asm dev/dev_z80sio.asm dev/dev_z280.asm \
		dev/dev_64180.asm dev/dev_emily.asm dev/dev_nsc858.asm \
		dev/dev_emuz80.asm

all:	unimon_z80.bin

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.bin:
	p2bin $*.p $*.bin

.p.sr:
	p2hex -F Moto $*.p $*.sr

.asm.p:	config.inc $(devs)
	asl -L $*.asm

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst *.bin
