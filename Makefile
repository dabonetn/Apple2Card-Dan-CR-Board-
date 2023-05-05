all:
	make -C Apple2Arduino $@
	make -C bootpg $@
	make -C eprom $@
	make -C utilities $@

clean:
	make -C Apple2Arduino $@
	make -C bootpg $@
	make -C eprom $@
	make -C utilities $@

