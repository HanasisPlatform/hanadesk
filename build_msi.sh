#!/bin/bash

SKIP_CARGO=""
VERSION_UP=""
SIGN=""


# Check if version argument is provided
print_usage() {
  echo "Usage: ./build_msi.sh <version> [--skip-cargo] [--version-up] [--sign]"
  exit 1
}


# 옵션 파싱
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --skip-cargo)
      SKIP_CARGO="--skip-cargo"
      ;;
    --version-up)
      VERSION_UP="--version-up"
      ;;
    --sign)
      SIGN="--sign"
      ;;
    -*)
      echo "Unknown option: $1"
      print_usage
      ;;
    *)
      # 첫 번째 비옵션 인자를 VERSION으로 간주
      if [ -z "$VERSION" ]; then
        VERSION="$1"
      else
        echo "Unexpected argument: $1"
        print_usage
      fi
      ;;
  esac
  shift
done

# VERSION 필수 확인
if [ -z "$VERSION" ]; then
  echo "Error: <version> is required."
  print_usage
fi

# 옵션 확인 출력 (디버깅용)
echo "VERSION: $VERSION"
echo "SKIP_CARGO: $SKIP_CARGO"
echo "VERSION_UP: $VERSION_UP"
echo "SIGN: $SIGN"


# Add MSBuild to PATH (Adjust path based on your system)
export PATH=$PATH:"/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin"

alias msbuild="/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe"

# Verify MSBuild is available
if ! command -v MSBuild.exe &> /dev/null; then
  echo "MSBuild not found in PATH. Make sure MSBuild is installed and added to PATH."
  exit 1
fi

# Step 1: Run Python build.py

BUILD_COMMAND="python build.py --flutter --skip-portable-pack"

# 옵션 처리
if [ "$SKIP_CARGO" == "--skip-cargo" ]; then
  echo "Skipping cargo build..."
  BUILD_COMMAND="$BUILD_COMMAND --skip-cargo"
fi

if [ "$SIGN" == "--sign" ]; then
  echo "Including sign option..."
  BUILD_COMMAND="$BUILD_COMMAND --sign"
fi

# 최종 명령 실행
echo "Executing: $BUILD_COMMAND"
$BUILD_COMMAND

# 명령 실행 결과 확인
if [ $? -ne 0 ]; then
  echo "Error during Python build.py. Exiting..."
  exit 1
fi

# Step 2: Change directory to /res/msi
echo "Changing directory to res/msi..."
cd res/msi || { echo "Directory /res/msi does not exist. Exiting..."; exit 1; }

# Step 3: Run preprocess.py

if [ "$VERSION_UP" == "--version-up" ]; then

  echo "Running preprocess.py with version: $VERSION..."
  python preprocess.py --arp -d ../../HanaDesk --version "$VERSION" --app-name "HanaDesk"
else 
  echo "VERSION_UP is not set to '--version-up'. Skipping preprocess.py."
fi

if [ $? -ne 0 ]; then
  echo "Error during preprocess.py. Exiting..."
  exit 1
fi

# Step 4: Restore NuGet packages
echo "Restoring NuGet packages..."
nuget restore msi.sln
if [ $? -ne 0 ]; then
  echo "Error during NuGet restore. Exiting..."
  exit 1
fi

# Step 5: Build with MSBuild
echo "Building solution with MSBuild..."
powershell.exe -Command "MSBuild.exe msi.sln /p:Configuration=Release /p:Platform=x64 /p:TargetVersion=Windows10; exit"
if [ $? -ne 0 ]; then
  echo "Error during MSBuild. Exiting..."
  exit 1
fi


CERTIFICATE_NAME="HANASIS CO., LTD."
TIMESTAMP_SERVER="http://timestamp.digicert.com"
MSI_NAME="HanaDesk-${VERSION}"

# Step 6: Move output MSI file
echo "Moving generated MSI to Hanadesk..."

if [ "$SIGN" == "--sign" ]; then
  echo "Signing the MSI file using SafeNet..."

  OUTPUT_FILE="Package/bin/x64/Release/en-us/Package.msi"
  cmd="signtool sign /d \"${MSI_NAME}\" /n \"${CERTIFICATE_NAME}\" /tr \"${TIMESTAMP_SERVER}\" /td SHA256 /fd SHA256 \"${OUTPUT_FILE}\"; exit"

  echo "Executing powershell.exe -Command \"${cmd}\"..."

  powershell.exe -Command "${cmd}"

  if [ $? -ne 0 ]; then
    echo "Code signing failed. Exiting..."
    exit 1
  fi
else
  echo "SIGN is not set to '--sign'. Skipping code signing."
fi

MSI_FILE="../../HanaDesk-${VERSION}.msi"

if [ -f "$MSI_FILE" ]; then
  echo "File $MSI_FILE exists. Deleting it..."
  rm "$MSI_FILE"
  if [ $? -eq 0 ]; then
    echo "File $MSI_FILE deleted successfully."
  else
    echo "Failed to delete $MSI_FILE."
    exit 1
  fi
else
  echo "File $MSI_FILE does not exist. Nothing to delete."
fi

cp Package/bin/x64/Release/en-us/Package.msi $MSI_FILE
if [ $? -ne 0 ]; then
  echo "Error during file move. Exiting..."
  exit 1
fi


echo "Build completed successfully."
