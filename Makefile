all:
	make -C bootpg $@
	make -C firmware $@
	make -C utilities $@

clean:
	make -C bootpg $@
	make -C firmware $@
	make -C utilities $@

