<div align="center">

# 🌾 FarmHud

[![Documentation](https://img.shields.io/badge/📖_Docs-GitHub_Pages-2ea44f?style=for-the-badge)](https://xurkon.github.io/PA-FarmHud/)

<img src="https://img.shields.io/badge/WoW-3.3.5a-blue?style=for-the-badge&logo=battle.net&logoColor=white" alt="WoW 3.3.5a">
<img src="https://img.shields.io/badge/Version-2.0.0--alpha-orange?style=for-the-badge" alt="Version 2.0.0-alpha">
<img src="https://img.shields.io/badge/Project-Ascension-purple?style=for-the-badge" alt="Project Ascension">
<img src="https://img.shields.io/badge/Status-Work%20In%20Progress-red?style=for-the-badge" alt="WIP">

**A transparent HUD overlay for efficiently farming herbs, ore, and other gathering nodes**

<br>

> ⚠️ **WORK IN PROGRESS** ⚠️
>
> This addon is currently under active development. It is based on an edited 3.3.5a version,
> **not** a complete backport from retail. Many features are still being built and may not
> function correctly. Use at your own risk!

<br>

<img src="https://img.shields.io/badge/Compatible%20With-GatherMate2%20%7C%20Routes%20%7C%20HandyNotes-informational?style=flat-square" alt="Compatibility">

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🗺️ HUD Overlay

- Transparent minimap overlay centered on screen
- See gathering nodes without opening the map
- Adjustable opacity and scale

</td>
<td width="50%">

### 📍 TrailPath Module

- Drop pins to mark your farming route
- Pins remain static at world positions
- Configurable fade timer

</td>
</tr>
<tr>
<td width="50%">

### 🔌 Addon Integration

- **GatherMate2** - Display herb/ore nodes
- **Routes** - Show your farming routes
- **HandyNotes** - Display custom markers
- **LootCollector** - Track your loot
- **_NPCScan.Overlay** - Rare spawn areas

</td>
<td width="50%">

### ⚙️ Customization

- Configurable keybindings
- Adjustable HUD size and position
- Cardinal direction indicators
- Mouse interaction toggle

</td>
</tr>
</table>

---

## 📦 Installation

1. Download the latest release
2. Extract to `Interface/AddOns/FarmHud`
3. Restart WoW or `/reload`

---

## 🎮 Usage

| Keybind | Action |
|---------|--------|
| **Toggle HUD** | Set in WoW Keybindings → Addons |
| **/farmhud** | Open configuration panel |

---

## 📜 Changelog

<details>
<summary><b>v2.0.0</b> - 3.3.5a Backport <i>(December 9, 2025)</i></summary>

### 🔄 Complete Backport from Retail to 3.3.5a

**Core Changes:**

- ✅ Updated `.toc` to interface version 30300
- ✅ Replaced modern `C_Map` API with 3.3.5a equivalents
- ✅ Created polyfills for `C_Map`, `C_Minimap`, `C_Timer`, `C_AddOns`
- ✅ Replaced XML mixin attributes with standard Lua scripts
- ✅ Removed retail-specific checks (`WOW_PROJECT_ID`, `EditModeManagerFrame`)

**Fixes:**

- 🔧 Fixed cardinal points positioning on HUD
- 🔧 TrailPath: Pins now remain static at world positions
- 🔧 TrailPath: Corrected minimap/HUD trail positioning and scaling
- 🔧 TrailPath: Proper clipping for pins outside visible range

**Technical:**

- 📁 Created `Compat.lua` with API polyfills
- 📁 Modified `FarmHud.xml` for standard script blocks
- 📁 Updated event handling for 3.3.5a system

</details>

<details>
<summary><b>v1.1.0</b> - Original Release <i>(May 4, 2011)</i></summary>

**Changes:**

- 🔧 Fixed config dialog
- ➕ Added `_NPCScan.Overlay` support

</details>

---

## 👥 Credits

<table>
<tr>
<td align="center">
<b>CodeRedLin</b><br>
<sub>Original Author</sub>
</td>
<td align="center">
<b>Xurkon</b><br>
<sub>3.3.5a Backport</sub>
</td>
</tr>
</table>

---

<div align="center">

**Made for [Project Ascension](https://ascension.gg)**

<sub>This addon is open source and provided as-is. Not affiliated with Blizzard Entertainment.</sub>

</div>

[Documentation](docs/index.html)
