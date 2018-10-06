#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>

runWait(@comSpec & ' /c getmac > "c:\Data\Mac.txt"')


   Local $hFileOpen = FileOpen("c:\Data\Mac.txt", $FO_READ)
   If $hFileOpen = -1 Then
	  MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
	  Return False
   EndIf
   ; Read the contents of the file using the handle returned by FileOpen.
    Local $sFileRead = FileReadLine($hFileOpen, 4)
	$sFileRead = StringReplace(StringLeft($sFileRead, 17), "-", "")

    ; Close the handle returned by FileOpen.
    FileClose($hFileOpen)

    ; Display the contents of the file.
    MsgBox($MB_SYSTEMMODAL, "", "Contents of the file:" & @CRLF & $sFileRead)

    ; Delete the temporary file.
    FileDelete($sFilePath)