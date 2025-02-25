This is my take on a surface mount version of the DAN II Card.

This version removes all the debug headers, and adds jumpers to the resistors for the Wiznet Header. (R27 & R28 on the original board)

I removed the ability to reprogram a eeprom on this version, and I tied all nonused address lines to gnd with a 10k resistor.
(A9 thru A15), This should allow using 2764, 27128, 27256, 27512 Eproms, and W27C512 EEPROMS.

ICSP port always provides power, and I don't recommend adding a header to this connector, but just use a male pinheader to program the unit.

 
This Version is not working at the moment.. I tied lines high instead of low and forgot to connect A8 from the Eprom.
