#!/bin/bash
result=${PWD##*/}  
echo $result

if [ $result == "xcode" ]; then
    echo "1"
    cd ...
else
   	echo "2"
fi;

echo `pwd`

PREFIX="dcodetools/xcode"

sh "$PREFIX"/build.sh Combo ComboDev.mobileprovision Combo Debug "$PREFIX"
