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
* cp -r /Users/david/Dropbox/Daves_Docs/superego/releases/templatedir /Users/david/Dropbox/Daves_Docs/superego/releases/<version>
* rm /Users/david/Dropbox/Daves_Docs/superego/releases/<version>/Superego.dmg
* rm -rf /Users/david/Dropbox/Daves_Docs/superego/releases/<version>/Superego/Superego.app
* cp -r /Users/david/Library/Developer/Xcode/DerivedData/Superego-exgcwbtwuzxgmnbbbyobaqtweofp/Build/Products/Debug/Superego.app /Users/david/Dropbox/Daves_Docs/superego/releases/<version>/Superego
* hdiutil create /Users/david/Dropbox/Daves_Docs/superego/releases/v0.12/Superego.dmg -srcfolder /Users/david/Dropbox/Daves_Docs/superego/releases/v0.12/Superego
* s3cmd -c /Users/david/.s3cfg-personal put /Users/david/Dropbox/Daves_Docs/superego/releases/<version>/Superego.dmg s3://superego_download
