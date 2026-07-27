import SwiftUI

struct AlertsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 29
    @StateObject private var vm = AlertsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "alerts"))
                        .font(.system(size: titleSize, weight: .heavy))
                        .foregroundStyle(theme.text)
                        .accessibilityIdentifier("alerts_title")

                    if vm.isLoading && vm.items.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                    } else if let error = vm.errorMessage, vm.items.isEmpty {
                        EmptyStateView(
                            symbol: "exclamationmark.triangle",
                            title: String(localized: "alerts_error_title"),
                            message: error,
                            onRetry: {
                                guard let id = appState.selectedBusinessID else { return }
                                Task { await vm.reload(businessID: id, appState: appState) }
                            }
                        )
                    } else if vm.items.isEmpty {
                        EmptyStateView(
                            symbol: "bell.slash",
                            title: String(localized: "alerts_empty_title"),
                            message: String(localized: "alerts_empty"),
                            retryTitle: nil,
                            onRetry: nil
                        )
                    } else {
                        ForEach(vm.items) { alert in
                            Button {
                                vm.open(alert, appState: appState)
                            } label: {
                                AlertCard(alert: alert)
                                    .opacity((alert.isRead ?? true) ? 0.85 : 1)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("alert_\(alert.id)")
                        }

                        if vm.canLoadMore {
                            Button {
                                Task { await vm.loadMore() }
                            } label: {
                                if vm.isLoadingMore {
                                    ProgressView().frame(maxWidth: .infinity)
                                } else {
                                    Text(String(localized: "load_more"))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(theme.accent(for: appState.mode))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .accessibilityIdentifier("alerts_load_more")
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.bg.ignoresSafeArea())
            .refreshable {
                if let id = appState.selectedBusinessID {
                    await vm.reload(businessID: id, appState: appState)
                }
            }
            .task(id: appState.selectedBusinessID) {
                if let id = appState.selectedBusinessID {
                    await vm.reload(businessID: id, appState: appState)
                }
            }
        }
    }
}
