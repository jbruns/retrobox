# Location variables
$cores_url="http://buildbot.libretro.com/nightly/windows/x86_64/latest"
$retroarch_path = "C:\RetroArch"
$cores_path="$retroarch_path\cores"
$updater_path="$retroarch_path\ps_updater"
$logfile="$updater_path\cores_updater.log"

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Prepare files
if(-not(Test-Path "$updater_path\cores_timestamps.old")){$null > "$updater_path\cores_timestamps.old"}
if(-not(Test-Path "$updater_path\cores_timestamps.new")){$null > "$updater_path\cores_timestamps.new"}
mv "$updater_path\cores_timestamps.new" "$updater_path\cores_timestamps.old" -Force
# Grab timestamps from URL
Start-BitsTransfer -Source $cores_url/.index-extended -Destination $updater_path\cores_timestamps.new -TransferType Download

# Check if downloaded
if ($(Test-Path "$updater_path\cores_timestamps.new"))
{

	# New logfile entry
	echo "-- $(date) --" >> "$logfile"

	# Download and replace cores
	$cores = Get-ChildItem $cores_path -File *.dll
	for ($i=0; $i -lt $cores.Count; $i++) {
		if (-not($cores[$i].name.Contains("_libretro"))) {continue}
		$corename=$cores[$i].name
		$timestamp_old=$(Get-Content "$updater_path\cores_timestamps.old" | Select-String -simplematch $corename)
		$timestamp_new=$(Get-Content "$updater_path\cores_timestamps.new"| Select-String -simplematch $corename)
		$current_timestamp=$timestamp_new.ToString($timestamp_new).Split(" ")[0]
		if ( "$timestamp_new" -eq "$timestamp_old" )
		{
			Write-Host $current_timestamp,"SKIPPED ",$corename -ForegroundColor Gray
			Write-output $current_timestamp`t"SKIPPED "`t$corename >> $logfile
			continue
		}

		$core_full_url=$cores_url + "/" + $corename + ".zip"
		Start-BitsTransfer -Source $core_full_url -Destination $cores_path\$corename.zip -TransferType Download
		
		# Check if downloaded
		if ($(Test-Path $cores_path\$corename.zip))
		{
			rm $cores_path\$corename
			Expand-Archive "$cores_path\$corename.zip" "$cores_path" -force
			rm "$cores_path\$corename.zip"
				
			
			Write-Host $current_timestamp,"UPDATED ",$corename  -ForegroundColor Green
			Write-output $current_timestamp`t"UPDATED "`t$corename >> $logfile
		}
		else
		{
			Write-Host $current_timestamp,"FAILED ",$corename  -ForegroundColor Red
			Write-output $current_timestamp`t"FAILED "`t$corename >> $logfile
		}

	}
	echo "Done"
}
else
{
	Write-Host "FAILED to download timestamps" -ForegroundColor Red
}

