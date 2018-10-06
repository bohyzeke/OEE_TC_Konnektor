#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here



#include <FileConstants.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <String.au3>
#include <Date.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Inet.au3>

Global $Setting1, $Setting2, $MysqlConn, $aRetArray, $Chyba, $Chyba1, $ChybaS
Global $CTime, $sUniqueID, $TCIP, $TCFV
Global $Mlog
Global $db[11][2], $Connect[10], $Setting[11][3]
$DataDir = @ScriptDir & "\Data\"
$FINI = $DataDir & "konfig.ini"
$Fdata = $DataDir & "OEE.txt"
$FTwincat = "C:\Twincat\OEE.txt"

; $SerIP   = Iniread($FINI,"CONFIGSERVER","ip","10.26.48.23")
$SerIP = IniRead($FINI, "CONFIGSERVER", "ip", "localhost")
$SerPort = IniRead($FINI, "CONFIGSERVER", "port", "3306")
$SerUser = IniRead($FINI, "CONFIGSERVER", "user", "oee")
$SerPass = IniRead($FINI, "CONFIGSERVER", "pwd", "eeo")
$SerDB = IniRead($FINI, "CONFIGSERVER", "db", "konfig")

$SerNo = IniRead($FINI, "HW", "serialnr", "001352707343")
$FTwincat = IniRead($FINI, "HW", "file", "C:\Twincat\OEE.txt")
$Multi = IniRead($FINI, "HW", "multi", "0") ;Multi instancia pre viac PLC
If $Multi <> 0 Then
   $db = IniReadSection($FINI, "MULTIDB") ;$DB[0][0]udava pocet pripojeni ;$db[x+1][1]koncovka k databaze stroja
EndIf



   ;GUICtrlSetData ($Label,"Ziskavanie dat")
   If Not FileExists($Fdata) And FileExists($FTwincat) Then ; zistenie ci boli odoslane predchadzajuce data a ci existuje zdrojovy subor
	  $Mlog = "Kopirujem subor zo zdroja na docasne miesto"
      FileMove($FTwincat, $Fdata, $FC_NOOVERWRITE + $FC_CREATEPATH) ; ked boli odoslane presun subor zo zdroja
      If @error Then
         $Mlog = "Chyba kopirovania suboru zo zdroja na docasne miesto"
		 ConsoleWrite($Mlog)

      EndIf
   EndIf

   $Filesize = FileGetSize($Fdata) ; zisti velkost suboru ci nieje prazdny

   If $Filesize > 10 Then ; Ak je subor nieje prazdny alebo prilis maly
      _FileReadToArray($Fdata, $aRetArray, Default, "|") ; nactanie obsahu subora do pola
      If @error Then
         $Mlog = "Chyba nacitania suboru " & $Fdata & ": " & @error
		 ConsoleWrite($Mlog)

      EndIf
   Else
	  $Mlog = "Subor " & $Fdata & " je prilis maly"& $Filesize
	  ConsoleWrite($Mlog)
      If FileExists($Fdata) Then
         FileDelete($Fdata) ;vymazanie suboru
         ConsoleWrite(@CRLF & "Vymazanie subotu " & $Fdata)
      EndIf

   EndIf

