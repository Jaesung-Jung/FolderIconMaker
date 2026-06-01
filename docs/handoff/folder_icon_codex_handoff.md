# macOS 26 Tahoe 폴더 아이콘 리소스 조사: Codex 핸드오프

## 작업 목표

macOS 26 Tahoe에서 Finder가 실제로 표시하는 최신 폴더 아이콘 리소스의 위치와 생성 방식을 조사해 주세요.

핵심은 단순히 `Folder.icns` 또는 `Folder` asset을 찾는 것이 아니라, **Tahoe의 실제 Finder 폴더 아이콘이 정적 리소스인지, Finder/IconServices/CoreUI/SystemAppearance가 런타임에 합성하는 결과인지 판별**하는 것입니다.

---

## 배경

- `/System/Library/PrivateFrameworks/IconFoundation.framework/Versions/A/Resources/Assets.car`에서 다음 asset을 추출했습니다.
  - `Folder`
  - `FolderDark`
  - `SmartFolder`
  - `SmartFolderDark`
- 그러나 이 `Folder` 이미지는 Tahoe Finder에서 보이는 실제 최신 폴더 형태와 다릅니다.
- 따라서 `IconFoundation.framework`의 `Folder`는 예전/legacy/fallback 이미지일 가능성이 높습니다.
- Tahoe Finder의 폴더는 더 둥글고 Liquid Glass/Solarium 계열의 형태이며, 빈 폴더와 항목이 들어 있는 폴더도 다르게 보입니다.
- macOS 26의 Customize Folder 기능은 색상, SF Symbol, Emoji를 폴더에 추가하지만, 사용자 이미지를 이 방식으로 넣는 것은 지원하지 않는 것으로 보입니다.
- Customize Folder 정보는 이미지 파일이 아니라 xattr 메타데이터에 저장되는 것으로 알려져 있습니다.

관련 xattr 후보:

```text
com.apple.FinderInfo
com.apple.icon.folder
com.apple.icon.folder#S
```

예시:

```json
{"sym":"camera.viewfinder"}
```

```json
{"emoji":"📷"}
```

---

## 조사해야 할 핵심 질문

1. Tahoe Finder에서 실제로 보이는 최신 기본 폴더 아이콘의 원본 리소스는 어디에 있는가?
2. 그 리소스가 단일 PNG/ICNS/Assets.car asset으로 존재하는가, 아니면 IconServices/Finder가 런타임에 합성하는가?
3. 빈 폴더와 항목이 들어 있는 폴더의 차이는 별도 리소스인가, 아니면 썸네일/document layer를 동적으로 합성한 결과인가?
4. `IconFoundation.framework`의 `Folder` asset이 legacy/fallback인지 검증할 수 있는가?
5. 앱에서 Tahoe 실제 폴더 모양을 재현하려면 정적 리소스 추출이 가능한가, 아니면 `NSWorkspace.shared.icon(forFile:)` 같은 렌더링 결과 캡처가 더 정확한가?

---

## 우선 확인할 경로

```text
/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Assets.car
/System/Library/CoreServices/Finder.app/Contents/Resources/Assets.car
/System/Library/CoreServices/SystemAppearance.bundle/Contents/Resources/
/System/Library/PrivateFrameworks/IconServices.framework/
/System/Library/PrivateFrameworks/IconFoundation.framework/
/System/Library/PrivateFrameworks/CoreUI.framework/
/Library/Apple/System/Library/
/System/Library/AssetsV2/
```

`/System/Library/AssetsV2/` 또는 유사한 asset 저장소가 있는지도 확인해 주세요.

---

## 전체 Assets.car 검색

### grep 기반

```bash
find /System/Library /Library/Apple/System/Library -name "Assets.car" 2>/dev/null |
while IFS= read -r car; do
  hits=$(
    xcrun --sdk macosx assetutil --info "$car" 2>/dev/null |
    grep -iE '"Name" : ".*(folder|public\.folder|generic|solarium|liquid|glass|preview|thumbnail|stack|container|document)' |
    head -50
  )
  if [ -n "$hits" ]; then
    echo
    echo "### $car"
    echo "$hits"
  fi
done
```

### jq 기반

```bash
find /System/Library /Library/Apple/System/Library -name "Assets.car" 2>/dev/null |
while IFS= read -r car; do
  xcrun --sdk macosx assetutil --info "$car" 2>/dev/null |
  jq -r --arg car "$car" '
    .[]?
    | select((.Name // "") | test("folder|public\\.folder|generic|solarium|liquid|glass|preview|thumbnail|stack|container|document"; "i"))
    | "\($car)\t\(.AssetType // "-")\t\(.Name // "-")\t\(.RenditionName // "-")\t\(.PixelWidth // "-")x\(.PixelHeight // "-")"
  '
done
```

---

## `.icon` / `.icns` 파일 검색

```bash
sudo find /System/Library /Library/Apple/System/Library /Applications \
  -name "*.icon" -o -name "*.icns" 2>/dev/null |
  grep -iE 'folder|generic|finder|coretypes|iconservices|appearance'
```

주의: macOS 26의 앱 아이콘은 `.icon` → `Assets.car` 구조와 관련될 수 있지만, 시스템 폴더 아이콘이 `Folder.icon` 같은 형태로 노출되어 있을지는 불확실합니다.

---

## IconServices 관련 파일 검색

```bash
sudo find /System/Library/PrivateFrameworks/IconServices.framework \
  -type f 2>/dev/null | sed 's#^#IconServices: #'
```

---

## SystemAppearance 관련 파일 검색

```bash
sudo find /System/Library/CoreServices/SystemAppearance.bundle \
  -type f 2>/dev/null | sed 's#^#SystemAppearance: #'
```

---

## CoreTypes / Finder asset 상세 dump

```bash
xcrun --sdk macosx assetutil --info \
  /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Assets.car \
  > ~/Desktop/CoreTypes-assets.json

xcrun --sdk macosx assetutil --info \
  /System/Library/CoreServices/Finder.app/Contents/Resources/Assets.car \
  > ~/Desktop/Finder-assets.json
```

---

## 추출 테스트

후보 asset 이름이 나오면 `iconutil` 또는 Asset Catalog Tinkerer로 추출해 Finder 실제 표시와 비교해 주세요.

주의:

- `IconFoundation.framework`의 `Folder`는 이미 Tahoe 실제 표시와 다릅니다.
- 따라서 이 asset은 fallback 또는 legacy 후보로 분류해야 합니다.

예시:

```bash
iconutil -c icns \
  /System/Library/PrivateFrameworks/IconFoundation.framework/Versions/A/Resources/Assets.car \
  Folder \
  -o ~/Desktop/IconFoundation-Folder.icns
```

후보가 `CoreTypes.bundle` 또는 `Finder.app`에서 발견되면 같은 방식으로 추출을 시도합니다.

---

## 검증용 Swift 코드

다음 방식으로 시스템이 실제 렌더링한 폴더 아이콘을 PNG로 저장하고, 추출 asset과 픽셀/시각 비교해 주세요.

```swift
import AppKit

func saveIcon(for path: String, to output: String) throws {
    let image = NSWorkspace.shared.icon(forFile: path)
    image.size = NSSize(width: 1024, height: 1024)

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconDump", code: 1)
    }

    try png.write(to: URL(fileURLWithPath: output))
}

let emptyFolder = "/tmp/tahoe-empty-folder-test"
let nonEmptyFolder = "/tmp/tahoe-non-empty-folder-test"

try? FileManager.default.removeItem(atPath: emptyFolder)
try? FileManager.default.removeItem(atPath: nonEmptyFolder)

try FileManager.default.createDirectory(atPath: emptyFolder, withIntermediateDirectories: true)
try FileManager.default.createDirectory(atPath: nonEmptyFolder, withIntermediateDirectories: true)
try "hello".write(toFile: "\(nonEmptyFolder)/test.txt", atomically: true, encoding: .utf8)

try saveIcon(for: emptyFolder, to: "/tmp/tahoe-empty-folder.png")
try saveIcon(for: nonEmptyFolder, to: "/tmp/tahoe-non-empty-folder.png")

print("Saved:")
print("/tmp/tahoe-empty-folder.png")
print("/tmp/tahoe-non-empty-folder.png")
```

---

## 추가 검증 항목

1. 빈 폴더 PNG와 `IconFoundation`에서 추출한 `Folder` PNG를 비교합니다.
2. Finder에서 보이는 모양과 `NSWorkspace.shared.icon(forFile:)` 결과가 일치하는지 비교합니다.
3. 항목 있는 폴더의 경우 내부 파일 종류에 따라 아이콘이 달라지는지 확인합니다.
   - `txt`
   - `png`
   - `app`
   - `pdf`
   - 여러 파일
4. 내부 파일 종류에 따라 달라진다면, 별도 “non-empty folder” 리소스가 아니라 Finder/IconServices 런타임 합성일 가능성이 높습니다.

---

## xattr 실험

```bash
mkdir -p /tmp/tahoe-xattr-folder
xattr -w 'com.apple.icon.folder#S' '{"sym":"camera.viewfinder"}' /tmp/tahoe-xattr-folder
xattr -l /tmp/tahoe-xattr-folder
```

확인할 것:

- Finder에서 해당 폴더에 SF Symbol overlay가 표시되는지
- `NSWorkspace.shared.icon(forFile:)` 결과에도 overlay가 반영되는지
- xattr 값만으로 심볼/이모지 표시가 가능한지
- `com.apple.FinderInfo`가 없으면 표시가 안 되는지

---

## 주의 사항

- 시스템 파일은 수정하지 말고 읽기/복사/추출만 할 것.
- SIP/sealed system volume 때문에 시스템 리소스 직접 변경은 하지 말 것.
- 목적은 “리소스 위치 확인”과 “런타임 합성 여부 판별”입니다.
- 캐시 파일에서 이미지를 뽑는 것은 재현성이 낮으므로 최종 방법으로 권장하지 않습니다.

---

## 예상 가설

### A. Tahoe 실제 폴더는 단일 `Folder.png` / `Folder.icns`가 아니다

Finder에서 보이는 최종 폴더는 정적 이미지 하나가 아니라 여러 레이어와 상태를 조합한 결과일 가능성이 높습니다.

### B. `IconFoundation.framework/.../Assets.car`의 `Folder`는 legacy/fallback asset이다

이미 추출 결과가 Tahoe Finder 표시와 다르므로 fallback/legacy 가능성이 높습니다.

### C. 실제 Finder 폴더는 CoreTypes/SystemAppearance/IconServices/Finder가 Liquid Glass/Solarium 스타일로 런타임 합성한다

특히 macOS 26의 새 폴더 사용자화 기능은 색상, SF Symbol, Emoji overlay를 동적으로 반영합니다.

### D. 항목 있는 폴더는 기본 폴더 + document/page/thumbnail layer + mask/shadow 조합일 가능성이 높다

내부 파일 종류에 따라 표시가 달라진다면 정적 asset이 아니라 합성 결과로 판단할 수 있습니다.

### E. 앱에서 정확히 같은 이미지를 얻으려면 내부 리소스 추출보다 `NSWorkspace.shared.icon(forFile:)` 또는 Finder Get Info icon copy 방식이 더 신뢰도 높을 수 있다

정적 리소스 경로는 macOS 업데이트마다 바뀔 수 있습니다.

---

## 최종 산출물

Codex는 다음 결과물을 제공해야 합니다.

1. Tahoe 실제 폴더 아이콘 후보 리소스 경로 목록
2. 각 후보의 asset 이름, AssetType, 크기, 추출 가능 여부
3. `IconFoundation`의 `Folder`와 실제 Finder 아이콘 비교 결과
4. 빈 폴더/항목 있는 폴더가 정적 리소스인지 런타임 합성인지에 대한 결론
5. 앱에서 사용하기 적합한 방식 제안
   - 정적 리소스 추출 가능 시: 경로와 추출 방법
   - 불가능하거나 불안정할 시: `NSWorkspace.shared.icon(forFile:)` 기반 렌더링 캡처 방식
6. 재현 가능한 bash/Swift 스크립트

---

## 짧은 실행 지시

Codex에는 다음 방향으로 지시하면 됩니다.

> macOS 26 Tahoe의 실제 Finder 폴더 아이콘 리소스를 찾되, 단순히 `Folder` asset을 찾는 데서 끝내지 말고, Finder에서 보이는 최신 폴더가 정적 asset인지 IconServices/Finder/CoreUI/SystemAppearance가 런타임 합성한 결과인지 검증해 주세요. `IconFoundation.framework`의 `Folder`는 Tahoe 실제 폴더와 다르므로 fallback/legacy로 가정하고, CoreTypes, Finder.app, SystemAppearance, IconServices, AssetsV2 등을 조사해 주세요. 최종적으로 앱에서 Tahoe 폴더 모양을 재현할 수 있는 안정적인 방법까지 제안해 주세요.
