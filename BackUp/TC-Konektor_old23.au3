#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Res_Comment=ZF Slovakia Automation Pluss  TC-Konektor
#AutoIt3Wrapper_Res_Fileversion=0.1.30.16
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=ZF Slovakia
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Field=Creator| Eduard Bohacek
#AutoIt3Wrapper_Res_Field=PerNo |2226
#AutoIt3Wrapper_Res_Field=Tel.no|9760
#AutoIt3Wrapper_Res_File_Add=libmysql.dll
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/tc 3 /gd
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; *** Start added by AutoIt3Wrapper ***
#include <APIDiagConstants.au3>
; *** End added by AutoIt3Wrapper ***
#cs ----------------------------------------------------------------------------

   AutoIt Version: 3.3.14.1
   Author:         Eduard Bohacek

   Script Function:
   Sending Data from twincat file to Mysql server Automationpluss.

#ce ----------------------------------------------------------------------------
;~ #NoTrayIcon

#include "mysql.au3"
#include <FileConstants.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <String.au3>
#include <Date.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Inet.au3>


$PCV = "PC_Connector"
$ver = "0.51 2017/06/16 "

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

$LastE = IniRead($FINI, "SETTING", "LaastEror", "0")

; GUICtrlSetData ("Inicializacia kniznic")
; MYSQL Startuje, DLL na Ceste(Cesta pre DLL @ScriptDir), sont Pfad zur DLL angeben. DLL muss libmysql.dll heißen.
_MySQL_InitLibrary($DataDir & "\libmysql.dll", True)
If @error Then
   MsgBox(0, 'DLL Error', "libmysql.dll File not found")
   Exit
EndIf


; Ziskanie MAC Adresy
GetMAC()

If $SerNo <> $sUniqueID Then
   IniWrite($FINI, "HW", "serialnr", $sUniqueID) ; Zapisanie Noveho serioveho cisla
   $Mlog = "Zmena hardwaroveho c. : ( " & $SerNo & " ) na ( " & $sUniqueID
   WriteLog()
   $SerNo = $sUniqueID
EndIf


$main_GUI = GUICreate("OEE", 450, 20, 0, 0, $WS_POPUP, $WS_EX_TOPMOST)
;~ $Label = GUICtrlCreateLabel("OEE Logovanie suborov", 0, 0, 450, 20, 0, 0x00000001)
;~ GUICtrlSetData($Label, "OK")
;~ GUISetState(@SW_SHOW)



$Spoj = True
Global $Spoj2 = False




; Main loop
; Status: Uvolnena
; Start : 0.0.0.0
; Zmena : 0.1.30.15
; Popis : Hlavny program
While 1
   $Chyba = False
   If Not $Chyba And $Spoj Then
      TCSetting()
      NastavenieServra() ; Funkcia na ziskanie nastavenie servera
      SetTime() ; Funkcia na ziskanie nastavenie servera
   EndIf
   ;	ConsoleWrite(@CRLF & $Spoj &" "&$Chyba &" "& $Spoj2 )
   If Not $Chyba And Not $Spoj And Not $Spoj2 Then
      Pripoj()
   EndIf
   Sleep(1000) ; prestavka v programe

   If Not $Chyba And Not $Spoj And $Spoj2 Then Subor()
   Sleep(1000) ; prestavka v programe
   If Not $Chyba And Not $Spoj And $Spoj2 And Not $ChybaS Then SendData()
   Sleep(1000) ; prestavka v programe
   If $Chyba Then WriteLog()

WEnd

; Hardvare()nedokoncene
; Status: beta
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Ziskanie HardwareNo a Updatovanie na servery
;~ Func HWupdate($sn,)
;	if  $SerNo <> $sUniqueID Then
;		IniWrite($FINI,"HW","serialnr",$sUniqueID) ; Zapisanie Noveho serioveho cisla
;		If $Multi == 0 Then
;
;			IniWrite($FINI,"HW","serialnr",$sUniqueID) ; Zapisanie Noveho serioveho cisla
;		Else
;
;		EndIf
;
;
;	Else
;		$HWOk = True
;	EndIf
;	$SerNo = $sUniqueID
;~ EndFunc   ;==>HWupdate


; SetTime()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Nastav cas na PC podla servera
Func SetTime()
   If Not $Chyba Then
      $ArayTime = _StringExplode($CTime[1][0], " ", 0)
      $ADate = _StringExplode($ArayTime[0], "-", 0)
      $ATime = _StringExplode($ArayTime[1], ":", 0)
      $tNew = _Date_Time_EncodeSystemTime($ADate[1], $ADate[2], $ADate[0], $ATime[0], $ATime[1], $ATime[2])
      If Not _Date_Time_SetLocalTime($tNew) Then
         MsgBox($MB_SYSTEMMODAL, @CRLF & "Chyba", "Systemove hodiny sa nedaju nastavit:" & _WinAPI_GetLastErrorMessage())
         $Mlog = "Systemove hodiny sa nedaju nastavit:" & _WinAPI_GetLastErrorMessage()
         ;			GUICtrlSetData ($Label,"Systemove hodiny sa nedaju nastavit")
         $Chyba = True
         Exit
      EndIf
   EndIf
EndFunc   ;==>SetTime

; Pripoj()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: vytvorenie pripojeni k tabulkam na servery
Func Pripoj()
   $c = 1

   If $Multi = 0 Then
      $Connect[1] = _MySQL_Init()
      Local $Setting1 = $Setting[1][0]
      Local $ConServer = _MySQL_Real_Connect($Connect[1], $Setting1[1][0], $Setting1[1][1], $Setting1[1][2], $Setting1[1][3])
;~       ConsoleWrite(@CRLF & "connect  :" & $Setting1[1][0] & "   " & $Setting1[1][1] & "   " & $Setting1[1][2] & "   " & $Setting1[1][3])
      If $ConServer = 0 Then
         $Mlog = "MySQl pripojenie neuspesne"
         $Chyba = True
         $Spoj2 = False
         Return
      Else
         $Chyba = False
         $Chyba2 = ""
      EndIf
      $Spoj2 = True
   Else
      For $c = 1 To $db[0][0] Step 1
         $Connect[$c] = _MySQL_Init()
         Local $Setting1 = $Setting[$c][0]
         ;_ArrayDisplay($setting1,"Settingov")
         ;;;;;;;;;;;;;_MySQL_Real_Connect("Pripojenie=$Connect[$c]","IP Servra","uzivatel","Heslo","databaza");;;;;;;;;;;;;;;;;;;;;;
         Local $ConServer = _MySQL_Real_Connect($Connect[$c], $Setting1[1][0], $Setting1[1][1], $Setting1[1][2], $Setting1[1][3])
;~          ConsoleWrite(@CRLF & "connect  :  " & $Setting1[1][0] & "   " & $Setting1[1][1] & "   " & $Setting1[1][2] & "   " & $Setting1[1][3])
         If $ConServer = 0 Then
            $Mlog = "MySQl pripojenie neuspesne"
            $Chyba = True
            $Spoj2 = False
            Return
         Else
            $Chyba = False
            $Chyba2 = ""
         EndIf
      Next
      $Spoj2 = True
   EndIf
EndFunc   ;==>Pripoj

; Subor()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Load Data from File to Array and delete file
Func Subor()
   ;GUICtrlSetData ($Label,"Ziskavanie dat")
   If Not FileExists($Fdata) Then ; zistenie ci boli odoslane predchadzajuce data
      FileMove($FTwincat, $Fdata, $FC_NOOVERWRITE + $FC_CREATEPATH) ; ked boli odoslane presun subor zo zdroja
   EndIf

   $Filesize = FileGetSize($Fdata) ; zisti velkost suboru ci nieje prazdny

   If $Filesize > 10 Then ; Ak je subor nieje prazdny alebo prilis maly
      _FileReadToArray($Fdata, $aRetArray, Default, "|") ; nactanie obsahu subora do pola
      If @error Then
         $Mlog = "Chyba nacitania suboru " & $Fdata & ": " & @error
         $ChybaS = True ; nastavenie chyby
         $Chyba = True
      EndIf
   Else
      FileDelete($Fdata) ;vymazanie suboru
      $Mlog = "Chyba velkosti suboru " & $Fdata & " : Subor bude vymazany"
      $ChybaS = True
      $Chyba = True ; nastavenie chyby
   EndIf

EndFunc   ;==>Subor

; SendData()
; Status: beta
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Send data to Mysql
Func SendData()
   _ArrayDisplay($aRetArray, "Edo")
   $b = 0
   If $Setting1 == 0 Then $b = 1 ; osetrenie nenajdeneho id
   While $b == 0

      For $k = 1 To $aRetArray[0][0]
         $Date = StringMid($aRetArray[$k][0], 1, 10) & " " & StringMid($aRetArray[$k][0], 12, 8) ;Prepocet Datumu zo
         $Stanica = $aRetArray[$k][1] ;Ziskanie Cisla stanice
         $Status = $aRetArray[$k][2] ;Ziskanie Statusu stroja
         $io_nio = $aRetArray[$k][3] ;Ziskanie stavu dielu
         $AEror = $aRetArray[$k][4] ;Zistenie aktualnej chyby
         $OEror = $aRetArray[$k][5] ;Zistenie predchadzajuceho stavu chyby
         ;ConsoleWrite(@CRLF & "Data "&$io_nio& )

         If $io_nio == "-1" And $AEror = $OEror Then ; Ak nebol vyrobeny kus
            ;Poslanie stavu stroja nebol vyrobeny kus
            $dbQuery = "Call betriebszust( '" & $Date & "'," & $Status & ",0)" ; vytvorenie dopytu stavu stroja
            ConsoleWrite(@CRLF & $dbQuery) ; Poslanie dopytu na konzolu
            $sql = GetSetting($Connect[$Stanica + 1], $dbQuery) ; Poslanie dopytu na server ( ziskanie odpovede asi zbytocne!!)
         EndIf
         If $io_nio >= 0 And $AEror = $OEror Then
            ; Bol vyrobeny kus s OK alebo NGx vysledkom
            $dbQuery = "Call spprodukt(-1 ,'" & $Date & "'," & $io_nio & ",0,0,'','')" ; vytvorenie dopytu stavu dielu
            ConsoleWrite(@CRLF & $dbQuery) ; Poslanie dopytu na konzolu
            $sql = GetSetting($Connect[$Stanica + 1], $dbQuery) ; Poslanie dopytu na server ( ziskanie odpovede asi zbytocne!!)
         EndIf

         ;			if $AEror<>$OEror Then
         ;				;Poslanie chybovej hlasky alebo resethlasky
         ;				$dbQuery = "Call spstoerung( "&$OEror&", "& $AEror &", 1, '"&$Date&"',0)"
         ;				ConsoleWrite(@CRLF & $dbQuery )
         ;				$sql = GetSetting($Connect[$Stanica + 1],$dbQuery )
         ;			EndIf
         ; sem pride poslanie chybovej hlasky na server
         ; Nedokoncene posielanie chyb na server


         ;$ConServer[]
         $Chyba1 = _MySQL_Error($Connect[$Stanica + 1]) ; Zistenie chyby zo servra
         If $Chyba1 <> "" Then ; Ak je chyba
            $Mlog = "Data Error: " & $Chyba1
            ConsoleWrite(@CRLF & "Data Error: " & $Chyba1) ; Zapisanie Chyby zo servera
            $Spoj2 = False ; Spoj2 false aby dalej neposielalo data
;~             GUISetState(@SW_SHOW) ; Zobrazenie GUI
            Return ; vyhodenie z funkcie aby sa nezmazal subor
         EndIf
      Next

      FileDelete($Fdata) ; Po skoceni posielania dat vymaze subor
      $b = 1

   WEnd

EndFunc   ;==>SendData


; GetSetting()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Poslanie dotazu a ziskanie odpovede z MySQL
Func GetSetting($MysqlCon, $query)

   _MySQL_Real_Query($MysqlCon, $query) ; Poslanie na server dopytu na server
   $res = _MySQL_Store_Result($MysqlCon) ; Zapametanie odpovede zo servra
   $rows = _MySQL_Num_Rows($res) ; zistenie poctu riadkov
   $array = _MySQL_Fetch_Result_StringArray($res) ; Zapisanie vysledku do pola
   Return $array ; vratenie vysledku funkcie

EndFunc   ;==>GetSetting


; NastavenieServra()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Get data from Mysql Konfig
Func NastavenieServra()
   $MysqlConn = _MySQL_Init() ; vytvorenie pripojenia
   ;pripojenie k servru na konfig a zistenie nastavenia stroja
   ; Connecting to server db konfig
   ;_MySQL_Real_Connect($MysqlConn,"IP Server","User","Password","Database")
   $ConServer1 = _MySQL_Real_Connect($MysqlConn, $SerIP, $SerUser, $SerPass, $SerDB)
   If Not $ConServer1 = 0 Then
      ; Get data for Machine
      If $Multi == 0 Then ;pripad pre jeden stroj
         $db[1][1] = ""
         $db[0][0] = 1
      EndIf

      For $d = 1 To $db[0][0] Step 1
         $No = $SerNo & $db[$d][1]
         $dbQuery = "SELECT database_ip,user,pwd,datenbank,endprellzeit, mitPD, eingang " & _
               "FROM phoenix WHERE seriennr = '" & $No & "'"
         ConsoleWrite(@CRLF & $dbQuery)
         $Setting[$d][0] = GetSetting($MysqlConn, $dbQuery)
         ConsoleWrite(@CRLF & $Setting[$d][0])

         $dbQuery = "SELECT anlage_bezeichnung, ip, part_factor, dns_name, DnsServer, Domain" & _
               "FROM phoenix inner join anlage on anlage_nummer=datenbank WHERE seriennr = '" & $No & "'"
         ConsoleWrite(@CRLF & $dbQuery)
         $Setting[$d][1] = GetSetting($MysqlConn, $dbQuery)

         ConsoleWrite(@CRLF & $Setting[$d][1])

         $dbQuery = "UPDATE phoenix SET aktuelle_ip = '" & $TCIP & _
               "',zeitstempel = now(), controllertype = 'TC-connector" & _
               "',firmware = '4.30 08/05/17" & _
               "', version = '" & $TCFV & _
               "', seriennr = '" & $No & _
               "', MacAdresse = '00:A0:45:94:79:30' WHERE seriennr = '" & $No & "'"
         ConsoleWrite(@CRLF & $dbQuery)
         $Setting[$d][2] = GetSetting($MysqlConn, $dbQuery)
         ConsoleWrite(@CRLF & $Setting[$d][2])
      Next

      ; Get Actual Date from MySQL server
      $dbQuery = "SELECT NOW()"
      ConsoleWrite($dbQuery & @CRLF)
      $CTime = GetSetting($MysqlConn, $dbQuery)
      ConsoleWrite($CTime[1][0] & @CRLF)
      _MySQL_Close($MysqlConn) ;Close Connection on server

      ; treba poriesit nastavenia z ostatnych nastaveni ako ip domenove meno atd...
		_ArrayDisplay(,,$Setting)

      If $Setting[1][0] == 0 Or $Setting[2][0] == 0 Or $Setting[3][0] == 0 Or $Setting[4][0] == 0 Then
         $Spoj = True
      Else
         $Spoj = False
      EndIf

   Else

      ConsoleWrite(@CRLF & "Konfig Error : " & _MySQL_Error($MysqlConn))
      $Mlog = "Konfig Error : " & _MySQL_Error($MysqlConn)
      $Chyba = True

   EndIf

EndFunc   ;==>NastavenieServra

; TCSetting()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Ziskanie nastaveni TC-konektora
Func TCSetting()
   $TCIP = @IPAddress1 ; ziskanie IP adresy z aktualneho pripojenia
   ;   $TCMAC =
   $TCFV = FileGetVersion(@ScriptFullPath) ; Ziskanie verzie suboru zo samotneho suboru

;~    $Mlog = "verzia suboru : " & $TCFV

;~    ConsoleWrite(@CRLF & @ScriptFullPath)

EndFunc   ;==>TCSetting

; WriteLog()
; Status: beta
; Start : 0.1.30.15
; Zmena : 0.1.30.15
; Popis: Write data to log File
Func WriteLog()

   If $Mlog <> "" Then
      Local $LogFile = $DataDir & "Error.log"
      Local $LogSize = FileGetSize($Fdata)
      Local $Cas1 = _Date_Time_GetSystemTime()
      Local $cas = _Date_Time_SystemTimeToDateTimeStr($Cas1)
      If $LogSize > 15000 Then
         FileMove($LogFile, $cas & "Archive.log", $FC_OVERWRITE)
      EndIf
      Local $hFileLOG = FileOpen($LogFile, $FO_APPEND)
      $Mlog = $cas & " : " & $Mlog ; Pripisanie casu k hlaseniu
      FileWriteLine($hFileLOG, $Mlog)
      $Mlog = ""
      FileClose($hFileLOG)

   EndIf
EndFunc   ;==>WriteLog

; GetMAC()
; Status: uvolnena
; Start : 0.1.30.15
; Zmena : 0.1.30.16
; Popis: Ziskanie Unikatneho cisla z macAdresy prvej sietovej karty
Func GetMAC()
   $FMAC = "C:\Data\Mac.txt"
   RunWait(@ComSpec & ' /c getmac > "C:\Data\Mac.txt"')
   Local $hFileOpen = FileOpen("C:\Data\Mac.txt", $FO_READ)
;~ 	If $hFileOpen = -1 Then
;~ 		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
;~ 		Return False
;~ 	EndIf
   Local $sFileRead = FileReadLine($hFileOpen, 4) ; Read the contents of the file using the handle returned by FileOpen.
   $sFileRead = StringReplace(StringLeft($sFileRead, 17), "-", "") ; orezanie a nahradenie pomlciek
   FileClose($hFileOpen) ; Close the handle returned by FileOpen.
   FileDelete($FMAC) ; Delete the temporary file.
   $sUniqueID = $sFileRead

EndFunc   ;==>GetMAC
