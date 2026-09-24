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

# 5. Empty file
if [ ! -s "$input" ]; then
    echo "usage: the file is empty – no .bin file is produced"
    exit 1
fi

# 6/7. Assemble the program
#
# File format:
#   line 1        -> N, how many raw data values follow
#   next N lines  -> decimal values, each becomes one output byte
#   remaining lines -> instructions "MNEMONIC,mode,operand"
#                      mode is currently unused (always 0 in test files)
#                      operand (decimal) becomes the instruction's second byte

# Opcode table: mnemonic -> hex opcode byte
declare -A OPCODES=(
    [LOAD]="04"
    [STORE]="08"
    [ADD]="0c"
    [SUB]="10"
    [PRINT]="24"
    [QUIT]="20"
)
# NOTE: SUB="10" is an UNVERIFIED GUESS, not confirmed by any provided
# example file. Reasoning: LOAD=04, STORE=08, ADD=0c are consecutive
# multiples of 4 (slots 1, 2, 3), and QUIT=20/PRINT=24 sit at slots 8
# and 9 - leaving slots 4-7 (0x10, 0x14, 0x18, 0x1c) unused. SUB, as
# the natural next arithmetic instruction after ADD, is guessed to
# take the next slot: 0x10. Confirm this against a real sub.vsc file
# or the course spec before relying on it.

# Read all non-blank lines, stripping any Windows-style \r characters
mapfile -t lines < <(tr -d '\r' < "$input" | grep -v '^[[:space:]]*$')

num_data="${lines[0]}"
idx=1

bytes=()

# Data segment
for ((i = 0; i < num_data; i++)); do
    value="${lines[idx]}"
    bytes+=("$(printf '%02x' "$value")")
    ((idx++))
done

# Instructions
mnemonics=()
while [ "$idx" -lt "${#lines[@]}" ]; do
    IFS=',' read -r mnemonic mode operand <<< "${lines[idx]}"
    mnemonic=$(echo "$mnemonic" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
    operand=$(echo "$operand" | tr -d '[:space:]')

    opcode="${OPCODES[$mnemonic]}"
    if [ -z "$opcode" ]; then
        echo "usage: unknown instruction $mnemonic"
        exit 1
    fi

    bytes+=("$opcode")
    bytes+=("$(printf '%02x' "$operand")")
    mnemonics+=("$mnemonic")
    ((idx++))
done

# Work out which kind of program this is
is_quit_only=true
has_addsub=false
for m in "${mnemonics[@]}"; do
    [ "$m" != "QUIT" ] && is_quit_only=false
    { [ "$m" == "ADD" ] || [ "$m" == "SUB" ]; } && has_addsub=true
done

if $is_quit_only; then
    echo "It is a QUIT program"
elif $has_addsub; then
    echo "It is an ADD/SUB program"
fi

# Write the .bin file (raw bytes, not text)
output="${input%.vsc}.bin"
hex_escapes=""
for b in "${bytes[@]}"; do
    hex_escapes+="\\x$b"
done
printf '%b' "$hex_escapes" > "$output"

# Display the bytes on STDOUT
echo "The content of the .bin file is"
for b in "${bytes[@]}"; do
    echo "$b"
done

exit 0
