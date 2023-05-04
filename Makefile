all:
	make -C bootpg $@
	make -C eprom $@
	make -C utilities $@

clean:
	make -C bootpg $@
	make -C eprom $@
	make -C utilities $@

