# 🛠️ HanaDesk 개발 환경 설정 가이드

이 문서는 HanaDesk 프로젝트를 빌드하고 개발하기 위한 완전한 환경 설정 가이드입니다.

## 📋 목차

- [필수 개발 도구](#필수-개발-도구)
- [Windows 빌드 환경](#windows-빌드-환경)
- [환경변수 설정](#환경변수-설정)
- [빌드 명령어](#빌드-명령어)
- [문제 해결](#문제-해결)

## 🔧 필수 개발 도구

### 1. Rust 개발 환경

```bash
# Rust 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Windows PowerShell에서:
# Invoke-WebRequest -Uri https://win.rustup.rs/ -OutFile rustup-init.exe
# .\rustup-init.exe
```

### 2. Flutter 개발 환경

```bash
# Flutter SDK 다운로드 및 설치
# https://docs.flutter.dev/get-started/install/windows

# Flutter Rust Bridge 설치
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
```

**Flutter 설치 확인:**
```bash
flutter doctor -v
flutter --version
```

### 3. C++ 빌드 환경

**Windows:**
- **Visual Studio 2022 Community** 설치
  - 워크로드: "C++를 사용한 데스크톱 개발"
  - MSBuild 경로: `C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin`

### 4. vcpkg (C++ 패키지 매니저)

```bash
# vcpkg 클론 및 설치
git clone https://github.com/microsoft/vcpkg
cd vcpkg
git checkout 2023.04.15

# Windows
.\bootstrap-vcpkg.bat

# Linux/macOS
./bootstrap-vcpkg.sh

# Windows용 필수 라이브러리 설치
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static

# Linux/macOS용 라이브러리 설치
vcpkg install libvpx libyuv opus aom
```

### 5. LLVM/Clang

**Windows:**
```bash
# LLVM 다운로드 및 설치
# https://github.com/llvm/llvm-project/releases
# 권장 설치 경로: C:\LLVM
```

**Linux:**
```bash
sudo apt install -y clang libclang-dev
```

## 🏗️ Windows 빌드 환경

### MSI 빌드용 추가 도구

1. **Python 3.x**
   ```bash
   # Python 설치 확인
   python --version
   python -m pip --version
   ```

2. **NuGet 패키지 매니저**
   - Visual Studio와 함께 자동 설치됨

3. **Git Bash** (선택사항)
   - Git for Windows 설치 시 포함
   - 쉘 스크립트 실행용

4. **WiX Toolset** (MSI 패키지 생성용)
   - https://wixtoolset.org/

### 코드 서명 (상용 배포시)

```bash
# SafeNet 인증서 설정
# signtool.exe (Windows SDK 포함)
# 인증서: "HANASIS CO., LTD."
# 타임스탬프 서버: "http://timestamp.digicert.com"
```

## 🌐 환경변수 설정

### Windows 환경변수

```bash
# 시스템 환경변수 설정
VCPKG_ROOT=C:\vcpkg
LLVM_PATH=C:\LLVM
LLVM_HOME=C:\LLVM

# PATH 환경변수에 추가
PATH=%PATH%;C:\LLVM\bin
PATH=%PATH%;C:\vcpkg\bin
PATH=%PATH%;C:\flutter\bin
PATH=%PATH%;%USERPROFILE%\.cargo\bin
```

### 환경변수 설정 확인

```powershell
# PowerShell에서 확인
echo $env:VCPKG_ROOT
echo $env:LLVM_PATH
echo $env:LLVM_HOME

# 또는
Get-ChildItem Env: | Where-Object Name -like "*LLVM*"
Get-ChildItem Env: | Where-Object Name -like "*VCPKG*"
```

## 🚀 빌드 명령어

### Flutter 앱 개발 및 실행

```bash
# 프로젝트 루트에서
cd flutter

# CS 버전 실행 (수정된 스크립트)
./run_cs.sh

# 또는 수동 실행
flutter pub get
flutter_rust_bridge_codegen --rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./windows/runner/bridge_generated.h --llvm-path "${LLVM_PATH}"
flutter run --dart-define=FLAVOR=cs lib/main_cs.dart

# Member 버전 실행
./run_member.sh
```

### Rust 라이브러리 빌드

```bash
# 프로젝트 루트에서
cargo build --features flutter

# 릴리즈 빌드
cargo build --release --features flutter

# 특정 기능 포함 빌드
cargo build --features flutter,hwcodec
```

### MSI 패키지 빌드

```bash
# 전체 MSI 빌드 (버전 1.3.6 예시)
./build_msi.sh 1.3.6 --version-up --sign

# 빌드 옵션들:
./build_msi.sh 1.3.6                    # 기본 빌드
./build_msi.sh 1.3.6 --skip-cargo       # Cargo 빌드 생략
./build_msi.sh 1.3.6 --version-up       # 버전 업데이트
./build_msi.sh 1.3.6 --sign             # 코드 서명
./build_msi.sh 1.3.6 --version-up --sign # 버전 업데이트 + 서명
```

### Python 빌드 스크립트

```bash
# 기본 Flutter 빌드
python build.py --flutter

# CS 버전 빌드
python build.py --flutter --cs

# 하드웨어 코덱 포함
python build.py --flutter --hwcodec

# 포터블 버전 빌드
python build.py --flutter --portable

# Cargo 빌드 생략 (개발 중)
python build.py --flutter --skip-cargo
```

## 🔍 개발 워크플로우

### 1. 초기 환경 설정

```bash
# 1. 저장소 클론
git clone <repository-url>
cd hanadesk

# 2. Rust 의존성 확인
cargo check

# 3. Flutter 의존성 설치
cd flutter
flutter pub get

# 4. 브리지 코드 생성
flutter_rust_bridge_codegen --rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./windows/runner/bridge_generated.h --llvm-path "${LLVM_PATH}"
```

### 2. 개발 중 빌드

```bash
# Rust 코드 변경 시
cargo build --features flutter

# Flutter 코드 변경 시
flutter hot reload  # 또는 hot restart

# FFI 인터페이스 변경 시
flutter_rust_bridge_codegen --rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./windows/runner/bridge_generated.h --llvm-path "${LLVM_PATH}"
```

### 3. 배포 빌드

```bash
# 릴리즈 빌드
cargo build --release --features flutter

# MSI 패키지 생성
./build_msi.sh <version> --version-up --sign
```

## 🛡️ 윈도우 서비스 설정

### 개발 환경에서 서비스 비활성화

현재 개발 버전에서는 **윈도우 서비스로 자동 실행되지 않도록** 관련 코드들이 주석처리되어 있습니다.

#### 주석처리된 서비스 관련 코드 위치:

##### 1. **MSI CustomActions 서비스 생성/시작 코드 주석처리**
**파일**: `res/msi/CustomActions/CustomActions.cpp` (753-810줄)

```cpp
// TryCreateStartServiceByShell 함수에서 서비스 생성 명령어 주석처리됨
// hr = StringCchPrintfW(szCmd, cchCmd, L"create %ls binpath= \"%ls\" start= demand DisplayName= \"%ls\"", 
//                       svcName, szNewBin, szSvcDisplayName);
// hi = ShellExecuteW(NULL, L"open", L"sc", szCmd, NULL, SW_HIDE);

// 서비스 시작 명령어도 주석처리됨  
// hr = StringCchPrintfW(szCmd, cchCmd, L"/c sc start %ls", svcName);
// hi = ShellExecuteW(NULL, L"open", L"cmd.exe", szCmd, NULL, SW_HIDE);
```

##### 2. **Rust 윈도우 플랫폼 서비스 코드 비활성화**
**파일**: `src/platform/windows.rs` (2260-2285줄)

```rust
// 서비스 설치 함수 주석처리됨
// pub fn install_service() -> ResultType<()> {
//     let cmd = std::env::current_exe()?;
//     let args = vec!["--service"];
//     // ... 서비스 설치 로직
// }

// 서비스 제거 함수도 주석처리됨
// pub fn uninstall_service() -> ResultType<()> {
//     // ... 서비스 제거 로직  
// }
```

##### 3. **WiX 설치 패키지 서비스 관련 주석처리**
**파일**: `res/msi/Package/Components/RustDesk.wxs` (9줄, 46줄)

```xml
<!-- 방화벽 예외 주석처리됨 -->
<!--<fire:FirewallException Id="AppEx" Name="$(var.Product) Service" Scope="any" IgnoreFailure="yes" />-->

<!-- 서비스 생성 및 시작 커스텀 액션 매개변수 설정 주석처리됨 -->
<!-- <Custom Action="CreateStartService.SetParam" Before="CreateStartService" 
         Condition="(NOT (Installed AND REMOVE AND NOT UPGRADINGPRODUCTCODE)) AND (NOT STOP_SERVICE=&quot;&apos;Y&apos;&quot;) AND (NOT CC_CONNECTION_TYPE=&quot;outgoing&quot;)" /> -->
```

##### 4. **ServiceUtils.cpp 서비스 생성 함수**
**파일**: `res/msi/CustomActions/ServiceUtils.cpp`

```cpp
// 서비스 생성 함수는 구현되어 있지만 CustomActions.cpp에서 호출이 주석처리됨
bool MyCreateServiceW(LPCWSTR serviceName, LPCWSTR displayName, LPCWSTR binaryPath)
{
    // SERVICE_AUTO_START로 설정되어 있어 활성화 시 자동 시작됨
    schService = CreateServiceW(
        schSCManager,              // SCM database 
        serviceName,               // name of service 
        displayName,               // service name to display 
        SERVICE_ALL_ACCESS,        // desired access 
        SERVICE_WIN32_OWN_PROCESS, // service type 
        SERVICE_AUTO_START,        // start type (자동 시작)
        SERVICE_ERROR_NORMAL,      // error control type 
        binaryPath,                // path to service's binary 
        // ...
    );
}
```

### 서비스 활성화 방법 (필요시)

#### 1. **MSI CustomActions 서비스 생성/시작 코드 활성화**
```cpp
// res/msi/CustomActions/CustomActions.cpp의 TryCreateStartServiceByShell 함수에서 주석 제거
hr = StringCchPrintfW(szCmd, cchCmd, L"create %ls binpath= \"%ls\" start= demand DisplayName= \"%ls\"", 
                      svcName, szNewBin, szSvcDisplayName);
hi = ShellExecuteW(NULL, L"open", L"sc", szCmd, NULL, SW_HIDE);

// 서비스 시작 코드도 활성화
hr = StringCchPrintfW(szCmd, cchCmd, L"/c sc start %ls", svcName);
hi = ShellExecuteW(NULL, L"open", L"cmd.exe", szCmd, NULL, SW_HIDE);
```

#### 2. **Rust 서비스 함수 활성화**
```rust
// src/platform/windows.rs에서 주석 제거
pub fn install_service() -> ResultType<()> {
    // 서비스 설치 로직 구현
}

pub fn uninstall_service() -> ResultType<()> {
    // 서비스 제거 로직 구현
}
```

#### 3. **WiX 방화벽 예외 및 서비스 액션 활성화**
```xml
<!-- res/msi/Package/Components/RustDesk.wxs에서 주석 제거 -->
<!-- 방화벽 예외 활성화 -->
<fire:FirewallException Id="AppEx" Name="$(var.Product) Service" Scope="any" IgnoreFailure="yes" />

<!-- 서비스 생성 및 시작 커스텀 액션 활성화 -->
<Custom Action="CreateStartService.SetParam" Before="CreateStartService" 
        Condition="(NOT (Installed AND REMOVE AND NOT UPGRADINGPRODUCTCODE)) AND (NOT STOP_SERVICE=&quot;&apos;Y&apos;&quot;) AND (NOT CC_CONNECTION_TYPE=&quot;outgoing&quot;)" />
```
## ⚠️ 문제 해결

### 일반적인 오류 및 해결책

#### 1. `Failed to get rustdesk_core_main`
```bash
run_cs.sh 또는 run_member.sh 실행시 에러
```

#### 2. `LLVM path not found`
```bash
# 원인: LLVM 경로 설정 문제
# 해결책:
# 1. LLVM_PATH 환경변수 확인
echo $env:LLVM_PATH  # PowerShell

# 2. run_cs.sh 스크립트에서 수동 지정
--llvm-path "C:/LLVM"
```

#### 3. `flutter command not found`
```bash
# 원인: Flutter가 PATH에 없음
# 해결책:
# Flutter 설치 확인 및 PATH 추가
flutter doctor -v
```

#### 4. `vcpkg libraries not found`
```bash
# 원인: vcpkg 라이브러리 미설치 또는 환경변수 문제
# 해결책:
echo $env:VCPKG_ROOT
vcpkg list  # 설치된 패키지 확인
```

#### 5. `MSBuild not found`
```bash
# 원인: Visual Studio 미설치 또는 PATH 문제
# 해결책:
# Visual Studio 2022 Community 설치
# MSBuild PATH 확인
where MSBuild.exe
```

### 디버깅 명령어

```bash
# 환경 진단
flutter doctor -v
cargo --version
rustc --version
python --version

# 의존성 확인
cargo check
flutter pub deps

# 빌드 로그 확인
cargo build --features flutter --verbose
flutter build windows --verbose
```

## 📚 추가 리소스

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Rust 공식 문서](https://doc.rust-lang.org/)
- [vcpkg 문서](https://vcpkg.io/)
- [Flutter Rust Bridge](https://github.com/fzyzcjy/flutter_rust_bridge)

## 🔄 업데이트 가이드

```bash
# Flutter 업데이트
flutter upgrade

# Rust 업데이트
rustup update

# vcpkg 업데이트
cd vcpkg
git pull
./bootstrap-vcpkg.sh  # 또는 .bat

# 의존성 재설치
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static
```

---

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. 모든 환경변수가 올바르게 설정되었는지 확인
2. 필수 도구들이 모두 설치되었는지 확인
3. 빌드 로그에서 구체적인 오류 메시지 확인
4. 이 가이드의 문제 해결 섹션 참조

**마지막 업데이트:** 2024년 3월 