#!/bin/bash

usage() {
    echo "Usage: $0 -i <input domain or file> -w <wordlist> [-a <additional ffuf args>] [-r <rate>]"
    echo "  -i: Single domain or file containing list of domains/IP:PORTs"
    echo "  -w: Wordlist"
    echo "  -a: Additional arguments for ffuf (optional)"
    echo "  -r: Rate limit for ffuf requests (default: 10)"
    exit 1
}

if ! command -v ffuf &> /dev/null; then
    echo "ffuf could not be found. Please install it first."
    echo "sudo apt get install ffuf -y"
    exit 1
fi

run_ffuf() {
    local target=$1
    local wordlist=$2
    local additional_args=$3
    local throttle=$4
    local output_file="${target//[^a-zA-Z0-9]/_}.html"
    local prev_line_count=-1
    local same_line_count=0
    local max_same_line=15

    [[ "$target" =~ ^https?:// ]] || target="http://${target}"

    echo "Running ffuf on target: $target"
    ffuf -w "$wordlist" -u "$target/FUZZ" -rate $throttle $additional_args -of html -o "$output_file" | while read -r line; do
        if echo "$line" | grep -q 'Lines'; then
            current_line_count=$(echo "$line" | grep -oP 'Lines: \K\d+')

            if [[ "$current_line_count" == "$prev_line_count" ]]; then
                ((same_line_count++))
                if [[ "$same_line_count" -ge "$max_same_line" ]]; then
                    echo "Detected $max_same_line requests with the same line count. Moving to next target."
                    break
                fi
            else
                same_line_count=1
            fi

            prev_line_count=$current_line_count
        fi
    done
}

while getopts ":i:w:a:r:" opt; do
    case $opt in
        i) input=$OPTARG ;;
        w) wordlist=$OPTARG ;;
        a) additional_args=$OPTARG ;;
        r) throttle=$OPTARG ;;
        *) usage ;;
    esac
done

[[ -z "$input" || -z "$wordlist" ]] && usage

throttle=${throttle:-10}

if [[ -f "$input" ]]; then
    while IFS= read -r target; do
        run_ffuf "$target" "$wordlist" "$additional_args" "$throttle"
    done < "$input"
else
    run_ffuf "$input" "$wordlist" "$additional_args" "$throttle"
fi
