# AGENTS.md

Agent guidance for `mathmate` (Flutter/Dart).

This file is intended for autonomous coding agents working in this repository.
Follow these conventions unless the user explicitly overrides them.

## Project Snapshot

- Stack: Flutter app (`lib/`, `test/`, platform folders for Android/iOS/Web/Desktop).
- Language: Dart (SDK constraint in `pubspec.yaml`: `^3.11.3`).
- Lint baseline: `flutter_lints` via `analysis_options.yaml`.
- Current scope: early-stage app scaffold with one widget test.

## Rule Sources (Cursor/Copilot)

- Checked for Cursor rules in `.cursor/rules/` and `.cursorrules`: none found.
- Checked for Copilot rules in `.github/copilot-instructions.md`: none found.
- If any of these files are added later, treat them as additional required constraints.
- When rules conflict, prioritize explicit user instructions, then repo rule files, then this document.

## Environment and Setup

- Install Flutter SDK compatible with Dart `^3.11.3`.
- From repo root, run dependency install before analysis/tests/build:
- Command: `flutter pub get`
- Verify toolchain:
- Command: `flutter doctor`

## Core Commands

### Run App

- Debug run on connected device/emulator: `flutter run`
- Select a specific device: `flutter devices` then `flutter run -d <device-id>`

### Format

- Format all Dart code: `dart format .`
- Format a specific file: `dart format lib/main.dart`
- Check-only formatting (CI friendly): `dart format --output=none --set-exit-if-changed .`

### Lint / Static Analysis

- Primary lint/analyzer command: `flutter analyze`
- Analyze a specific path: `flutter analyze lib`

### Tests

- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Run a single test by name (preferred):
- `flutter test --plain-name "Counter increments smoke test" test/widget_test.dart`
- Alternate name filter (regex): `flutter test --name "Counter.*smoke"`
- Machine output (CI/debugging): `flutter test --machine`

### Builds

- Android APK (debug): `flutter build apk --debug`
- Android APK (release): `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- iOS (requires macOS/Xcode): `flutter build ios --release`
- Web: `flutter build web --release`
- Linux/macOS/Windows desktop (if enabled):
- `flutter build linux --release`
- `flutter build macos --release`
- `flutter build windows --release`

## Suggested Local Validation Sequence

- 1) `flutter pub get`
- 2) `dart format --output=none --set-exit-if-changed .`
- 3) `flutter analyze`
- 4) `flutter test`
- 5) Run targeted build command for affected platform when relevant.

## Repository Structure Guidance

- App entrypoint: `lib/main.dart`.
- Tests: `test/` (currently widget-test focused).
- Product planning notes: `Plan/Plan.md` (Chinese-language planning doc).
- Keep feature code in `lib/` and mirror tests under `test/`.

## Dart and Flutter Style Guidelines

### Formatting and General Style

- Always run `dart format` after code edits.
- Use trailing commas in multiline widget trees for stable formatting.
- Prefer small, composable widgets over long `build` methods.
- Avoid commented-out dead code and stale TODO blocks.
- Keep files focused; split large UI trees into private widgets/helpers.

### Imports

- Prefer package imports for project files (e.g., `package:mathmate/...`).
- Order imports in groups: Dart SDK, Flutter/package deps, local package imports.
- Keep one import per line.
- Remove unused imports before finalizing changes.
- Avoid relative parent imports like `../` when package import is viable.

### Types and Null Safety

- Use explicit types when they improve readability.
- Use `final` by default; use `const` where values/widgets are compile-time constant.
- Avoid `dynamic` unless truly necessary and documented.
- Respect null safety: model nullable values explicitly (`Type?`).
- Use late variables sparingly and only when initialization cannot happen at declaration.

### Naming Conventions

- Classes/enums/typedefs: `PascalCase`.
- Variables/functions/parameters: `lowerCamelCase`.
- Files/directories: `snake_case`.
- Constants: `lowerCamelCase` for Dart style; avoid Java-style ALL_CAPS.
- Private symbols: prefix with `_`.
- Use clear domain names (e.g., `cameraButton`, not generic `btn1`).

### Widget and UI Patterns

- Prefer `StatelessWidget` unless mutable state is needed.
- Use `const` constructors/widgets whenever possible.
- Keep side effects out of `build`; move to callbacks/controllers/services.
- For async UI actions, handle loading and error states explicitly.
- Keep theme/styling centralized; avoid hardcoded magic numbers repeated across files.

### State and Logic

- Keep business logic outside widget tree where practical.
- Separate pure computation from UI rendering for testability.
- When adding state management libraries, document the chosen pattern in README/AGENTS update.

### Error Handling

- Do not silently swallow exceptions.
- Catch specific exceptions when possible.
- Provide user-safe error messages in UI; keep internals in logs.
- Use `debugPrint` for development diagnostics (instead of `print`).
- For async code, always await futures that must complete and handle failures.

### Testing Standards

- Add or update tests for behavior changes.
- Prefer focused tests with descriptive names.
- Keep widget tests deterministic (avoid real network/time dependencies).
- Use finders/assertions that verify user-visible behavior.
- For bug fixes, include a regression test when practical.

## Lint Notes

- Lints come from `package:flutter_lints/flutter.yaml`.
- Do not add blanket `ignore_for_file` unless absolutely necessary.
- If suppressing a lint on one line, justify it with a short rationale comment.

## Agent Execution Expectations

- Make minimal, targeted changes consistent with existing code patterns.
- Prefer updating existing files over introducing new abstractions too early.
- Before running build tasks or Bash commands, ask the user for confirmation first.
- If a command fails, report the failure and likely cause concisely.
- Do not commit or push unless explicitly requested by the user.
- Before handoff, list changed files and mention which checks were run.

## Known Current Caveat

- `test/widget_test.dart` appears to be the default counter test and may not match current UI in `lib/main.dart`.
- If touching UI/app structure, update this test accordingly so `flutter test` reflects real behavior.

## 代码开发与整合规约 (Development & Integration Protocol)

### 1. 角色定义
你现在担任 **Flutter/Dart 全栈开发工程师**，可以直接：
- 编写新功能代码
- 创建新文件 / 新组件 / 新工具类
- 修改现有文件实现需求
- 修复 Bug、优化结构
- 按规范自动生成符合项目风格的完整代码

### 2. 工作模式（二选一）
1. **功能开发模式（默认）**
   - 直接根据用户需求写代码
   - 直接修改 `/lib/` 下的文件
   - 可新建文件、新建类、新建组件
   - 代码必须符合本文件所有规范

2. **代码整合模式**
   - 仅当用户明确说「整合代码」「同步 raw_code」时触发
   - 从 `./raw_code_preview/` 合并到 `./lib/`
   - 必须先给变更概要 → 等待确认 → 再写入

### 3. 目录规则
- 主项目代码：`./lib/`（你可以直接修改）
- 暂存区代码：`./raw_code_preview/`（仅整合时使用）
- 新功能优先放在对应目录：
  - UI 组件 → `lib/widgets/`
  - 页面 → `lib/pages/`
  - 工具类 → `lib/utils/`
  - 服务/逻辑 → `lib/services/`

### 4. 开发行为规则
- 可以**直接生成完整代码**，不需要等待确认再写逻辑
- 修改前会**简要说明要改什么**
- 新建文件会**告知文件路径**
- 代码必须遵循：dart format、flutter_lints、空安全、项目命名规范
- 完成后自动给出：修改清单 + 可运行的代码
## 功能开发授权
用户现在需要你**直接开发新功能**，不再仅限于代码整合。
你可以：
✅ 直接修改 lib/ 下的文件
✅ 直接创建新文件、新组件、新类
✅ 直接根据需求写完整 Flutter 代码
✅ 直接写页面、组件、逻辑、工具类