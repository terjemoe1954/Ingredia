import SwiftUI

struct SourceTrustBadge: View {
    let trustLevel: ProductSourceTrustLevel
    let language: AppLanguage

    var body: some View {
        Text(trustLevel.title(language: language))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.14))
            )
    }

    private var color: Color {
        switch trustLevel {
        case .verified:
            return .green
        case .community:
            return .blue
        case .limited:
            return .orange
        }
    }
}
