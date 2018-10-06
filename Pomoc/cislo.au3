



#include "_GetHardwareID.au3"

$sUniqueID = _GetHardwareID($UHID_All) ; Ziskanie unikatneho cisla z hardwaru
$sUniqueID = StringReplace($sUniqueID, "}", "") ; odstranenie zatvoriek
$sUniqueID = StringReplace($sUniqueID, "{", "")
$sUniqueID = StringReplace($sUniqueID, "-", "") ; odstranenie pomlciek
IniWrite("C:\Data\Cislo.ini","Serial","ID",$sUniqueID)


#include <WinAPIDiag.au3>
$Edo =_WinAPI_UniqueHardwareID ()
$Edo = StringReplace($Edo, "}", "") 
$Edo = StringReplace($Edo, "{", "")
$Edo = StringReplace($Edo, "-", "")

IniWrite("C:\Data\Cislo.ini","Serial","Edo",$Edo)
