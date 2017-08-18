//
//  RxReachability.swift
//  MessagesExtension
//
//  Created by Naim Lujan on 7/19/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import SystemConfiguration
import Foundation
import RxSwift

enum Reachability {
    case offline
    case online
    case unknown
    
    init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        
        if !connectionRequired && isReachable {
            self = .online
        } else {
            self = .offline
        }
    }
}

class RxReachability {
    static let shared = RxReachability()
    
    fileprivate init() {}
    
    private static var _status = Variable<Reachability>(.unknown)
    var status: Observable<Reachability> {
        get {
            return RxReachability._status.asObservable().distinctUntilChanged()
        }
    }
    
    class func reachabilityStatus() -> Reachability {
        return RxReachability._status.value
    }
    
    func isOnline() -> Bool {
        switch RxReachability._status.value {
        case .online:
            return true
        case .offline, .unknown:
            return false
        }
    }
    
    private var reachability: SCNetworkReachability?
    
    func startMonitor(_ host: String) -> Bool {
        if let _ = reachability {
            return true
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        if let reachability = SCNetworkReachabilityCreateWithName(nil, host) {
            
            SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
                let status = Reachability(reachabilityFlags: flags)
                RxReachability._status.value = status
            }, &context)
            
            SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            self.reachability = reachability
            
            return true
        }
        
        return true
    }
    
    func stopMonitor() {
        if let _reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue);
            reachability = nil
        }
    }
    
}

