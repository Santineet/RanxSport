//
//  HelperExtensions.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 24.01.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import Foundation

extension StringProtocol  {
    
    func substringFacebook(from start: Self) -> SubSequence? {
        guard let lower = range(of: start)?.upperBound else { return nil }
        return self[lower...]
    }
    
    func substringWhatsUp(from start: Self) -> SubSequence? {
        guard let end = range(of: start)?.lowerBound else { return nil }
        return self[..<end]
    }
}

