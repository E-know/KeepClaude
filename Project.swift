import ProjectDescription

let project = Project(
    name: "KeepClaude",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "P2UJWPTGRX",
            "SWIFT_VERSION": "6.0"
        ]
    ),
    targets: [
        .target(
            name: "KeepClaude",
            destinations: .macOS,
            product: .app,
            bundleId: "com.inhochoi.KeepClaude",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "KeepClaude",
                "NSHumanReadableCopyright": "Copyright (c) 2026 Inho Choi"
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            defaultLocalization: "ko",
            entitlements: .dictionary([
                "com.apple.security.app-sandbox": false
            ])
        ),
        .target(
            name: "KeepClaudeTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.inhochoi.KeepClaudeTests",
            sources: ["Tests/Sources/**"],
            dependencies: [
                .target(name: "KeepClaude")
            ]
        )
    ]
)
