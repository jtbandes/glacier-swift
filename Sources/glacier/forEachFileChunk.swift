import Foundation

func forEachFileChunk(
  _ path: String,
  chunkSizeBytes: Int,
  reportProgress: ((_ fraction: Double, _ megabytesPerSecond: Double) -> Void)?,
  body: (Data) -> Void
) throws
{
  guard let file = FileHandle(forReadingAtPath: path) else {
    throw Errors.couldNotOpenFile
  }
  let fileSize: UInt64
  if #available(macOS 10.15.4, *) {
    fileSize = try file.seekToEnd()
  } else {
    fileSize = file.seekToEndOfFile()
  }
  if #available(macOS 10.15, *) {
    try file.seek(toOffset: 0)
  } else {
    file.seek(toFileOffset: 0)
  }
  
  var start = DispatchTime.now()
  var startChunksRead = 0
  let totalChunks = Double(fileSize) / Double(chunkSizeBytes)
  
  var chunksRead = 0
  repeat {} while try autoreleasepool {
    let data: Data
    if #available(OSX 10.15.4, *) {
      guard let readData = try file.read(upToCount: chunkSizeBytes) else { return false }
      data = readData
    } else {
      data = file.readData(ofLength: chunkSizeBytes)
      if data.isEmpty {
        return false
      }
    }
    chunksRead += 1
    body(data)
    if let reportProgress = reportProgress, (chunksRead - startChunksRead) * chunkSizeBytes > 1024 * 1024 * 100 {
      let megabytesPerSecond = Double((chunksRead - startChunksRead) * chunkSizeBytes) / 1024 / 1024 * 1e9 / Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds)
      let fraction = Double(chunksRead) / totalChunks
      reportProgress(fraction, megabytesPerSecond)
      start = DispatchTime.now()
      startChunksRead = chunksRead
    }
    return true
  }
}
