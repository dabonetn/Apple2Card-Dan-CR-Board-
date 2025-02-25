echo "Building eprom..."
call eprom\assemble.bat
echo "Building boot programs..."
call bootpg\assemble.bat
echo "Building utilties..."
call utilties\assemble.bat
echo "Building volumes..."
call volumes\makevols.bat
