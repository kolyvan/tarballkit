//
//  TarballWriter.swift
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


public final class TarballWriter {

    public enum Mode {
        case `default`, append, gzipped, bzipped
    }

    public let filePath: String
    private let raw: RawArchive

    public init(filePath: String, mode: Mode = .default) throws {
        precondition(!filePath.isEmpty)
        if mode == .append {
            self.raw = try RawArchive.openAppend(filePath)
        } else {
            self.raw = try RawArchive.openWrite(filePath, filter: RawArchiveFilter(mode))
        }
        self.filePath = filePath
    }

    public func write(data: Data, path: String) throws {
        let entry = RawArchiveEntry()
        entry.path = path
        entry.content = data
        try raw.write(entry)
    }

    public func write(entry: TarballEntry) throws {
        try raw.write(RawArchiveEntry(entry))
    }

    public func write(entries: [TarballEntry]) throws {
        for entry in entries {
            try raw.write(RawArchiveEntry(entry))
        }
    }
}


private extension RawArchiveEntry {

    convenience init(_ entry: TarballEntry) {
        self.init()
        self.path = entry.path
        self.content = entry.content
        self.created = entry.created
        self.modified = entry.modified
    }
}

private extension RawArchiveFilter {

    init(_ mode: TarballWriter.Mode) {
        switch mode {
        case .default: self = .none
        case .append:  self = .none
        case .gzipped: self = .gzip
        case .bzipped: self = .bzip2
        }
    }
}
