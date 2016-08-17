//
//  SourceKit.swift
//  SwiftSourceKit
//

import sourcekitd

public protocol SourceKitDelegate: class {
    func sourceKitDidReceiveError(error: ResponseError)
    func sourceKitDidReceiveNotification(response: Response)
}

public final class SourceKit {
    public weak var delegate: SourceKitDelegate?
    public static var sandboxAccessBookmark: NSData?
    public static let sharedInstance: SourceKit = {
        SourceKit(sandboxAccessBookmark: sandboxAccessBookmark)
    }()
    
    private init(sandboxAccessBookmark: NSData?) {
        if let bookmarkData = sandboxAccessBookmark {
            sourcekitd_initialize(bookmarkData.bytes, bookmarkData.length)
        } else {
            sourcekitd_initialize(nil, 0)
        }

        sourcekitd_set_notification_handler {
            (response) in
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