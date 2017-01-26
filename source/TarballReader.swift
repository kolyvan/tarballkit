//
//  TarballReader.swift
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


public struct TarballReader {

    public let filePath: String

    public init(filePath: String) {
        precondition(!filePath.isEmpty)
        self.filePath = filePath
    }

    public func items() throws -> [TarballItem] {
        let raw = try RawArchive.openRead(filePath)
        return try raw.items().map{ item in
            return TarballItem(item, filter: raw.filter)
        }
    }

    public func read(path: String) throws -> Data {
        let raw = try RawArchive.openRead(filePath)
        return try raw.readData(path)
    }

    public func read(item: TarballItem) throws -> Data {
        if item.compressed {
            return try read(path: item.path)
        } else {
            return try read(range: item.range)
        }
    }

    private func read(range: Range<Int64>) throws -> Data {
        precondition(range.lowerBound >= 0)
        let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath))
        defer { handle.closeFile() }
        handle.seek(toFileOffset: UInt64(range.lowerBound))
        return handle.readData(ofLength: range.upperBound - range.lowerBound)
    }
}

public final class TarballReaderIterator: IteratorProtocol {

    private var raw: RawArchive?

    init(_ raw: RawArchive?) {
        self.raw = raw
    }

    public func next() -> TarballEntry? {
        guard let raw = raw else { return nil }
        if let entry = try? raw.readNext() {
            return TarballEntry(entry)
        }
        self.raw = nil
        return nil
    }
}

extension TarballReader: Sequence {

    public func makeIterator() -> TarballReaderIterator {
        let raw = try? RawArchive.openRead(filePath)
        return TarballReaderIterator(raw)
    }
}
