#!/bin/sh
# Tests der Lernlogik. Mit Xcode reicht `swift test`; mit nur den Command Line Tools
# müssen die Pfade zum Testing-Framework mitgegeben werden.
cd "$(dirname "$0")/../VokabelKit" || exit 1
if xcode-select -p | grep -q CommandLineTools; then
  F=/Library/Developer/CommandLineTools/Library/Developer
  exec swift test -Xswiftc -F$F/Frameworks -Xlinker -F$F/Frameworks \
    -Xlinker -rpath -Xlinker $F/Frameworks -Xlinker -rpath -Xlinker $F/usr/lib
fi
exec swift test
