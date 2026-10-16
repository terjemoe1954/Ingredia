import SwiftUI

struct SafetyNoticeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 72

    let language: AppLanguage
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero

                    noticeSection(
                        title: AppText.text(.safetyNoticeWhatItDoes, language: language),
                        body: AppText.text(.safetyNoticeWhatItDoesBody, language: language)
                    )

                    noticeSection(
                        title: AppText.text(.safetyNoticeWhatItCannotDo, language: language),
                        body: AppText.text(.safetyNoticeWhatItCannotDoBody, language: language)
                    )

                    noticeSection(
                        title: AppText.text(.safetyNoticeAlwaysCheck, language: language),
                        body: AppText.text(.safetyNoticeAlwaysCheckBody, language: language)
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(AppText.text(.safetyNoticeTitle, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text(AppText.text(.safetyNoticeContinue, language: language))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0, green: 0.38, blue: 0.17))
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: heroIconSize, height: heroIconSize)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .accessibilityHidden(true)

            Text(AppText.text(.safetyNoticeHeadline, language: language))
                .font(.title2.weight(.bold))

            Text(AppText.text(.safetyNoticeSummary, language: language))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func noticeSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}
