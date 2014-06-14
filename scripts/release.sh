#!/bin/sh

# Usage: release.sh <version>

version=$1

echo "Releasing $version"

git tag $version
git push
cp -r /Users/david/Dropbox/Daves_Docs/superego/releases/templatedir /Users/david/Dropbox/Daves_Docs/superego/releases/$version
rm /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego.dmg
rm -rf /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego/Superego.app
cp -r /Users/david/Library/Developer/Xcode/DerivedData/Superego-exgcwbtwuzxgmnbbbyobaqtweofp/Build/Products/Debug/Superego.app /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego
hdiutil create /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego.dmg -srcfolder /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego
s3cmd -c /Users/david/.s3cfg-personal -P put /Users/david/Dropbox/Daves_Docs/superego/releases/$version/Superego.dmg s3://superego_download
