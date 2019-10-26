Function Update-RetroArch {
    param (
        [Parameter(Mandatory = $true)] [String]$RetroArchPath,
        [switch]$CheckVersionOnly
    )

    $retroarch_path = $RetroArchPath
    $retroarch_lkg_path = $RetroArchPath + '-LKG'
    $retroarch_upgrade_path = $RetroArchPath + '-Upgrade'
    $updater_path = "ps_updater"
    $github_url = "https://api.github.com/repos/libretro/RetroArch/releases"
    $buildbot_url = "https://buildbot.libretro.com/stable"
    $platform = "windows/x86_64"
    $preserved_directories = "autoconfig", "cheats", "config", "cores", "downloads", "history", "playlists", "recordings", "saves", "screenshots", "states", "system", "thumbnails"
    $preserved_files = "retroarch.cfg", "retroarch-core-options.cfg", "retroarch-overrides.cfg"

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $github_data = Invoke-WebRequest -UseBasicParsing $github_url
    $release_latest = ($github_data | ConvertFrom-Json)[0].tag_name
    $release_latest = $release_latest.Replace("v", "")
    $release_latest_date = ($github_data | ConvertFrom-Json)[0].published_at
    $release_latest_date = Get-Date -Date $release_latest_date -Format d

    Write-Host "--Github latest release:", $release_latest, $release_latest_date
    # Catch 4-digit version strings, like '1.7.9.2', as they don't match what's on the buildbot
    If ($release_latest.Length -gt 5) {
        $release_latest = $release_latest.SubString(0, [math]::min(5, $release_latest.length))
        Write-Host "Latest version is suspected to be a re-release - looking for version $release_latest, instead."
    }
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
        If ($CheckVersionOnly) {
            break
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
}

Function Update-RetroArchCores {
    param (
        [Parameter(Mandatory = $true)] [String]$RetroArchPath
    )

    # Location variables
    $cores_url = "http://buildbot.libretro.com/nightly/windows/x86_64/latest"
    $retroarch_path = $RetroArchPath
    $cores_path = "$retroarch_path\cores"
    $updater_path = "$retroarch_path\ps_updater"
    $logfile = "$updater_path\cores_updater.log"

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    # Prepare files
    if (-not(Test-Path "$updater_path\cores_timestamps.old")) { $null > "$updater_path\cores_timestamps.old" }
    if (-not(Test-Path "$updater_path\cores_timestamps.new")) { $null > "$updater_path\cores_timestamps.new" }
    mv "$updater_path\cores_timestamps.new" "$updater_path\cores_timestamps.old" -Force
    # Grab timestamps from URL
    Start-BitsTransfer -Source $cores_url/.index-extended -Destination $updater_path\cores_timestamps.new -TransferType Download

    # Check if downloaded
    if ($(Test-Path "$updater_path\cores_timestamps.new")) {

        # New logfile entry
        echo "-- $(date) --" >> "$logfile"

        # Download and replace cores
        $cores = Get-ChildItem $cores_path -File *.dll
        for ($i = 0; $i -lt $cores.Count; $i++) {
            if (-not($cores[$i].name.Contains("_libretro"))) { continue }
            $corename = $cores[$i].name
            $timestamp_old = $(Get-Content "$updater_path\cores_timestamps.old" | Select-String -simplematch $corename)
            $timestamp_new = $(Get-Content "$updater_path\cores_timestamps.new" | Select-String -simplematch $corename)
            $current_timestamp = $timestamp_new.ToString($timestamp_new).Split(" ")[0]
            if ( "$timestamp_new" -eq "$timestamp_old" ) {
                Write-Host $current_timestamp, "SKIPPED ", $corename -ForegroundColor Gray
                Write-output $current_timestamp`t"SKIPPED "`t$corename >> $logfile
                continue
            }

            $core_full_url = $cores_url + "/" + $corename + ".zip"
            Start-BitsTransfer -Source $core_full_url -Destination $cores_path\$corename.zip -TransferType Download
		
            # Check if downloaded
            if ($(Test-Path $cores_path\$corename.zip)) {
                rm $cores_path\$corename
                Expand-Archive "$cores_path\$corename.zip" "$cores_path" -force
                rm "$cores_path\$corename.zip"
				
			
                Write-Host $current_timestamp, "UPDATED ", $corename  -ForegroundColor Green
                Write-output $current_timestamp`t"UPDATED "`t$corename >> $logfile
            }
            else {
                Write-Host $current_timestamp, "FAILED ", $corename  -ForegroundColor Red
                Write-output $current_timestamp`t"FAILED "`t$corename >> $logfile
            }

        }
        echo "Done"
    }
    else {
        Write-Host "FAILED to download timestamps" -ForegroundColor Red
    }
}

Function New-RetroArchConfig {
    param (
        [Parameter(Mandatory = $true)] [String]$RetroArchPath,
        [string]$DefaultConfigFile,
        [switch]$GenerateOverrides = $false,
        [switch]$CommitConfig = $false
    )

    If (($GenerateOverrides) -and ($CommitConfig)) {
        Write-Host "Cannot generate overrides and commit new configuration in the same invocation. Please specify one or the other."
        break
    }

    $raBin = $RetroArchPath + '\retroarch.exe'
    $lkgCfgFile = $RetroArchPath + '\retroarch-lkg.cfg'
    $runCfgFile = $RetroArchPath + '\retroarch.cfg'
    $overrideCfgFile = $RetroArchPath + '\retroarch-overrides.cfg'
    $overrideLkgCfgFile = $RetroArchPath + '\retroarch-overrides-lkg.cfg'

    $cfg_running = @{ }
    $cfg_default = @{ }
    $cfg_overrides = @{ }
    $cfg_comp_new = @{ }
    $cfg_comp_old = @{ }
    $cfg_comp_delta = @{ }

    ## Parse the default config.
    # for testing - doesn't run retroarch.exe
    If (($DefaultConfigFile) -and (Test-Path $DefaultConfigFile)) {
        Write-Host "--Using defaults config file provided in $DefaultConfigFile"
    }
    # if a defaults config file is not provided, run retroarch.exe to get it
    Else {
        If (Test-Path $raBin) {
            $DefaultConfigFile = $RetroArchPath + '\retroarch-defaults.cfg'
            If (Test-Path $DefaultConfigFile) {
                Remove-Item $DefaultConfigFile
            }
            Write-Host "--Running retroarch.exe to generate temporary default config in $DefaultConfigFile"
            Start-Process $raBin -ArgumentList "--config $DefaultConfigFile --max-frames 1" -Wait
        }
        Else {
            Write-Host "Attempted to generate setting defaults, but can't find retroarch.exe at $raBin. A default configuration file may be provided instead by using -DefaultConfigFile <path>."
            break
        }
    }
    $defCfg = Get-Content $DefaultConfigFile
    $cfg_default = ParseConfigItems($defCfg)
    # clean up temporary file, if one was created
    If ($env:temp -eq $DefaultConfigFile.DirectoryName) {
        Remove-Item $DefaultConfigFile
    }

    ## Parse the running config.
    If (Test-Path $runCfgFile) {
        Write-Host "--Reading running configuration file ($runCfgFile) and parsing settings.."
        $runCfg = Get-Content $runCfgFile
        $cfg_running = ParseConfigItems($runCfg)
    
        ### NEW SETTINGS: in the default config, but not in the running config
        ForEach ($item in $cfg_default.Keys) {
            If (-not($cfg_running.ContainsKey($item))) {
                $cfg_comp_new.add($item, $cfg_default[$item])
            }
        }
        ### OLD SETTINGS: not in the default config, but in the running config
        ForEach ($item in $cfg_running.Keys) {
            If (-not($cfg_default.ContainsKey($item))) {
                $cfg_comp_old.add($item, $cfg_running[$item])
            }
        }

        ### DELTAS: same settings exist, but are set to different values
        ForEach ($item in $cfg_running.Keys) {
            If ($cfg_default.ContainsKey($item)) {
                If ($cfg_running[$item] -ne $cfg_default[$item]) {
                    $cfg_comp_delta.$item = @{ }
                    $cfg_comp_delta.$item.default = $cfg_default[$item]
                    $cfg_comp_delta.$item.running = $cfg_running[$item]
                }
            }
        }
        Write-Host "-- NEW SETTINGS: Not defined in running configuration:"
        If ($cfg_comp_new.Count -gt 0) { $cfg_comp_new.GetEnumerator() | sort Name | ft -AutoSize }
        Write-Host "-- OLD SETTINGS: Not defined in default configuration:"
        If ($cfg_comp_old.Count -gt 0) { $cfg_comp_old.GetEnumerator() | sort Name | ft -AutoSize }
        Write-Host "-- OVERRIDES: Settings defined in both configurations, but differ in defined value:"
        If ($cfg_comp_delta.Count -gt 0) { $cfg_comp_delta.GetEnumerator() | sort Name | select Name, @{N = 'Default Value'; E = { $_.Value.default } }, @{N = 'Running Value'; E = { $_.Value.running } } | ft -AutoSize }
    
        If ($GenerateOverrides) {
            Write-Host "-- Generating overrides in $overrideCfgFile.."
            If (Test-Path $overrideLkgCfgFile) {
                Write-Host "$overrideLkgCfgFile already exists - rename or remove it before continuing."
                break
            }
            If (Test-Path $overrideCfgFile) {
                Write-Host "Renaming existing overrides file to $overrideLkgCfgFile."
                Rename-Item -Path $overrideCfgFile -NewName $overrideLkgCfgFile
            }

            $deltaSettings = $cfg_comp_delta.GetEnumerator() | sort Name
            ForEach ($item in $deltaSettings.Name) {
                Add-Content $overrideCfgFile "# Default: $item = $($cfg_comp_delta.$item.default)"
                Add-Content $overrideCfgFile "$item = $($cfg_comp_delta.$item.running)"
            }
            break
        }
        If ($CommitConfig) {
            Write-Host "-- Generating new configuration."
            If (Test-Path $lkgCfgFile) {
                Write-Host "$lkgCfgFile already exists - rename or remove it before continuing."
                break
            }
            Rename-Item -Path $runCfgFile -NewName $lkgCfgFile
            # Parse the overrides file
            $overrideCfg = Get-Content $overrideCfgFile
            $cfg_overrides = ParseConfigItems($overrideCfg)
            # Apply overrides to default configuration
            ForEach ($item in $cfg_overrides.Keys) {
                If ($cfg_default.ContainsKey($item)) {
                    Write-Host "Setting $item = $($cfg_overrides.$item)"
                    $cfg_default.$item = $cfg_overrides.$item
                }
            }
            Write-Host "Writing new configuration to $runCfgFile"
            Add-Content $runCfgFile ("# Generated by $($MyInvocation.MyCommand.Name) - " + (Get-Date))
            $cfg_final = $cfg_default.GetEnumerator() | sort Name
            ForEach ($item in $cfg_final.Name) {
                Add-Content $runCfgFile "$item = $($cfg_default.$item)"
            }
        }
    
    }
    Else {
        Write-Host "$runCfgFile does not exist."
    }
}

Function ParseConfigItems($cfgArray) {
    $cfg_out = @{ }
    ForEach ($item in $cfgArray) {
        # check that the line isn't a comment and probably isn't a line break
        If ((-not($item -like '#*')) -and ($item.length -gt 1)) {
            $cfg_parse = $item -split " = "
            $cfg_out.add($cfg_parse[0], $cfg_parse[1])
        }
    }
    return $cfg_out
}