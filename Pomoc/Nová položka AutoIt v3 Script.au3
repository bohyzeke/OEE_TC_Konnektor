#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
runWait(@comSpec & ' /c ipconfig /all > "c:\Data\ipconfig.txt"')

$objWMIService  = ObjGet("winmgmts:{impersonationLevel=impersonate}")
$netAdapterSet = $objWMIService.ExecQuery("select * from Win32_NetworkAdapter")
;~ For $netAdapter in $netAdapterSet
;~     MsgBox(0, "", $netAdapter.MACAddress)
;~ Next

$objNetwork = ""
$netAdapterSet = ""
$MAC = _GetMACFromIP (@IPAddress1)
MsgBox (0, "MAC Value", $MAC)

Func _GetMACFromIP ($sIP)
    Local $MAC,$MACSize
    Local $i,$s,$r,$iIP

;Create the struct
;{
;   char    data[6];
;}MAC
    $MAC        = DllStructCreate("byte[6]")

;Create a pointer to an int
;   int *MACSize;
    $MACSize    = DllStructCreate("int")

;*MACSize = 6;
    DllStructSetData($MACSize,1,6)

;call inet_addr($sIP)
    $r = DllCall ("Ws2_32.dll", "int", "inet_addr","str", $sIP)
    $iIP = $r[0]

;Make the DllCall
    $r = DllCall ("iphlpapi.dll", "int", "SendARP","int", $iIP,"int", 0,"ptr", DllStructGetPtr($MAC),"ptr", DllStructGetPtr($MACSize))

;Format the MAC address into user readble format: 00:00:00:00:00:00
    $s  = ""
    For $i = 0 To 5
        If $i Then $s = $s ;& ":"
        $s = $s & Hex(DllStructGetData($MAC,1,$i+1),2)
    Next

;Must free the memory after it is used
;~     _DllStructDelete($MAC)
;~     DllStructDelete($MACSize)

;Return the user readble MAC address
    Return $s
EndFunc