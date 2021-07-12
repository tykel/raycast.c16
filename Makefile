CC:=$(shell which gcc)
AS16=$(shell which as16)
ASFLAGS=-m
CFLAGS:=-O2
LDFLAGS:=-lm

raycast.c16: raycast.s lut.s data.s
	$(AS16) $< -o $@ $(ASFLAGS)

lut.s: lut
	./$< >$@

data.s: data
	./$< >$@

lut: lut.c
	$(CC) -o $@ $(CFLAGS) $^ $(LDFLAGS)

data: data.c
	$(CC) -o $@ $(CFLAGS) $^
