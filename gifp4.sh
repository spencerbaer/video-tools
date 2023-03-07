echoerr() { printf "%s\n" "$*" >&2; }

get_num_frames() {
    local num_frames
    num_frames=$(exiftool -b -FrameCount "$1")
    if [ -z "$num_frames" ]; then
        echoerr "Error: Could not get number of frames in $1"
        exit 1
    fi
    echo "$num_frames"
}

convert_to_mp4() {
    ffmpeg -i "$1" -vcodec libx264 -pix_fmt yuv420p -movflags faststart -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$2"
}

change_extension () {
  local filepath="$1"
  local new_extension="$2"
  local filename="${filepath%.*}"
  local new_filepath="${filename}.${new_extension}"
  echo "${new_filepath}"
}

# check for required filename and optional -y flag for overwrite
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo $@
    echoerr "Usage: gifp4.sh <gif file> [-y]"
    exit 1
fi

if [ $# -eq 2 ]; then
    if [ "$2" != "-y" ]; then
        echo $@
        echoerr "Usage: gifp4.sh <gif file> [-y]"
        exit 1
    fi
fi


gif_file="$1"
if [ ! -f "$gif_file" ]; then
    echoerr "Error: $gif_file does not exist"
    exit 2
fi

if [ "${gif_file##*.}" != "gif" ]; then
    echoerr "Error: $gif_file is not a gif"
    exit 3
fi

num_frames=$(get_num_frames "$gif_file")

# If get_num_frames fails, it will exit the script
if [ $? -ne 0 ]; then
    exit $? # exit with the same error code as get_num_frames
fi

if [ $num_frames -lt 2 ]; then
    echoerr "Error: $gif_file has less than 2 frames"
    exit 4
fi

mp4_file=$(change_extension "$gif_file" "mp4")

# If overwrite flag is set, remove existing mp4 file
if [ $# -eq 2 ]; then
    if [ "$2" == "-y" ]; then
        if [ -f "$mp4_file" ]; then
            rm "$mp4_file"
        fi
    fi
fi

if [ -f "$mp4_file" ]; then
    echoerr "Error: $mp4_file already exists"
    exit 5
fi

convert_to_mp4 "$gif_file" "$mp4_file"

if [ $? -ne 0 ]; then
    echoerr "Error: Could not convert $gif_file to $mp4_file"
    exit 6
fi

if [ ! -f "$mp4_file" ]; then
    echoerr "Error: $mp4_file was not created"
    exit 7
fi


touch -r "$gif_file" "$mp4_file"

if [ $? -ne 0 ]; then
    echoerr "Error: Could not set timestamp of $mp4_file to match $gif_file"
    rm "$mp4_file"
    exit 8
fi

rm "$gif_file"

# num_frames_mp4=$(get_num_frames "$mp4_file")
# if [ "$num_frames" -ne "$num_frames_mp4" ]; then
#     echoerr "Error: $gif_file has $num_frames frames but $mp4_file has $num_frames_mp4 frames"
#     exit 9
# fi

#rm "$gif_file"

