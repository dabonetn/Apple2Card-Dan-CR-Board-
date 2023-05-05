all:
	make -C bootpg $@
	make -C eprom $@
	make -C Apple2Arduino $@
	make -C utilities $@

clean:
	make -C bootpg $@
	make -C eprom $@
	make -C Apple2Arduino $@
	make -C utilities $@

