# Mivio Roku Agents Configuration

## Project Overview
Mivio for Roku is a premium, high-performance media management and playback application explicitly designed for Roku devices. Built natively using BrightScript and Roku SceneGraph (RSG), Mivio delivers an elegant, fast, and deeply integrated media streaming experience for Roku TVs and streaming sticks.

## Key Technologies
- Language: BrightScript
- Framework: Roku SceneGraph (RSG)
- Development Approach: Native Roku development

## Project Structure
```
mivio-roku/
├── components/       # SceneGraph components
├── images/           # Image assets
├── source/           # BrightScript source files
├── manifest          # Roku manifest file (currently empty)
├── CONTRIBUTING.md   # Contribution guidelines
├── LICENSE           # License file
├── README.md         # Project documentation
└── SECURITY.md       # Security policy
```

## Development Guidelines
- Target branch for PRs: `beta` (main is production-ready)
- Prerequisites: 
  - A Roku device in Developer Mode
  - Command-line tools (make, curl) for deploying to the device
  - Roku VSCode Extension (recommended for BrightScript debugging)
- Setup process:
  1. Clone repository
  2. Configure device IP in Makefile or .env file:
     ```
     ROKU_DEV_TARGET=192.168.1.xxx
     ROKU_DEV_PASSWORD=your_password
     ```
  3. Deploy to Roku using `make install`

## Platform Features & Limitations
- ❌ No USB / Local Storage: Roku's limitations prevent reading local media efficiently
- ✅ Home Server Client: Functions exclusively as a streaming client for home servers (Plex, Jellyfin)
- ✅ Native Roku Player: Utilizes native BrightScript Video node for hardware-accelerated media playback
- ❌ No Local Multi-Account: Profiles and watch states are strictly managed by home server

## Agent Instructions
When working on this project:
1. Understand Roku SceneGraph (RSG) architecture and component lifecycle
2. Work primarily with BrightScript in the source/ directory
3. Modify SceneGraph components in the components/ directory as needed
4. Ensure compatibility with Roku's specific UI conventions and limitations
5. Focus on home server client functionality (Plex, Jellyfin, Emby integration)
6. Optimize for Roku's hardware capabilities and limitations
7. Test thoroughly on actual Roku devices in Developer Mode
8. Follow existing code patterns and conventions in the BrightScript codebase
9. Keep the scope focused on media streaming - avoid attempting to implement local storage features
10. Update documentation when changing public APIs or significant functionality