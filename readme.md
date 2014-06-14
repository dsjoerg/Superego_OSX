### Superego_OSX

### Get started

* install CocoaPods
* `pod install`
* `open Superego.xcworkspace`

### Cut a new release

* increment version number in nib
* git commit
* git tag <version number>
* git push
* clean-build new executable
* scripts/release.sh <version>
