#!/bin/bash

usage() {
    echo "Usage: $0 -i <input domain or file> -w <wordlist> [-a <additional ffuf args>] [-r <rate>]"
    echo "  -i: Domain or file containing list of domains/IPs"
    echo "  -w: Wordlist file for ffuf"
    echo "  -a: Additional arguments for ffuf (optional)"
    echo "  -r: Rate limit for ffuf requests (default: 10)"
    exit 1
}

if ! command -v ffuf &> /dev/null; then
    echo "ffuf could not be found. Please install it first."
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

combine_html_files() {
    local output_file="combined_output.html"
    local table_counter=1

    echo "<!DOCTYPE html><html><head><title>Combined Output</title></head><body>" > "$output_file"

    for file in *.html; do
        echo "<div style='margin-top:20px; margin-bottom:20px;'>" >> "$output_file"
        echo "<h2 style='color: blue;'>Content from: $file</h2>" >> "$output_file"
        
        sed "s/id=\"ffufreport\"/id=\"ffufreport_${table_counter}\"/" "$file" >> "$output_file"

        echo "</div>" >> "$output_file"
        ((table_counter++))
    done

    echo "</body></html>" >> "$output_file"
    echo ""
    echo "All HTML files have been combined into $output_file"
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

combine_html_files
