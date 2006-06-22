#!/bin/sh

TARGET_NAME="QuickFileType"
sitetear_path='/usr/local/bin/sitetear'
manual_folder='/Users/tkurita/Factories/Websites/scriptfactory/scriptfactory/ScriptGallery/FinderHelpers/QuickFileType/manual'
#iconPath="$manual_folder/TeXCompileServerIcon16.png"

copyHelp() {
	manual_path=$1;
	helpdir=$2;
	mkdir -p "$helpdir"
	$sitetear_path -F PageFilterAbs "$manual_path" "$helpdir"
	open -a 'Help Indexer' "$helpdir"
	#cp "$iconPath" "$helpdir"
}

helpdir="${TARGET_NAME}Help"

manual_page="index.html" 

copyHelp "$manual_folder/$manual_page" "$helpdir"


