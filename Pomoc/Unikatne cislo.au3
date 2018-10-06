



#include "_GetHardwareID.au3"

$sUniqueID = _GetHardwareID($UHID_CPU) ; Ziskanie unikatneho cisla z hardwaru
MsgBox("",$sUniqueID,$sUniqueID)
$sUniqueID = StringReplace($sUniqueID, "}", "") ; odstranenie zatvoriek

$sUniqueID = StringReplace($sUniqueID, "-", "") ; odstranenie pomlciek
MsgBox("",$sUniqueID,$sUniqueID)
$sUniqueID = StringRight($sUniqueID, 12) ; Orezanie poslednych 12 znakov

#include <WinAPIDiag.au3>
$Edo=_WinAPI_UniqueHardwareID ( [$iFlags = 0] )





MsgBox("",$sUniqueID,$sUniqueID)