#!/bin/bash

# Organise ROMS for running on the MIST SNES core.
# * Adds [Hi] to filename for HiROM games. 
# * Removes headers and renames to SFC format.
# * Renames ROM files to NSRT standard.
# * Generates SAV files with correct size for support games.
# * Moves unsupported ROMS to subdirectory.
# * Organises files into subdirectories based on first letter.
# Requires NSRT Linux https://www.romhacking.net/utilities/401/
# Version 20190930

# User Settings
OPT_SAVES=yes    #Create SAV files? [yes/no]
OPT_SUB=no     #Organise in subdirectories based on first letter

#############################################
# Nothing to change below here!

mkdir _unsupported 2>/dev/null

# First remove headers and rename roms
echo "============================"
echo "Rename and remove headers..."
echo "============================"
./nsrt -remhead -lowext -rename *.sfc *.smc *.bin *.fig >/dev/null
[[ $? -ne 0 ]] && exit 1

./nsrt -infocsv *.sfc 2>/dev/null | tail -n +2 >list.csv
[[ $? -ne 0 ]] && exit 1

echo "============================"
echo "Arrange and add SAV files..."
echo "============================"
while read LINE
do
    FILE=$(echo "$LINE" | awk -F "\"," '{print substr($1,2)}')
    SRAM=$(echo "$LINE" | awk -F "\"," '{print gensub(/ Kb/,"",1,substr($7,2)) }')
    LOHI=$(echo "$LINE" | awk -F "\"," '{print substr($5,2)}')
    CHIP=$(echo "$LINE" | awk -F "\"," '{print substr($8,2)}')

    NEWFILE=$FILE

    echo ${FILE}
    #echo ${FILE}___${SRAM}__${LOHI}___${CHIP}___

    if [[ $CHIP =~ "Super FX" ]] || [[ $CHIP =~ "SA-1" ]]; then
        mv "$FILE" _unsupported/
        continue
    fi

    if [[ $LOHI = "HiROM" ]] && [[ ! $FILE =~ "[Hi].sfc" ]]; then
       NEWFILE=${FILE/%.sfc}[Hi].sfc
       mv "$FILE" "$NEWFILE"
    fi

    #Generate SAV files
    if [[ $OPT_SAVES = "yes" ]] && [[ $SRAM -ne 0 ]]; then
        echo "Generate SAV file"
        dd if=/dev/zero of="${FILE/%.sfc}.sav" bs=1 count=${SRAM}k 2>/dev/null
        [[ $? -ne 0 ]] && exit 1
    fi

    #Move to sub directories
    if [[ $OPT_SUB = "yes" ]] ; then
        mkdir ${NEWFILE::1} >/dev/null 2>&1
        mv "${NEWFILE}" ${NEWFILE::1}/
    fi 
    
done <list.csv

rm list.csv
