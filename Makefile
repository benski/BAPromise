#!/usr/bin/env make

lib:  
	swift build
linux:  
	swift build -Xcc -mcx16 -Xswiftc -DENABLE_DOUBLEWIDE_ATOMICS -c release
clean: 
	rm -rf .build
test:
	swift test
test-generate: 
	swift test --generate-linuxmain
doc: 
	jazzy
xcode: 
	swift package generate-xcodeproj --enable-code-coverage --output BAPromise-SwiftPackage.xcodeproj
