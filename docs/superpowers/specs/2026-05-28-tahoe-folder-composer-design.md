# Tahoe Folder Composer Design

작성일: 2026-05-28

## 목표

`TahoeFolderComposer`는 macOS Tahoe 스타일의 폴더 아이콘을 빠르게 만들기 위한 개인용 macOS 앱이다. 사용자는 PNG 또는 SVG 심볼을 넣고, 제공된 Tahoe 폴더 베이스 이미지 위에 고정 emboss 레시피로 합성한 뒤, 결과를 1024x1024 PNG로 저장하거나 선택한 폴더의 Finder custom icon으로 적용한다.

첫 버전은 정확한 제품화보다 빠른 개인 사용을 우선한다. 정상 입력을 넣었을 때 결과가 빠르게 나오면 성공이다.

## 확정된 범위

- 일반 Xcode macOS SwiftUI 앱으로 만든다.
- 첫 버전은 비샌드박스 로컬 앱으로 둔다.
- 폴더 베이스는 프로젝트의 `assets/composite-back-front.png`, `assets/composite-back-paper-front.png`를 사용한다.
- 심볼 입력은 PNG와 best-effort SVG를 지원한다.
- 렌더 효과는 고정 Tahoe emboss 레시피를 사용한다.
- 결과 이미지는 항상 1024x1024 PNG로 만든다.
- `NSWorkspace.shared.setIcon(_:forFile:options:)`로 선택한 폴더에 렌더 결과를 custom icon으로 적용한다.

## 제외 범위

- SF Symbol/Emoji의 Finder 공식 xattr 렌더 캡처는 첫 버전에 넣지 않는다.
- 튜닝 슬라이더와 프리셋 저장은 첫 버전에 넣지 않는다.
- `.icns` export는 첫 버전에 넣지 않는다.
- 복잡한 SVG 호환성, 샌드박스 배포, 권한 설계, 정교한 예외 처리는 첫 버전에 넣지 않는다.
- 엣지 케이스 대응은 하지 않는다.

## 앱 구조

앱 이름은 `TahoeFolderComposer`로 한다. UI는 단일 작업 화면으로 구성한다.

- 왼쪽 영역: 폴더 스타일 선택, 심볼 파일 선택, 렌더, PNG 저장, 폴더에 적용 버튼
- 오른쪽 영역: 렌더 결과 미리보기
- 하단 또는 작은 텍스트 영역: 간단한 상태 메시지

주요 파일:

- `TahoeFolderComposerApp.swift`: 앱 진입점
- `ContentView.swift`: 전체 UI와 사용자 액션 연결
- `Models/FolderStyle.swift`: `empty`, `paper` 폴더 스타일
- `Models/RenderSettings.swift`: 고정 캔버스 크기, 심볼 위치, emboss 수치
- `Rendering/SymbolImageLoader.swift`: PNG/SVG 로드와 alpha mask 생성
- `Rendering/TahoeEmbossRenderer.swift`: 폴더 베이스와 심볼 마스크 합성
- `Exporting/PNGExporter.swift`: `CGImage`를 PNG 파일로 저장
- `SystemIntegration/FinderIconApplier.swift`: 렌더 결과를 폴더 custom icon으로 적용

## 데이터 흐름

1. 사용자가 `Empty` 또는 `Paper` 폴더 스타일을 선택한다.
2. 앱이 번들 리소스에서 해당 1024 폴더 베이스 PNG를 로드한다.
3. 사용자가 PNG 또는 SVG 심볼 파일을 선택한다.
4. `SymbolImageLoader`가 심볼을 alpha mask로 변환한다.
5. `TahoeEmbossRenderer`가 심볼 mask를 고정 위치에 배치한다.
6. renderer가 폴더 베이스 픽셀을 기준으로 심볼 영역을 어둡게 만들고, 가장자리 하이라이트/그림자/글로우를 더한다.
7. 결과 `CGImage`를 미리보기, PNG export, Finder custom icon 적용에 재사용한다.

## 렌더링 방식

첫 버전은 Core Graphics bitmap 기반 per-pixel 처리로 구현한다. Core Image 필터 체인은 첫 버전에 도입하지 않는다.

기본 설정:

- 캔버스: 1024x1024
- 기본 심볼 영역: `x: 352, y: 415, width: 320, height: 320`
- 폴더 스타일:
  - `empty`: `composite-back-front.png`
  - `paper`: `composite-back-paper-front.png`
- 메인 음각 효과: mask 내부에서 base RGB를 약 0.84배로 어둡게 한다.
- 내부 그림자: mask를 우하단으로 민 영향으로 어두운 edge를 만든다.
- 하이라이트/글로우: mask edge 주변에 밝은 cyan 계열 영향을 더한다.

심볼 이미지는 컬러를 그대로 쓰지 않고 alpha 중심의 mask로 사용한다. PNG는 alpha 채널을 우선 사용하고, SVG는 `NSImage(contentsOf:)`로 로드 가능한 경우 래스터화해 mask를 만든다.

## Export와 Finder 적용

PNG export는 `NSSavePanel`로 저장 위치를 받은 뒤 현재 렌더 결과를 PNG로 쓴다. 출력은 항상 1024x1024이다.

Finder 적용은 사용자가 `Apply to Folder`를 누르면 `NSOpenPanel`로 폴더 하나를 선택하고, 현재 렌더 결과를 `NSImage`로 변환한 뒤 `NSWorkspace.shared.setIcon(_:forFile:options:)`에 전달한다. 첫 버전은 비샌드박스 앱이므로 별도 권한 흐름을 만들지 않는다.

## 실패 처리

이 앱은 개인용 빠른 제작 도구이므로 정교한 예외 처리를 만들지 않는다. 실패 상황은 간단한 `statusMessage`에 `로드 실패`, `저장 실패`, `적용 실패`처럼 표시한다. 복구 UI, 상세 오류 분류, 엣지 케이스 대응은 첫 버전에 넣지 않는다.

## 테스트와 검증

자동 테스트는 핵심 유닛만 최소로 둔다.

- `TahoeEmbossRendererTests`: 1024 베이스 이미지와 간단한 mask를 넣었을 때 결과 이미지가 생성되는지 확인한다.
- `PNGExporterTests`: `CGImage`를 PNG 데이터 또는 파일로 변환할 수 있는지 확인한다.

수동 검증:

1. `assets/composite-back-front.png`와 PNG 심볼로 미리보기가 생성된다.
2. `assets/composite-back-paper-front.png`와 SVG 심볼로 미리보기가 생성된다.
3. 생성 결과를 임시 폴더에 Finder custom icon으로 적용할 수 있다.

## 성공 기준

- 앱을 실행하면 단일 작업 화면이 열린다.
- PNG/SVG 심볼을 선택하고 렌더하면 Tahoe 스타일 폴더 이미지 미리보기가 나온다.
- 결과를 1024x1024 PNG로 저장할 수 있다.
- 결과를 선택한 폴더의 Finder custom icon으로 적용할 수 있다.
