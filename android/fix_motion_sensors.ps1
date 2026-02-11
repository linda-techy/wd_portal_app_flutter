# Script to fix the motion_sensors plugin namespace issue
# Run this script if you encounter namespace errors after running flutter pub get

$motionSensorsPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\motion_sensors-0.1.0\android\build.gradle"

if (Test-Path $motionSensorsPath) {
    Write-Host "Patching motion_sensors plugin..."
    
    $content = @'
group 'finaldev.motion_sensors'
version '1.0-SNAPSHOT'

buildscript {
    ext.kotlin_version = '1.9.22'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    namespace 'finaldev.motion_sensors'
    compileSdk 28

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }
    defaultConfig {
        minSdkVersion 16
    }
    lintOptions {
        disable 'InvalidPackage'
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
'@
    
    Set-Content -Path $motionSensorsPath -Value $content
    Write-Host "Motion sensors plugin patched successfully!" -ForegroundColor Green
} else {
    Write-Host "Motion sensors plugin not found at: $motionSensorsPath" -ForegroundColor Yellow
    Write-Host "Please run 'flutter pub get' first." -ForegroundColor Yellow
}
