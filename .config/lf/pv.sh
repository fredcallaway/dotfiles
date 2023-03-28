#!/bin/sh
width=${2:-30}
height=${3:-100}

case "$1" in
    *.png) viu -b $1 --width $width;;
    *.jpeg) viu -b $1 --width $width;;
    *.jpg) viu -b $1 --width $width;;
    *.tar*) tar tf "$1";;
    *.zip) unzip -l "$1";;
    *.rar) unrar l "$1";;
    *.7z) 7z l "$1";;
    *.pdf) pdftotext "$1" -;;
    *) bat -f $1 --line-range :$height;;
esac