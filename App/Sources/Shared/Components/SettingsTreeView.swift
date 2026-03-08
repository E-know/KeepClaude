import SwiftUI

struct SettingsTreeRow: View {
    let node: SettingsTreeNode

    var body: some View {
        if node.isExpandable {
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children) { child in
                        SettingsTreeRow(node: child)
                    }
                }
            } label: {
                nodeLabel
            }
        } else {
            nodeLabel
        }
    }

    private var nodeLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: node.icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)
            Text(node.name)
            Spacer()
            if node.fileCount > 1 {
                Text("\(node.fileCount)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            if !node.formattedSize.isEmpty {
                Text(node.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
