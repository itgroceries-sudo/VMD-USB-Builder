# 🚀 VMD Driver Cloud Installer & USB Builder
### *Powered by IT Groceries Shop*

![License](https://img.shields.io/badge/License-MIT-green.svg) ![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg) ![Version](https://img.shields.io/badge/Version-8.2%20Stable-purple.svg) ![Intel](https://img.shields.io/badge/Driver%20Source-Official%20Intel-0071C5.svg)

**The ultimate solution for "No Drives Found" during Windows Installation.** Automated. Intelligent. Always Fresh.

---

## 📸 Overview

This project solves the common issue where Windows Setup cannot detect NVMe drives on modern Intel platforms (11th Gen+ Tiger Lake/Alder Lake/Raptor Lake) due to Intel® VMD technology.

### 🛠 Phase 1: The Smart Builder (PowerShell)
*Runs on your working PC to prepare the USB.*

<details><summary>Click to expand *(See more)*</summary>
    <td width="50%" align="center" valign="top">
      <img src="Images/image_363b6a.png" alt="VMD USB Builder" width="95%" />
      <br />
      <em>(Screenshot: PowerShell script used to automate the process of creating a bootable USB drive.)</em>
    </td>
</details>

*(Screenshot: The Builder detecting CPU and recommending the correct driver version)*

**✨ Key Features:**
* **📡 Live Fetch:** Downloads the *latest* `SetupRST.exe` directly from Intel's official servers. No stale drivers!
* **🧠 Intelligent Scanning:** Automatically detects your current CPU generation and recommends the optimal driver version (v18, v19, or v20).
* **⚡ Auto-Extraction:** Magically extracts `.inf` and `.sys` files from the downloaded `.exe` installer (bypassing the install wizard).
* **💾 One-Click Deploy:** Copies the `Autounattend.xml` and driver payload directly to your Windows Installation USB.

### 🔧 Phase 2: The Injector (WinPE)
*Runs automatically when you boot the USB on the target PC.*

<details><summary>Click to expand *(See more)*</summary>
<table border="0">
  <tr>
    <td width="50%" align="center" valign="top">
      <img src="Images/image_363ee8.png" alt="WinPE Installer UI" width="95%" />
      <br />
      <em>(Screenshot: The Script running inside Windows Setup, ready to inject drivers)</em>
    </td>
    <td width="50%" align="center" valign="top">
      <img src="Images/image_3709f7.jpg" alt="WinPE Installer Action" width="95%" />
      <br />
      <em>(Screenshot: The Script running inside Windows Setup, ready to inject drivers)</em>
    </td>
  </tr>
</table>
</details>


**✨ Key Features:**
* **🔍 Auto-Launch:** Triggered via `Autounattend.xml` before Windows Setup begins.
* **🛡️ Hardware Detection:** Scans the target machine to identify the VMD Controller.
* **💉 On-the-Fly Injection:** Uses `drvload` to inject the VMD driver into WinPE memory instantly.
* **👀 Instant Visibility:** Your NVMe drives appear immediately after injection.
* **🛑 Rescue Mode:** If an old Windows OS is found, offers a "Go to BIOS" shortcut.

---

## 🚀 How It Works

### Step 1: Build Your USB
1.  Run `PowerShell` and type 
<details><summary>Click to expand</summary>
iex(irm bit.ly/VMDUSBBuilder)
</details>

2.  The script analyzes your hardware:
    > `[ System Detected ] CPU: Intel Core i5-10600K -> Recommendation: Universal`
3.  Select your desired mode:
    * **[1] Build All:** Downloads v18, v19, and v20 (Safest bet).
    * **[2-4] Specific Gen:** Downloads only what you need.
4.  The script downloads `SetupRST.exe` from Intel, extracts the drivers using internal switches, and saves them to your USB's `\Support` folder.

### Step 2: Install Windows
1.  Boot your target PC with the prepared USB.
2.  **Before** the partition screen, the **VMD Driver Installer** window will pop up.
3.  Select the driver version corresponding to the target CPU (e.g., Press `20` for Gen 13/14).
4.  Watch the magic happen! The script injects the driver, and Windows Setup proceeds normally.

---

## 📦 Compatibility Matrix

| Intel Generation | VMD Version | Folder Name | Status |
| :--- | :--- | :--- | :--- |
| **Gen 10 - 11** (Ice/Tiger Lake) | **v18.x** | `VMD_v18` | ✅ Supported |
| **Gen 12** (Alder Lake) | **v19.x** | `VMD_v19` | ✅ Supported |
| **Gen 13 - 14+** (Raptor Lake) | **v20.x** | `VMD_v20` | ✅ Supported |

---

## ⚠️ Requirements
* **Source PC:** Windows 10/11 with PowerShell 5.1+ (for building the USB).
* **Target PC:** Intel Platform with VMD/RST enabled in BIOS.
* **Internet:** Required during the *Build* phase to fetch drivers.

---

## 📜 Credits
Developed with ❤️ by **IT Groceries Shop**.
* *Script Logic:* PowerShell & Batch
* *Driver Source:* Intel Corporation

---

## 🚀 Original Source
<div align="center">
<details>
  <summary>Click to watch video YouTube</summary>

  [![YouTube Video](https://img.youtube.com/vi/Il1kgIVKE3U/sddefault.jpg)](https://www.youtube.com/watch?v=Il1kgIVKE3U  "แจกไฟล์ RST / VMD / AHCI แก้ปัญหาลง Windows แล้วมองไม่เห็น SSD/NVMe 4⃣🅺/|💻🅸🆃🅶🆁🅾🅲🅴🆁🅸🅴🆂™")
</details>
</div>
---

