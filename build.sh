#!/bin/bash
set -e

echo "This script will build the APK, DEB, and RPM packages for the Tapper app."
echo "It will first attempt to install the required packaging tools for your system."
echo "You may be prompted for your password to install these packages."

# Install dependencies based on the package manager
if [ -x "$(command -v apt-get)" ]; then
  echo "Detected Debian/Ubuntu based system. Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y fakeroot dpkg rpm
elif [ -x "$(command -v dnf)" ]; then
  echo "Detected Fedora based system. Installing dependencies..."
  sudo dnf install -y fakeroot dpkg rpm-build
else
  echo "Could not detect package manager. Please install fakeroot, dpkg, and rpm/rpm-build manually."
fi

# Create a directory to store the builds
mkdir -p build/packages

# Build the APK
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk build/packages/tapper.apk

# Build the DEB and RPM packages
flutter pub run fastforge

# Move the packages to the build/packages directory
mv dist/*.deb build/packages/
mv dist/*.rpm build/packages/

echo "Build complete. Packages are in the build/packages directory."
