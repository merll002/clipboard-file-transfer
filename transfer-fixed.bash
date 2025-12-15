#!/bin/bash
set -eo pipefail
clear
print_usage() {
    echo "usage: $0 [command] [-c <compression>] [-t <method>] [file]"
    echo
    echo "Args:"
    echo "  -t  select compression type, e.g., \`-t gz\`"
    echo "  -c  set clipboard copy method. Default: \`wl-copy -p\`"
    echo
    echo "Commands:"
    echo "  get-compression-method, gcm  Determine the optimal compression method supported on the target system"
    echo "  bench                        Start a transfer speed benchmark (cool)"
    echo
    echo "Examples:"
    echo "  $0 get-compression-method"
    echo "  $0 -t gzip file.txt  Transfer file with the gzip compression method"
    exit 1
}
clip_copy='wl-copy -p'
while getopts 'c:t:h' opt; do
    case "$opt" in
        c)
            echo "Picking ${OPTARG} for the clipboard copy command."
            clip_copy="${OPTARG}"
            ;;

        t)
            echo "Choosing ${OPTARG} as the compression method."
            comp_method="${OPTARG}"
            transfer_chosen=true
            ;;
    
        *)
            print_usage
            ;;
    esac
done
shift "$(($OPTIND -1))"

get_compression_method() {
    encoded_script=$(cat <<'EOF' | base64 -w 0
    clear
    if test $(which xz 2>/dev/null); then best=xz
        elif test $(which bzip2 2>/dev/null); then best=bzip2
        elif test $(which zstd 2>/dev/null); then best=zstd
        elif test $(which gzip 2>/dev/null); then best=gzip
        elif test $(which lz4 2>/dev/null); then best=lz4
        elif test $(which tar 2>/dev/null); then best=tar
        else best=none
    fi
    echo "The best compression available is $best. Use this with the -t argument"
EOF
    )
        echo "bash <(echo $encoded_script | base64 -d)" | ${clip_copy}
}

start_bench() {
    encoded_script=$(cat <<'EOF' | base64 -w 0
clear
echo "Get ready to spam paste!"
stty -icanon -echo
total=0
unset runs
while true; do
    first_ns=0
    last_ns=0
    read -rsn1 -d X
    first_ns=$(date +%s%N)
    read -rsn 50000 -d X
    last_ns=$(date +%s%N)
    elapsed_ns=$((last_ns - first_ns))
    n=50000
    b_per_sec=$(awk -v n="$n" -v ns="$elapsed_ns" 'BEGIN { printf("%.12f", (n / (ns/1e9) )) }')
    chars_per_sec=$(printf "%.0f" $b_per_sec)
    kb_per_s=$(awk -v n="$n" -v c_p_s="$b_per_sec" 'BEGIN { printf("%.3f", c_p_s/1024) }')
    if [ ! -v runs ]; then
        runs=("$kb_per_s")
    else
        runs+=($kb_per_s)
    fi
    total=0
    for i in ${runs[@]}; do
        total=$(awk "BEGIN {print $i+$total; exit}")
    done
    average_kb_per_sec=$(awk -v num_runs="${#runs[@]}" -v total="$total" 'BEGIN { printf("%.3f", total/num_runs) }')
    printf "\r\033[2K$chars_per_sec ASCII characters per second, ~$kb_per_s KB/s (average over time: $average_kb_per_sec KB/s)  "
    
done
stty sane
EOF
    )
        echo "bash <(echo $encoded_script | base64 -d)" | ${clip_copy}
        echo "Paste your clipboard and press enter in the remote terminal to start benchmark."
        read -rp "Press enter once pasted..."
        echo "Paste on repeat to see results (may lag). Press Ctrl + C to stop."
        python -c "print('.'*50001)" | ${clip_copy}
}

start_receiver() {

    letters_per_percentage=$(awk "BEGIN { printf(\"%.0f\", $data_len / 100) }")
    accurate_letters_per_percentage=$(awk "BEGIN { print $data_len / 100 }")
    if [ "$letters_per_percentage" == "0" ]; then
        letters_per_percentage=1
    fi

    if [ "$data_len" -gt 100 ]; then
        iterations=100
    else
        iterations=$data_len
    fi
    filename=$(basename "$target_file")
    part1=$(cat <<EOF
    accurate_letters_per_percentage=$accurate_letters_per_percentage
    letters_per_percentage=$letters_per_percentage
    iterations=$iterations
    data_len=$data_len
    uncomp_command=("${uncomp_command[@]}")
    filename=$filename

EOF
    )
    part2=$(cat <<'EOF'

    stty -icanon -echo
    unset data
    percentage=0
    clear
    read -sn $letters_per_percentage -p "Ready to recieve (paste): " part
    data+=$part
    for i in $(seq 1 $iterations); do
        printf "\r\033[2KReceiving... "
        read -sn $letters_per_percentage -p "$percentage% (if stuck at 99%, press enter)" part
        if [ ${part: -1} == '#' ]; then
            data+=${part: 0:-1}
            break
        fi
        data+=$part
        percentage=$(awk "BEGIN { printf(\"%.2f\", $i * (100/$data_len) * $accurate_letters_per_percentage) }")
    done
    echo -e "\r\033[2K$percentage%"
    echo "Recieved! Uncompressing..."
    base64 -d <<<$data | ${uncomp_command[@]} | tar -xf - || echo "^^^^ Ignore this error if using gzip (its probably fine) ^^^^"
    stty sane
EOF
    )
    encoded_script=$(base64 -w 0 <<<"$part1$part2")
        echo "bash <(echo $encoded_script | base64 -d)" | ${clip_copy}
}

set_comp_uncomp_vars() {
    if [ "$comp_method" == "tar" ]; then
        comp_command=(tar -cf -)
    fi
    if [ "$comp_method" == "xz" ]; then
        comp_command=(tar -cf - --use-compress-program="xz -T$(nproc) -zce9q")
    elif [ "$comp_method" == "bzip2" ]; then
        comp_command=(tar -cf - --use-compress-program="bzip2 -zkc9")
    elif [ "$comp_method" == "zstd" ]; then
        comp_command=(tar -cf - --use-compress-program="zstd -22 --ultra -T0 -q")
    elif [ "$comp_method" == "gzip" ]; then
        comp_command=(tar -cf - --use-compress-program="gzip -9")
    elif [ "$comp_method" == "lz4" ]; then
        comp_command=(lz4 -12rcz)
    elif [ "$comp_method" == "none" ]; then
        comp_command=(cat)
    else
        echo 'Invalid compression method'
        exit 1
    fi
    if [ "$comp_method" == "tar" ]; then
        uncomp_command=(tar -x -f -)
    fi
    if [ "$comp_method" == "xz" ]; then
        uncomp_command=(xzcat)
    elif [ "$comp_method" == "bzip2" ]; then
        uncomp_command=(bzcat)
    elif [ "$comp_method" == "zstd" ]; then
        uncomp_command=(zstcat)
    elif [ "$comp_method" == "gzip" ]; then
        uncomp_command=(tar -x --use-compress-program=gzip -f -)
    elif [ "$comp_method" == "lz4" ]; then
        uncomp_command=(lz4cat)
    elif [ "$comp_method" == "none" ]; then
        if [ -d "$filename" ]; then
            echo "Folders are not supported when using uncompressed cat mode :("
            exit 
        fi
        uncomp_command=(cat)
    fi
}
if [ ! -z "$transfer_chosen" ]; then
    set_comp_uncomp_vars
    target_file="$1"
    echo "Compressing file/folder, may take a while... (but not longer than the transfer xD)"
    encoded_data=$("${comp_command[@]}" "$1" | base64 -w 0)
    echo "Finished compressing."
    data_len=${#encoded_data}

    start_receiver
    echo "Paste your clipboard and press enter in the remote terminal to start the receiver."
    echo
    read -rsn1 -p "Press enter when ready to copy payload..."
    ${clip_copy} <<<"$encoded_data"#
    echo
    echo "All done here, goodbye!"
elif [ "$1" == "gcm" ] || [ "$1" == "get-compression-method" ]; then
    get_compression_method
    echo "Paste your clipboard and press enter in the remote terminal to see the results."

elif [ "$1" == "bench" ]; then
    start_bench
else
    print_usage
fi