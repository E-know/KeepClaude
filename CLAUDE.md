# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**KeepClaude** — Claude Code 설정(`~/.claude/`)을 GitHub 저장소에 백업/동기화하는 macOS 네이티브 앱.

## 빌드 & 실행

```bash
tuist generate                    # Xcode workspace 생성 (프로젝트 변경 시 필수)
tuist build                       # CLI 빌드
tuist clean                       # 캐시 정리
tuist edit                        # Project.swift 편집 (Xcode에서)
open KeepClaude.xcworkspace       # Xcode에서 열기
```

### 테스트

```bash
tuist test                        # 전체 테스트 실행
```

Xcode에서 개별 테스트: `Tests/Sources/` 내 파일 열고 테스트 함수 옆 다이아몬드 클릭.
테스트 프레임워크: **Swift Testing** (`@Test` 매크로, XCTest 아님).

## 기술 스택

- **Swift 6** (strict concurrency) / **SwiftUI** / **macOS 15.0+**
- **Tuist 4.x** 프로젝트 관리
- 외부 의존성 없음 (URLSession, Security framework만 사용)

## 아키텍처: VIP + Protocol-Oriented

```
View → (Action) → Interactor → (Response) → Presenter → ViewModel(@Observable)
                      ↓
                    Worker → Repository → Service → (GitHub API / FileSystem / Keychain)
```

### 레이어 규칙

- **단방향 의존**: Feature → Data → Infrastructure. 역방향 금지.
- **모든 계층 간 통신은 Protocol**을 통해서만 수행.
- 모든 Protocol에 `Sendable` 준수 (Swift 6 동시성).
- Presenter 메서드는 `nonisolated`로 선언, 내부에서 `Task { @MainActor in ... }`으로 ViewModel 갱신.
- Feature 간 직접 의존 금지 — 공유 데이터는 `Data/Entities/`를 통해서만.

### VIP 씬 구성 (Feature당)

| 파일 | 역할 |
|------|------|
| `{Feature}Protocols.swift` | `~Interacting`, `~Presenting` 프로토콜 |
| `{Feature}Action.swift` | View → Interactor 전달 enum |
| `{Feature}Response.swift` | Interactor → Presenter 전달 enum |
| `{Feature}ViewModel.swift` | `@Observable @MainActor` 뷰 상태 |
| `{Feature}View.swift` | SwiftUI 뷰 |
| `{Feature}Interactor.swift` | 비즈니스 로직, Worker 호출 |
| `{Feature}Presenter.swift` | Response → ViewModel 변환 |
| `{Feature}Configurator.swift` | 의존성 조립 (`static func configure()`) |

### Data 계층

| 계층 | 네이밍 패턴 | 프로토콜 패턴 |
|------|------------|--------------|
| Worker | `{Name}Worker` | `{Name}Working` |
| Repository | `{Name}Repository` | `{Name}RepositoryProtocol` |
| Service | `{Name}Service` | `{Name}Servicing` |

### 4개 Feature

- **Dashboard**: `~/.claude/` 설정 트리 시각화
- **Push**: 선택한 카테고리를 GitHub에 업로드
- **Pull**: GitHub에서 설정 다운로드 및 복원
- **AppSettings**: GitHub PAT 관리, 언어 설정, 저장소 설정

## 핵심 구현 사항

### 경로 치환 (PathSubstitution)

Push 시 절대 경로를 플레이스홀더로 치환, Pull 시 복원:
- `/Users/username/.claude/` → `{{CLAUDE_DIR}}/`
- `/Users/username/` → `{{HOME}}/`

### GitHub Multi-File Push

Git Data API 사용: blob 생성 → tree 생성 → commit 생성 → ref 업데이트 (단일 커밋).

### 동기화 제외 경로

`history.jsonl`, `projects/`, `debug/`, `cache/`, `telemetry/`, `todos/`, `tasks/`, `teams/`, `file-history/`, `shell-snapshots/`, `session-env/`, `stats-cache.json`, `.DS_Store`, `paste-cache/`, `plans/`, `backups/`, `plugins/cache/`, `plugins/marketplaces/`

### 보안

- PAT는 macOS Keychain에만 저장 (Security framework)
- 복원 전 자동 백업: `~/.claude/backups/keepclaude_{timestamp}/`

## 다국어 지원

- 한국어(ko, 개발 기본), 영어(en), 일본어(ja)
- `App/Resources/Localizable.xcstrings` (Xcode 16 형식)
- `String(localized:)` 매크로 사용

## 테스트 구조

Mock 기반 의존성 주입으로 Worker/Repository 계층 테스트:
- `MockFileSystemService`, `MockKeychainService`, `MockGitHubAPIService`
- `Tests/Sources/` 하위에 Workers, Repositories 단위 테스트

## 주의사항

- `Project.swift` 수정 후 반드시 `tuist generate` 실행
- `settings.json` 내 절대 경로는 반드시 플레이스홀더 치환
- GitHub API rate limit 고려 (NetworkError.rateLimited 처리)
- SettingsCategory 기본 활성: coreSettings, plugins, skills, commands / 기본 비활성: localSettings, keybindings, sounds
