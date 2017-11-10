#!/bin/bash
# Copyright © 2015 Hansoft AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR/MTool.sh"

Conf_Safe=false
Conf_Echo=false
Conf_Old=false
{
	OLDIFS="$IFS"
	IFS=$'\n'
	if [ -f "Repo.conf" ] ; then
		RepoConfig=`cat Repo.conf`
		for Line in $RepoConfig; do
			IFS=' '

			read -a LineCommands <<< "$Line"
			Key=${LineCommands[0]}
			Value=${LineCommands[1]}

			if [[ "$Key" == "XcodeVersion" ]]; then
				XcodeVersion=$Value
			fi
			if [[ "$Key" == "VisualStudioVersion" ]]; then
				VisualStudioVersion=$Value
			fi
		done
	fi
	IFS="$OLDIFS"
}

if [[ $IsOSX == true ]] ; then
	if [ ! "$XcodeVersion" == "" ]; then
		Conf_Version=$XcodeVersion
	else
		Conf_Version=`xcodebuild -version | grep Xcode | awk -F ' ' {'print $2'} | awk -F '.' {'print $1'}`
	fi
elif [[ $IsWindows == true ]] ; then
	if [ ! "$VisualStudioVersion" == "" ]; then
		Conf_Version=$VisualStudioVersion
	else
		Conf_Version=
	fi
else
	Conf_Version=
fi

while getopts "seo456" opt; do
    case "$opt" in
    s)  Conf_Safe=true
        ;;
    o)  Conf_Old=true
        ;;
    e)  Conf_Echo=true
        ;;
    6)  Conf_Version=6
        ;;
    5)  Conf_Version=5
        ;;
    4)  Conf_Version=4
        ;;
    2012)  Conf_Version=2012
        ;;
    2013)  Conf_Version=2013
        ;;
    2015)  Conf_Version=2015
        ;;
    2017)  Conf_Version=2017
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

Conf_Workspace=$1

if [[ "$Conf_Safe" == "true" ]] ; then
	if [ ! -e BuildSystem/MTool ] ; then
		mkdir -p BuildSystem
		cp $MToolExecutable BuildSystem/
	fi
	MToolExecutable=BuildSystem/MTool
fi

function DoEcho()
{
	if [[ "$Conf_Echo" == "true" ]] ; then
		echo $1
	fi
}

function GenerateForVersion()
{
	if [[ "$Conf_Old" == "true" ]] ; then
		Files=`find . -maxdepth 1 -name '*.OldMBuildSystem'`
	else
		Files=`find . -maxdepth 1 -name '*.MBuildSystem'`
	fi

	for f in $Files ; do
		if [ "$Conf_Old" == "true" ] ; then
			DoEcho "$MToolExecutable BuildSystemGen Malterlib.IdsBuildSystem Generator=$1 OutputDirectory=$PWD/BuildSystem/Old"
			$MToolExecutable BuildSystemGen "$f" "Generator=$1" "OutDir=$PWD/BuildSystem/Old"
		elif [ "$Conf_Workspace" == "" ] ; then
			DoEcho "$MToolExecutable BuildSystemGen Malterlib.IdsBuildSystem Generator=$1"
			$MToolExecutable BuildSystemGen "$f" "Generator=$1"
		else
			DoEcho "$MToolExecutable BuildSystemGen Malterlib.IdsBuildSystem Generator=$1 Workspace=$Conf_Workspace"
			$MToolExecutable BuildSystemGen "$f" "Generator=$1" "Workspace=$Conf_Workspace"
		fi
	done
}


if [[ "$IsWindows" == "true" ]]; then
	if [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "VisualStudio$Conf_Version"
	else
		WindowsGenerator="VisualStudio2017"
		if [ -f "Repo.conf" ] ; then
		{
			OLDIFS="$IFS"
			IFS=$'\n'
			RepoConfig=`cat Stream.conf`
			for Line in $RepoConfig; do
				IFS=' '
				
				read -a LineCommands <<< "$Line"
				Key=${LineCommands[0]}
				Value=${LineCommands[1]}
				
				if [[ "$Key" == "WindowsGenerator" ]]; then
					WindowsGenerator=$Value
				fi
			done
			IFS="$OLDIFS"
		}
		fi
		echo GenerateForVersion "$WindowsGenerator"
		GenerateForVersion "$WindowsGenerator"
	fi
else
	if [ "$Conf_Version" == "4" ] ; then
		GenerateForVersion Xcode
	elif [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "Xcode$Conf_Version"
	else
		GenerateForVersion "Xcode5"
	fi
fi

echo "Build system generation done"
