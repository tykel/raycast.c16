DEF_COLUMNS=40
DEF_COLW=$(shell bash -c "echo $$(( 320 / $(DEF_COLUMNS) ))")
DEF_COLSPRW=$(shell bash -c "echo $$(( $(DEF_COLW) / 2 ))")
DEF_COLSPRHW=$(shell bash -c "echo $$(( 0x7800 + $(DEF_COLSPRW)))")
DEF_DEBUG=0

CC:=$(shell which gcc)
AS16=$(shell which as16)
ASFLAGS=-m
CFLAGS:=-O2 -DDEF_COLUMNS=$(DEF_COLUMNS) -DDEF_DEBUG=$(DEF_DEBUG)
LDFLAGS:=-lm

raycast.c16: raycast.s lut.s data.s defs.s font.bin
	$(AS16) $< -o $@ $(ASFLAGS)

lut.s: lut
	./$< >$@

data.s: data
	./$< >$@

defs.s:
	echo "DEF_COLUMNS equ $(DEF_COLUMNS)" > $@
	echo "DEF_COLW equ $(DEF_COLW)" >> $@
	echo "DEF_COLSPRW equ $(DEF_COLSPRW)" >> $@
	echo "DEF_COLSPRHW equ $(DEF_COLSPRHW)" >> $@
	echo "DEF_DEBUG equ $(DEF_DEBUG)" >> $@

lut: lut.c
	$(CC) -o $@ $(CFLAGS) $^ $(LDFLAGS)

data: data.c
	$(CC) -o $@ $(CFLAGS) $^ $(LDFLAGS)
