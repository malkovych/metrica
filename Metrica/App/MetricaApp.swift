import SwiftUI
import SwiftData

@main
struct MetricaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var auth = AuthService()

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: CachedPayload.self)
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(auth)
                .environment(\.locale, appState.locale)
                .preferredColorScheme(appState.theme.preferredColorScheme)
                .onOpenURL { url in
                    appState.open(url)
                }
                .task {
                    CrashGuard.install()
                    PayloadCache.shared.configure(container: modelContainer)
                    PushService.shared.configure(appState: appState)
                    applyLaunchOverrides()
                    wirePersistence()
                    await auth.bootstrap()
                    if auth.isAuthenticated {
                        auth.applyProfile(to: appState)
                    }
                    // Deep-link до APNs — інакше діалог дозволів блокує навігацію з пуша.
                    flushPendingDeepLink()
                    if auth.isAuthenticated {
                        await registerPushIfNeeded()
                    }
                }
                .onChange(of: auth.phase) { _, phase in
                    if phase == .authenticated {
                        // Якщо deep-link прийшов до логіну — pending уже застосовано до selectedTab.
                        flushPendingDeepLink()
                        Task { await registerPushIfNeeded() }
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    private func applyLaunchOverrides() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITestResetAuth") {
            auth.resetForUITests()
        }
        // UITest / debug: -UITestDeepLink metrica://business/biz-resto/dashboard/revenue
        if let idx = args.firstIndex(of: "-UITestDeepLink"), args.indices.contains(idx + 1),
           let url = URL(string: args[idx + 1]) {
            DeepLinkPending.shared.url = url
        }
    }

    private func flushPendingDeepLink() {
        if let url = DeepLinkPending.shared.url {
            DeepLinkPending.shared.url = nil
            appState.open(url)
        }
    }

    private func registerPushIfNeeded() async {
        // UI-тести: не показуємо системний діалог APNs
        if ProcessInfo.processInfo.arguments.contains("-UITesting") { return }
        await PushService.shared.requestAuthorizationAndRegister()
    }

    private func wirePersistence() {
        appState.onBusinessChange = { id in
            Task { @MainActor in
                auth.rememberSelectedBusiness(id)
            }
        }
    }
}
