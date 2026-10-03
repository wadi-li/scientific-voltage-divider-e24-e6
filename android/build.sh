#!/bin/bash
set -e
# Требуется: Android build-tools 34, platform android-34, JDK 17.
# Использование: KS=/путь/к/keystore.jks KSP=пароль [VC=2 VN=1.1] ./android/build.sh
BT=${BT:-$HOME/android/android-14}; AJ=${AJ:-$HOME/android/android-34/android.jar}
: "${KS:?Укажите KS — путь к keystore}"; : "${KSP:?Укажите KSP — пароль keystore}"
cd "$(dirname "$0")"
rm -rf out && mkdir -p out/gen out/classes
mkdir -p assets && cp ../index.html assets/index.html
$BT/aapt2 compile --dir res -o out/res.zip
$BT/aapt2 link -o out/base.apk -I $AJ --manifest AndroidManifest.xml -A assets --java out/gen out/res.zip --min-sdk-version 24 --target-sdk-version 34 --version-code ${VC:-1} --version-name ${VN:-1.0}
javac -nowarn --release 11 -encoding UTF-8 -classpath $AJ -d out/classes $(find src out/gen -name '*.java')
$BT/d8 --release --min-api 24 --lib $AJ --output out $(find out/classes -name '*.class')
cd out && cp base.apk unsigned.apk && zip -q -j unsigned.apk classes.dex && cd ..
$BT/zipalign -f -p 4 out/unsigned.apk out/aligned.apk
$BT/apksigner sign --ks $KS --ks-pass pass:$KSP --key-pass pass:$KSP --out out/app.apk out/aligned.apk
$BT/apksigner verify --print-certs out/app.apk | head -3
mkdir -p ../dist && cp out/app.apk ../dist/voltage-divider-e24-e6-${VN:-1.0}.apk
echo "APK: dist/voltage-divider-e24-e6-${VN:-1.0}.apk"
