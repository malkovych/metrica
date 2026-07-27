import Foundation
import Security
import CryptoKit

/// TLS pinning за SPKI SHA-256 (опційно, `AppConfig.enableTLSPinning`).
final class TLSPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard AppConfig.enableTLSPinning else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        guard AppConfig.pinnedHosts.contains(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let pins = AppConfig.pinnedSPKIHashes
        guard !pins.isEmpty else {
            // Прапор увімкнено, але пінів немає — системна перевірка (dev).
            AppLog.info("tls_pinning_no_pins", ["host": host])
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let spki = Self.spkiSHA256(of: trust), pins.contains(spki) else {
            AppLog.error("tls_pin_mismatch", ["host": host])
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    /// Base64 SHA-256 від SPKI публічного ключа leaf-сертифіката.
    static func spkiSHA256(of trust: SecTrust) -> String? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let cert = chain.first,
              let key = SecCertificateCopyKey(cert),
              let data = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
    }
}

enum URLSessionFactory {
    static func make() -> URLSession {
        if AppConfig.enableTLSPinning {
            let config = URLSessionConfiguration.ephemeral
            return URLSession(configuration: config, delegate: TLSPinningDelegate(), delegateQueue: nil)
        }
        return .shared
    }
}
