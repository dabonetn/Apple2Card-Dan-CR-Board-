This is my take on a surface mount version of the DAN II Card.

This version removes all the debug headers, and adds jumpers to the resistors for the Wiznet Header. (R27 & R28 on the original board)

ICSP port always provides power, and I don't recommend adding a header to this connector, but just use a male pinheader to program the unit.

This schematic allows cutting a jumper for 27256 or 27512 eprom chips programmed at the beginning of the chip, or leave it as is and program these chips at offset $4000.

 
