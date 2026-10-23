from pathlib import Path

groovy = Path("android/app/build.gradle")
kotlin = Path("android/app/build.gradle.kts")

if groovy.exists():
    p = groovy
    s = p.read_text()
    block = """
    signingConfigs {
        lovelyRelease {
            keyAlias System.getenv('ANDROID_KEY_ALIAS')
            keyPassword System.getenv('ANDROID_KEY_PASSWORD')
            storePassword System.getenv('ANDROID_KEYSTORE_PASSWORD')
            storeFile file('lovely-release.jks')
        }
    }
"""
    if "lovelyRelease {" not in s:
        if "android {" not in s:
            raise SystemExit("ERROR: android block not found")
        s = s.replace("android {", "android {\n" + block, 1)
    if "signingConfig signingConfigs.lovelyRelease" not in s:
        if "signingConfig signingConfigs.debug" not in s:
            raise SystemExit("ERROR: release signing line not found")
        s = s.replace("signingConfig signingConfigs.debug",
                      "signingConfig signingConfigs.lovelyRelease")
elif kotlin.exists():
    p = kotlin
    s = p.read_text()
    block = """
    signingConfigs {
        create("lovelyRelease") {
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            storeFile = file("lovely-release.jks")
        }
    }
"""
    if 'create("lovelyRelease")' not in s:
        if "android {" not in s:
            raise SystemExit("ERROR: android block not found")
        s = s.replace("android {", "android {\n" + block, 1)
    if 'signingConfigs.getByName("lovelyRelease")' not in s:
        old = 'signingConfig = signingConfigs.getByName("debug")'
        if old not in s:
            old = "signingConfig = signingConfigs.debug"
        if old not in s:
            raise SystemExit("ERROR: release signing line not found")
        s = s.replace(old, 'signingConfig = signingConfigs.getByName("lovelyRelease")')
else:
    raise SystemExit("ERROR: Gradle build file not found")

p.write_text(s)
print("OK: Release signing configured in", p)
