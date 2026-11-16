import AppsFlyerLib

extension OrderAnalytics {
    static let shared = OrderAnalytics { name, parameters in
#if DEBUG
        print("[AppsFlyer] Submitting \(name), app_id=\(AppStoreConstants.userAppID), values=\(parameters)")
#endif
        AppsFlyerLib.shared().logEvent(
            name: name,
            values: parameters,
            completionHandler: { _, error in
#if DEBUG
                if let error {
                    let sdkError = error as NSError
                    print("[AppsFlyer] \(name) submission failed: \(sdkError.domain) (\(sdkError.code)): \(sdkError.localizedDescription)")
                } else {
                    print("[AppsFlyer] \(name) submission succeeded")
                }
#endif
            }
        )
    }
}
