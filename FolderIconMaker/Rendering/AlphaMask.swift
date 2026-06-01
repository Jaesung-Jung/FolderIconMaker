import Foundation

struct AlphaMask: Equatable {
  let width: Int
  let height: Int
  var values: [UInt8]

  func value(x: Int, y: Int) -> UInt8 {
    guard x >= 0, y >= 0, x < width, y < height else { return 0 }
    return values[y * width + x]
  }
}
