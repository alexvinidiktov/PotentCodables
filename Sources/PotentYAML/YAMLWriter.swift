//
//  YAMLWriter.swift
//  PotentCodables
//
//  Copyright © 2021 Outfox, inc.
//
//
//  Distributed under the MIT License, See LICENSE for details.
//

import Cfyaml
import Foundation

internal struct YAMLWriter {

  typealias Error = YAMLSerialization.Error

  typealias Writer = (String?) -> Void

  enum Width {
    case normal
    case wide
    case infinite
  }

  static func write(_ documents: YAML.Sequence,
                    preferredCollectionStyle: YAML.CollectionStyle = .block,
                    pretty: Bool = true,
                    width: Width = .normal,
                    sortedKeys: Bool = false,
                    writer: @escaping Writer) throws {

    func output(
      emitter: OpaquePointer?,
      writeType: fy_emitter_write_type,
      str: UnsafePointer<Int8>?,
      len: Int32,
      userInfo: UnsafeMutableRawPointer?
    ) -> Int32 {
      guard let writer = userInfo?.assumingMemoryBound(to: Writer.self).pointee else {
        fatalError()
      }
      guard let str = str else {
        writer(nil)
        return 0
      }
      let strPtr = UnsafeMutableRawPointer(mutating: str)
      writer(String(bytesNoCopy: strPtr, length: Int(len), encoding: .utf8, freeWhenDone: false))
      return len
    }

    try withUnsafePointer(to: writer) { writerPtr in

      var flags: UInt32 = pretty ? FYECF_MODE_PRETTY.rawValue : FYECF_DEFAULT.rawValue

      switch width {
      case .normal:
        flags |= FYECF_WIDTH_80.rawValue
      case .wide:
        flags |= FYECF_WIDTH_132.rawValue
      case .infinite:
        flags |= FYECF_WIDTH_INF.rawValue
      }

      var emitterCfg = fy_emitter_cfg(
        flags: fy_emitter_cfg_flags(rawValue: flags),
        output: output,
        userdata: UnsafeMutableRawPointer(mutating: writerPtr),
        diag: nil
      )

      guard let emitter = fy_emitter_create(&emitterCfg) else {
        throw Error.unableToCreateEmitter
      }
      defer { fy_emitter_destroy(emitter) }

      emit(emitter: emitter, type: FYET_STREAM_START)

      try documents.forEach {
        emit(emitter: emitter, type: FYET_DOCUMENT_START, args: 0, 0, 0)

        try emit(emitter: emitter,
                 value: $0,
                 preferredCollectionStyle: preferredCollectionStyle,
                 sortedKeys: sortedKeys)

        emit(emitter: emitter, type: FYET_DOCUMENT_END)
      }

      emit(emitter: emitter, type: FYET_STREAM_END)
    }

  }

  private static func emit(emitter: OpaquePointer,
                           value: YAML,
                           preferredCollectionStyle: YAML.CollectionStyle,
                           sortedKeys: Bool) throws {

    switch value {
    case .null(anchor: let anchor):
      emit(emitter: emitter, scalar: "null", style: FYSS_PLAIN, anchor: anchor, tag: nil)

    case .string(let string, style: let style, tag: let tag, anchor: let anchor):
      let scalarStyle = fy_scalar_style(rawValue: style.rawValue)
      emit(emitter: emitter, scalar: string, style: scalarStyle, anchor: anchor, tag: tag?.rawValue)

    case .integer(let integer, anchor: let anchor):
      emit(emitter: emitter, scalar: integer.value, style: FYSS_PLAIN, anchor: anchor, tag: nil)

    case .float(let float, anchor: let anchor):
      emit(emitter: emitter, scalar: float.value, style: FYSS_PLAIN, anchor: anchor, tag: nil)

    case .bool(let bool, anchor: let anchor):
      emit(emitter: emitter, scalar: bool ? "true" : "false", style: FYSS_PLAIN, anchor: anchor, tag: nil)

    case .sequence(let sequence, style: let style, tag: let tag, anchor: let anchor):
      try emit(emitter: emitter,
               sequence: sequence,
               style: style,
               preferredStyle: preferredCollectionStyle,
               sortedKeys: sortedKeys,
               anchor: anchor,
               tag: tag)

    case .mapping(let mapping, style: let style, tag: let tag, anchor: let anchor):
      try emit(emitter: emitter,
               mapping: mapping,
               style: style,
               preferredStyle: preferredCollectionStyle,
               sortedKeys: sortedKeys,
               anchor: anchor,
               tag: tag)

    case .alias(let alias):
      emit(emitter: emitter, alias: alias)

    }
  }

  private static func emit(
    emitter: OpaquePointer,
    mapping: YAML.Mapping,
    style: YAML.CollectionStyle,
    preferredStyle: YAML.CollectionStyle,
    sortedKeys: Bool,
    anchor: String?,
    tag: YAML.Tag?
  ) throws {
    emit(
      emitter: emitter,
      type: FYET_MAPPING_START,
      args: style.nodeStyle(preferred: preferredStyle).rawValue,
      anchor.varArg,
      (tag?.rawValue).varArg
    )
    var mapping = mapping
    if sortedKeys {
      mapping = mapping.sorted {
        $0.key.description < $1.key.description
      }
    }
    try mapping.forEach { entry in
      try emit(emitter: emitter, value: entry.key, preferredCollectionStyle: preferredStyle, sortedKeys: sortedKeys)
      try emit(emitter: emitter, value: entry.value, preferredCollectionStyle: preferredStyle, sortedKeys: sortedKeys)
    }
    emit(emitter: emitter, type: FYET_MAPPING_END)
  }

  private static func emit(
    emitter: OpaquePointer,
    sequence: [YAML],
    style: YAML.CollectionStyle,
    preferredStyle: YAML.CollectionStyle,
    sortedKeys: Bool,
    anchor: String?,
    tag: YAML.Tag?
  ) throws {
    emit(
      emitter: emitter,
      type: FYET_SEQUENCE_START,
      args: style.nodeStyle(preferred: preferredStyle).rawValue,
      anchor.varArg,
      (tag?.rawValue).varArg
    )
    try sequence.forEach { element in
      try emit(emitter: emitter, value: element, preferredCollectionStyle: preferredStyle, sortedKeys: sortedKeys)
    }
    emit(emitter: emitter, type: FYET_SEQUENCE_END)
  }

  private static func emit(
    emitter: OpaquePointer,
    scalar: String,
    style: fy_scalar_style,
    anchor: String?,
    tag: String?
  ) {
    scalar.withCString { scalarPtr in
      anchor.withCString { anchorPtr in
        tag.withCString { tagPtr in
          emit(emitter: emitter, type: FYET_SCALAR, args: style.rawValue, scalarPtr, FY_NT, anchorPtr, tagPtr)
        }
      }
    }
  }

  private static func emit(
    emitter: OpaquePointer,
    alias: String
  ) {
    alias.withCString { aliasPtr in
      emit(emitter: emitter, type: FYET_ALIAS, args: aliasPtr)
    }
  }

  private static func emit(emitter: OpaquePointer, type: fy_event_type, args: CVarArg...) {
    withVaList(args) { valist in
      let event = fy_emit_event_vcreate(emitter, type, valist)
      fy_emit_event(emitter, event)
    }
  }

}

extension Optional where Wrapped: CVarArg {

  var varArg: CVarArg { self ?? unsafeBitCast(0, to: OpaquePointer.self) }

}


extension Optional where Wrapped == String {

  func withCString<Result>(_ body: (UnsafePointer<Int8>) throws -> Result) rethrows -> Result {
    if let str = self {
      return try str.withCString(body)
    }
    else {
      return try body(UnsafePointer<Int8>(unsafeBitCast(0, to: OpaquePointer.self)))
    }
  }

}

extension YAML.CollectionStyle {

  func nodeStyle(preferred: Self) -> fy_node_style {
    switch (self, preferred) {
    case (.any, .any): return FYNS_ANY
    case (.any, .flow), (.flow, _): return FYNS_FLOW
    case (.any, .block), (.block, _): return FYNS_BLOCK
    }
  }

}
