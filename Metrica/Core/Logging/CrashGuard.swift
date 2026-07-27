import Foundation

/// Легкий перехоплювач крашів без сторонніх SDK (§10 crash-free).
enum CrashGuard {
    static func install() {
        NSSetUncaughtExceptionHandler { exception in
            AppLog.fault("uncaught_exception", [
                "name": exception.name.rawValue,
                "reason": String(exception.reason?.prefix(120) ?? ""),
            ])
        }
    }
}
