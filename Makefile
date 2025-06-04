all: clean archive export

archive: Build
	xcodebuild -scheme Router archive -archivePath Build/Router.xcarchive

export: Build/Router.xcarchive
	xcodebuild -exportArchive -exportOptionsPlist ExportOptions.plist -archivePath Build/Router.xcarchive -exportPath Build

clean:
	rm -rf Build/*

.PHONY: clean
