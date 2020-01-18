#!/bin/bash
# ./makealib.sh
set -e
rm -rf outlib || true
rm -rf outlib_interop || true
rm -rf outlib_cardviewstub || true
android create lib-project -t android-23 -k com.microsoft.onlineid.sdk -p outlib
android create lib-project -t android-23 -k com.microsoft.onlineid.interop -p outlib_interop
android create lib-project -t android-23 -k android.support.v7.cardview -p outlib_cardviewstub
rm -rf outlib/res outlib/src outlib/AndroidManifest.xml
cat >outlib/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.microsoft.onlineid.sdk"
      android:versionCode="1"
      android:versionName="1.0">
</manifest>
EOF
cat >outlib_interop/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.microsoft.onlineid.interop"
      android:versionCode="1"
      android:versionName="1.0">
</manifest>
EOF
cat >outlib_cardviewstub/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="android.support.v7.cardview"
      android:versionCode="1"
      android:versionName="1.0">
</manifest>
EOF

mkdir -p outlib/src/com/microsoft/onlineid/internal
cat >outlib/src/com/microsoft/onlineid/internal/Applications.java << EOF
package com.microsoft.onlineid.internal;
public class Applications {
	public static String buildClientAppUri(android.content.Context context, String second) {
		return "android-app://com.mojang.minecraftpe.H62DKCBHJP6WXXIV7RBFOGOL4NAK4E6Y";
	}
}
EOF
mkdir -p outlib/src/com/microsoft/onlineid/userdata
cat >outlib/src/com/microsoft/onlineid/userdata/TelephonyManagerReader.java <<EOF
package com.microsoft.onlineid.userdata;
import android.content.Context;
import android.telephony.TelephonyManager;
public class TelephonyManagerReader implements IPhoneNumberReader {
	public TelephonyManagerReader(Context ctx) {
	}
	public TelephonyManagerReader(TelephonyManager tm) {
	}
	public String getIsoCountryCode() {
		return null;
	}
	public String getPhoneNumber() {
		return null;
	}
}
EOF
cat >outlib/src/com/microsoft/onlineid/userdata/MeContactReader.java <<EOF
package com.microsoft.onlineid.userdata;
import android.content.Context;
public class MeContactReader implements IPhoneNumberReader {
	public MeContactReader(Context ctx) {
	}
	public FullName getFullName() {
		return new FullName(null, null);
	}
	public String getPhoneNumber() {
		return null;
	}
	public class FullName {
		public String _firstName, _lastName;
		public FullName(String firstName, String lastName) {
			_firstName = firstName;
			_lastName = lastName;
		}
		public String getFirstName() {
			return _firstName;
		}
		public String getLastName() {
			return _lastName;
		}
	}
}
EOF
FILELIST=`find res -type f |grep -v /iconvr\.png|grep -v /icon\.png|grep -v /public.xml`
for i in $FILELIST
do
	mkdir -p outlib/`dirname $i`
	cp $i outlib/$i
done
cat >outlib/res/values/attrs_styleable.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <declare-styleable name="StyledTextView">
    <attr name="font" format="string" />
    <attr name="isUnderlined" format="boolean" />
  </declare-styleable>
</resources>
EOF
cp "$ANDROID_HOME/extras/android/support/v7/cardview/res/values/attrs.xml" outlib/res/values/attrs_cardview.xml
grep -v "\"font\"" res/values/attrs.xml|grep -v "\"isUnderlined\"" >outlib/res/values/attrs.xml
# remove the card attrs; we add the real ones from the lib for styleable
REMOVELIST="""cardBackgroundColor
cardCornerRadius
cardElevation
cardMaxElevation
cardUseCompatPadding
cardPreventCornerOverlap
contentPadding
contentPaddingLeft
contentPaddingRight
contentPaddingTop
contentPaddingBottom"""
for nam in $REMOVELIST
do
	sed -i -e "/name=\"$nam\"/d" outlib/res/values/attrs.xml
done
#cp patched/attrs.xml outlib/res/values/attrs.xml
#cp patched/styles.xml outlib/res/values/styles.xml
grep -v "name=\"icon\"" res/values/public.xml|grep -v "name=\"iconvr\"" >outlib/res/values/public.xml
JARDEL="org/fmod com/mojang com/amazon com/android com/googleplay com/microsoft/onlineid/sdk/R*.class com/microsoft/onlineid/interop/R*.class com/microsoft/onlineid/internal/Applications.class com/microsoft/onlineid/userdata/TelephonyManagerReader.class com/microsoft/onlineid/userdata/MeContactReader*.class com/facebook android/support com/google/android/gms" # gson is needed
#cp ../mcpe123b1.apk ./mcpe.apk
dex2jar mcpe.apk
7z -tzip d mcpe_dex2jar.jar $JARDEL
mv mcpe_dex2jar.jar outlib/libs
rm -rf outlib_interop/res outlib_interop/src
mkdir outlib_interop/src
echo "android.library.reference.1=../outlib" >>outlib_interop/project.properties
echo "android.library.reference.2=../outlib_cardviewstub" >>outlib_interop/project.properties
rm -rf outlib_cardviewstub/res outlib_cardviewstub/src
mkdir outlib_cardviewstub/src
echo "android.library.reference.1=../outlib" >>outlib_cardviewstub/project.properties
cd outlib_interop
ant clean debug
