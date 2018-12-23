$UserContext = "BUILTIN\Administrators"
$DInputFiles = @(
    "C:\Windows\System32\dinput8.dll"
    "C:\Windows\SysWOW64\dinput8.dll"
)
foreach ($DInputFile in $DInputFiles) {
    takeown /A /F $DInputFile
    Write-Host "Adding $UserContext to NTFS ACL."
    $acl = Get-Acl $DInputFile
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($UserContext,"FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl $DInputFile
    Write-Host "Renaming original dinput8.dll to dinput8org.dll."
    Rename-Item -Path $DInputFile -NewName "dinput8org.dll"
    if ($DInputFile -like '*System32*') {
        Write-Host "Copying devreorder dinput8.dll (x64) to \Windows\System32."
        Copy-Item 'x64\dinput8.dll' -Destination $DInputFile 
    }
    if ($DInputFile -like '*SysWOW64*') {
        Write-Host "Copying devreorder dinput8.dll (x86) to \Windows\SysWOW64."
        Copy-Item 'x86\dinput8.dll' -Destination $DInputFile
    }
}
If (!(Test-Path 'C:\ProgramData\devreorder')) {
    Write-Host "Creating ProgramData path for devreorder."
    New-Item -Path 'C:\ProgramData\devreorder' -ItemType Directory
}
Write-Host "Copying default devreorder.ini to \ProgramData\devreorder."
Copy-Item 'devreorder.ini' -Destination 'C:\ProgramData\devreorder'
