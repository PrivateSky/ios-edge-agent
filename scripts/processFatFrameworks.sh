#!/bin/bash

fatFrameworksDirectory="$1"
sourceDirectory=$(pwd)
convertFATtoXCFHelper="$sourceDirectory/convertFATtoXCF.sh"

function convertFATtoXCF {
    local currentFramework="$1"
    local namePart=${currentFramework%%.*}
    
    rm -r -f "$namePart.xcframework"
    bash "$convertFATtoXCFHelper" "$fatFrameworksDirectory/$currentFramework"

}



cd "$fatFrameworksDirectory"
frameworkList=$(ls | grep '\.framework'$ )

echo "Value of frameworkList is $frameworkList"


echo "$frameworkList" | while read line 
do
    echo "Currenttly processing $line"
    convertFATtoXCF "$line"
done

