import Foundation
import CommonCrypto

enum MultipartChecksumEncoding {
  case hex
  case base64
}

extension BaseDigest {
  func encoded(as encoding: MultipartChecksumEncoding) -> String {
    switch encoding {
    case .hex:
      return self.description
    case .base64:
      return self.base64Description
    }
  }
}

// https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html?icmpid=docs_amazons3_console#large-object-checksums
// https://stackoverflow.com/questions/12186993/what-is-the-algorithm-to-compute-the-amazon-s3-etag-for-a-file-larger-than-5gb
func computeMultipartChecksum<D: BaseDigest>(
  _ algorithm: D.Type,
  encodedAs encoding: MultipartChecksumEncoding,
  options: MultipartChecksumOptions,
  reportProgress: ((_ fraction: Double, _ megabytesPerSecond: Double) -> Void)? = nil
) throws -> String
{
  let chunkSizeBytes = options.chunkSizeBytes ?? (options.chunkSizeMB * 1024 * 1024)
  var chunkCount = 0
  var lastMD5: D?

  let combined = try D { (update: ([UInt8]) -> Void) in
    try forEachFileChunk(options.filePath, chunkSizeBytes: chunkSizeBytes, reportProgress: reportProgress) { data in
      let chunkDigest = D(data)
      update(chunkDigest.data)
      lastMD5 = chunkDigest
      chunkCount += 1
    }
  }
  if chunkCount == 1, let lastMD5 = lastMD5 {
    return "\(lastMD5.encoded(as: encoding))"
  }
  return "\(combined.encoded(as: encoding))-\(chunkCount)"
}
