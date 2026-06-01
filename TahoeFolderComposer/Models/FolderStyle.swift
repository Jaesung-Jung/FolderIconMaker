import Foundation

enum FolderStyle: String, CaseIterable, Identifiable {
  case empty = "OS Empty"
  case paper = "Paper"

  var id: String { rawValue }

  var resourceName: String {
    switch self {
    case .empty:
      return "composite-back-front"
    case .paper:
      return "composite-back-paper-front"
    }
  }
}
