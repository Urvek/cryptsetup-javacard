#!/bin/bash

if [ "$1" = '-?' ] || [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo "Usage: $0 [ARGS...]"
    echo "  ARGS -- extra arguments to pass to GlobalPlatform (e. .g -r 'My Reader')"
    exit 0
fi

if [ -z "$JAVA_HOME" ]; then
    echo "ERROR: You must set JAVA_HOME to your JDK path!" 1>&2
    echo "ERROR:   e. g. JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 $0 [...]" 1>&2
    exit 1
fi

APPLET_PACKAGE_AID='0x4a:0x43:0x4b:0x65:0x79:0x70:0x6b:0x67'
APPLET_PACKAGE=applets
APPLET_CLASS="$APPLET_PACKAGE.KeyStorageApplet"
APPLET_AID='0x4a:0x43:0x4b:0x65:0x79:0x53:0x74:0x6f:0x72:0x61:0x67:0x65'
APPLET_VERSION=1.0

OUT_PATH=$(mktemp -d)

PROJECT_HOME="$(dirname "$0")/.."
APPLET_PATH="$PROJECT_HOME/JCKeyStorage/src/applets"
APPLET_SOURCE="$APPLET_PATH/KeyStorageApplet.java"

JCDK_PATH="$PROJECT_HOME/ext/java_card_kit-2_2_2"

# Compile the class file:
"$JAVA_HOME/bin/javac" -d "$OUT_PATH" -classpath "$OUT_PATH:$JCDK_PATH/lib/api.jar" -sourcepath "$APPLET_PATH" -target 1.2 -g:none -Xlint -Xlint:-options -Xlint:-serial -source 1.3 "$APPLET_SOURCE"

# Convert to CAP:
bash "$JCDK_PATH/bin/converter" -classdir "$OUT_PATH" -exportpath "$JCDK_PATH/api_export_files" -verbose -nobanner -out CAP EXP -applet "$APPLET_AID" "$APPLET_CLASS" "$APPLET_PACKAGE" "$APPLET_PACKAGE_AID" "$APPLET_VERSION"

read -sp 'Enter the master password: ' MASTER_PWD; echo

# Install the applet:
"$JAVA_HOME/bin/java" -jar "$PROJECT_HOME/ext/gp.jar" -d --install "$OUT_PATH/$APPLET_PACKAGE/javacard/$APPLET_PACKAGE.cap" --params "$MASTER_PWD" "$@"

MASTER_PWD=''

rm -rf "$OUT_PATH"