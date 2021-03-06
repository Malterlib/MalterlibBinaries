#!/bin/bash
# Copyright © 2015-2018 Nonna Holding AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MToolSourceOnly=true source "$DIR/MTool.sh"

set -e

Conf_Safe=false
Conf_Echo=false
Conf_Old=false
MalterlibXcodeVersion=
MalterlibVisualStudioVersion=

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
				MalterlibXcodeVersion=$Value
			fi
			if [[ "$Key" == "VisualStudioVersion" ]]; then
				MalterlibVisualStudioVersion=$Value
			fi
		done
	fi
	IFS="$OLDIFS"
}

if [[ $IsOSX == true ]] ; then
	if [ ! "$MalterlibXcodeVersion" == "" ]; then
		Conf_Version=$MalterlibXcodeVersion
	else
		Conf_Version=`xcodebuild -version | grep Xcode | awk -F ' ' {'print $2'} | awk -F '.' {'print $1'}`
	fi
elif [[ $IsWindows == true ]] ; then
	if [ ! "$MalterlibVisualStudioVersion" == "" ]; then
		Conf_Version=$MalterlibVisualStudioVersion
	else
		Conf_Version=
	fi
else
	Conf_Version=
fi

while getopts "seo" opt; do
    case "$opt" in
    s)  Conf_Safe=true
        ;;
    o)  Conf_Old=true
        ;;
    e)  Conf_Echo=true
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

ToolType=BuildSystemGen

if [[ "$MalterlibTool" == "true" ]]; then
	ToolType=Malterlib
else
	if (( $# >= 1)); then
		Conf_Workspace=$1
		shift
	fi
fi

if [[ "$Conf_Safe" == "true" ]] ; then
	mkdir -p "$PWD/BuildSystem/MTool"
	cp -r "$MToolDirectory/"* "$PWD/BuildSystem/MTool/"
	MToolExecutable="$PWD/BuildSystem/MTool/MTool"
fi

function DoEcho()
{
	if [[ "$Conf_Echo" == "true" ]] ; then
		echo $@
	fi
}

function RunMTool()
{
	DoEcho "$MToolExecutable" "$@"
	set +e
	"$MToolExecutable" "$@"
	MToolExit=$?
	set -e

	if [[ $MToolExit != 0 ]] ; then
		exit $MToolExit
	fi
}

function GenerateForVersion()
{
	if [[ "$Conf_Old" == "true" ]] ; then
		Files=`find . -maxdepth 1 -name '*.OldMBuildSystem'`
	else
		Files=`find . -maxdepth 1 -name '*.MBuildSystem'`
	fi

	Generator="$1"
	shift

	for f in $Files ; do
		if [ "$Conf_Old" == "true" ] ; then
			RunMTool $ToolType "$f" "Generator=$Generator" "OutDir=$PWD/BuildSystem/Old" "$@"
		elif [ "$Conf_Workspace" == "" ] ; then
			RunMTool $ToolType "$f" "Generator=$Generator" "$@"
		else
			RunMTool $ToolType "$f" "Generator=$Generator" "Workspace=$Conf_Workspace" "$@"
		fi
	done
}

if [[ "$IsWindows" == "true" ]]; then
	if [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "VisualStudio$Conf_Version" "$@"
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
		GenerateForVersion "$WindowsGenerator" "$@"
	fi
else
	if [ "$Conf_Version" == "4" ] ; then
		GenerateForVersion Xcode "$@"
	elif [ ! "$Conf_Version" == "" ] ; then
		GenerateForVersion "Xcode$Conf_Version" "$@"
	else
		GenerateForVersion "Xcode5" "$@"
	fi
fi

if [[ "$MalterlibTool" != "true" ]]; then
	echo "Build system generation done"
fi
