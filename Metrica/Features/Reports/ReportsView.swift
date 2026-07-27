import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 29
    @StateObject private var vm = ReportsViewModel()
    @State private var shareURL: URL?
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "reports"))
                        .font(.system(size: titleSize, weight: .heavy))
                        .foregroundStyle(theme.text)
                        .accessibilityIdentifier("reports_title")

                    if vm.isLoading && vm.reports.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 100)
                    } else if let err = vm.errorMessage, vm.reports.isEmpty {
                        EmptyStateView(
                            symbol: "exclamationmark.triangle",
                            title: String(localized: "alerts_error_title"),
                            message: err,
                            onRetry: {
                                Task { await vm.load(businessID: appState.selectedBusinessID) }
                            }
                        )
                    } else if vm.reports.isEmpty {
                        EmptyStateView(
                            symbol: "doc.text",
                            title: String(localized: "reports_empty"),
                            message: String(localized: "reports_empty_body"),
                            retryTitle: nil,
                            onRetry: nil
                        )
                    } else {
                        ForEach(vm.reports) { report in
                            ReportRow(
                                report: report,
                                isSharing: vm.sharingID == report.id,
                                onShare: {
                                    Task {
                                        if let url = await vm.prepareShare(report) {
                                            shareURL = url
                                            showShare = true
                                        }
                                    }
                                }
                            )
                        }

                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Text(String(localized: "rep_note"))
                        .font(.caption)
                        .foregroundStyle(theme.sub)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(theme.bg.ignoresSafeArea())
            .task(id: appState.selectedBusinessID) {
                await vm.load(businessID: appState.selectedBusinessID)
            }
            .sheet(isPresented: $showShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
        }
    }
}

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var isLoading = false
    @Published var sharingID: String?
    @Published var errorMessage: String?

    func load(businessID: String?) async {
        guard let businessID else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            reports = try await APIClient.shared.reports(businessID: businessID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareShare(_ report: Report) async -> URL? {
        guard report.status == .ready else {
            errorMessage = String(localized: "report_generating")
            return nil
        }
        sharingID = report.id
        defer { sharingID = nil }
        AnalyticsEvents.reportShare(id: report.id)

        if AppConfig.useMocks {
            return try? MockPDF.make(for: report)
        }
        guard let remote = report.pdfURL else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: remote)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(report.id).pdf")
            try data.write(to: url)
            return url
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

enum MockPDF {
    static func make(for report: Report) throws -> URL {
        let title: String
        switch report.type {
        case .weekly: title = "Weekly report"
        case .monthly: title = "Monthly report"
        case .investor: title = "Investor report"
        }
        // Мінімальний валідний PDF
        let content = """
        %PDF-1.1
        1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj
        2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj
        3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] /Contents 4 0 R /Resources<< /Font<< /F1 5 0 R >> >> >>endobj
        4 0 obj<< /Length 68 >>stream
        BT /F1 18 Tf 40 100 Td (\(title)) Tj ET
        endstream endobj
        5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>endobj
        xref
        0 6
        0000000000 65535 f 
        0000000010 00000 n 
        0000000060 00000 n 
        0000000117 00000 n 
        0000000260 00000 n 
        0000000380 00000 n 
        trailer<< /Size 6 /Root 1 0 R >>
        startxref
        456
        %%EOF
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(report.id).pdf")
        try Data(content.utf8).write(to: url)
        return url
    }
}

struct ReportRow: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let report: Report
    var isSharing = false
    var onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(report.type == .investor ? "📊" : "📄")
                .frame(width: 42, height: 42)
                .background(theme.accentSoft(for: mode))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.sub)
            }
            Spacer()
            Button(action: onShare) {
                if isSharing {
                    ProgressView()
                } else {
                    Text(String(localized: "share"))
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(
                            report.status == .ready
                                ? theme.accent(for: mode)
                                : theme.sub
                        )
                }
            }
            .disabled(report.status != .ready || isSharing)
            .accessibilityIdentifier("share_\(report.id)")
        }
        .padding(15)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
        .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, x: theme.shadowCard.x, y: theme.shadowCard.y)
    }

    private var title: String {
        if let key = report.titleKey {
            return String(localized: String.LocalizationValue(key))
        }
        switch report.type {
        case .weekly: return String(localized: "reports_w")
        case .monthly: return String(localized: "reports_m")
        case .investor: return String(localized: "inv_report")
        }
    }

    private var subtitle: String {
        if report.type == .investor {
            return String(localized: "inv_sub")
        }
        let status = report.status == .ready ? String(localized: "ready") : String(localized: "generating")
        return "\(report.period) · \(status)"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
