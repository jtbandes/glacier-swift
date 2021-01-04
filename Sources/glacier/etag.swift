import Foundation
import CommonCrypto

// https://stackoverflow.com/questions/12186993/what-is-the-algorithm-to-compute-the-amazon-s3-etag-for-a-file-larger-than-5gb
func computeETag(
  at path: String,
  chunkSizeMB: Int,
  reportProgress: ((_ fraction: Double, _ megabytesPerSecond: Double) -> Void)? = nil
) throws -> String
{
  var chunkCount = 0
  var lastMD5: MD5?
  
  let combined = try MD5 { (update: ([UInt8]) -> Void) in
    try forEachFileChunk(path, chunkSizeBytes: chunkSizeMB * 1024 * 1024, reportProgress: reportProgress) { data in
      let md5 = MD5(data)
      update(md5.data)
      lastMD5 = md5
      chunkCount += 1
    }
  }
  if chunkCount == 1, let lastMD5 = lastMD5 {
    return "\(lastMD5)"
  }
  return "\(combined)-\(chunkCount)"
}
