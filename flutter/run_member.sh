#!/usr/bin/env bash

cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
flutter pub get
# LLVM_PATH 환경변수 설정 (Windows에서)
export LLVM_HOME="${LLVM_PATH:-C:/LLVM}"
~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ../src/flutter_ffi.rs --dart-output ./lib/generated_bridge.dart --c-output ./windows/runner/bridge_generated.h --llvm-path "${LLVM_PATH:-C:/LLVM}"
# call `flutter clean` if cargo build fails
# export LLVM_HOME=/Library/Developer/CommandLineTools/usr/

cargo build --features flutter
flutter run $@ --dart-define=FLAVOR=member lib/main_member.dart
