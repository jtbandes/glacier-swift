import Foundation

/// https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html
func computeTreeHash(
  at path: String,
  reportProgress: ((_ fraction: Double, _ megabytesPerSecond: Double) -> Void)? = nil
) throws -> SHA256
{
  var stack: [SHA256] = []
  
  func mergeLastTwoChunks() {
    assert(stack.count >= 2)
    let a = stack.removeLast()
    let b = stack.removeLast()
    stack.append(SHA256(b.data + a.data))
  }
  
  var chunksRead = 0
  try forEachFileChunk(path, chunkSizeBytes: 1024 * 1024, reportProgress: reportProgress) { data in
    stack.append(SHA256(data))
    chunksRead += 1
    var counter = chunksRead
    while counter & 1 == 0 {
      mergeLastTwoChunks()
      counter >>= 1
    }
  }
  while stack.count > 1 {
    mergeLastTwoChunks()
  }
  
  return stack[0]
}
