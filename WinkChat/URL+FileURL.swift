//
//  HelperFunctions.swift
//  WinkChat
//
//  Created by Naim Lujan on 6/30/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import Foundation

extension URL {
    static func cachedFileURL(_ fileName: String) -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent(fileName)
    }
}

