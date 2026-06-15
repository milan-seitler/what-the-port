.PHONY: build run package clean

build:
	swift build

run:
	swift run ServerBar

package:
	bash scripts/package_app.sh

clean:
	swift package clean
	rm -rf outputs
