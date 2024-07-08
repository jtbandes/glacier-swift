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
  static var configuration = CommandConfiguration(
    abstract: "Compute the tree hash used by the glacier complete-multipart-upload command. (https://docs.aws.amazon.com/cli/v1/userguide/cli-services-glacier.html#cli-services-glacier-complete)"
  )
  @Argument var filePath: String
  
  func run() throws {
    let digest = try computeTreeHash(at: filePath, reportProgress: reportProgress)
    print(digest)
  }
}

struct MultipartChecksumOptions: ParsableArguments {
  @Argument var filePath: String
  
  @Option(help: "Chunk size in megabytes.")
  var chunkSizeMB = 8
  
  @Option(help: "Chunk size in bytes. Note that files uploaded through the AWS Console web UI use a chunk size of 17179870 bytes.")
  var chunkSizeBytes: Int?
}

struct Etag: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Compute the ETag (MD5 checksum) used by S3. For multipart objects, a checksum of checksums is used. (https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html)",
    aliases: ["md5"]
  )
  @OptionGroup var options: MultipartChecksumOptions
  func run() throws {
    let etag = try computeMultipartChecksum(MD5.self, encodedAs: .hex, options: options, reportProgress: reportProgress)
    print(etag)
  }
}

struct Sha1: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Compute the SHA-1 checksum used by S3. For multipart objects, a checksum of checksums is used. (https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html)"
  )
  @OptionGroup var options: MultipartChecksumOptions
  func run() throws {
    let etag = try computeMultipartChecksum(SHA1.self, encodedAs: .base64, options: options, reportProgress: reportProgress)
    print(etag)
  }
}

struct Sha256: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Compute the SHA-256 checksum used by S3. For multipart objects, a checksum of checksums is used. (https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html)"
  )
  @OptionGroup var options: MultipartChecksumOptions
  func run() throws {
    let etag = try computeMultipartChecksum(SHA256.self, encodedAs: .base64, options: options, reportProgress: reportProgress)
    print(etag)
  }
}

struct Glacier: ParsableCommand {
  static var configuration = CommandConfiguration(
    subcommands: [Treehash.self, Etag.self, Sha1.self, Sha256.self]
  )
}

Glacier.main()
