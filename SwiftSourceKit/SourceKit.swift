//
//  SourceKit.swift
//  SwiftSourceKit
//

import sourcekitd

public protocol SourceKitDelegate: class {
    func sourceKitDidReceiveError(_ error: ResponseError)
    func sourceKitDidReceiveNotification(_ response: Response)
}

public final class SourceKit {
    public weak var delegate: SourceKitDelegate?
    public static var sandboxAccessBookmark: Data?
    public static let sharedInstance: SourceKit = {
        SourceKit(sandboxAccessBookmark: sandboxAccessBookmark)
    }()
    
    private init(sandboxAccessBookmark: Data?) {
        if let bookmarkData = sandboxAccessBookmark {
            bookmarkData.withUnsafeBytes { bytes in
                sourcekitd_initialize(bytes, bookmarkData.count)
            }
        } else {
            sourcekitd_initialize(nil, 0)
        }

        sourcekitd_set_notification_handler {
            (response) in
            guard let response = response else {
                assertionFailure()
                return
            }
            if sourcekitd_response_is_error(response) {
                let error = ResponseError(response: response)
                self.delegate?.sourceKitDidReceiveError(error)
                return
            }
            let result = Response(response: response)
            self.delegate?.sourceKitDidReceiveNotification(result)
        }
    }
    
    deinit {
        sourcekitd_shutdown()
    }
}
