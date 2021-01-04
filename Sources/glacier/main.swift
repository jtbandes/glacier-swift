import ArgumentParser
import Foundation

/// Allows `print(..., to: &stderr)`.
extension UnsafeMutablePointer: TextOutputStream where Pointee == FILE {
  public func write(_ string: String) {
    var string = string
    return string.withUTF8 {
      fwrite($0.baseAddress, 1, $0.count, self)
    }
  }
}

enum Errors: Error {
  case couldNotOpenFile
}

func reportProgress(fraction: Double, megabytesPerSecond: Double) {
  print(String(format: "%4.02fMB/s, %2.1f%%", megabytesPerSecond, fraction * 100), to: &stderr)
}

struct Treehash: ParsableCommand {
  @Argument var filePath: String
  
  func run() throws {
    let digest = try computeTreeHash(at: filePath, reportProgress: reportProgress)
    print(digest)
  }
}

struct Etag: ParsableCommand {
  @Argument var filePath: String
  @Option var chunkSizeMB = 8

  func run() throws {
    let etag = try computeETag(at: filePath, chunkSizeMB: chunkSizeMB, reportProgress: reportProgress)
    print(etag)
  }
}

struct Glacier: ParsableCommand {
  static var configuration = CommandConfiguration(
    subcommands: [Treehash.self, Etag.self]
  )
}

Glacier.main()
