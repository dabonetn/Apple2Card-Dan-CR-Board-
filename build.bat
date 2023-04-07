echo "Building firmware..."
call firmware\assemble.bat
echo "Building boot programs..."
call bootpg\assemble.bat
echo "Building utilties..."
call utilties\assemble.bat
echo "Building volumes..."
call utilties\makevols.bat
