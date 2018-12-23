$retroarch_path = "C:\RetroArch"
$retroarch_lkg_path = "C:\RetroArch-LKG"
$retroarch_upgrade_path = "C:\RetroArch-Update"
$updater_path = "ps_updater"
$github_url = "https://api.github.com/repos/libretro/RetroArch/releases"
$buildbot_url = "https://buildbot.libretro.com/stable"
$platform = "windows/x86_64"
$preserved_directories = "cheats", "config", "cores", "downloads", "history", "playlists", "recordings", "saves", "screenshots", "states", "system", "thumbnails"
$preserved_files = "retroarch.cfg", "retroarch-core-options.cfg"

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$github_data = Invoke-WebRequest -UseBasicParsing $github_url
$release_latest = ($github_data | ConvertFrom-Json)[0].tag_name
$release_latest = $release_latest.Replace("v","")
$release_latest_date = ($github_data | ConvertFrom-Json)[0].published_at
$release_latest_date = Get-Date -Date $release_latest_date -Format d

Write-Host "--Github latest release:",$release_latest,$release_latest_date

If ($(Test-Path $retroarch_path)) {
    If (!(Test-Path $retroarch_path\$updater_path )) {
        mkdir $retroarch_path\$updater_path | Out-Null
        Write-Host "Created: $retroarch_path\$updater_path"
    }
    Else {
        If ($(Test-Path $retroarch_path\$updater_path\version)) {
            $release_existing = Get-Content $retroarch_path\$updater_path\version
            If ($release_latest -eq $release_existing) {
                Write-Host "--Installed release: $release_existing" 
                Break
            }
        }
    }
    If ($(Test-Path $retroarch_lkg_path)) {
        Write-Host "RetroArch LKG path at $retroarch_lkg_path exists. Remove it before upgrading."
        Break
    }
    Write-Host "Downloading RetroArch $release_latest"
    $release_url = "$buildbot_url/$release_latest/$platform/RetroArch.7z"
    Start-BitsTransfer -Source $release_url -Destination $retroarch_path\$updater_path\RetroArch-$release_latest.7z -TransferType Download
    
    If ($(Test-Path $retroarch_path\$updater_path\RetroArch-$release_latest.7z)) {
        Write-Host "Extracting to $retroarch_upgrade_path"
        mkdir $retroarch_upgrade_path | Out-Null
        $target = "-o$retroarch_upgrade_path"
        & .\7za.exe x $retroarch_path\$updater_path\RetroArch-$release_latest.7z $target
        Move-Item $retroarch_path $retroarch_lkg_path
        Write-Host "Preserving existing install in $retroarch_lkg_path"
        Move-Item $retroarch_upgrade_path $retroarch_path
        Write-Host "Building upgraded RetroArch installation in $retroarch_path"
        ForEach ($item in $preserved_directories) {
            $source = $retroarch_lkg_path + "\" + $item
            If (Test-Path $source) {
                Write-Host "Copying $source to $retroarch_path"
                Copy-Item $source $retroarch_path -Recurse -Force
            }
        }
        ForEach ($Item in ($preserved_files)) {
            $source = $retroarch_lkg_path + "\" + $Item
            If (Test-Path $source) {
                Write-Host "Copying $source to $retroarch_path"
                Copy-Item $source $retroarch_path -Force
            }
        }
        Write-Host "Writing version tag file."
        mkdir $retroarch_path\$updater_path | Out-Null
        $release_latest | Set-Content $retroarch_path\$updater_path\version
        Write-Host "Complete!"
    }
    Else {
        Write-Host "Download failed. Attempted URL: $release_url"
    }
}
Else {
    Write-Host "$retroarch_path does not exist."
}
