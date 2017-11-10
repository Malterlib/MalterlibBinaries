#!/bin/bash
# Copyright © 2015 Hansoft AB
# Distributed under the MIT license, see license text in LICENSE.Malterlib

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

SysName=$(uname -s)
ProcessorArch=$(uname -m)

IsWindows=false
IsOSX=false

if [[ $SysName ==  MINGW* ]] || [[ $SysName ==  CYGWIN* ]] || [[ $SysName ==  windows* ]] ; then
	IsWindows=true
	export MToolExecutable="$DIR/General/Windows/MTool"
elif [[ $SysName ==  Darwin* ]] ; then
	IsOSX=true
	if [[ $ProcessorArch == i*86 ]] ; then
		export MToolExecutable="$DIR/General/OSX/x86/MTool"
	elif [[ $ProcessorArch == x86_64 ]] ; then
		export MToolExecutable="$DIR/General/OSX/x64/MTool"
	else
		echo $ProcessorArch is not a recognized architechture and no build of MTool is available for it
		exit 1
	fi
elif [[ $SysName ==  Linux* ]] ; then
	if [[ $ProcessorArch == i*86 ]] ; then
		export MToolExecutable="$DIR/General/Linux/x86/MTool"
	elif [[ $ProcessorArch == x86_64 ]] ; then
		export MToolExecutable="$DIR/General/Linux/x64/MTool"
	else
		echo $ProcessorArch is not a recognized architechture and no build of MTool is available for it
		exit 1
	fi
else
	echo "Couldn't detect system"
fi

if [[ $# != 0 ]]; then
	$MToolExecutable "$@"
fi
