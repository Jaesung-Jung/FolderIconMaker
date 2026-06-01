import AppKit
import SwiftUI

struct ContentView: View {
  @State private var folderStyle: FolderStyle = .empty
  @State private var symbolURL: URL?
  @State private var renderedImage: CGImage?
  @State private var statusMessage = "심볼 파일을 선택하세요."

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 16) {
        Picker("Folder", selection: $folderStyle) {
          ForEach(FolderStyle.allCases) { style in
            Text(style.rawValue).tag(style)
          }
        }
        .pickerStyle(.segmented)

        Button("Choose Symbol") {
          chooseSymbol()
        }

        Text(symbolURL?.lastPathComponent ?? "선택된 심볼 없음")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)

        Button("Render") {
          render()
        }
        .disabled(symbolURL == nil)

        Button("Save PNG") {
          savePNG()
        }
        .disabled(renderedImage == nil)

        Button("Apply to Folder") {
          applyToFolder()
        }
        .disabled(renderedImage == nil)

        Spacer()

        Text(statusMessage)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(width: 260)

      ZStack {
        Color(nsColor: .windowBackgroundColor)
        if let renderedImage {
          Image(
            nsImage: NSImage(
              cgImage: renderedImage,
              size: NSSize(width: renderedImage.width, height: renderedImage.height))
          )
          .resizable()
          .interpolation(.high)
          .scaledToFit()
          .padding(36)
        } else {
          Text("Preview")
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 640, height: 620)
    }
    .frame(width: 900, height: 620)
    .onChange(of: folderStyle) {
      renderedImage = nil
      statusMessage = "다시 렌더하세요."
    }
  }

  private func chooseSymbol() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .svg]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if panel.runModal() == .OK {
      renderedImage = nil
      symbolURL = panel.url
      statusMessage = "심볼 선택됨"
    }
  }

  private func render() {
    guard
      let base = loadBaseImage(),
      let symbolURL,
      let symbol = SymbolImageLoader.loadCGImage(from: symbolURL)
    else {
      renderedImage = nil
      statusMessage = "로드 실패"
      return
    }

    renderedImage = FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: .default)
    statusMessage = "렌더 완료"
  }

  private func savePNG() {
    guard let renderedImage else { return }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = "FolderIconMaker.png"
    if panel.runModal() == .OK, let url = panel.url {
      do {
        try PNGExporter.write(renderedImage, to: url)
        statusMessage = "저장 완료"
      } catch {
        statusMessage = "저장 실패"
      }
    }
  }

  private func applyToFolder() {
    guard let renderedImage else { return }
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      statusMessage = FinderIconApplier.apply(renderedImage, to: url) ? "적용 완료" : "적용 실패"
    }
  }

  private func loadBaseImage() -> CGImage? {
    if folderStyle == .empty {
      return SystemFolderIconProvider().emptyFolderIcon(
        canvasSize: RenderSettings.default.canvasSize)
    }

    guard
      let url = Bundle.main.url(forResource: folderStyle.resourceName, withExtension: "png"),
      let image = NSImage(contentsOf: url)
    else { return nil }

    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
  }
}
