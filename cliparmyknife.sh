#!/bin/bash

#set -e

get_clip_params () {

    CLIP_PATH=$( dirname "$1" )
    CLIP_NAME=$( basename "$1" | sed -r "s|\.[^. ]*$||g" )
    CLIP_EXTENSION=$( echo "$1" | sed -r "s|^.*\.||g" )
    CLIP_WIDTH=$( ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$1" )
    CLIP_HEIGHT=$( ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$1" )
    CLIP_SAR=$( ffprobe -v error -select_streams v:0 -show_entries stream=sample_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "$1" )
    CLIP_FRAMERATE=$( ffprobe -i "$1" 2>&1 | grep -oP "\d{1,5}\.?\d{1,5} fps" | tail -1 | sed -r "s|\ fps||g" )

    MOD=1
    
    [[ "$CLIP_SAR" != "1:1" ]] && MOD=$( echo "$CLIP_SAR" | sed -r "s|\:|\ \/\ |g; s|^|scale\=5\;\ |g" | bc ) && CLIP_HEIGHT=$( printf "%.0f" $( echo "$CLIP_HEIGHT / $MOD" | bc ) )

}

dump_clip_params () {

    echo -e "\nCLIP NAME: $CLIP_NAME.$CLIP_EXTENSION\nCLIP LOCATION: $CLIP_PATH/\nCLIP DIMENSIONS: ${CLIP_WIDTH}x${CLIP_HEIGHT}\nCLIP FRAMERATE: $CLIP_FRAMERATE\nCLIP SAR: $CLIP_SAR"

}

crop () {

    echo -e "-----out_w is the width of the output rectangle-----\n-----out_h is the height of the output rectangle-----\n-----x and y specify the top left corner of the output rectangle-----"
    echo -e "-----CURRENT VIDEO DIMENSIONS OF $CLIP_NAME.$CLIP_EXTENSION: ${CLIP_WIDTH}x${CLIP_HEIGHT}"
    


    re='^[0-9]+(\ )+[0-9]+(\ )+[0-9]+(\ )+[0-9]+$'

    declare OUT_W OUT_H X Y CROP_PARAMS

    while read -p "Enter new clip dimensions [FORMAT: out_w out_h x y]: " CROP_PARAMS; do    

        CROP_PARAMS=${CROP_PARAMS:-"$CLIP_WIDTH $CLIP_HEIGHT 0 0"}

        if ! [[ $CROP_PARAMS =~ $re ]]; then
            echo "error: Invalid crop parameters" >&2; continue
        fi



        OUT_W=$( echo "$CROP_PARAMS" | tr -s ' '  | cut -d ' ' -f 1 )
        OUT_H=$( echo "$CROP_PARAMS" | tr -s ' ' | cut -d ' ' -f 2 )
        X=$( echo "$CROP_PARAMS" | tr -s ' ' | cut -d ' ' -f 3 )
        Y=$( echo "$CROP_PARAMS" | tr -s ' ' | cut -d ' ' -f 4 )

        if [[ $( echo "$OUT_W + $X" | bc ) -gt $CLIP_WIDTH || $( echo "$OUT_H + $Y" | bc ) -gt $CLIP_HEIGHT ]]; then
            echo "error: Crop parameters go outside clip bounds" >&2; continue
        fi

        break
    done

    OUT_H_MOD=$( echo "$OUT_H * $MOD" | bc )
    Y_MOD=$( echo "$Y * $MOD" | bc )

    ffmpeg -i "$1" -filter:v "crop=$OUT_W:$OUT_H_MOD:$X:$Y_MOD" "$CLIP_NAME [cropped $OUT_W:$OUT_H:$X:$Y].$CLIP_EXTENSION"

}

join () {
    [[ ! -f "join.$CLIP_EXTENSION" ]] && cp "$1" "join.$CLIP_EXTENSION" && return
    JOIN_WIDTH=$( ffprobe -i "join.$CLIP_EXTENSION" 2>&1 | grep -oP "[1-9]\d{1,10}x[1-9]\d{1,10}" | sed -r "s|\ ||g; s|x[0-9]*$||g" )
    JOIN_HEIGHT=$( ffprobe -i "join.$CLIP_EXTENSION" 2>&1 | grep -oP "[1-9]\d{1,10}x[1-9]\d{1,10}" | sed -r "s|\ ||g; s|^[0-9]*x||g" )

    #ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i boximouto.webm -c:v copy -c:a libopus -shortest boximouto2.webm
    #ffprobe -i ikadiabetes2.gif -show_streams -select_streams a -loglevel error

    [[ -z $(ffprobe -i "$1" -show_streams -select_streams a -loglevel error) ]] && ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i "$1" -c:v copy -c:a libopus -shortest "/tmp/clip_treated.$CLIP_EXTENSION" || cp "$1" "/tmp/clip_treated.$CLIP_EXTENSION"
    [[ -z $(ffprobe -i "join.$CLIP_EXTENSION" -show_streams -select_streams a -loglevel error) ]] && ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i "join.$CLIP_EXTENSION" -c:v copy -c:a libopus -shortest "/tmp/join_treated.$CLIP_EXTENSION" || cp "join.$CLIP_EXTENSION" "/tmp/join_treated.$CLIP_EXTENSION"


    echo "JOIN DIMENSIONS: $JOIN_WIDTH x $JOIN_HEIGHT"
    
    [[ $JOIN_WIDTH -gt $CLIP_WIDTH ]] && PAD_WIDTH=$JOIN_WIDTH || PAD_WIDTH=$CLIP_WIDTH
    [[ $JOIN_HEIGHT -gt $CLIP_HEIGHT ]] && PAD_HEIGHT=$JOIN_HEIGHT || PAD_HEIGHT=$CLIP_HEIGHT
    PAD_X=$( echo "($JOIN_WIDTH - $CLIP_WIDTH) / 2" | bc )
    PAD_Y=$( echo "($JOIN_HEIGHT - $CLIP_HEIGHT) / 2" | bc )

    echo "PAD DIMENSIONS: $PAD_X, $PAD_Y"
    
    if [[ $PAD_X -ge 0 && $PAD_Y -ge 0 ]]; then
        cp "/tmp/join_treated.$CLIP_EXTENSION" "/tmp/join_temp.$CLIP_EXTENSION"
        ffmpeg -y -i "/tmp/clip_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=$PAD_X:y=$PAD_Y:color=black" "/tmp/clip_temp.$CLIP_EXTENSION"
    elif [[ $PAD_X -lt 0 && $PAD_Y -ge 0 ]]; then
        ffmpeg -y -i "/tmp/join_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=${PAD_X#-}:y=0:color=black" "/tmp/join_temp.$CLIP_EXTENSION"
        ffmpeg -y -i "/tmp/clip_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=0:y=$PAD_Y:color=black" "/tmp/clip_temp.$CLIP_EXTENSION"
    elif [[ $PAD_X -ge 0 && $PAD_Y -lt 0 ]]; then
        ffmpeg -y -i "/tmp/join_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=0:y=${PAD_Y#-}:color=black" "/tmp/join_temp.$CLIP_EXTENSION"
        ffmpeg -y -i "/tmp/clip_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=$PAD_X:y=0:color=black" "/tmp/clip_temp.$CLIP_EXTENSION"
    elif [[ $PAD_X -lt 0 && $PAD_Y -lt 0 ]]; then
        ffmpeg -y -i "/tmp/join_treated.$CLIP_EXTENSION" -vf "pad=width=$PAD_WIDTH:height=$PAD_HEIGHT:x=${PAD_X#-}:y=${PAD_Y#-}:color=black" "/tmp/join_temp.$CLIP_EXTENSION"
        cp "/tmp/clip_treated.$CLIP_EXTENSION" "/tmp/clip_temp.$CLIP_EXTENSION"
    else
        echo "something fucked up" && exit 1
    fi    


    if [[ -n $(ffprobe -i "/tmp/clip_temp.$CLIP_EXTENSION" -show_streams -select_streams a -loglevel error) && -n $(ffprobe -i "/tmp/clip_temp.$CLIP_EXTENSION" -show_streams -select_streams a -loglevel error) ]]; then
        ffmpeg -y -i "/tmp/join_temp.$CLIP_EXTENSION"  -i "/tmp/clip_temp.$CLIP_EXTENSION" -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" "/tmp/join2.$CLIP_EXTENSION"
    else
        ffmpeg -y -i "/tmp/join_temp.$CLIP_EXTENSION"  -i "/tmp/clip_temp.$CLIP_EXTENSION" -filter_complex "[0:v:0] [1:v:0]concat=n=2:v=1[outv]" -map "[outv]" "/tmp/join2.$CLIP_EXTENSION"
    fi

    mv "/tmp/join2.$CLIP_EXTENSION" "join.$CLIP_EXTENSION"
    rm "/tmp/join_treated.$CLIP_EXTENSION" "/tmp/clip_treated.$CLIP_EXTENSION" "/tmp/join_temp.$CLIP_EXTENSION" "/tmp/clip_temp.$CLIP_EXTENSION"
}

mute () {

    ffmpeg -i "$1" -c copy -an "$CLIP_NAME [no audio].$CLIP_EXTENSION"

}

extract_audio () {

    ffmpeg -i "$1" -codec:a libmp3lame "$CLIP_NAME [audio only].mp3"

}

scale () {

    echo -e "-----CURRENT VIDEO DIMENSIONS OF $CLIP_NAME.$CLIP_EXTENSION: $CLIP_WIDTH x $CLIP_HEIGHT"
    while read -p "Enter scale coefficient [Default: 2; Recommended: $( echo "scale=2; $CLIP_HEIGHT / 360" | bc )]: " SCALE; do    

        SCALE=${SCALE:-2}

        re='^[0-9]*([.][0-9]+)?$'
        if ! [[ $SCALE =~ $re ]] ; then
            echo "error: Not a non-zero number" >&2; continue
        fi

        break
    done

    ffmpeg -i "$1" -vf scale="-1:$( printf "%.0f" $( echo "scale=5; $CLIP_HEIGHT / $SCALE" | bc ) )" -c:a copy "$CLIP_NAME [$SCALE].$CLIP_EXTENSION" 

}

reverse () {

    ffmpeg -i "$1" -vf reverse -af areverse "$CLIP_NAME [reversed].$CLIP_EXTENSION"

}

clip_to_gif () {

    echo -e "-----CURRENT VIDEO DIMENSIONS OF $CLIP_NAME.$CLIP_EXTENSION: $CLIP_WIDTH x $CLIP_HEIGHT"
    while read -p "Enter scale coefficient [Default: 2; Recommended: $( echo "scale=2; $CLIP_HEIGHT / 360" | bc )]: " SCALE; do    

        SCALE=${SCALE:-2}

        re='^[0-9]*([.][0-9]+)?$'
        if ! [[ $SCALE =~ $re ]] ; then
            echo "error: Not a non-zero number" >&2; continue
        fi

        break
    done

    echo -e "-----CURRENT FRAMERATE OF $CLIP_NAME.$CLIP_EXTENSION: $CLIP_FRAMERATE fps"
    while read -p "Enter new framerate [Default: 23.98; Recommended: $( echo "scale=2; $CLIP_FRAMERATE / 2" | bc )]: " RATE; do    

        RATE=${RATE:-23.98}

        re='^[1-9][0-9]*([.][0-9]+)?$'
        if ! [[ $RATE =~ $re ]] ; then
            echo "error: Not a non-zero number" >&2; continue
        fi

        break
    done

    ffmpeg -y -i "$1" -vf palettegen "/tmp/_tmp_palette_$CLIP_NAME.png"
    ffmpeg -y -i "$1" -i "/tmp/_tmp_palette_$CLIP_NAME.png" -filter_complex paletteuse -r "$RATE"  "/tmp/tmp_out_$CLIP_NAME.gif"
    rm "/tmp/_tmp_palette_$CLIP_NAME.png"
    gifsicle --optimize=3 --no-background --output "$CLIP_NAME [$SCALE - $RATE].gif" --resize "$( echo "$CLIP_WIDTH / $SCALE" | bc )x$( echo "$CLIP_HEIGHT / $SCALE" | bc )" "/tmp/tmp_out_$CLIP_NAME.gif"
    rm "/tmp/tmp_out_$CLIP_NAME.gif"

}

clip_to_webm () {

    echo -e "-----CURRENT VIDEO DIMENSIONS OF $CLIP_NAME.$CLIP_EXTENSION: $CLIP_WIDTH x $CLIP_HEIGHT"
    while read -p "Enter scale coefficient [Default: 2; Recommended: $( echo "scale=2; $CLIP_HEIGHT / 360" | bc )]: " SCALE; do    

        SCALE=${SCALE:-2}

        re='^[1-9][0-9]*([.][0-9]+)?$'
        if ! [[ $SCALE =~ $re ]] ; then
            echo "error: Not a non-zero number" >&2; continue
        fi

        break
    done

    ffmpeg -i "$1" -c:v libvpx-vp9 -crf 30 -b:v 0 -b:a 128k -vf scale="-1:$( echo "$CLIP_HEIGHT / $SCALE" | bc )" -c:a libopus "$CLIP_NAME [$SCALE].webm"
}

webp_to_gif () {
    python3 -c "from PIL import Image;Image.open('$1').save('${1%.webp}.gif','gif',save_all=True,optimize=True,background=0)"
}

FUNCTION=""

while getopts "hicsrjmxgw" opt; do
    case $opt in
    h) echo -e "usage: $0 [-h help] [-i get clip info] [-c crop clip] [-s scale/resize clip] [-r reverse clip] [-j join clips] [-m mute clip] [-x extract audio] [-g convert clip to gif] [-w convert clip to webm]";  exit ;;
    i) FUNCTION="dump_clip_params"; break;;
    c) FUNCTION="crop"; break ;;
    s) FUNCTION="scale"; break ;;
    r) FUNCTION="reverse"; break ;;
    j) FUNCTION="join"; break ;;
    m) FUNCTION="mute"; break ;;
    x) FUNCTION="extract_audio"; break ;;
    g) FUNCTION="convert"; break ;;
    w) FUNCTION="clip_to_webm"; break ;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
    esac
done

if [ "$#" -lt 2 ]
then
echo  "Please insert only one flag and at least one argument"
exit
else
echo -e "\c"
fi

i=0

for file in "${@:2}"
do
    re='s|\.[^. ]*$||g'

    ! [[ $file =~ $re ]] && echo "$file NOT A PROPER FILE, IGNORING..." && continue
    get_clip_params "$file"
    echo "$CLIP_NAME - $CLIP_EXTENSION - $FUNCTION"

    if [[ "$FUNCTION" == "convert" ]]; then

        if [[ "$CLIP_EXTENSION" == "gif" ]]; then
            echo -e "$CLIP_NAME.$CLIP_EXTENSION IS ALREADY A GIF. SKIPPING...\n\n-------------------------$file DONE-------------------------\n\n" && continue     
        elif [[ "$CLIP_EXTENSION" == "webp" ]]; then
            FUNCTION="webp_to_gif"    
        else
            FUNCTION="clip_to_gif"
        fi
  
    fi

    $FUNCTION "$file"
    [[ "$FUNCTION" =~ ^(clip|webp)_to_gif$ ]] && FUNCTION="convert"
    echo -e "\n\n------------------------- $file - DONE -------------------------\n\n"
done


# TO ADD: MORE FLEXIBLE FLAG/ARGUMENT PROCESSING, FLAG WHICH MAKES EVERY FUNCTION RESPECT FILEPATHS (I.E. DOESN'T DRAG EVERY OUTPUT TO CURRENT DIRECTORY)


