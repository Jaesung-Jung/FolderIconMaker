import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @State private var folderStyle: FolderStyle = .empty
  @State private var symbolURL: URL?
  @State private var preview = PreviewState()
  @State private var renderTask: Task<Void, Never>?
  @State private var statusMessage = "Choose a symbol file."

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Folder Style")
            .font(.caption)
            .foregroundStyle(.secondary)

          Picker("Folder Style", selection: $folderStyle) {
            ForEach(FolderStyle.allCases) { style in
              Text(style.rawValue).tag(style)
            }
          }
          .labelsHidden()
          .pickerStyle(.segmented)

          Button {
            chooseSymbol()
          } label: {
            Text("Choose Symbol")
              .frame(maxWidth: .infinity)
          }

          Text(symbolURL?.lastPathComponent ?? "No symbol selected")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .buttonSizing(.flexible)

        Divider()

        VStack {
          HStack {
            Button("Save PNG") {
              savePNG()
            }

            Button("Save ICNS") {
              saveICNS()
            }
          }

          Button("Apply to Folder") {
            applyToFolder()
          }
          .buttonStyle(.borderedProminent)
        }
        .buttonSizing(.flexible)
        .disabled(preview.exportImage == nil || preview.isRendering)

        Spacer()

        Text(statusMessage)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(width: 260)

      ZStack {
        Color(nsColor: .windowBackgroundColor)
        if let image = preview.visibleImage {
          Image(
            nsImage: NSImage(
              cgImage: image,
              size: NSSize(width: image.width, height: image.height))
          )
          .resizable()
          .interpolation(.high)
          .scaledToFit()
          .padding(36)
        } else {
          Text("Preview")
            .foregroundStyle(.secondary)
        }

        if preview.isRendering {
          ProgressView()
            .controlSize(.large)
        }
      }
    }
    .onAppear {
      refreshPreview()
    }
    .onChange(of: folderStyle) {
      refreshPreview()
    }
    .onDisappear {
      renderTask?.cancel()
    }
  }

  private func chooseSymbol() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .svg]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    if panel.runModal() == .OK {
      symbolURL = panel.url
      refreshPreview()
    }
  }

  private func refreshPreview() {
    renderTask?.cancel()

    let base = loadBaseImage()
    preview.showBase(base)

    guard let base else {
      statusMessage = "Failed to load folder image."
      return
    }

    guard let symbolURL else {
      statusMessage = "Choose a symbol file."
      return
    }

    guard let symbol = SymbolImageLoader.loadCGImage(from: symbolURL) else {
      statusMessage = "Failed to load symbol."
      return
    }

    preview.beginRendering(baseImage: base)
    statusMessage = "Rendering..."
    renderTask = Task { @MainActor in
      await Task.yield()
      if Task.isCancelled { return }

      let image = await Task.detached(priority: .userInitiated) {
        FolderIconMakerEmbossRenderer().render(base: base, symbol: symbol, settings: .default)
      }.value
      if Task.isCancelled { return }

      preview.showRendered(image)
      statusMessage = "Render complete."
    }
  }

  private func savePNG() {
    guard let image = preview.exportImage else { return }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = "FolderIconMaker.png"
    if panel.runModal() == .OK, let url = panel.url {
      do {
        try PNGExporter.write(image, to: url)
        statusMessage = "PNG saved."
      } catch {
        statusMessage = "Failed to save PNG."
      }
    }
  }

  private func saveICNS() {
    guard let image = preview.exportImage else { return }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [UTType(filenameExtension: "icns")!]
    panel.nameFieldStringValue = "FolderIconMaker.icns"
    if panel.runModal() == .OK, let url = panel.url {
      do {
        try ICNSExporter.write(image, to: url)
        statusMessage = "ICNS saved."
      } catch {
        statusMessage = "Failed to save ICNS."
      }
    }
  }

  private func applyToFolder() {
    guard let image = preview.exportImage else { return }
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    if panel.runModal() == .OK, let url = panel.url {
      statusMessage = FinderIconApplier.apply(image, to: url) ? "Applied to folder." : "Failed to apply."
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

#Preview {
  ContentView()
}
