## THIS SCRIPT IS UNTESTED and INCOMPLETE, has no error handling, very few checks, may eat all the cheese in your fridge.
# The settings themselves are known to work, but this has been adapted from various .reg/.bat files.
# This script hides most of the Windows logon UI and sets the shell to be defined per-user, or explorer.exe if not defined.

# RUN AS ADMINISTRATOR

# Turn off the boot and shutdown ux. If your motherboard UEFI supports custom logos, your build will look more "complete" with one installed.

bcdedit.exe -set {globalsettings} bootuxdisabled on

## TODO: Install-WindowsFeatures: Device Lockdown, enable 'Custom Logon', 'Shell Launcher' and 'Unbranded Boot'

# Set required registry params

Write-Host "Setting EmbeddedLogon parameters."
$EmbeddedLogon = "HKLM:\SOFTWARE\Microsoft\Windows Embedded\EmbeddedLogon"
$Names = "HideAutoLogonUI", "HideFirstLogonAnimation"
$value = "1"

if (!(Test-Path $EmbeddedLogon)) {
    Write-Host "EmbeddedLogon registry path does not exist, creating it."
    New-Item -Path $EmbeddedLogon -Force | Out-Null
}

foreach ($name in $names) {
    Write-Host "Setting property $name"
    Set-ItemProperty -Path $EmbeddedLogon -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}

# Set shell directives

$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$perUserShellPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\system.ini\boot"
$name = "Shell"
$defaultShell = "explorer.exe"
$perUserShell = "USR:Microsoft\\Windows NT\\CurrentVersion\\Winlogon"

Write-Host "Setting default shell to $defaultShell"
Set-ItemProperty -Path $WinlogonPath -Name $name -Value $defaultShell -Force | Out-Null
Write-Host "Setting per-user shell directive."
Set-ItemProperty -Path $perUserShellPath -Name $name -Value $perUserShell -Force | Out-Null
