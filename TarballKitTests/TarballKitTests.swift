//
//  TarballKitTests.swift
//  TarballKitTests
//
//  Created by Konstantin Bukreev on 25.01.17.
//  Copyright © 2017 Konstantin Bukreev. All rights reserved.
//

import XCTest
import TarballKit

class TarballKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(atPath: tmpFolder())
    }
    
    func testReaderItems() {
        let items = try! resourceReader().items()
        XCTAssertTrue(items.count > 0)
    }

    func testReaderReadNotFound() {

        XCTAssertThrowsError(try resourceReader().read(path: "bad"))

        do {
            let _ = try resourceReader().read(path: "bad")
        } catch let e as NSError {
            XCTAssertEqual(e.domain, "com.kolyvan.tarballkit")
            XCTAssertEqual(e.code, 6)
        } catch {
            XCTFail()
        }
    }

    func testReaderRead() {

        let reader = resourceReader()
        for item in try! reader.items() {
            let data1 = try! reader.read(item: item)
            let data2 = try! reader.read(path: item.path)
            let original = resourceData(filename: item.path)
            XCTAssertEqual(data1, original)
            XCTAssertEqual(data2, original)
        }
    }

    func testReaderSequence() {

        let entries = resourceReader().map{ $0 }
        for entry in entries {
            let original = resourceData(filename: entry.path)
            XCTAssertEqual(entry.content, original)
        }
    }

    func testReaderReadGzip() {

        let reader = resourceReader(ext: "tgz")
        for item in try! reader.items() {
            let data = try! reader.read(item: item)
            let original = resourceData(filename: item.path)
            XCTAssertEqual(data, original)
        }
    }

    func testReaderReadBzip2() {

        let reader = resourceReader(ext: "tbz")
        for item in try! reader.items() {
            let data = try! reader.read(item: item)
            let original = resourceData(filename: item.path)
            XCTAssertEqual(data, original)
        }
    }

    func testWriter() {

        let path = tmpFolder() + "/test-\(Date.timeIntervalSinceReferenceDate).tar"
        let sample = "red fox jumps over lazy dog".data(using: .utf8)

        do {
            let writer = try! TarballWriter(filePath: path)
            try! writer.write(data: sample!, path: "sample.txt")
        }

        do {
            let reader = TarballReader(filePath: path)
            let data = try! reader.read(path: "sample.txt")
            XCTAssertEqual(data, sample)
        }
    }

    func testWriterAppend() {

        let path = tmpFolder() + "/test-\(Date.timeIntervalSinceReferenceDate).tar"
        let sample1 = "red fox jumps over lazy dog".data(using: .utf8)
        let sample2 = "It was the White Rabbit, trotting slowly back again".data(using: .utf8)

        do {
            let writer = try! TarballWriter(filePath: path)
            try! writer.write(data: sample1!, path: "sample1.txt")
        }

        do {
            let writer = try! TarballWriter(filePath: path, append: true)
            try! writer.write(data: sample2!, path: "sample2.txt")
        }

        do {
            let reader = TarballReader(filePath: path)
            let data1 = try! reader.read(path: "sample1.txt")
            let data2 = try! reader.read(path: "sample2.txt")
            XCTAssertEqual(data1, sample1)
            XCTAssertEqual(data2, sample2)
        }
    }

    private func resourceReader(ext: String = "tar") -> TarballReader {
        let path = Bundle(for: type(of: self)).path(forResource: "sample", ofType: ext)
        return TarballReader(filePath: path!)
    }

    private func resourceData(filename: String) -> Data {
        let url = Bundle(for: type(of: self)).resourceURL?.appendingPathComponent(filename, isDirectory: false)
        return try! Data(contentsOf: url!)
    }

    private func tmpFolder() -> String {
        let folder = NSTemporaryDirectory() + "tarrballkittests"
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        return folder
    }
}
