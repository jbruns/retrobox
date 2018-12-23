$UserContext = "HOME\mediarouser"

$UserDirectories = @(
	"C:\PCSX2",
	"C:\Dolphin",
	"C:\RetroArch",
	"C:\LaunchBox"
)

Foreach ($UserDirectory in $UserDirectories) {
	$acl = Get-Acl $UserDirectory
	$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($UserContext,"FullControl","Allow")
	$acl.SetAccessRule($AccessRule)
	$acl | Set-Acl $UserDirectory
}