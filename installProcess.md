# Retrobox software installation
* If you want to hide more of the Windows UX and make the machine look/feel more like a console, you'll need a Windows 10 Enterprise or LTSC SKU.
* Take the latest cumulative and security updates.
* If the machine is to belong to a domain, join the domain.
* Create a C:\build directory and copy all of the files from this repository's build directory to it.
    
    * Also, add:
        * LaunchBox installer
        * Kodi installer
        * Controller Companion installer
        * Launcher4Kodi installer
        * RetroArch.7z
        * PCSX2.7z
        * Dolphin.7z
        * GPU drivers
        * autologon.exe
        * vcredist 2013/2015/2017 x86 and x64
        * dxredist june 2010
        * Zadig

* Install necessary drivers for your hardware. Usually a conservative approach is best, to reduce the number of processes spawned on boot or services running in the background.
    * I only install NVIDIA drivers (without GeForce Experience).

* TODO: Group Policy

* In an elevated PowerShell session, run RetroBox-InitialSetup.ps1.
    * [Enterprise SKUs] Set BCD "bootuxdisabled"
    * [Enterprise SKUs] Install Embedded Logon and other custom shell features
    * Install .NET Framework 3.5
    * Set per-user shell directives. The default shell will still be explorer.exe.
    * Open firewall rulegroups for remote management and monitoring.

* Install dxredist and vcredist files.
    * dxredist June 2010
    * vc: 2013, 2015, 2017

* devreorder
    * Run install.ps1. This script modifies system files.
* Set power profile to High Performance or Ultimate Performance.
* Create a normal user account for the 10' UI (Big Box, consoles and handhelds).
* Optionally, create a normal user account for the 2' UI (LaunchBox, retro computers).
* Install Kodi.
* Install Controller Companion.
* Install Launcher4Kodi. Don't change the shell parameters yet.
* Install and license LaunchBox, installing to C:\LaunchBox.
* Decompress the latest RetroArch stable release to C:\RetroArch.
* Decompress the latest Dolphin and PCSX2 releases to C:\Dolphin and C:\PCSX2.
* Create a C:\scripts directory and copy all of the files from this repository's scripts directory to it.
* Copy the files for the bliss-box API and firmware to C:\bliss-box.
* If you are using network storage for your games, create an NTFS link (mklink) to your share from C:\LaunchBox\Games.
* Set-DirectoryPermissions.ps1 is provided to aid in allowing your normal user accounts to access and write to the emulator and LaunchBox directories.
* Configure Launcher4Kodi. When you are ready, set the user's shell to Launcher4Kodi by modifying HKCU:\Microsoft\Windows NT\CurrentVersion\Winlogon.
