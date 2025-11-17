flutter clean
rm pubspec.lock
if [ -f "l10n.yaml" ]; then
  flutter gen-l10n
  echo "✔ flutter gen-l10n build successfully!"
fi
flutter pub get
# examples
cd example && flutter clean && cd ..
rm -r example/ios/Pods
rm example/ios/Podfile.lock
rm example/ios/Flutter/Flutter.podspec
cd example && flutter pub get && cd ..
cd example/ios && pod install