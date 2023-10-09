#!/bin/bash

set -x
set -e

# Pass scheme name as the first argument to the script
# NAME=$1
NAME=PotentJSON

# Build the scheme for all platforms that we plan to support
for PLATFORM in "iOS" "iOS Simulator"; do
# for PLATFORM in "iOS"; do

    case $PLATFORM in
    "iOS")
    RELEASE_FOLDER="Release-iphoneos"
    ;;
    "iOS Simulator")
    RELEASE_FOLDER="Release-iphonesimulator"
    ;;
    esac

    ARCHIVE_PATH=$RELEASE_FOLDER

    # Rewrite Package.swift so that it declaras dynamic libraries, since the approach does not work with static libraries
    perl -i -p0e 's/type: .static,//g' Package.swift
    perl -i -p0e 's/type: .dynamic,//g' Package.swift
    perl -i -p0e 's/(library[^,]*,)/$1 type: .dynamic,/g' Package.swift

    xcodebuild archive -workspace . -scheme $NAME \
            -destination "generic/platform=$PLATFORM" \
            -archivePath $ARCHIVE_PATH \
            -derivedDataPath ".build" \
            SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

    FRAMEWORK_PATH="$ARCHIVE_PATH.xcarchive/Products/usr/local/lib/$NAME.framework"
    MODULES_PATH="$FRAMEWORK_PATH/Modules"
    mkdir -p $MODULES_PATH

    BUILD_PRODUCTS_PATH=".build/Build/Intermediates.noindex/ArchiveIntermediates/$NAME/BuildProductsPath"
    RELEASE_PATH="$BUILD_PRODUCTS_PATH/$RELEASE_FOLDER"
    SWIFT_MODULE_PATH="$RELEASE_PATH/$NAME.swiftmodule"
    RESOURCES_BUNDLE_PATH="$RELEASE_PATH/${NAME}_${NAME}.bundle"

    # Copy Swift modules
    if [ -d $SWIFT_MODULE_PATH ] 
    then
        cp -r $SWIFT_MODULE_PATH $MODULES_PATH
    else
        # In case there are no modules, assume C/ObjC library and create module map
        echo "module $NAME { export * }" > $MODULES_PATH/module.modulemap
        # TODO: Copy headers
    fi

    # Copy resources bundle, if exists 
    if [ -e $RESOURCES_BUNDLE_PATH ] 
    then
        cp -r $RESOURCES_BUNDLE_PATH $FRAMEWORK_PATH
    fi

done

xcodebuild -create-xcframework \
-framework Release-iphoneos.xcarchive/Products/usr/local/lib/$NAME.framework \
-framework Release-iphonesimulator.xcarchive/Products/usr/local/lib/$NAME.framework \
-output $NAME.xcframework

# Copy .swiftmodule files to the XCFramework folder that are not copied over by the previous command for no apparent reason

for PLATFORM in "iOS" "iOS Simulator"; do

    case $PLATFORM in
        "iOS")
        RELEASE_FOLDER="Release-iphoneos"
        ;;
        "iOS Simulator")
        RELEASE_FOLDER="Release-iphonesimulator"
        ;;
    esac

    ARCHIVE_PATH=$RELEASE_FOLDER
    FRAMEWORK_PATH="$ARCHIVE_PATH.xcarchive/Products/usr/local/lib/$NAME.framework"
    MODULES_PATH="$FRAMEWORK_PATH/Modules"

    # RELEASE_PATH="$BUILD_PRODUCTS_PATH/$RELEASE_FOLDER"
    SWIFT_MODULE_PATH="$MODULES_PATH/$NAME.swiftmodule"

    if [ -d $SWIFT_MODULE_PATH ] 
    then
        case $PLATFORM in
        "iOS")
        cp "$SWIFT_MODULE_PATH/arm64-apple-ios.swiftmodule" "$NAME.xcframework/ios-arm64/$NAME.framework/Modules/$NAME.swiftmodule"
        ;;
        "iOS Simulator")
        cp "$SWIFT_MODULE_PATH/arm64-apple-ios-simulator.swiftmodule" "$NAME.xcframework/ios-arm64_x86_64-simulator/$NAME.framework/Modules/$NAME.swiftmodule"
        cp "$SWIFT_MODULE_PATH/x86_64-apple-ios-simulator.swiftmodule" "$NAME.xcframework/ios-arm64_x86_64-simulator/$NAME.framework/Modules/$NAME.swiftmodule"
        ;;
    esac
    fi

done
