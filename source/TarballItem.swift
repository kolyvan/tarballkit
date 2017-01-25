//
//  TarballItem.swift
//  https://github.com/kolyvan/tarballkit
//
//  Created by Konstantin Bukreev on 24.01.17.
//

/*
 Copyright (c) 2017 Konstantin Bukreev All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation


public struct TarballItem {
    public let path: String
    public let range: Range<Int64>
    public let compressed: Bool
    public let created: Date?
    public let modified: Date?
    public var size: Int64 { return range.upperBound - range.lowerBound }
}

extension TarballItem {

    init(_ item: RawArchiveItem, filter: RawArchiveFilter) {
        self.path = item.path
        self.range = item.offset..<item.offset+item.size
        self.compressed = filter != .none
        self.created = item.created
        self.modified = item.modified
    }
}

extension TarballItem: CustomDebugStringConvertible {

    public var debugDescription: String {
        var s = "taritem("
        s += path
        s += ", size: \(size)"
        if compressed {
            s += ", compressed: true"
        }
        if let created = created {
            s += ", created: \(created)"
        }
        if let modified = modified {
            s += ", modified: \(modified)"
        }
        s += ")"
        return s
    }
}
