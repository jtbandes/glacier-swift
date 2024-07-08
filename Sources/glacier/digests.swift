import Foundation
import CommonCrypto

protocol DigestContext {
  init()
}

protocol DigestInfo {
  associatedtype Context: DigestContext
  static var digestLength: Int32 { get }
  static var digestFunc: (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? { get }
  static var digestInitFunc: (UnsafeMutablePointer<Context>?) -> Int32 { get }
  static var digestUpdateFunc: (UnsafeMutablePointer<Context>?, UnsafeRawPointer?, CC_LONG) -> Int32 { get }
  static var digestFinalFunc: (UnsafeMutablePointer<UInt8>?, UnsafeMutablePointer<Context>?) -> Int32 { get }
}

protocol BaseDigest: CustomStringConvertible {
  var data: [UInt8] { get }
  var base64Description: String { get }
  init(_ buffer: UnsafeRawBufferPointer)
  init(_ array: [UInt8])
  init(_ data: Data)
  init(_ body: (_ update: (UnsafeRawBufferPointer) -> Void) throws -> Void) rethrows
  init(_ body: (_ update: ([UInt8]) -> Void) throws -> Void) rethrows
}

struct Digest<Info: DigestInfo>: BaseDigest {
  var data = [UInt8](repeating: 0, count: Int(Info.digestLength))
}

typealias SHA1 = Digest<SHA1DigestInfo>
extension CC_SHA1_CTX: DigestContext {}
enum SHA1DigestInfo: DigestInfo {
  typealias Context = CC_SHA1_CTX
  static var digestLength = CC_SHA1_DIGEST_LENGTH
  static var digestFunc = CC_SHA1
  static var digestInitFunc = CC_SHA1_Init
  static var digestUpdateFunc = CC_SHA1_Update
  static var digestFinalFunc = CC_SHA1_Final
}

typealias SHA256 = Digest<SHA256DigestInfo>
extension CC_SHA256_CTX: DigestContext {}
enum SHA256DigestInfo: DigestInfo {
  typealias Context = CC_SHA256_CTX
  static var digestLength = CC_SHA256_DIGEST_LENGTH
  static var digestFunc = CC_SHA256
  static var digestInitFunc = CC_SHA256_Init
  static var digestUpdateFunc = CC_SHA256_Update
  static var digestFinalFunc = CC_SHA256_Final
}

typealias MD5 = Digest<MD5DigestInfo>
extension CC_MD5_CTX: DigestContext {}
enum MD5DigestInfo: DigestInfo {
  typealias Context = CC_MD5_CTX
  static var digestLength = CC_MD5_DIGEST_LENGTH
  static var digestFunc = CC_MD5
  static var digestInitFunc = CC_MD5_Init
  static var digestUpdateFunc = CC_MD5_Update
  static var digestFinalFunc = CC_MD5_Final
}

extension Digest {
  init(_ buffer: UnsafeRawBufferPointer) {
    _ = Info.digestFunc(buffer.baseAddress, CC_LONG(buffer.count), &self.data)
  }
  init(_ array: [UInt8]) {
    self = array.withUnsafeBufferPointer { Self(UnsafeRawBufferPointer($0)) }
  }
  init(_ data: Data) {
    self = data.withUnsafeBytes { Self($0) }
  }
  
  init(_ body: (_ update: (UnsafeRawBufferPointer) -> Void) throws -> Void) rethrows {
    var context = Info.Context()
    _ = Info.digestInitFunc(&context)
    try body { _ = Info.digestUpdateFunc(&context, $0.baseAddress, CC_LONG($0.count)) }
    _ = Info.digestFinalFunc(&self.data, &context)
  }
  
  init(_ body: (_ update: ([UInt8]) -> Void) throws -> Void) rethrows {
    var context = Info.Context()
    _ = Info.digestInitFunc(&context)
    try body {
      $0.withUnsafeBufferPointer {
        _ = Info.digestUpdateFunc(&context, $0.baseAddress, CC_LONG($0.count))
      }
    }
    _ = Info.digestFinalFunc(&self.data, &context)
  }
}

extension String {
  init(polyfill_unsafeUninitializedCapacity capacity: Int, initializingUTF8With initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Int) rethrows {
    if #available(macOS 11.0, *) {
      try self.init(unsafeUninitializedCapacity: capacity, initializingUTF8With: initializer)
    } else {
      let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: capacity)
      defer { buffer.deallocate() }
      let length = try initializer(buffer)
      self = String(bytes: buffer.prefix(length), encoding: .utf8) ?? ""
    }
  }
}

extension Digest: CustomStringConvertible {
  var description: String {
    let alphabet = Array("0123456789abcdef".utf8)
    return String(polyfill_unsafeUninitializedCapacity: data.count * 2) { buffer in
      for (i, byte) in data.enumerated() {
        buffer[i * 2] = alphabet[Int(byte / 0x10)]
        buffer[i * 2 + 1] = alphabet[Int(byte % 0x10)]
      }
      return data.count * 2
    }
  }

  var base64Description: String {
    return Data(data).base64EncodedString()
  }
}
