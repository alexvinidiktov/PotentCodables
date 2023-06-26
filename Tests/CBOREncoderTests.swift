//
//  CBOREncoderTests.swift
//  PotentCodables
//
//  Copyright © 2021 Outfox, inc.
//
//
//  Distributed under the MIT License, See LICENSE for details.
//

import BigInt
@testable import PotentCBOR
@testable import PotentCodables
import XCTest


class CBOREncoderTests: XCTestCase {

  func encode<T: Encodable>(_ value: T, dates: CBOREncoder.DateEncodingStrategy = .iso8601) throws -> [UInt8] {
    return Array(try CBOREncoder().encode(value))
  }

  func testEncodeNull() {
    XCTAssertEqual(try encode(String?(nil)), [0xF6])
  }

  func testEncodeBools() {
    XCTAssertEqual(try encode(false), [0xF4])
    XCTAssertEqual(try encode(true), [0xF5])
  }

  func testEncodeInts() {
    // Less than 24
    XCTAssertEqual(try encode(0), [0x00])
    XCTAssertEqual(try encode(8), [0x08])
    XCTAssertEqual(try encode(10), [0x0A])
    XCTAssertEqual(try encode(23), [0x17])

    // Just bigger than 23
    XCTAssertEqual(try encode(24), [0x18, 0x18])
    XCTAssertEqual(try encode(25), [0x18, 0x19])

    // Bigger
    XCTAssertEqual(try encode(100), [0x18, 0x64])
    XCTAssertEqual(try encode(1000), [0x19, 0x03, 0xE8])
    XCTAssertEqual(try encode(1_000_000), [0x1A, 0x00, 0x0F, 0x42, 0x40])
    XCTAssertEqual(try encode(Int64(1_000_000_000_000)), [0x1B, 0x00, 0x00, 0x00, 0xE8, 0xD4, 0xA5, 0x10, 0x00])

    // Biggest
    XCTAssertEqual(
      try encode(UInt64(18_446_744_073_709_551_615)),
      [0x1B, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    )

    // Specific Types
    XCTAssertEqual(try encode(Int8.max), [0x18, 0x7f])
    XCTAssertEqual(try encode(Int16.max), [0x19, 0x7f, 0xff])
    XCTAssertEqual(try encode(Int32.max), [0x1A, 0x7f, 0xff, 0xff, 0xff])
    XCTAssertEqual(try encode(Int64.max), [0x1B, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
    XCTAssertEqual(
      try encode(Int.max),
      MemoryLayout<Int>.size == 4
      ? [0x1A, 0x7f, 0xff, 0xff, 0xff]
      : [0x1B, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
    XCTAssertEqual(try encode(UInt8.max), [0x18, 0xff])
    XCTAssertEqual(try encode(UInt16.max), [0x19, 0xff, 0xff])
    XCTAssertEqual(try encode(UInt32.max), [0x1A, 0xff, 0xff, 0xff, 0xff])
    XCTAssertEqual(try encode(UInt64.max), [0x1B, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
    XCTAssertEqual(
      try encode(UInt.max),
      MemoryLayout<Int>.size == 4
      ? [0x1A, 0xff, 0xff, 0xff, 0xff]
      : [0x1B, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
  }

  func testEncodeNegativeInts() {
    // Less than 24
    XCTAssertEqual(try encode(-1), [0x20])
    XCTAssertEqual(try encode(-10), [0x29])

    // Bigger
    XCTAssertEqual(try encode(-100), [0x38, 0x63])
    XCTAssertEqual(try encode(-1000), [0x39, 0x03, 0xE7])

    // Biggest
    XCTAssertEqual(
      try encode(Int64(-9_223_372_036_854_775_808)),
      [0x3B, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
    )

    XCTAssertEqual(try encode(Int8.min), [0x38, 0x7f])
    XCTAssertEqual(try encode(Int16.min), [0x39, 0x7f, 0xff])
    XCTAssertEqual(try encode(Int32.min), [0x3A, 0x7f, 0xff, 0xff, 0xff])
    XCTAssertEqual(try encode(Int64.min), [0x3B, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
    XCTAssertEqual(
      try encode(Int.min),
      MemoryLayout<Int>.size == 4
      ? [0x3A, 0x7f, 0xff, 0xff, 0xff]
      : [0x3B, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
  }

  func testEncodeHalfs() {

    XCTAssertEqual(try encode(CBOR.Half(1.5)), [0xf9, 0x3e, 0x00])
    XCTAssertEqual(try encode(CBOR.Half(-1.5)), [0xf9, 0xbe, 0x00])
  }

  func testEncodeFloats() {

    XCTAssertEqual(try encode(Float(1.9874999523162842)), [0xfa, 0x3f, 0xfe, 0x66, 0x66])
    XCTAssertEqual(try encode(Float(-1.9874999523162842)), [0xfa, 0xbf, 0xfe, 0x66, 0x66])
  }

  func testEncodeDoubles() {

    XCTAssertEqual(try encode(Double(1.234)), [0xfb, 0x3f, 0xf3, 0xbe, 0x76, 0xc8, 0xb4, 0x39, 0x58])
    XCTAssertEqual(try encode(Double(-1.234)), [0xfb, 0xbf, 0xf3, 0xbe, 0x76, 0xc8, 0xb4, 0x39, 0x58])
  }

  func testEncodeStrings() {
    XCTAssertEqual(try encode(""), [0x60])
    XCTAssertEqual(try encode("a"), [0x61, 0x61])
    XCTAssertEqual(try encode("IETF"), [0x64, 0x49, 0x45, 0x54, 0x46])
    XCTAssertEqual(try encode("\"\\"), [0x62, 0x22, 0x5C])
    XCTAssertEqual(try encode("\u{00FC}"), [0x62, 0xC3, 0xBC])
  }

  func testEncodeByteStrings() {
    XCTAssertEqual(try encode(Data([0x01, 0x02, 0x03, 0x04])), [0x44, 0x01, 0x02, 0x03, 0x04])
  }

  func testEncodeArrays() {
    XCTAssertEqual(
      try encode([String]()),
      [0x80]
    )
    XCTAssertEqual(
      try encode([1, 2, 3]),
      [0x83, 0x01, 0x02, 0x03]
    )
    XCTAssertEqual(
      try encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]),
      [0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
       0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19]
    )
    XCTAssertEqual(
      try encode([[1], [2, 3], [4, 5]]),
      [0x83, 0x81, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]
    )
  }

  func testEncodeMaps() throws {
    XCTAssertEqual(try encode([String: String]()), [0xA0])

    let stringToString = try encode(["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
    XCTAssertEqual(stringToString.first!, 0xA5)

    let dataMinusFirstByte = stringToString[1...].map { $0 }.chunked(into: 4)
      .sorted(by: { $0.lexicographicallyPrecedes($1) })
    let dataForKeyValuePairs: [[UInt8]] = [
      [0x61, 0x61, 0x61, 0x41],
      [0x61, 0x62, 0x61, 0x42],
      [0x61, 0x63, 0x61, 0x43],
      [0x61, 0x64, 0x61, 0x44],
      [0x61, 0x65, 0x61, 0x45],
    ]
    XCTAssertEqual(dataMinusFirstByte, dataForKeyValuePairs)

    let oneTwoThreeFour = try encode([1: 2, 3: 4])
    XCTAssert(
      oneTwoThreeFour == [0xA2, 0x61, 0x31, 0x02, 0x61, 0x33, 0x04] || oneTwoThreeFour ==
        [0xA2, 0x61, 0x33, 0x04, 0x61, 0x31, 0x02]
    )
  }

  func testEncodeDeterministicMaps() throws {

    struct Test: Codable {
      struct Sub: Codable {
        var value: Int
      }

      var test: String
      var sub: Sub
    }

    print(try CBOR.Encoder.deterministic.encode(Test(test: "a", sub: .init(value: 5))).hexEncodedString())

    XCTAssertEqual(
      try CBOR.Encoder.deterministic.encode(Test(test: "a", sub: .init(value: 5))),
      Data([0xA2, 0x63, 0x73, 0x75, 0x62, 0xA1, 0x65, 0x76, 0x61, 0x6C,
            0x75, 0x65, 0x05, 0x64, 0x74, 0x65, 0x73, 0x74, 0x61, 0x61])
    )
  }

  func testEncodingDoesntTranslateMapKeys() throws {
    let encoder = CBOREncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let tree = try encoder.encodeTree(["thisIsAnExampleKey": 0])
    XCTAssertEqual(tree.mapValue?.keys.first, "thisIsAnExampleKey")
  }

  func testEncodeDates() throws {
    let dateOne = Date(timeIntervalSince1970: 1_363_896_240)
    let dateTwo = Date(timeIntervalSince1970: 1_363_896_240.5)

    // numeric  dates
    let encoder = CBOREncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    XCTAssertEqual(try Array(encoder.encode(dateOne)), [0x1B, 0x00, 0x00, 0x01, 0x3D, 0x8E, 0x8D, 0x07, 0x80])
    XCTAssertEqual(try Array(encoder.encode(dateTwo)), [0x1B, 0x00, 0x00, 0x01, 0x3D, 0x8E, 0x8D, 0x09, 0x74])

    // numeric fractional dates
    encoder.dateEncodingStrategy = .secondsSince1970
    XCTAssertEqual(try Array(encoder.encode(dateOne)), [0xC1, 0xFB, 0x41, 0xD4, 0x52, 0xD9, 0xEC, 0x00, 0x00, 0x00])
    XCTAssertEqual(try Array(encoder.encode(dateTwo)), [0xC1, 0xFB, 0x41, 0xD4, 0x52, 0xD9, 0xEC, 0x20, 0x00, 0x00])

    // string dates (no fractional seconds)
    encoder.dateEncodingStrategy = .iso8601
    XCTAssertEqual(
      try Array(encoder.encode(dateOne)),
      [0xC0, 0x78, 0x18, 0x32, 0x30, 0x31, 0x33, 0x2D, 0x30, 0x33, 0x2D, 0x32, 0x31, 0x54, 0x32, 0x30,
       0x3A, 0x30, 0x34, 0x3A, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x30, 0x5A]
    )
    XCTAssertEqual(
      try Array(encoder.encode(dateTwo)),
      [0xC0, 0x78, 0x18, 0x32, 0x30, 0x31, 0x33, 0x2D, 0x30, 0x33, 0x2D, 0x32, 0x31, 0x54, 0x32, 0x30,
       0x3A, 0x30, 0x34, 0x3A, 0x30, 0x30, 0x2E, 0x35, 0x30, 0x30, 0x5A]
    )
  }

  func testEncodeSimpleStructs() throws {
    struct MyStruct: Codable {
      let age: Int
      let name: String
    }

    let encoded = try encode(MyStruct(age: 27, name: "Ham"))

    XCTAssert(
      encoded == [0xA2, 0x63, 0x61, 0x67, 0x65, 0x18, 0x1B, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x48, 0x61, 0x6D]
        || encoded == [0xA2, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x48, 0x61, 0x6D, 0x63, 0x61, 0x67, 0x65, 0x18, 0x1B]
    )
  }

  func testEncodeData() {
    XCTAssertEqual(try encode(Data([1, 2, 3, 4, 5])), [0x45, 0x1, 0x2, 0x3, 0x4, 0x5])
  }

  func testEncodeURL() {
    XCTAssertEqual(try encode(URL(string: "https://example.com/some/thing")),
                   [0xD8, 0x20, 0x78, 0x1E, 0x68, 0x74, 0x74, 0x70, 0x73, 0x3A, 0x2F, 0x2F,
                    0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D, 0x2F,
                    0x73, 0x6F, 0x6D, 0x65, 0x2F, 0x74, 0x68, 0x69, 0x6E, 0x67])
  }

  func testEncodeUUID() {
    XCTAssertEqual(try encode(UUID(uuidString: "975AEBED-8060-4E4D-8A11-28C5E8DDD24C")),
                   [0xD8, 0x25, 0x50, 0x97, 0x5A, 0xEB, 0xED, 0x80, 0x60, 0x4E,
                    0x4D, 0x8A, 0x11, 0x28, 0xC5, 0xE8, 0xDD, 0xD2, 0x4C])
  }

  func testEncodePositiveDecimalNegativeExponent() {
    XCTAssertEqual(try encode(Decimal(sign: .plus, exponent: -3, significand: 1234567)),
                   [0xC4, 0x82, 0x22, 0xC2, 0x43, 0x12, 0xD6, 0x87])
  }

  func testEncodePositiveDecimalPositiveExponent() {
    XCTAssertEqual(try encode(Decimal(sign: .plus, exponent: 1, significand: 1234567)),
                   [0xC4, 0x82, 0x01, 0xC2, 0x43, 0x12, 0xD6, 0x87])
  }

  func testEncodeNegativeDecimalNegativeExponent() throws {
    XCTAssertEqual(try encode(Decimal(sign: .minus, exponent: -3, significand: 1234567)),
                   [0xC4, 0x82, 0x22, 0xC3, 0x43, 0x12, 0xD6, 0x86])
  }

  func testEncodeNegativeDecimalPositiveExponent() {
    XCTAssertEqual(try encode(Decimal(sign: .minus, exponent: 1, significand: 1234567)),
                   [0xC4, 0x82, 0x01, 0xC3, 0x43, 0x12, 0xD6, 0x86])
  }

  func testEncodePositiveBigInt() {
    XCTAssertEqual(try encode(BigInt(1234567)),
                   [0xC2, 0x43, 0x12, 0xD6, 0x87])
  }

  func testEncodeNegativeBigInt() {
    XCTAssertEqual(try encode(BigInt(-1234567)),
                   [0xC3, 0x43, 0x12, 0xD6, 0x86])
  }

  func testEncodePositiveBigUInt() {
    XCTAssertEqual(try encode(BigUInt(1234567)),
                   [0xC2, 0x43, 0x12, 0xD6, 0x87])
  }

  func testEncodeAnyDictionary() throws {

    let dict: AnyValue.AnyDictionary = ["b": 1, "z": 2, "n": 3, "f": 4]

    XCTAssertEqual(try encode(dict),
                   [0xA4, 0x61, 0x62, 0x01, 0x61, 0x7A, 0x02, 0x61, 0x6E, 0x03, 0x61, 0x66, 0x04])
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
