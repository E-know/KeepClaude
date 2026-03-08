# KeepClaude - Claude Code Settings Sync for macOS

## 프로젝트 개요

Claude Code의 설정(plugins, skills, commands, hooks 등)을 GitHub 저장소에 백업/동기화하는 **macOS 네이티브 앱**.
컴퓨터가 바뀌어도 GitHub에서 설정을 불러와 동일한 Claude Code 환경을 즉시 복원할 수 있다.

- **저장(Push)**: GitHub 저장소 소유자만 가능 (인증 필요)
- **불러오기(Pull)**: 누구나 가능 (public repo인 경우 인증 불필요)

## 기술 스택

| 항목 | 선택 |
|------|------|
| 언어 | Swift 6 |
| UI 프레임워크 | SwiftUI |
| 최소 지원 | macOS 15.0 (Sequoia) |
| 프로젝트 관리 | **Tuist 4.x** (`tuist generate`로 Xcode workspace 생성) |
| GitHub 연동 | GitHub REST API v3 (URLSession, 외부 의존성 없음) |
| 인증 | Personal Access Token (PAT) → macOS Keychain 저장 |
| 아키텍처 | **VIP** (View-Interactor-Presenter) |
| 네트워크 계층 | **Worker → Repository → Service** |
| 설계 원칙 | **Protocol-Oriented Programming** |
| 동시성 | Swift Concurrency (async/await) |

---

## 아키텍처 개요

### VIP 사이클

```
┌──────────┐  Action   ┌──────────────┐  Response  ┌───────────┐
│   View   │ ────────▶ │  Interactor  │ ─────────▶ │ Presenter │
│ (SwiftUI)│           │              │            │           │
│          │ ◀──────── │              │            │           │
└──────────┘ ViewModel └──────────────┘            └───────────┘
                              │
                              ▼
                        ┌──────────┐
                        │  Worker  │
                        └──────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │  Repository  │
                       └──────────────┘
                              │
                              ▼
                        ┌───────────┐
                        │  Service  │
                        └───────────┘
                              │
                              ▼
                    (GitHub API / FileSystem / Keychain)
```

### 레이어 역할

| 레이어 | 역할 | Protocol |
|--------|------|----------|
| **View** | SwiftUI 뷰. Action → Interactor, ViewModel 바인딩으로 렌더링 | - |
| **Interactor** | 비즈니스 로직. Action 수신 → Worker 호출 → Response를 Presenter에 전달 | `~Interacting` |
| **Presenter** | Response → ViewModel 변환 (포맷팅, 상태 매핑) | `~Presenting` |
| **ViewModel** | `@Observable` 뷰 상태. Presenter가 직접 갱신 | - |
| **Worker** | 유스케이스 단위. Repository 조합하여 작업 수행 | `~Working` |
| **Repository** | 데이터 소스 추상화. Service 호출 → Entity 변환 | `~RepositoryProtocol` |
| **Service** | 실제 I/O (네트워크, 파일, Keychain) | `~Servicing` |
| **Entity** | 공유 도메인 모델 | `Codable`, `Sendable` |

---

## Feature-Based 프로젝트 구조

```
KeepClaude/
├── Tuist/
│   └── Package.swift
├── Project.swift
│
├── App/
│   ├── Sources/
│   │   ├── KeepClaudeApp.swift
│   │   │
│   │   ├── Features/                          # ── Feature 단위 그룹 ──
│   │   │   │
│   │   │   ├── Dashboard/                     # 설정 현황 Feature
│   │   │   │   ├── Scene/
│   │   │   │   │   ├── DashboardProtocols.swift    # Interacting, Presenting 프로토콜
│   │   │   │   │   ├── DashboardAction.swift
│   │   │   │   │   ├── DashboardResponse.swift
│   │   │   │   │   ├── DashboardViewModel.swift    # @Observable
│   │   │   │   │   ├── DashboardView.swift
│   │   │   │   │   ├── DashboardInteractor.swift
│   │   │   │   │   ├── DashboardPresenter.swift
│   │   │   │   │   └── DashboardConfigurator.swift
│   │   │   │   └── Domain/
│   │   │   │       └── SettingsTreeNode.swift       # Dashboard 전용 모델
│   │   │   │
│   │   │   ├── Push/                          # GitHub 저장 Feature
│   │   │   │   ├── Scene/
│   │   │   │   │   ├── PushProtocols.swift
│   │   │   │   │   ├── PushAction.swift
│   │   │   │   │   ├── PushResponse.swift
│   │   │   │   │   ├── PushViewModel.swift
│   │   │   │   │   ├── PushView.swift
│   │   │   │   │   ├── PushInteractor.swift
│   │   │   │   │   ├── PushPresenter.swift
│   │   │   │   │   └── PushConfigurator.swift
│   │   │   │   └── Domain/
│   │   │   │       └── PushDiffItem.swift           # Push 전용 모델
│   │   │   │
│   │   │   ├── Pull/                          # GitHub 불러오기 Feature
│   │   │   │   ├── Scene/
│   │   │   │   │   ├── PullProtocols.swift
│   │   │   │   │   ├── PullAction.swift
│   │   │   │   │   ├── PullResponse.swift
│   │   │   │   │   ├── PullViewModel.swift
│   │   │   │   │   ├── PullView.swift
│   │   │   │   │   ├── PullInteractor.swift
│   │   │   │   │   ├── PullPresenter.swift
│   │   │   │   │   └── PullConfigurator.swift
│   │   │   │   └── Domain/
│   │   │   │       └── RestoreOption.swift           # Pull 전용 모델
│   │   │   │
│   │   │   └── AppSettings/                   # 앱 설정 Feature
│   │   │       ├── Scene/
│   │   │       │   ├── AppSettingsProtocols.swift
│   │   │       │   ├── AppSettingsAction.swift
│   │   │       │   ├── AppSettingsResponse.swift
│   │   │       │   ├── AppSettingsViewModel.swift
│   │   │       │   ├── AppSettingsView.swift
│   │   │       │   ├── AppSettingsInteractor.swift
│   │   │       │   ├── AppSettingsPresenter.swift
│   │   │       │   └── AppSettingsConfigurator.swift
│   │   │       └── Domain/
│   │   │           └── AppConfig.swift
│   │   │
│   │   ├── Data/                              # ── Entity + Worker + Repository ──
│   │   │   │
│   │   │   ├── Entities/                      # 공유 도메인 모델
│   │   │   │   ├── ClaudeSettings.swift
│   │   │   │   ├── CoreSettings.swift
│   │   │   │   ├── PluginSettings.swift
│   │   │   │   ├── SkillDefinition.swift
│   │   │   │   ├── CommandDefinition.swift
│   │   │   │   ├── SoundFile.swift
│   │   │   │   ├── SettingsCategory.swift
│   │   │   │   ├── SettingsDiff.swift
│   │   │   │   ├── Manifest.swift
│   │   │   │   ├── GitHubUser.swift
│   │   │   │   └── GitHubRepo.swift
│   │   │   │
│   │   │   ├── Workers/                       # 유스케이스 단위
│   │   │   │   ├── Protocols/
│   │   │   │   │   ├── SettingsScanWorking.swift
│   │   │   │   │   ├── GitHubPushWorking.swift
│   │   │   │   │   ├── GitHubPullWorking.swift
│   │   │   │   │   ├── SettingsRestoreWorking.swift
│   │   │   │   │   └── AuthWorking.swift
│   │   │   │   ├── SettingsScanWorker.swift
│   │   │   │   ├── GitHubPushWorker.swift
│   │   │   │   ├── GitHubPullWorker.swift
│   │   │   │   ├── SettingsRestoreWorker.swift
│   │   │   │   └── AuthWorker.swift
│   │   │   │
│   │   │   └── Repositories/                  # 데이터 소스 추상화
│   │   │       ├── Protocols/
│   │   │       │   ├── ClaudeSettingsRepositoryProtocol.swift
│   │   │       │   ├── GitHubRepositoryProtocol.swift
│   │   │       │   └── AuthRepositoryProtocol.swift
│   │   │       ├── ClaudeSettingsRepository.swift
│   │   │       ├── GitHubRepository.swift
│   │   │       └── AuthRepository.swift
│   │   │
│   │   ├── Infrastructure/                    # ── Service (실제 I/O) ──
│   │   │   ├── Protocols/
│   │   │   │   ├── GitHubAPIServicing.swift
│   │   │   │   ├── FileSystemServicing.swift
│   │   │   │   └── KeychainServicing.swift
│   │   │   ├── GitHubAPIService.swift
│   │   │   ├── FileSystemService.swift
│   │   │   ├── KeychainService.swift
│   │   │   └── Networking/
│   │   │       ├── GitHubEndpoint.swift
│   │   │       ├── GitHubDTO.swift
│   │   │       └── NetworkError.swift
│   │   │
│   │   └── Shared/                            # ── 공통 유틸 ──
│   │       ├── PathSubstitution.swift
│   │       ├── Constants.swift
│   │       └── Components/                    # 재사용 SwiftUI 뷰
│   │           ├── SettingsTreeView.swift
│   │           └── DiffView.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
│
├── Tests/
│   └── Sources/
│       ├── Workers/
│       ├── Repositories/
│       └── Services/
│
├── PROMPT.md
└── README.md
```

### 의존성 방향 (단방향)

```
Features/*/Scene  →  Data/Workers  →  Data/Repositories  →  Infrastructure/Services
       │                   │                  │                       │
       │                   │                  │                       │
       ▼                   ▼                  ▼                       ▼
  Feature/Domain     Data/Entities      Data/Entities           Networking/
                                                               GitHubDTO
```

- **Feature → Data → Infrastructure** 순서로만 의존
- 역방향 의존 금지 (Infrastructure가 Data를, Data가 Feature를 알면 안 됨)
- 모든 계층 간 통신은 **Protocol**을 통해서만 수행

---

## Protocol-Oriented 설계

### Feature Scene Protocols (각 Feature 내부)

```swift
// Features/Dashboard/Scene/DashboardProtocols.swift

protocol DashboardInteracting: AnyObject, Sendable {
    func handleAction(_ action: DashboardAction)
}

protocol DashboardPresenting: AnyObject, Sendable {
    func present(_ response: DashboardResponse)
    func presentError(_ error: Error)
}
```

```swift
// Features/Push/Scene/PushProtocols.swift

protocol PushInteracting: AnyObject, Sendable {
    func handleAction(_ action: PushAction)
}

protocol PushPresenting: AnyObject, Sendable {
    func present(_ response: PushResponse)
    func presentError(_ error: Error)
}
```

### Worker Protocols

```swift
// Data/Workers/Protocols/SettingsScanWorking.swift

protocol SettingsScanWorking: Sendable {
    func scanSettings() async throws -> ClaudeSettings
}
```

```swift
// Data/Workers/Protocols/GitHubPushWorking.swift

protocol GitHubPushWorking: Sendable {
    func push(
        categories: Set<SettingsCategory>,
        message: String
    ) async throws
}
```

```swift
// Data/Workers/Protocols/GitHubPullWorking.swift

protocol GitHubPullWorking: Sendable {
    func fetchRemote(owner: String, repo: String) async throws -> ClaudeSettings
}
```

```swift
// Data/Workers/Protocols/SettingsRestoreWorking.swift

protocol SettingsRestoreWorking: Sendable {
    func backup() async throws -> URL
    func restore(
        _ settings: ClaudeSettings,
        categories: Set<SettingsCategory>
    ) async throws
}
```

```swift
// Data/Workers/Protocols/AuthWorking.swift

protocol AuthWorking: Sendable {
    func authenticate(token: String) async throws -> GitHubUser
    func loadSavedToken() throws -> String?
    func deleteToken() throws
}
```

### Repository Protocols

```swift
// Data/Repositories/Protocols/ClaudeSettingsRepositoryProtocol.swift

protocol ClaudeSettingsRepositoryProtocol: Sendable {
    func scan() async throws -> ClaudeSettings
    func backup() async throws -> URL
    func restore(
        _ settings: ClaudeSettings,
        categories: Set<SettingsCategory>
    ) async throws
}
```

```swift
// Data/Repositories/Protocols/GitHubRepositoryProtocol.swift

protocol GitHubRepositoryProtocol: Sendable {
    func fetchRemoteSettings(
        owner: String,
        repo: String,
        token: String?
    ) async throws -> ClaudeSettings

    func pushSettings(
        _ settings: ClaudeSettings,
        owner: String,
        repo: String,
        message: String,
        token: String
    ) async throws

    func compareWithRemote(
        local: ClaudeSettings,
        owner: String,
        repo: String,
        token: String?
    ) async throws -> SettingsDiff
}
```

```swift
// Data/Repositories/Protocols/AuthRepositoryProtocol.swift

protocol AuthRepositoryProtocol: Sendable {
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
    func validateToken(_ token: String) async throws -> GitHubUser
}
```

### Service Protocols

```swift
// Infrastructure/Protocols/GitHubAPIServicing.swift

protocol GitHubAPIServicing: Sendable {
    func request<T: Decodable & Sendable>(
        _ endpoint: GitHubEndpoint
    ) async throws -> T
    func requestRaw(_ endpoint: GitHubEndpoint) async throws -> Data
}
```

```swift
// Infrastructure/Protocols/FileSystemServicing.swift

protocol FileSystemServicing: Sendable {
    func readData(at url: URL) async throws -> Data
    func writeData(_ data: Data, to url: URL) async throws
    func listContents(of directory: URL) async throws -> [URL]
    func fileExists(at url: URL) -> Bool
    func fileSize(at url: URL) throws -> UInt64
    func modificationDate(at url: URL) throws -> Date
    func createDirectory(at url: URL) async throws
    func copyItem(from source: URL, to destination: URL) async throws
}
```

```swift
// Infrastructure/Protocols/KeychainServicing.swift

protocol KeychainServicing: Sendable {
    func save(token: String, for account: String) throws
    func load(for account: String) throws -> String?
    func delete(for account: String) throws
}
```

---

## VIP Scene 구현 예시 (Dashboard)

### Action / Response

```swift
// Features/Dashboard/Scene/DashboardAction.swift

enum DashboardAction: Sendable {
    case onAppear
    case refresh
    case selectCategory(SettingsCategory)
}
```

```swift
// Features/Dashboard/Scene/DashboardResponse.swift

enum DashboardResponse: Sendable {
    case scanned(ClaudeSettings)
    case diffResult(SettingsDiff)
    case loading(Bool)
}
```

### ViewModel

```swift
// Features/Dashboard/Scene/DashboardViewModel.swift

@Observable
@MainActor
final class DashboardViewModel {
    var settingsTree: [SettingsTreeNode] = []
    var syncStatus: SyncStatus = .unknown
    var isLoading = false
    var errorMessage: String?
}

enum SyncStatus: Sendable {
    case unknown, synced, modified, neverSynced
}
```

### View → Interactor → Presenter → ViewModel

```swift
// Features/Dashboard/Scene/DashboardView.swift

struct DashboardView: View {
    let interactor: any DashboardInteracting
    @State var viewModel: DashboardViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                SettingsTreeView(nodes: viewModel.settingsTree)
            }
        }
        .onAppear {
            interactor.handleAction(.onAppear)
        }
        .toolbar {
            Button("새로고침", systemImage: "arrow.clockwise") {
                interactor.handleAction(.refresh)
            }
        }
    }
}
```

```swift
// Features/Dashboard/Scene/DashboardInteractor.swift

final class DashboardInteractor: DashboardInteracting {
    private let presenter: any DashboardPresenting
    private let scanWorker: any SettingsScanWorking

    init(presenter: any DashboardPresenting, scanWorker: any SettingsScanWorking) {
        self.presenter = presenter
        self.scanWorker = scanWorker
    }

    func handleAction(_ action: DashboardAction) {
        switch action {
        case .onAppear, .refresh:
            Task {
                presenter.present(.loading(true))
                do {
                    let settings = try await scanWorker.scanSettings()
                    presenter.present(.scanned(settings))
                } catch {
                    presenter.presentError(error)
                }
            }
        case .selectCategory(let category):
            break // ...
        }
    }
}
```

```swift
// Features/Dashboard/Scene/DashboardPresenter.swift

@MainActor
final class DashboardPresenter: DashboardPresenting {
    private let viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func present(_ response: DashboardResponse) {
        Task { @MainActor in
            switch response {
            case .scanned(let settings):
                viewModel.settingsTree = SettingsTreeMapper.map(settings)
                viewModel.isLoading = false
            case .diffResult(let diff):
                viewModel.syncStatus = diff.hasChanges ? .modified : .synced
            case .loading(let isLoading):
                viewModel.isLoading = isLoading
            }
        }
    }

    nonisolated func presentError(_ error: Error) {
        Task { @MainActor in
            viewModel.errorMessage = error.localizedDescription
            viewModel.isLoading = false
        }
    }
}
```

### Configurator (의존성 조립)

```swift
// Features/Dashboard/Scene/DashboardConfigurator.swift

enum DashboardConfigurator {
    @MainActor
    static func configure() -> (DashboardView, DashboardViewModel) {
        let viewModel = DashboardViewModel()

        // Infrastructure
        let fileSystemService: any FileSystemServicing = FileSystemService()

        // Repository
        let settingsRepo: any ClaudeSettingsRepositoryProtocol =
            ClaudeSettingsRepository(fileSystemService: fileSystemService)

        // Worker
        let scanWorker: any SettingsScanWorking =
            SettingsScanWorker(settingsRepository: settingsRepo)

        // Presenter
        let presenter: any DashboardPresenting =
            DashboardPresenter(viewModel: viewModel)

        // Interactor
        let interactor: any DashboardInteracting =
            DashboardInteractor(presenter: presenter, scanWorker: scanWorker)

        // View
        let view = DashboardView(interactor: interactor, viewModel: viewModel)
        return (view, viewModel)
    }
}
```

---

## Data 계층 구현

### Worker 구현 예시

```swift
// Data/Workers/GitHubPushWorker.swift

final class GitHubPushWorker: GitHubPushWorking {
    private let settingsRepo: any ClaudeSettingsRepositoryProtocol
    private let githubRepo: any GitHubRepositoryProtocol
    private let authRepo: any AuthRepositoryProtocol

    init(
        settingsRepo: any ClaudeSettingsRepositoryProtocol,
        githubRepo: any GitHubRepositoryProtocol,
        authRepo: any AuthRepositoryProtocol
    ) {
        self.settingsRepo = settingsRepo
        self.githubRepo = githubRepo
        self.authRepo = authRepo
    }

    func push(categories: Set<SettingsCategory>, message: String) async throws {
        guard let token = try authRepo.loadToken() else {
            throw AuthError.notAuthenticated
        }
        let user = try await authRepo.validateToken(token)
        var settings = try await settingsRepo.scan()
        settings.filter(by: categories)
        try await githubRepo.pushSettings(
            settings, owner: user.login, repo: "claude-settings",
            message: message, token: token
        )
    }
}
```

### Repository 구현 예시

```swift
// Data/Repositories/ClaudeSettingsRepository.swift

final class ClaudeSettingsRepository: ClaudeSettingsRepositoryProtocol {
    private let fileSystemService: any FileSystemServicing
    private let claudeDir: URL

    init(
        fileSystemService: any FileSystemServicing,
        claudeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".claude")
    ) {
        self.fileSystemService = fileSystemService
        self.claudeDir = claudeDirectory
    }

    func scan() async throws -> ClaudeSettings {
        // settings.json 읽기
        let settingsData = try await fileSystemService.readData(
            at: claudeDir.appending(path: "settings.json")
        )
        let coreSettings = try JSONDecoder().decode(CoreSettings.self, from: settingsData)

        // plugins, skills, commands, sounds 각각 스캔
        let plugins = try await scanPlugins()
        let skills = try await scanSkills()
        let commands = try await scanCommands()
        let sounds = try await scanSounds()

        return ClaudeSettings(
            coreSettings: coreSettings,
            plugins: plugins,
            skills: skills,
            commands: commands,
            sounds: sounds
        )
    }

    // backup(), restore() ...
}
```

---

## Claude Code 설정 파일 (동기화 대상)

### 동기화 대상 (`~/.claude/`)

| 파일/경로 | 설명 | 동기화 |
|-----------|------|--------|
| `settings.json` | 전역 설정 (permissions, hooks, statusLine, enabledPlugins, language 등) | 필수 |
| `settings.local.json` | 로컬 오버라이드 | 선택 (기본 Off) |
| `keybindings.json` | 키바인딩 | 선택 |
| `plugins/installed_plugins.json` | 설치된 플러그인 목록 | 필수 |
| `plugins/known_marketplaces.json` | 마켓플레이스 정보 | 필수 |
| `plugins/config.json` | 플러그인 저장소 설정 | 선택 |
| `plugins/blocklist.json` | 차단 목록 | 선택 |
| `skills/*/SKILL.md` | 커스텀 스킬 정의 | 필수 |
| `commands/*.md` | 슬래시 커맨드 정의 | 필수 |
| `sound/*.aiff` | 알림 사운드 | 선택 |

### 동기화 제외

`history.jsonl`, `projects/`, `debug/`, `cache/`, `telemetry/`, `todos/`, `tasks/`, `teams/`, `file-history/`, `shell-snapshots/`, `session-env/`, `stats-cache.json`, `mcp-needs-auth-cache.json`, `.DS_Store`, `paste-cache/`, `plans/`, `backups/`, `plugins/cache/`, `plugins/marketplaces/`

---

## GitHub 저장소 구조 (Push 결과)

```
(저장소 루트)/
├── manifest.json
├── settings.json
├── settings.local.json          # (선택)
├── keybindings.json             # (선택)
├── plugins/
│   ├── installed_plugins.json
│   ├── known_marketplaces.json
│   ├── config.json
│   └── blocklist.json
├── skills/
│   ├── commit/SKILL.md
│   ├── scrapling-web-fetch/SKILL.md
│   └── swift-docc-comments/SKILL.md
├── commands/
│   └── commit.md
└── sounds/
    ├── alert.aiff
    └── end.aiff
```

### manifest.json

```json
{
  "version": "1.0",
  "appVersion": "1.0.0",
  "syncedAt": "2026-03-07T14:00:00Z",
  "syncedBy": "inhochoi",
  "platform": { "os": "macOS", "osVersion": "26.3.1" },
  "categories": {
    "coreSettings": true, "localSettings": false,
    "keybindings": false, "plugins": true,
    "skills": true, "commands": true, "sounds": true
  },
  "summary": {
    "pluginCount": 4, "skillCount": 3,
    "commandCount": 1, "soundCount": 2
  }
}
```

---

## 보안

1. **PAT**: macOS Keychain 저장 (Security framework)
2. **경로 치환**:
   - Push: `/Users/username/.claude/` → `{{CLAUDE_DIR}}/`, `/Users/username/` → `{{HOME}}/`
   - Pull: 플레이스홀더 → 현재 사용자 실제 경로
3. **settings.local.json**: 기본 비동기화 (명시적 선택 필요)
4. **복원 전 백업**: `~/.claude/backups/{timestamp}/` 에 자동 백업

---

## GitHub API 엔드포인트

| 기능 | 엔드포인트 | 메서드 |
|------|-----------|--------|
| 인증 확인 | `/user` | GET |
| 저장소 확인 | `/repos/{owner}/{repo}` | GET |
| 저장소 생성 | `/user/repos` | POST |
| 파일 읽기 | `/repos/{owner}/{repo}/contents/{path}` | GET |
| 파일 쓰기 | `/repos/{owner}/{repo}/contents/{path}` | PUT |
| 트리 생성 | `/repos/{owner}/{repo}/git/trees` | POST |
| 커밋 생성 | `/repos/{owner}/{repo}/git/commits` | POST |
| ref 조회 | `/repos/{owner}/{repo}/git/ref/{ref}` | GET |
| ref 업데이트 | `/repos/{owner}/{repo}/git/refs/{ref}` | PATCH |

> 여러 파일 Push: Git Data API (tree → commit → ref update)로 단일 커밋 처리.

---

## 앱 화면 구성

### 메인 (NavigationSplitView)

사이드바: GitHub 연결 상태 + 메뉴 (Dashboard / Push / Pull / Settings)

### Dashboard

`~/.claude/` 설정 파일을 트리 형태로 표시. 파일 존재 여부, 크기, GitHub와의 동기화 상태(변경됨/동일/신규/삭제됨) 시각화.

### Push

카테고리별 체크박스 선택 → diff 미리보기 → 커밋 메시지 입력 → Push 실행.

### Pull

저장소 URL 입력 (또는 저장된 저장소) → 원격 내용 미리보기 → 복원 항목 선택 → 충돌 처리 (유지/덮어쓰기) → 복원 실행.

### Settings

GitHub PAT 연결/해제, 기본 저장소 설정(owner/repo), 동기화 제외 패턴, 백업 경로 설정.

---

## Tuist 설정

### Project.swift

```swift
import ProjectDescription

let project = Project(
    name: "KeepClaude",
    targets: [
        .target(
            name: "KeepClaude",
            destinations: .macOS,
            product: .app,
            bundleId: "com.inhochoi.KeepClaude",
            deploymentTargets: .macOS("15.0"),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            settings: .settings(
                base: ["SWIFT_VERSION": "6.0"]
            )
        ),
        .target(
            name: "KeepClaudeTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.inhochoi.KeepClaudeTests",
            sources: ["Tests/Sources/**"],
            dependencies: [.target(name: "KeepClaude")]
        )
    ]
)
```

---

## 개발 순서

### Phase 1: 프로젝트 세팅 + 설정 스캔
1. `Project.swift` 작성 → `tuist generate`
2. Entity 정의 (`ClaudeSettings`, `SettingsCategory` 등)
3. Infrastructure: `FileSystemService` + Protocol
4. Repository: `ClaudeSettingsRepository` + Protocol
5. Worker: `SettingsScanWorker` + Protocol
6. Feature/Dashboard VIP 씬 구현

### Phase 2: GitHub 연동 + Push
7. Infrastructure: `GitHubAPIService`, `KeychainService` + Protocols
8. Networking: `GitHubEndpoint`, `GitHubDTO`, `NetworkError`
9. Repository: `GitHubRepository`, `AuthRepository` + Protocols
10. Worker: `AuthWorker`, `GitHubPushWorker` + Protocols
11. Feature/AppSettings VIP 씬
12. Feature/Push VIP 씬

### Phase 3: Pull + 복원
13. Worker: `GitHubPullWorker`, `SettingsRestoreWorker` + Protocols
14. Feature/Pull VIP 씬
15. `PathSubstitution` 유틸
16. 백업/복원 로직

### Phase 4: 마무리
17. 에러 처리 + 사용자 피드백
18. 테스트 (Worker / Repository / Service 계층별)
19. README

---

## 디자인

- macOS 네이티브 (NavigationSplitView, Form, GroupBox)
- SF Symbols
- 다크/라이트 모드
- Claude 브랜드 컬러 포인트 (주황/베이지)

## 명령어

```bash
tuist generate    # Xcode workspace 생성
tuist build       # 빌드
tuist clean       # 캐시 정리
tuist edit        # Project.swift 편집
open KeepClaude.xcworkspace
```

## 주의사항

- `plugins/cache/`, `plugins/marketplaces/` 절대 동기화 금지
- `settings.json` 내 절대 경로 → 플레이스홀더 치환 필수
- GitHub API rate limit 고려
- 모든 Protocol에 `Sendable` 준수 (Swift 6 동시성 안전)
- Feature 간 직접 의존 금지 — 공유 데이터는 Data/Entities를 통해서만
