# 🍿 Mivio for Roku

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Platform Compatibility](https://img.shields.io/badge/Platforms-RokuOS-brightgreen.svg?style=flat-square)](#platform-specific-goals)

**Mivio** is a premium, high-performance media management and playback application explicitly designed for Roku devices. Built natively using **BrightScript** and **Roku SceneGraph (RSG)**, Mivio delivers an elegant, fast, and deeply integrated media streaming experience for Roku TVs and streaming sticks.

---

## 🎨 Platform Features & Limitations

Mivio Roku embraces Roku's specific UI conventions while pushing the boundaries of SceneGraph capabilities, keeping the scope extremely focused:

- ❌ **No USB / Local Storage**: Roku's limitations prevent reading local media efficiently.
- ✅ **Home Server Client**: Functions exclusively as a streaming client for your home servers (Plex, Jellyfin).
- ✅ **Native Roku Player**: Utilizes the native BrightScript Video node for hardware-accelerated, yet somewhat limited, media playback.
- ❌ **No Local Multi-Account**: Profiles and watch states are strictly managed by your home server.

---

## 🚀 Getting Started

### Prerequisites
- A Roku device in **Developer Mode**.
- Command-line tools (e.g., `make`, `curl`) for deploying to the device.
- Roku VSCode Extension (recommended for BrightScript debugging).

### Setup and Running the Project
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/albertolicea00/mivio-roku.git
   cd mivio-roku
   ```

2. **Configure Device IP:**
   Update the `Makefile` or your `.env` file with your Roku device's IP address and developer password:
   ```bash
   ROKU_DEV_TARGET=192.168.1.xxx
   ROKU_DEV_PASSWORD=your_password
   ```

3. **Deploy to Roku:**
   Run the standard deployment command to zip the source and side-load it onto the device:
   ```bash
   make install
   ```

---

## 🤝 Contribution Guidelines

We use a structured branch strategy to protect stable builds while supporting active feature implementation:
- **`main`**: Production-ready release branch.
- **`beta`**: Standard development target. **Always target your PRs to `beta`!**

For detailed instructions on commit formats, coding style guidelines, and PR checks, please review [CONTRIBUTING.md](CONTRIBUTING.md).

For vulnerability reporting or security-related matters, see [SECURITY.md](SECURITY.md).

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
