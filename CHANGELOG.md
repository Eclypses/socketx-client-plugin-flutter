# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
-

### Changed
-

### Fixed
-


## [2.0.0] - 2026-07-30

### Changed
- **Public dependency sources.** iOS SPM now resolves `SocketXClient` from `mte-socketx-client-ios`: local path via the `MTE_SOCKETX_IOS_PATH` env var or `mteSocketxIosPath` in `local.properties`, otherwise the public GitHub package `github.com/Eclypses/mte-socketx-client-ios` (2.2.0). The stale `socketx-client-swift` remote fallback was removed.
- Android now depends on `com.eclypses:mte-socketx-client-android:2.0.0` from Maven Central; the internal JFrog Artifactory repository was removed, and the sibling `includeBuild` composite is dev-guarded (used only when the sibling lib is checked out).
- Bumped iOS minimum deployment target from 14.0 to 16.0 to match the `mte-socketx-client-ios` requirement.


## [1.3.0] - 2026-02-11

### Added
- Added Unit and Functionality Tests

### Changed
- Edited pipeline to run tests when pushing to develop or merging with master

### Fixed
-


## [1.2.1] - 2026-01-28

### Added
-

### Changed
-

### Fixed
- Forgot to save the CHANGELOG before commit.

## [1.2.0] - 2026-01-28

### Added
-

### Changed
- Changed example/pubspec.yaml to use local plugin
- Changed iOS and Android projects to use published socketx libraries rather tha local copies

### Fixed
-


## [1.0.2] - 2026-01-27

### Added
-

### Changed
- Corrected mistake in pipeline yml

### Fixed
-


## [1.0.1] - 2026-01-27

### Added
-

### Changed
- Edited pipeline yml

### Fixed
-


## [1.0.0] - 2026-01-26

### Added
- Initial Version

### Changed
-

### Fixed
-



[1.0.0]: https://github.com/Eclypses/socketx-client-flutter/releases/tag/v1.0.0

[1.0.1]: https://github.com/Eclypses/socketx-client-flutter/releases/tag/v1.0.1

[1.0.2]: https://github.com/Eclypses/socketx-client-flutter/releases/tag/v1.0.2

[1.2.1]: https://github.com/Eclypses/socketx-client-flutter/releases/tag/v1.2.1

[1.3.0]: https://github.com/Eclypses/socketx-client-flutter/releases/tag/v1.3.0
