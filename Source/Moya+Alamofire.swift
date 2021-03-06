import Foundation
import Alamofire

public typealias Manager = Alamofire.Manager

/// Choice of parameter encoding.
public enum ParameterEncoding {
    case URL
    case URLEncodedInURL
    case JSON
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
    
    internal var toAlamofire: Alamofire.ParameterEncoding {
        switch self {
        case .URL:
            return .URL
        case .URLEncodedInURL:
          return .URLEncodedInURL
        case .JSON:
            return .JSON
        case .PropertyList(let format, let options):
            return .PropertyList(format, options)
        case .Custom(let closure):
            return .Custom(closure)
        }
    }
}

/// Make the Alamofire Request type conform to our type, to prevent leaking Alamofire to plugins.
extension Request: RequestType { }

/// Internal token that can be used to cancel requests
internal final class CancellableToken: Cancellable , CustomDebugStringConvertible {
    let cancelAction: () -> Void
    let request : Request?
    private(set) var canceled: Bool = false
    
    private var lock: OSSpinLock = OS_SPINLOCK_INIT
    
    func cancel() {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        guard !canceled else { return }
        canceled = true
        cancelAction()
    }
    
    init(action: () -> Void){
        self.cancelAction = action
        self.request = nil
    }
    
    init(request : Request){
        self.request = request
        self.cancelAction = {
            request.cancel()
        }
    }
    
    var debugDescription: String {
        guard let request = self.request else {
            return "Empty Request"
        }
        return request.debugDescription
    }
    
}
