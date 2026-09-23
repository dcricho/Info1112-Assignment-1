#!/bin/bash
#
# assembler.sh - VSC Assembler
# Usage: bash assembler.sh <file.vsc>

# 1. No argument provided 
if [ "$#" -eq 0 ]; then
    echo "usage: no argument is provided"
    exit 1
fi

# 2. More than one argument provided 
if [ "$#" -gt 1 ]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi

input="$1"

# 3. Input is not a file or does not exist
if [ ! -f "$input" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

# 4. Invalid file extension
if [[ "$input" != *.vsc ]]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi


exit 0
