# Super simple script to be called on user logon that sets the active display according to the user that logged on.
# Example use case: initially, autologon with the "TV" user, and set the machine to 10-foot, controller driven mode on a TV.
# If the "TV" user logs off and instead the "PC" user logs on, set monitor(s) active instead for keyboard/mouse driven input.
# Depends on Display Changer II: https://12noon.com/?page_id=641

$desktopusername = "changeme"
$tvusername = "changeme"

If ($env:username -eq $tvusername) {
    # set TV as active display
    C:\scripts\dc2.exe -configure="C:\scripts\dc2-tv.xml"
}
If ($env:username -eq $desktopusername) {
    # set monitor as active display
    C:\scripts\dc2.exe -configure="C:\scripts\dc2-monitor.xml"
}