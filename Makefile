all:
	make -C bootpg
	make -C firmware

clean:
	make -C bootpg $@
	make -C firmware $@

