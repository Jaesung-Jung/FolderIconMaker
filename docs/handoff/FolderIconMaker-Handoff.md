# FolderIconMaker App - Handoff

작성일: 2026-05-28  
환경: macOS 26.5 Tahoe, Build 25F71  
목표: macOS Tahoe Finder의 폴더 커스터마이즈 효과와 최대한 동일하게, 임의 SVG/PNG 심볼을 원본 폴더 이미지에 합성하는 macOS 앱 제작

## 1. 최종 목표

사용자가 원하는 것은 Figma/Sketch에서 비슷하게 보이는 레이어 레시피가 아니라, macOS Tahoe Finder의 Customize Folder 기능처럼 보이는 결과를 앱에서 생성하는 것이다.

입력:

- Tahoe 기본 폴더 이미지 또는 시스템이 렌더링한 폴더 아이콘
- 사용자 SVG/PNG 심볼
- 선택 옵션: 빈 폴더 스타일, paper/document 포함 폴더 스타일, 심볼 위치/크기

출력:

- 1024x1024 PNG
- 가능하면 `.icns`
- 가능하면 Finder custom icon으로 바로 적용 가능한 폴더 설정 기능

중요: 사용자는 “동일하게” 만들고 싶어한다. Figma 레이어 근사치는 만족스럽지 않았다.

## 2. 지금까지 확인한 핵심 사실

### 2.1 Tahoe 실제 기본 폴더 리소스

`IconFoundation.framework`의 `Folder` asset은 최신 Finder 폴더와 다르다. legacy/fallback으로 보는 것이 맞다.

실제 Tahoe 기본 폴더 형태와 가장 가까운 리소스는:

```text
/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Assets.car
  FolderComponent_BackFlap/image_16..512
  FolderComponent_FrontFlap/image_16..512
  FolderComponent_PaperSheet/image_16..512
```

이 세 레이어를 합성하면 Tahoe 폴더에 매우 가까운 이미지를 만들 수 있다.

대표 파일:

```text
FolderComponent_BackFlap/image_512
FolderComponent_FrontFlap/image_512
FolderComponent_PaperSheet/image_512
```

1024 기준으로 `BackFlap + FrontFlap` 조합이 빈 폴더와 가깝고, `BackFlap + PaperSheet + FrontFlap` 조합이 paper/document가 들어간 폴더와 가깝다.

이미 만들어 둔 파일 위치:

```text
/Users/JS/Downloads/composite-back-front.png
/Users/JS/Downloads/composite-back-paper-front.png
```

### 2.2 NSWorkspace 렌더링

샌드박스 안에서는 `NSWorkspace.shared.icon(forFile:)`가 placeholder처럼 나왔고, sandbox 밖에서 실행해야 정상 아이콘이 나왔다.

실제 앱에서는 App Sandbox 여부와 파일 접근 권한을 조심해야 한다. 정확한 시스템 아이콘 캡처가 필요하면 sandbox disabled 개발 앱 또는 적절한 entitlement/권한 구조를 고려해야 한다.

### 2.3 Customize Folder xattr 조건

단순히 아래 xattr만 설정하면 부족하다.

```bash
xattr -w 'com.apple.icon.folder#S' '{"sym":"camera.viewfinder"}' folder
```

Finder/NSWorkspace가 커스텀 폴더로 인식하려면 `com.apple.FinderInfo`에 `kHasCustomIcon = 0x0400`이 있어야 했다.

검증된 FinderInfo 값:

```text
00 00 00 00 00 00 00 00 04 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

Swift/Darwin 기준:

```swift
var bytes = [UInt8](repeating: 0, count: 32)
bytes[8] = 0x04
bytes[9] = 0x00
setxattr(path, "com.apple.FinderInfo", bytes, 32, 0, 0)
setxattr(path, "com.apple.icon.folder#S", #"{"sym":"camera.viewfinder"}"#, ...)
```

단, 이 경로는 SF Symbol/Emoji에 대해서만 Finder가 자체 렌더링한다. 사용자 PNG/SVG를 이 API에 넣는 방식은 확인되지 않았고, macOS Tahoe Customize Folder UI도 사용자 이미지를 이 방식으로 직접 넣는 기능은 없어 보인다.

## 3. 실제 macOS 커스터마이즈 효과 관찰

### 3.1 SF Symbol

SF Symbol은 단순 PNG overlay가 아니라 폴더 표면에 눌린 듯한 음각/emboss imprint로 합성된다.

관찰된 특징:

- alpha는 거의 유지되고 RGB만 변화한다.
- 폴더 표면 색을 기준으로 어둡고 밝은 edge를 만들어낸다.
- source-over black 단일 레이어만으로는 부족하다.
- 외곽 glow, highlight rim, inner shadow/edge가 섞여 보인다.

`camera.viewfinder`로 비교한 초기 역추정:

```text
main depressed fill ~= black 14.1% source-over
highlight rim ~= #CAD5EC 20.7%
symbol placement for camera.viewfinder ~= X 320, Y 389, W 384, H 384
```

하지만 이후 실제 그림 폴더 샘플을 보면 심볼은 더 작고 낮았다.

첨부 샘플에서 추정한 1024 기준 그림 폴더 심볼 영역:

```text
non-square picture symbol visual box ~= X 295, Y 415, W 434, H 315
square Git symbol adjusted box ~= X 352, Y 415, W 320, H 320
```

### 3.2 Emoji

Emoji는 SF Symbol처럼 음각으로 처리되지 않고 Apple Color Emoji 렌더링을 거의 그대로 중앙에 source-over 합성하는 쪽에 가깝다.

## 4. Figma/Sketch 접근이 실패한 이유

Figma에 편집 가능한 레이어로 재현하려고 시도했다.

시도한 구조:

```text
Base folder
Outer glow
Soft dark contact shadow
Highlight rim
Main overlay color
Inner shadow
Inner light cut
```

그러나 결과가 실제 Finder와 많이 달랐다.

이유:

1. Figma blur/mask/opacity 합성은 Apple IconServices/CoreGraphics/CoreImage 렌더링과 다르다.
2. Finder의 효과는 단순 레이어 효과가 아니라 폴더 표면의 픽셀을 기반으로 한 per-pixel 색 변환에 가깝다.
3. Git 로고처럼 면적이 넓은 심볼은 macOS 기본 SF Symbol의 얇은 stroke/outline보다 훨씬 다르게 보인다.
4. 사용자가 원하는 정확도에는 Figma layer recipe가 부족하다.

결론: 정확한 결과가 필요하면 macOS 앱 또는 로컬 렌더링 엔진이 필요하다.

## 5. 추천 구현 방향

### 5.1 앱 형태

SwiftUI macOS 앱 추천.

기능:

- 폴더 베이스 선택:
  - Empty / Back+Front
  - Paper / Back+Paper+Front
  - NSWorkspace-rendered actual folder capture
- 심볼 입력:
  - SVG import
  - PNG import
  - SF Symbol name import
- 심볼 처리:
  - alpha mask 생성
  - optional: 컬러 PNG를 luminance/alpha mask로 변환
  - optional: filled icon을 outline/stroke화하거나 mask erosion 옵션 제공
- 렌더:
  - Core Image / Core Graphics / Metal 중 하나
  - 1024 PNG export
  - ICNS export
  - Finder custom icon 적용

### 5.2 가장 정확한 방법 후보

#### Option A: Finder/IconServices에 맡기고 캡처

가능한 경우 가장 정확하다.

SF Symbol 이름을 받는 경우:

1. temp folder 생성
2. `com.apple.FinderInfo`에 kHasCustomIcon 설정
3. `com.apple.icon.folder#S`에 `{"sym":"..."}` 설정
4. `NSWorkspace.shared.icon(forFile:)`로 렌더 결과 캡처

장점:

- Apple의 실제 효과와 동일

단점:

- SF Symbol/Emoji만 가능
- 사용자 PNG/SVG는 직접 지원하지 않음
- sandbox/권한 이슈 있음

#### Option B: 자체 렌더링 엔진

사용자 PNG/SVG는 이쪽이 필요하다.

추천 접근:

1. 폴더 base image를 `CIImage`/bitmap으로 로드
2. 심볼 alpha mask 생성
3. mask를 폴더 front face 영역에 배치
4. 다음 효과를 per-pixel로 적용

단순 Figma식 source-over가 아니라, base pixel RGB를 읽어 아래처럼 변환해야 한다.

개념 공식:

```text
base = folderPixel.rgb
mask = symbolAlpha 0..1

darkened = base * darkenFactor
highlighted = screen/lighten(base, highlightColor, edgeMask)
innerShadow = multiply(base, shadowColor, shiftedBlurredMask)
outerGlow = screen(base, glowColor, blurredMask)

result = combine based on masks and edge fields
```

초기 수치 후보:

```text
placement square symbol: X 352, Y 415, W 320, H 320
main target symbol color near screenshot: #569EC5
sampled folder face near symbol: #69B8E4
sampled symbol avg: #569EC5
```

초기 effect 후보:

```text
outerGlowColor: #A9E8FF
mainOverlayColor: #417E9F or derive from base * 0.82
innerShadowColor: #0D4258
highlightColor: #BDEEFF
```

하지만 이 값들은 Figma용으로는 맞지 않았다. 앱에서는 per-pixel fitting을 다시 해야 한다.

### 5.3 더 좋은 자체 렌더 알고리즘 제안

Figma 레이어 값보다 아래 방식이 더 정확할 가능성이 높다.

1. mask에서 signed distance field 또는 edge maps 생성:
   - `M`: 원본 mask
   - `B1 = gaussianBlur(M, 1.2)`
   - `B3 = gaussianBlur(M, 3.0)`
   - `edgeIn = M - erode(M)`
   - `edgeOut = dilate(M) - M`
   - `topLeftLight = shifted(M, -1, -1) - M`
   - `bottomRightDark = shifted(M, +2, +3)`

2. main fill:

```text
base.rgb = mix(base.rgb, base.rgb * 0.84, M * 0.75)
```

또는 screenshot target 방식:

```text
target = base.rgb * [0.82, 0.86, 0.88]
result = mix(base.rgb, target, M)
```

3. inner shadow:

```text
shadowMask = blur(shift(M, +2,+3), 1.8) * M
result = mix(result, result * [0.75,0.82,0.86], shadowMask * 0.5)
```

4. outer glow / bevel:

```text
glowMask = blur(M, 3.0) - M
result = screen(result, #A9E8FF, glowMask * 0.2)
```

5. highlight:

```text
highlightMask = blur(shift(M, -1,-1), 1.0) * edgeOut
result = screen(result, #BDEEFF, highlightMask * 0.35)
```

이 방식은 Figma보다 앱에서 훨씬 잘 튜닝 가능하다.

## 6. 필요한 샘플/파일

Downloads에 있는 파일:

```text
/Users/JS/Downloads/composite-back-front.png
/Users/JS/Downloads/composite-back-paper-front.png
/Users/JS/Downloads/Git.png
```

주의: `/Users/JS/Downloads/Git.png`는 사용자가 검정으로 바꿨다고 했지만 확인 당시 RGB가 여전히 붉은 계열이었다.

확인 결과:

```text
Git.png size: 3840x3840
RGB extrema: R 0..255, G 0..128, B 0..85, A 0..255
```

렌더링에 사용할 때는 원본을 건드리지 말고 alpha만 유지한 검정 mask를 생성하는 것이 좋다.

```swift
// concept
black.rgb = (0,0,0)
black.alpha = original.alpha
```

또는 Python으로는:

```python
from PIL import Image
im = Image.open("Git.png").convert("RGBA")
black = Image.new("RGBA", im.size, (0,0,0,0))
black.putalpha(im.getchannel("A"))
black.save("Git-black-mask.png")
```

첨부된 실제 그림 폴더 샘플:

```text
/var/folders/ym/f_p8k6kj5_qflxwmk_h2dsx00000gp/T/TemporaryItems/NSIRD_screencaptureui_FzKrBb/스크린샷 2026-05-28 오후 4.09.46.jpg
```

이 파일은 임시 경로라 사라질 수 있다. 새 프로젝트 시작 시 사용자에게 다시 첨부받거나 Downloads로 복사해 두는 것이 안전하다.

## 7. Figma 파일

작업했던 Figma 파일:

```text
https://www.figma.com/design/ydzO9AUe9xCBHvVZCBNVbL
```

하지만 사용자가 Figma의 결과가 많이 다르다고 했고, 새 앱 개발로 넘어가고 싶어한다. Figma 작업은 참고 정도로만 사용.

## 8. 로컬에 생성된 스크립트

현재 Codex 작업 폴더:

```text
/Users/JS/Documents/Codex/2026-05-28/macos-26-tahoe-codex-macos-26
```

주요 파일:

```text
TahoeIconProbe.swift
TahoeWorkspaceIconDump.swift
RenderTahoeFolderComposites.swift
ProbeTahoeFolderCustomization.swift
scan_tahoe_folder_assets.sh
tahoe_symbol_overlay.py
```

`tahoe_symbol_overlay.py`는 Figma용 레이어 레시피보다 나은 PNG 합성을 시도한 초기 스크립트다. 최종 품질은 부족하지만 출발점으로 유용하다.

## 9. 프로젝트 생성 시 추천 구조

앱 이름 예:

```text
FolderIconMaker
```

Swift Package 또는 Xcode macOS app.

추천 모듈:

```text
FolderIconMaker/
  App/
    FolderIconMakerApp.swift
    ContentView.swift
  Rendering/
    FolderBaseRenderer.swift
    SymbolMaskRenderer.swift
    FolderIconMakerEmbossRenderer.swift
    IconExporter.swift
  System/
    SystemFolderIconProvider.swift
    FinderCustomizationProbe.swift
  Models/
    RenderSettings.swift
    FolderStyle.swift
  Resources/
    optional fallback assets
```

### RenderSettings 초안

```swift
struct RenderSettings {
    var canvasSize: CGFloat = 1024
    var symbolRect: CGRect = CGRect(x: 352, y: 415, width: 320, height: 320)
    var usePaperSheet: Bool = true

    var mainDarken: CGFloat = 0.16
    var innerShadowOpacity: CGFloat = 0.35
    var innerShadowBlur: CGFloat = 1.8
    var innerShadowOffset: CGSize = CGSize(width: 2, height: 3)

    var outerGlowOpacity: CGFloat = 0.20
    var outerGlowBlur: CGFloat = 3.0
    var highlightOpacity: CGFloat = 0.35
    var highlightBlur: CGFloat = 1.0
    var highlightOffset: CGSize = CGSize(width: -1, height: -1)
}
```

### Rendering pipeline 초안

```swift
func render(folderBase: CGImage, symbolMask: CGImage, settings: RenderSettings) -> CGImage {
    // 1. Fit symbol mask into settings.symbolRect
    // 2. Generate blurred/shifted/edge masks
    // 3. Iterate pixels or use CI filters
    // 4. Apply base-relative darkening and bevels
    // 5. Export PNG
}
```

## 10. 개발 시 검증 방법

최소 세 개의 기준 이미지가 필요하다.

1. 실제 Finder 그림 폴더 샘플
2. macOS가 `{"sym":"camera.viewfinder"}`로 렌더한 결과
3. 앱이 같은 mask로 렌더한 결과

픽셀 비교:

- overlay bbox
- 평균 RGB
- edge highlight 위치
- inner shadow 위치
- SSIM 또는 mean absolute error

주의: Git 로고는 실제 macOS SF Symbol과 형태가 다르므로, 먼저 `camera.viewfinder`처럼 시스템 심볼과 같은 mask로 fitting하는 것이 좋다. 그 후 Git에 적용해야 한다.

## 11. 다음 에이전트에게 요청할 작업

1. 새 macOS SwiftUI 프로젝트 생성
2. Downloads의 폴더 base PNG와 Git.png 로드
3. Git.png를 alpha-only black mask로 변환
4. Core Image/Core Graphics 기반 renderer 구현
5. 먼저 `camera.viewfinder` 또는 그림 폴더 샘플에 맞춰 알고리즘 튜닝
6. UI에서 값 조정 가능하게 만들기:
   - symbol x/y/w/h
   - main darken
   - outer glow opacity/blur
   - inner shadow opacity/blur/offset
   - highlight opacity/blur/offset
7. PNG export
8. 가능하면 Finder custom icon 적용 기능 추가

## 12. 중요한 판단

Figma 레이어로 “수정 가능하게” 만드는 것은 가능하지만 사용자가 원하는 동일성에는 부족했다.

정확도 우선이면:

```text
macOS app + CoreGraphics/CoreImage renderer + numeric tuning UI
```

가 맞다.

가장 정확한 Apple 공식 효과는 SF Symbol/Emoji에 한해 Finder/IconServices가 직접 렌더링하는 결과를 캡처하는 방식이다. 임의 SVG/PNG에는 자체 렌더링이 필요하다.
