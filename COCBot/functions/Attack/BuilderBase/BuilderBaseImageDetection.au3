; #FUNCTION# ====================================================================================================================
; Name ..........: BuilderBaseImageDetection
; Description ...: Use on Builder Base attack , Get Points to Deploy , Get buildings etc
; Syntax ........: Several
; Parameters ....:
; Return values .: None
; Author ........: ProMac (03-2018), Fahid.Mahmood
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as Multibot and ClashGameBot. Copyright 2015-2020
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

#cs
Func TestBuilderBaseBuildingsDetection()
	Setlog("** TestBuilderBaseBuildingsDetection START**", $COLOR_DEBUG)
	Local $Status = $g_bRunState
	$g_bRunState = True
	; Reset the Boat Position , only in tests
	$g_aVillageSize = $g_aVillageSizeReset ; Deprecated dim - Team AIO Mod++
	Local $SelectedItem = _GUICtrlComboBox_GetCurSel($g_cmbBuildings)
	Local $temp = BuilderBaseBuildingsDetection($SelectedItem)
	For $i = 0 To UBound($temp) - 1
		Setlog(" - " & $temp[$i][0] & " - " & $temp[$i][3] & " - " & $temp[$i][1] & "x" & $temp[$i][2])
	Next
	DebugBuilderBaseBuildingsDetection2($temp)
	$g_bRunState = $Status
	Setlog("** TestBuilderBaseBuildingsDetection END**", $COLOR_DEBUG)
EndFunc   ;==>TestBuilderBaseBuildingsDetection
#ce

Func TestBuilderBaseGetDeployPoints()
	Setlog("** TestBuilderBaseGetDeployPoints START**", $COLOR_DEBUG)
	Local $Status = $g_bRunState
	$g_bRunState = True
	; Reset the Boat Position , only in tests
	$g_aVillageSize = $g_aVillageSizeReset ; Deprecated dim - Team AIO Mod++
	Local $FurtherFrom = 5 ; 5 pixels before the deploy point
	BuilderBaseGetDeployPoints($FurtherFrom, True)
	$g_bRunState = $Status
	Setlog("** TestBuilderBaseGetDeployPoints END**", $COLOR_DEBUG)
EndFunc   ;==>TestBuilderBaseGetDeployPoints

Func TestBuilderBaseGetHall()
	Setlog("** TestBuilderBaseGetHall START**", $COLOR_DEBUG)
	Local $Status = $g_bRunState
	$g_bRunState = True

	Local $BuilderHallPos = findMultipleQuick($g_sBundleBuilderHall, 1, "0,0,860,732", True, True)
	If Not IsArray($BuilderHallPos) And UBound($BuilderHallPos) < 1 Then
		SaveDebugImage("BuilderHall")
	EndIf
	Setlog(_ArrayToString($BuilderHallPos))
	$g_bRunState = $Status
	Setlog("** TestBuilderBaseGetHall END**", $COLOR_DEBUG)
EndFunc   ;==>TestBuilderBaseGetHall


Func __GreenTiles($sDirectory, $iQuantityMatch = 0, $vArea2SearchOri = "FV", $bForceCapture = True, $bDebugLog = False, $iDistance2check = 15, $minLevel = 0, $maxLevel = 1000)

	Local $iCount = 0, $returnProps = "objectname,objectlevel,objectpoints"
	Local $error, $extError

	If $bForceCapture = Default Then $bForceCapture = True
	If $vArea2SearchOri = Default Then $vArea2SearchOri = "FV"

	If (IsArray($vArea2SearchOri)) Then
		$vArea2SearchOri = GetDiamondFromArray($vArea2SearchOri)
	EndIf
	If 3 = ((StringReplace($vArea2SearchOri, ",", ",") <> "") ? (@extended) : (0)) Then
		$vArea2SearchOri = GetDiamondFromRect($vArea2SearchOri)
	EndIf

	Local $aCoords = "" ; use AutoIt mixed variable type and initialize array of coordinates to null
	Local $returnData = StringSplit($returnProps, ",", $STR_NOCOUNT + $STR_ENTIRESPLIT)
	Local $returnLine[UBound($returnData)]

	; Capture the screen for comparison
	If $bForceCapture Then _CaptureRegion2() ;to have FULL screen image to work with

	Local $result = DllCallMyBot("SearchMultipleTilesBetweenLevels", "handle", $g_hHBitmap2, "str", $sDirectory, "str", $vArea2SearchOri, "Int", $iQuantityMatch, "str", $vArea2SearchOri, "Int", $minLevel, "Int", $maxLevel)
	$error = @error ; Store error values as they reset at next function call
	$extError = @extended
	If $error Then
		_logErrorDLLCall($g_sLibMyBotPath, $error)
		SetDebugLog(" imgloc DLL Error : " & $error & " --- " & $extError)
		SetError(2, $extError, $aCoords) ; Set external error code = 2 for DLL error
		Return -1
	EndIf

	If checkImglocError($result, "_GreenTiles", $sDirectory) = True Then
		SetDebugLog("_GreenTiles Returned Error or No values : ", $COLOR_DEBUG)
		Return -1
	EndIf

	Local $resultArr = StringSplit($result[0], "|", $STR_NOCOUNT + $STR_ENTIRESPLIT)
	SetDebugLog(" ***  _GreenTiles multiples **** ", $COLOR_ORANGE)

	; Distance in pixels to check if is a duplicated detection , for deploy point will be 5
	Local $iD2C = $iDistance2check
	Local $aAR[0][4], $aXY
	For $rs = 0 To UBound($resultArr) - 1
		For $rD = 0 To UBound($returnData) - 1 ; cycle props
			$returnLine[$rD] = RetrieveImglocProperty($resultArr[$rs], $returnData[$rD])
			If $returnData[$rD] = "objectpoints" Then
				; Inspired in Chilly-chill
				Local $aC = StringSplit($returnLine[2], "|", $STR_NOCOUNT + $STR_ENTIRESPLIT)
				For $i = 0 To UBound($aC) - 1
					$aXY = StringSplit($aC[$i], ",", $STR_NOCOUNT + $STR_ENTIRESPLIT)
					If UBound($aXY) <> 2 Then ContinueLoop 3
						; If $returnLine[0] = "External" Then
							; If isInsideDiamondInt(Int($aXY[0]), Int($aXY[1])) Then
								; ContinueLoop
							; EndIf
						; EndIf
						If $iD2C > 0 Then
							If DuplicatedGreen($aAR, Int($aXY[0]), Int($aXY[1]), UBound($aAR)-1, $iD2C) Then
								ContinueLoop
							EndIf
						EndIf
					ReDim $aAR[$iCount + 1][4]
					$aAR[$iCount][0] = Int($aXY[0])
					$aAR[$iCount][1] = Int($aXY[1])
					$iCount += 1
					If $iCount >= $iQuantityMatch And $iQuantityMatch > 0 Then ExitLoop 3
				Next
			EndIf
		Next
	Next

	If UBound($aAR) < 1 Then Return -1

	Return $aAR
EndFunc   ;==>_GreenTiles

Func DuplicatedGreen($aXYs, $x1, $y1, $i3, $iD = 15)
	If $i3 > 0 Then
		For $i = 0 To $i3
			If Not $g_bRunState Then Return
			If Pixel_Distance($aXYs[$i][0], $aXYs[$i][1], $x1, $y1) < $iD Then Return True
		Next
	EndIf
	Return False
EndFunc   ;==>DuplicatedGreen

Func _GetDiamondGreenTiles($iHnowManyPoints = 10, $iCentreX = 400, $iCentreY = 400, $sDirectory = @ScriptDir & "\imgxml\Attack\BuilderBase\DPTit\")
	Local $g_aGreenTiles = -1
	Local $aTmp = __GreenTiles($sDirectory, 0, "FV", True, False, 15, 0, 1000)
	$g_aGreenTiles = IsArray($aTmp) ? ($aTmp) : (-1)
	If Not IsArray($g_aGreenTiles) Or UBound($g_aGreenTiles) < 0 Then Return -1
	Local $TL[0][3], $BL[0][3], $TR[0][3], $BR[0][3]
	Local $aCentre = [$iCentreX, $iCentreY] ; [$DiamondMiddleX, $DiamondMiddleY]
	_ArraySort($g_aGreenTiles, 0, 0, 0, 1)
	For $i = 0 To UBound($g_aGreenTiles) - 1
		Local $iCoordinate = [$g_aGreenTiles[$i][0], $g_aGreenTiles[$i][1]]
		; If not IsInsideDiamond($iCoordinate) Then ContinueLoop
		If DeployPointsPosition($iCoordinate) = "TopLeft" Then
			ReDim $TL[UBound($TL) + 1][3]
			$TL[UBound($TL) - 1][0] = $iCoordinate[0]
			$TL[UBound($TL) - 1][1] = $iCoordinate[1]
			$TL[UBound($TL) - 1][2] = Int(Pixel_Distance($aCentre[0], $aCentre[1], $iCoordinate[0], $iCoordinate[1]))
		EndIf
		If DeployPointsPosition($iCoordinate) = "BottomLeft" Then
			ReDim $BL[UBound($BL) + 1][3]
			$BL[UBound($BL) - 1][0] = $iCoordinate[0]
			$BL[UBound($BL) - 1][1] = $iCoordinate[1]
			$BL[UBound($BL) - 1][2] = Int(Pixel_Distance($aCentre[0], $aCentre[1], $iCoordinate[0], $iCoordinate[1]))
		EndIf
		If DeployPointsPosition($iCoordinate) = "TopRight" Then
			ReDim $TR[UBound($TR) + 1][3]
			$TR[UBound($TR) - 1][0] = $iCoordinate[0]
			$TR[UBound($TR) - 1][1] = $iCoordinate[1]
			$TR[UBound($TR) - 1][2] = Int(Pixel_Distance($aCentre[0], $aCentre[1], $iCoordinate[0], $iCoordinate[1]))
		EndIf
		If DeployPointsPosition($iCoordinate) = "BottomRight" Then
			ReDim $BR[UBound($BR) + 1][3]
			$BR[UBound($BR) - 1][0] = $iCoordinate[0]
			$BR[UBound($BR) - 1][1] = $iCoordinate[1]
			$BR[UBound($BR) - 1][2] = Int(Pixel_Distance($aCentre[0], $aCentre[1], $iCoordinate[0], $iCoordinate[1]))
		EndIf
	Next
	SetDebugLog("GreenTiles at TL are " & UBound($TL))
	SetDebugLog("GreenTiles at BL are " & UBound($BL))
	SetDebugLog("GreenTiles at TR are " & UBound($TR))
	SetDebugLog("GreenTiles at BR are " & UBound($BR))
	Local $AllSides[4] = [$TL, $TR, $BR, $BL]
	Local $aiGreenTilesBySide[4]
	Local $SIDESNAMES[4] = ["TL", "BL", "TR", "BR"]
	Local $oNumberOfDeployPoints = $iHnowManyPoints
	For $iAllSides = 0 To 3
		Local $OneSide = $AllSides[$iAllSides]
		_ArraySort($OneSide, 0, 0, 0, 2)
		Local $OneFinalSide[0][2]
		SetDebugLog(" --- Side " & $SIDESNAMES[$iAllSides] & " --- ")
		For $i = 0 To $oNumberOfDeployPoints - 1
			If $i < UBound($OneSide) Then
				ReDim $OneFinalSide[UBound($OneFinalSide) + 1][2]
				$OneFinalSide[UBound($OneFinalSide) - 1][0] = $OneSide[$i][0]
				$OneFinalSide[UBound($OneFinalSide) - 1][1] = $OneSide[$i][1]
			EndIf
		Next
		$aiGreenTilesBySide[$iAllSides] = $OneFinalSide
		SetDebugLog("Final GreenTiles at " & $SIDESNAMES[$iAllSides] & ": " & _ArrayToString($OneFinalSide, ",", -1, -1, "|"))
	Next
	Return $aiGreenTilesBySide
EndFunc   ;==>GetDiamondGreenTiles

Func BuilderBaseGetDeployPoints($FurtherFrom = $g_iFurtherFromBBDefault, $bDebugImage = False)
	If _Sleep(3000) Then Return

	Local $bBadPoints = False, $Sides = -1

	If Not $g_bRunState Then Return

	Local $DebugLog
	If $g_bDebugBBattack Or $bDebugImage Then
		$DebugLog = True
	EndIf

	; [0] - TopLeft ,[1] - TopRight , [2] - BottomRight , [3] - BottomLeft
	; Each with an Array [$i][2] =[x,y]  for Xaxis and Yaxis
	Local $DeployPoints[4]
	Local $Name[4] = ["TopLeft", "TopRight", "BottomRight", "BottomLeft"]
	Local $hStarttime = __TimerInit()

	Local $aBuilderHallPos
	For $i = 0 To 3
		$aBuilderHallPos = findMultipleQuick($g_sBundleBuilderHall, 1)
		If IsArray($aBuilderHallPos) Then ExitLoop
		If _Sleep(250) Then Return
	Next

	If IsArray($aBuilderHallPos) And UBound($aBuilderHallPos) > 0 Then
		$g_aBuilderHallPos = $aBuilderHallPos
	Else
		SaveDebugImage("BuilderHall")
		Setlog("Builder Hall detection Error!", $Color_Error)
		Local $aBuilderHall[1][4] = [["BuilderHall", 450, 425, -1]]
		$g_aBuilderHallPos = $aBuilderHall
	EndIf

	If Not $g_bRunState Then Return

	Setlog("Builder Base Hall detection: " & Round(__timerdiff($hStarttime) / 1000, 2) & " seconds", $COLOR_DEBUG)
	$hStarttime = __TimerInit()
	
	#CS
	; Dissociable drop points.
	Local $aDeployPointsResult = DMClassicArray(DFind($g_sBundleDeployPointsBBD, 0, 0, 0, 0, 0, 0, 1000, True), 10, ($g_bDebugImageSave Or $bDebugImage))
	If Not $g_bRunState Then Return
	SetDebugLog(_ArrayToString($aDeployPointsResult))

	If IsArray($aDeployPointsResult) And UBound($aDeployPointsResult) > 0 Then
		Local $Point[2], $Local = ""
		Local $iTopLeft[0][2], $iTopRight[0][2], $iBottomRight[0][2], $iBottomLeft[0][2]
		For $i = 0 To UBound($aDeployPointsResult) - 1
			$Point[0] = Int($aDeployPointsResult[$i][1])
			$Point[1] = Int($aDeployPointsResult[$i][2])
			SetDebugLog("[" & $i & "]Deploy Point: (" & $Point[0] & "," & $Point[1] & ")")
			$Local = DeployPointsPosition($Point)
			SetDebugLog("[" & $i & "]Deploy Local: (" & $Local & ")")
			Switch $Local
				Case "TopLeft"
					$Point[0] -= $FurtherFrom
					$Point[1] -= $FurtherFrom
					ReDim $iTopLeft[UBound($iTopLeft) + 1][2]
					$iTopLeft[UBound($iTopLeft) - 1][0] = $Point[0]
					$iTopLeft[UBound($iTopLeft) - 1][1] = $Point[1]
				Case "TopRight"
					$Point[0] += $FurtherFrom
					$Point[1] -= $FurtherFrom
					ReDim $iTopRight[UBound($iTopRight) + 1][2]
					$iTopRight[UBound($iTopRight) - 1][0] = $Point[0]
					$iTopRight[UBound($iTopRight) - 1][1] = $Point[1]
				Case "BottomRight"
					$Point[0] += $FurtherFrom
					$Point[1] += $FurtherFrom
					ReDim $iBottomRight[UBound($iBottomRight) + 1][2]
					$iBottomRight[UBound($iBottomRight) - 1][0] = $Point[0]
					$iBottomRight[UBound($iBottomRight) - 1][1] = $Point[1]
				Case "BottomLeft"
					$Point[0] -= $FurtherFrom
					$Point[1] += $FurtherFrom
					ReDim $iBottomLeft[UBound($iBottomLeft) + 1][2]
					$iBottomLeft[UBound($iBottomLeft) - 1][0] = $Point[0]
					$iBottomLeft[UBound($iBottomLeft) - 1][1] = $Point[1]
			EndSwitch
		Next

		Local $aTmpSides[4] = [$iTopLeft, $iTopRight, $iBottomRight, $iBottomLeft]
		$Sides = $aTmpSides
		Else
		$bBadPoints = True
	EndIf
	#CE
	
	#Region
	$Sides = _GetDiamondGreenTiles(15, $aBuilderHallPos[0][1], $aBuilderHallPos[0][2])
	#EndRegion
	
	If Not $g_bRunState Then Return

	If $bBadPoints = False Then
		For $i = 0 To 3
			Setlog($Name[$i] & " points: " & UBound($Sides[$i]))
			$DeployPoints[$i] = $Sides[$i]
		Next
	EndIf

	If Not $g_bRunState Then Return

	Setlog("Builder Base Internal Deploy Points: " & Round(__timerdiff($hStarttime) / 1000, 2) & " seconds", $COLOR_DEBUG)
	$hStarttime = __TimerInit()

	$g_aBuilderBaseDiamond = PrintBBPoly(False) ;BuilderBaseAttackDiamond()
	If @error Then
		SaveDebugImage("DeployPoints")
		Setlog("Deploy $g_aBuilderBaseDiamond - Points detection Error!", $Color_Error)
		; $g_aExternalEdges = BuilderBaseGetFakeEdges()
		Return False
	Else
		$g_aExternalEdges = BuilderBaseGetEdges($g_aBuilderBaseDiamond, "External Edges")
	EndIf

	Setlog("Builder Base Edges Deploy Points: " & Round(__timerdiff($hStarttime) / 1000, 2) & " seconds", $COLOR_DEBUG)

	$hStarttime = __TimerInit()

	$g_aBuilderBaseOuterDiamond = PrintBBPoly(True)

	If $g_aBuilderBaseOuterDiamond = -1 Then
		SaveDebugImage("DeployPoints")
		Setlog("Deploy $g_aBuilderBaseOuterDiamond - Points detection Error!", $Color_Error)
		; $g_aOuterEdges = BuilderBaseGetFakeEdges()
		Return False
	Else
		$g_aOuterEdges = BuilderBaseGetEdges($g_aBuilderBaseOuterDiamond, "Outer Edges")
	EndIf

	; Let's get the correct side by BH position  for Outer Points
	Local $iTopLeft[0][2], $iTopRight[0][2], $iBottomRight[0][2], $iBottomLeft[0][2]

	For $i = 0 To 3
		If Not $g_bRunState Then Return
		Local $iCorrectSide = $g_aOuterEdges[$i]
		For $j = 0 To UBound($iCorrectSide) - 1
			Local $Point[2] = [$iCorrectSide[$j][0], $iCorrectSide[$j][1]]
			Local $Local = DeployPointsPosition($Point)
			Select
				Case $Local = "TopLeft"
					ReDim $iTopLeft[UBound($iTopLeft) + 1][2]
					$iTopLeft[UBound($iTopLeft) - 1][0] = $Point[0]
					$iTopLeft[UBound($iTopLeft) - 1][1] = $Point[1]

				Case $Local = "TopRight"
					ReDim $iTopRight[UBound($iTopRight) + 1][2]
					$iTopRight[UBound($iTopRight) - 1][0] = $Point[0]
					$iTopRight[UBound($iTopRight) - 1][1] = $Point[1]

				Case $Local = "BottomRight"
					ReDim $iBottomRight[UBound($iBottomRight) + 1][2]
					$iBottomRight[UBound($iBottomRight) - 1][0] = $Point[0]
					$iBottomRight[UBound($iBottomRight) - 1][1] = $Point[1]

				Case $Local = "BottomLeft"
					ReDim $iBottomLeft[UBound($iBottomLeft) + 1][2]
					$iBottomLeft[UBound($iBottomLeft) - 1][0] = $Point[0]
					$iBottomLeft[UBound($iBottomLeft) - 1][1] = $Point[1]
			EndSelect
		Next
	Next
	; Final array
	$g_aFinalOuter[0] = $iTopLeft
	$g_aFinalOuter[1] = $iTopRight
	$g_aFinalOuter[2] = $iBottomRight
	$g_aFinalOuter[3] = $iBottomLeft

	#Region - Bad Points
	; In no 'DP' case.
	If $bBadPoints = True Then
		Setlog("BuilderBaseGetDeployPoints | No DP,	GET FROM EDGE.", $Color_Error)

		If Not $g_bRunState Then Return

		$Sides = $g_aOuterEdges

		For $i = 0 To 3
			Setlog($Name[$i] & " points: " & UBound($Sides[$i]))
			$DeployPoints[$i] = $Sides[$i]
		Next

	EndIf
	#EndRegion - Bad Points

	; Verify how many point and if needs OuterEdges points [5 points]
	For $i = 0 To 3
		If Not $g_bRunState Then Return
		If UBound($DeployPoints[$i]) < 5 Then
			Setlog($Name[$i] & " doesn't have enough deploy points(" & UBound($DeployPoints[$i]) & ") let's use Outer points", $COLOR_DEBUG)
			;When arrayconcatenate does not work so just simply use outer points(Because it can happen due to non array etc)
			If UBound($DeployPoints[$i], $UBOUND_COLUMNS) <> UBound($g_aFinalOuter[$i], $UBOUND_COLUMNS) Then
				SetDebugLog("$DeployPoints Array dimension array diff from $g_aFinalOuter array", $COLOR_DEBUG)
				$DeployPoints[$i] = $g_aFinalOuter[$i]
			Else
				; Array Combine
				Local $tempDeployPoints = $DeployPoints[$i]
				SetDebugLog($Name[$i] & " Outer points are " & UBound($g_aFinalOuter[$i]))
				Local $tempFinalOuter = $g_aFinalOuter[$i]
				For $j = 0 To UBound($tempFinalOuter, $UBOUND_ROWS) - 1
					ReDim $tempDeployPoints[UBound($tempDeployPoints, $UBOUND_ROWS) + 1][2]
					$tempDeployPoints[UBound($tempDeployPoints, $UBOUND_ROWS) - 1][0] = $tempFinalOuter[$j][0]
					$tempDeployPoints[UBound($tempDeployPoints, $UBOUND_ROWS) - 1][1] = $tempFinalOuter[$j][1]
				Next
				$DeployPoints[$i] = $tempDeployPoints
			EndIf
			Setlog($Name[$i] & " points(" & UBound($DeployPoints[$i]) & ") after using outer one", $COLOR_DEBUG)
		EndIf
	Next
	;Find Best 10 points 1-10 , the 5 is the Middle , 1 = closest to BuilderHall
	Local $BestDeployPoints[4]
	For $i = 0 To 3
		;Before Finding Best Drop Points First we need to sort x-axis so we have best points
		_ArraySort($DeployPoints[$i], 0, 0, 0, 0) ; Sort By X-Axis
		SetDebugLog("Get the best Points for " & $Name[$i])
		$BestDeployPoints[$i] = FindBestDropPoints($DeployPoints[$i])
	Next

	Setlog("Builder Base Outer Edges Deploy Points: " & Round(__timerdiff($hStarttime) / 1000, 2) & " seconds", $COLOR_DEBUG)

	If $bDebugImage Or $g_bDebugBBattack Then DebugBuilderBaseBuildingsDetection($DeployPoints, $BestDeployPoints, "Deploy_Points")
	$g_aDeployPoints = $DeployPoints
	$g_aDeployBestPoints = $BestDeployPoints

EndFunc   ;==>BuilderBaseGetDeployPoints

Func FindBestDropPoints($DropPoints, $MaxDropPoint = 10)
	;Find Best 10 points 1-10 , the 5 is the Middle , 1 = closest to BuilderHall
	Local $aDeployP[0][2]
	If Not $g_bRunState Then Return
	;Just in case $DropPoints is empty
	If Not UBound($DropPoints) > 0 Then Return

	; If the points are less than MaxDrop Points then is necessary to assign max drop points
	; New code correction
	If UBound($DropPoints) < $MaxDropPoint Then $MaxDropPoint = UBound($DropPoints)

	Local $ArrayDimStep = Ceiling(UBound($DropPoints) / $MaxDropPoint)
	SetDebugLog("The array dimension step is " & $ArrayDimStep)

	ReDim $aDeployP[UBound($aDeployP) + 1][2]
	$aDeployP[UBound($aDeployP) - 1][0] = $DropPoints[0][0] ; X axis First Point
	$aDeployP[UBound($aDeployP) - 1][1] = $DropPoints[0][1] ; Y axis First Point
	SetDebugLog("First point assigned at " & $DropPoints[0][0] & "," & $DropPoints[0][1])
	; New code correction
	If $MaxDropPoint > 2 Then
		For $i = 1 To $MaxDropPoint - 2 ; e.g if $MaxDeployPoint is 10 get 2 to 9 points
			Local $DimensionTemp = $ArrayDimStep * ($i) >= UBound($DropPoints) ? UBound($DropPoints) - 1 : $ArrayDimStep * ($i)
			SetDebugLog("Assigned Array Dimension: " & $DimensionTemp)
			If $DimensionTemp = (UBound($DropPoints) - 1) Then $DimensionTemp -= 1 ; Incase of $DropPoints is Odd Number Last Point Can Be Duplicate to avoid that did the -1
			SetDebugLog("Dimension Correction: " & $DimensionTemp)
			ReDim $aDeployP[UBound($aDeployP) + 1][2]
			$aDeployP[UBound($aDeployP) - 1][0] = $DropPoints[$DimensionTemp][0] ; X axis
			$aDeployP[UBound($aDeployP) - 1][1] = $DropPoints[$DimensionTemp][1] ; Y axis
		Next
	EndIf

	ReDim $aDeployP[UBound($aDeployP) + 1][2]
	$aDeployP[UBound($aDeployP) - 1][0] = $DropPoints[UBound($DropPoints) - 1][0] ; X axis of Last Point
	$aDeployP[UBound($aDeployP) - 1][1] = $DropPoints[UBound($DropPoints) - 1][1] ; Y axis of Last Point
	SetDebugLog("last point assigned at " & $DropPoints[UBound($DropPoints) - 1][0] & "," & $DropPoints[UBound($DropPoints) - 1][1])

	Return $aDeployP
EndFunc   ;==>FindBestDropPoints

Func DeployPointsPosition($aPixel, $bIsBH = False)
	If Not $g_bRunState Then Return
	Local $sReturn = "", $aXY[2]

	If $bIsBH = True And IsArray($g_aBuilderHallPos) Then
		$aXY[0] = $g_aBuilderHallPos[0][1]
		$aXY[1] = $g_aBuilderHallPos[0][2]
	Else
		$aXY[0] = 441
		$aXY[1] = 422
	EndIf

	; Using to determinate the Side position on Screen |Bottom Right|Bottom Left|Top Left|Top Right|
	If IsArray($aPixel) Then
		If $aPixel[0] < $aXY[0] And $aPixel[1] <= $aXY[1] Then $sReturn = "TopLeft"
		If $aPixel[0] >= $aXY[0] And $aPixel[1] < $aXY[1] Then $sReturn = "TopRight"
		If $aPixel[0] < $aXY[0] And $aPixel[1] > $aXY[1] Then $sReturn = "BottomLeft"
		If $aPixel[0] >= $aXY[0] And $aPixel[1] >= $aXY[1] Then $sReturn = "BottomRight"
		If $sReturn = "" Then
			Setlog("Error on SIDE: " & _ArrayToString($aPixel), $COLOR_ERROR)
			$sReturn = "TopLeft"
		EndIf
		Return $sReturn
	Else
		Setlog("ERROR SIDE|DeployPointsPosition!", $COLOR_ERROR)
	EndIf
EndFunc   ;==>DeployPointsPosition

Func BuilderBaseBuildingsDetection($iBuilding = 4, $bScreenCap = True)

	Local $aBuildings = ["AirDefenses", "Crusher", "GuardPost", "Cannon", "Air Bombs", "Lava Launcher", "Roaster", "BuilderHall"]
	If UBound($aBuildings) -1 < $iBuilding Then Return -1

	Local $sDirectory = $g_sImgOpponentBuildingsBB & "\" & $aBuildings[$iBuilding]

	Setlog("Initial detection for " & $aBuildings[$iBuilding], $COLOR_ACTION)

	If $bScreenCap = True Then _CaptureRegion2()

	Local $aScreen[4] = [83, 136, 844, 694]
	If Not $g_bRunState Then Return
	Return findMultipleQuick($sDirectory, 10, $aScreen, False, Default, Default, 10)

EndFunc   ;==>BuilderBaseBuildingsDetection

Func DebugBuilderBaseBuildingsDetection2($DetectedBuilding)
	_CaptureRegion2()
	Local $subDirectory = $g_sProfileTempDebugPath & "BuilderBase"
	DirCreate($subDirectory)
	Local $Date = @YEAR & "-" & @MON & "-" & @MDAY
	Local $Time = @HOUR & "." & @MIN & "." & @SEC
	Local $editedImage = _GDIPlus_BitmapCreateFromHBITMAP($g_hHBitmap2)
	Local $hGraphic = _GDIPlus_ImageGetGraphicsContext($editedImage)
	Local $hPenRED = _GDIPlus_PenCreate(0xFFFF0000, 3) ; Create a pencil Color FF0000/RED
	Local $filename = ""

	For $i = 0 To UBound($DetectedBuilding) - 1
		Local $SingleCoordinate = [$DetectedBuilding[$i][0], $DetectedBuilding[$i][1], $DetectedBuilding[$i][2]]
		_GDIPlus_GraphicsDrawString($hGraphic, $DetectedBuilding[$i][0], $DetectedBuilding[$i][1] + 10, $DetectedBuilding[$i][2] - 10)
		_GDIPlus_GraphicsDrawRect($hGraphic, $DetectedBuilding[$i][1] - 5, $DetectedBuilding[$i][2] - 5, 10, 10, $hPenRED)
		$filename = String($Date & "_" & $Time & "_" & $DetectedBuilding[$i][0] & "_.png")
	Next

	_GDIPlus_ImageSaveToFile($editedImage, $subDirectory & "\" & $filename)
	_GDIPlus_PenDispose($hPenRED)
	_GDIPlus_GraphicsDispose($hGraphic)
	_GDIPlus_BitmapDispose($editedImage)
EndFunc   ;==>DebugBuilderBaseBuildingsDetection2

Func DebugBuilderBaseBuildingsDetection($DeployPoints, $BestDeployPoints, $DebugText, $CSVDeployPoints = 0, $isCSVDeployPoints = False)

	_CaptureRegion2()
	Local $subDirectory = $g_sProfileTempDebugPath & "BuilderBase"
	DirCreate($subDirectory)
	Local $Date = @YEAR & "-" & @MON & "-" & @MDAY
	Local $Time = @HOUR & "." & @MIN & "." & @SEC
	Local $editedImage = _GDIPlus_BitmapCreateFromHBITMAP($g_hHBitmap2)
	Local $hGraphic = _GDIPlus_ImageGetGraphicsContext($editedImage)
	Local $hPenRED = _GDIPlus_PenCreate(0xFFFF0000, 3) ; Create a pencil Color FF0000/RED
	Local $hPenWhite = _GDIPlus_PenCreate(0xFFFFFFFF, 3) ; Create a pencil Color FFFFFF/WHITE
	Local $hPenYellow = _GDIPlus_PenCreate(0xFFEEF017, 3) ; Create a pencil Color EEF017/YELLOW
	Local $hPenBlue = _GDIPlus_PenCreate(0xFF6052F9, 3) ; Create a pencil Color 6052F9/BLUE

	If IsArray($g_aBuilderHallPos) Then
		_GDIPlus_GraphicsDrawRect($hGraphic, $g_aBuilderHallPos[0][1] - 5, $g_aBuilderHallPos[0][2] - 5, 10, 10, $hPenRED)
		_GDIPlus_GraphicsDrawLine($hGraphic, 0, $g_aBuilderHallPos[0][2], 860, $g_aBuilderHallPos[0][2], $hPenWhite)
		_GDIPlus_GraphicsDrawLine($hGraphic, $g_aBuilderHallPos[0][1], 0, $g_aBuilderHallPos[0][1], 628, $hPenWhite)
	EndIf

	Local $Text = ["TL", "TR", "BR", "BL"]
	Local $Position[4][2] = [[180, 230], [730, 230], [730, 600], [180, 600]]

	Local $hBrush = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
	Local $hFormat = _GDIPlus_StringFormatCreate()
	Local $hFamily = _GDIPlus_FontFamilyCreate("Arial")
	Local $hFont = _GDIPlus_FontCreate($hFamily, 20)

	If IsArray($g_aBuilderBaseDiamond) <> True Or Not (UBound($g_aBuilderBaseDiamond) > 0) Then Return False

	Local $iSize = $g_aBuilderBaseDiamond[0]

	For $i = 1 To UBound($g_aBuilderBaseDiamond) - 1
		Local $Coord = $g_aBuilderBaseDiamond[$i]
		Local $NextCoord = ($i = UBound($g_aBuilderBaseDiamond) - 1) ? $g_aBuilderBaseDiamond[1] : $g_aBuilderBaseDiamond[$i + 1]
		_GDIPlus_GraphicsDrawLine($hGraphic, $Coord[0], $Coord[1], $NextCoord[0], $NextCoord[1], $hPenBlue)
	Next

	Local $iSize = $g_aBuilderBaseOuterDiamond[0]

	For $i = 1 To UBound($g_aBuilderBaseOuterDiamond) - 1
		Local $Coord = $g_aBuilderBaseOuterDiamond[$i]
		Local $NextCoord = ($i = UBound($g_aBuilderBaseOuterDiamond) - 1) ? $g_aBuilderBaseOuterDiamond[1] : $g_aBuilderBaseOuterDiamond[$i + 1]
		_GDIPlus_GraphicsDrawLine($hGraphic, $Coord[0], $Coord[1], $NextCoord[0], $NextCoord[1], $hPenBlue)
	Next


	For $i = 0 To UBound($g_aExternalEdges) - 1
		Local $Local = $g_aExternalEdges[$i]
		For $j = 0 To UBound($Local) - 1
			_GDIPlus_GraphicsDrawRect($hGraphic, $Local[$j][0] - 2, $Local[$j][1] - 2, 4, 4, $hPenYellow)
		Next
	Next

	For $i = 0 To UBound($g_aOuterEdges) - 1
		Local $Local = $g_aOuterEdges[$i]
		For $j = 0 To UBound($Local) - 1
			_GDIPlus_GraphicsDrawRect($hGraphic, $Local[$j][0] - 2, $Local[$j][1] - 2, 4, 4, $hPenWhite)
		Next
	Next

	For $i = 0 To 3
		Local $Local = $DeployPoints[$i]
		Local $tLayout = _GDIPlus_RectFCreate($Position[$i][0], $Position[$i][1], 0, 0)
		Local $aInfo = _GDIPlus_GraphicsMeasureString($hGraphic, $Text[$i], $hFont, $tLayout, $hFormat)
		_GDIPlus_GraphicsDrawStringEx($hGraphic, $Text[$i], $hFont, $aInfo[0], $hFormat, $hBrush)
		For $j = 0 To UBound($Local) - 1
			_GDIPlus_GraphicsDrawRect($hGraphic, $Local[$j][0] - 2, $Local[$j][1] - 2, 4, 4, $hPenYellow)
		Next
	Next

	For $i = 0 To 3
		Local $Local = $BestDeployPoints[$i]
		Local $tLayout = _GDIPlus_RectFCreate($Position[$i][0], $Position[$i][1], 0, 0)
		Local $aInfo = _GDIPlus_GraphicsMeasureString($hGraphic, $Text[$i], $hFont, $tLayout, $hFormat)
		_GDIPlus_GraphicsDrawStringEx($hGraphic, $Text[$i], $hFont, $aInfo[0], $hFormat, $hBrush)
		For $j = 0 To UBound($Local) - 1
			_GDIPlus_GraphicsDrawRect($hGraphic, $Local[$j][0] - 2, $Local[$j][1] - 2, 4, 4, $hPenRED)
		Next
	Next

	If $isCSVDeployPoints And IsArray($CSVDeployPoints) = 1 Then
		For $j = 0 To UBound($CSVDeployPoints) - 1
			_GDIPlus_GraphicsDrawRect($hGraphic, $CSVDeployPoints[$j][0], $CSVDeployPoints[$j][1] - 2, 4, 4, $hPenWhite)
		Next
	EndIf

	Local $filename = String($Date & "_" & $Time & "_" & $DebugText & "_" & $iSize & "_.png")

	_GDIPlus_ImageSaveToFile($editedImage, $subDirectory & "\" & $filename)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_BrushDispose($hBrush)
	_GDIPlus_PenDispose($hPenRED)
	_GDIPlus_PenDispose($hPenWhite)
	_GDIPlus_PenDispose($hPenYellow)
	_GDIPlus_PenDispose($hPenBlue)
	_GDIPlus_GraphicsDispose($hGraphic)
	_GDIPlus_BitmapDispose($editedImage)

EndFunc   ;==>DebugBuilderBaseBuildingsDetection

Func BuilderBaseGetEdges($iBuilderBaseDiamond, $Text)

	Local $iTopLeft[0][2], $iTopRight[0][2], $iBottomRight[0][2], $iBottomLeft[0][2]
	If Not $g_bRunState Then Return

	Local $iCount = 0

	Local $iTop = $iBuilderBaseDiamond[1], $iRight = $iBuilderBaseDiamond[2], $iBottomR = $iBuilderBaseDiamond[3], $iBottomL = $iBuilderBaseDiamond[4], $iLeft = $iBuilderBaseDiamond[5]

	Local $X = [$iTop[0], $iRight[0]]
	Local $Y = [$iTop[1], $iRight[1]]

	; Old imprecise system removed, now points are generated by angles perfectly from line to line and randomly every 20 + (+/- random) py distance, which is crazy.
	Local $aLinecutter

	; TOP RIGHT
	$iCount = 0
	Local $iMult = Abs(Pixel_Distance($X[0], $Y[0], $X[1], $Y[1]) / 20)
	For $i = 1 To 20
		$aLinecutter = Linecutter($X[0], $Y[0], $X[1], $Y[1], $i * $iMult)

		ReDim $iTopRight[$iCount + 1][2]
		$iTopRight[$iCount][0] = Floor($aLinecutter[0])
		$iTopRight[$iCount][1] = Floor($aLinecutter[1])
		$iCount += 1
	Next

	Local $X = [$iRight[0], $iBottomR[0]]
	Local $Y = [$iRight[1], $iBottomR[1]]

	; BOTTOM RIGHT
	$iCount = 0
	Local $iMult = Abs(Pixel_Distance($X[0], $Y[0], $X[1], $Y[1]) / 10)
	For $i = 1 To 20
		$aLinecutter = Linecutter($X[0], $Y[0], $X[1], $Y[1], $i * $iMult)

		If Floor($aLinecutter[1]) > 570 Then ContinueLoop
		ReDim $iBottomRight[$iCount + 1][2]
		$iBottomRight[$iCount][0] = Floor($aLinecutter[0])
		$iBottomRight[$iCount][1] = Floor($aLinecutter[1])
		$iCount += 1
	Next

	Local $X = [$iBottomL[0], $iLeft[0]]
	Local $Y = [$iBottomL[1], $iLeft[1]]

	; BOTTOM LEFT
	$iCount = 0
	Local $iMult = Abs(Pixel_Distance($X[0], $Y[0], $X[1], $Y[1]) / 10)
	For $i = 1 To 20
		$aLinecutter = Linecutter($X[0], $Y[0], $X[1], $Y[1], $i * $iMult)

		If Floor($aLinecutter[1]) > 570 Then ContinueLoop
		ReDim $iBottomLeft[$iCount + 1][2]
		$iBottomLeft[$iCount][0] = Floor($aLinecutter[0])
		$iBottomLeft[$iCount][1] = Floor($aLinecutter[1])
		$iCount += 1
	Next

	Local $X = [$iLeft[0], $iTop[0]]
	Local $Y = [$iLeft[1], $iTop[1]]

	; TOP LEFT
	$iCount = 0
	Local $iMult = Abs(Pixel_Distance($X[0], $Y[0], $X[1], $Y[1]) / 20)
	For $i = 1 To 20
		$aLinecutter = Linecutter($X[0], $Y[0], $X[1], $Y[1], $i * $iMult)
		ReDim $iTopLeft[$iCount + 1][2]
		$iTopLeft[$iCount][0] = Floor($aLinecutter[0])
		$iTopLeft[$iCount][1] = Floor($aLinecutter[1])
		$iCount += 1
	Next

	Local $aExternalEdges[4] = [$iTopLeft, $iTopRight, $iBottomRight, $iBottomLeft]
	Local $asNames = ["Top Left", "Top Right", "Bottom Right", "Bottom Left"]

	For $i = 0 To 3
		SetDebugLog($Text & " Points to " & $asNames[$i] & " (" & UBound($aExternalEdges[$i]) & ")")
	Next

	Return $aExternalEdges

EndFunc   ;==>BuilderBaseGetEdges

#Cs
Func BuilderBaseGetFakeEdges()
	Local $aTopLeft[18][2], $aTopRight[18][2], $aBottomRight[18][2], $aBottomLeft[18][2]
	; several points when the Village was not zoomed
	; Presets
	For $i = 0 To 17
		$aTopLeft[$i][0] = 145 + ($i * 15)
		$aTopLeft[$i][1] = 275 - ($i * 11)
	Next
	For $i = 0 To 17
		$aTopRight[$i][0] = 430 + ($i * 20)
		$aTopRight[$i][1] = 75 + ($i * 15)
	Next
	For $i = 0 To 17
		$aBottomRight[$i][0] = 700 + ($i * 8)
		$aBottomRight[$i][1] = 610 + 88 - ($i * 6)
	Next
	For $i = 0 To 17
		$aBottomLeft[$i][0] = 10 + ($i * 4.5)
		$aBottomLeft[$i][1] = 500 + 88 + ($i * 3.5)
	Next

	Local $aExternalEdges[4] = [$aTopLeft, $aTopRight, $aBottomRight, $aBottomLeft]
	Return $aExternalEdges
EndFunc   ;==>BuilderBaseGetFakeEdges
#ce
Func BuilderBaseResetAttackVariables()
	$g_aAirdefensesPos = -1
	$g_aGuardPostPos = -1
	$g_aCrusherPos = -1
	$g_aCannonPos = -1
	$g_aAirBombs = -1
	$g_aLavaLauncherPos = -1
	$g_aRoasterPos = -1
	$g_aBuilderHallPos = -1

	$g_aDeployPoints = -1
	$g_aDeployBestPoints = -1

	Global $g_aExternalEdges, $g_aBuilderBaseDiamond, $g_aOuterEdges, $g_aBuilderBaseOuterDiamond, $g_aBuilderBaseOuterPolygon, $g_aFinalOuter[4]
EndFunc   ;==>BuilderBaseResetAttackVariables

Func BuilderBaseAttackMainSide()
	Local $sMainSide = "TopLeft"
	Local $sSideNames[4] = ["TopLeft", "TopRight", "BottomRight", "BottomLeft"]
	Local $sBuilderNames[5] = ["Airdefenses", "Crusher", "GuardPost", "Cannon", "BuilderHall"]
	Local $QuantitiesDetected[4] = [0, 0, 0, 0]
	Local $QuantitiesAttackSide[4] = [0, 0, 0, 0]
	Local $Buildings[5] = [$g_aAirdefensesPos, $g_aCrusherPos, $g_aGuardPostPos, $g_aCannonPos, $g_aBuilderHallPos]

	; $g_aAirdefensesPos, $g_aCrusherPos, $g_aGuardPostPos, $g_aCannonPos, $g_aBuilderHallPos
	For $Index = 0 To UBound($Buildings) -1
		If Not $g_bRunState Then Return
		Local $tempBuilders = $Buildings[$Index]
		SetDebugLog("BuilderBaseAttackMainSide - Builder Name : " & $sBuilderNames[$Index])
		SetDebugLog("BuilderBaseAttackMainSide - All points: " & _ArrayToString($tempBuilders))
		; Can exist more than One Building detected
		For $Howmany = 0 To UBound($tempBuilders) - 1
			If Not IsArray($tempBuilders) Then ExitLoop ; goes to next Builder Type
			Local $TempBuilder = [$tempBuilders[$Howmany][1], $tempBuilders[$Howmany][2]]
			Local $side = DeployPointsPosition($TempBuilder, ($Howmany = 4))
			SetDebugLog("BuilderBaseAttackMainSide - Point: " & _ArrayToString($TempBuilder))
			SetDebugLog("BuilderBaseAttackMainSide - " & $sBuilderNames[$Index] & " Side : " & $side)
			For $Sides = 0 To UBound($sSideNames) - 1
				If $side = $sSideNames[$Sides] Then
					; Add one more building to correct side
					$QuantitiesDetected[$Sides] += 1
					; ; ;
					; Let's get the Opposite side If doesn't have any detectable Buiding
					; ; ;
					Local $mainSide = $Sides + 2 > 3 ? Abs(($Sides + 2) - 4) : $Sides + 2
					SetDebugLog(" -- " & $sBuilderNames[$Index] & " Side : " & $sSideNames[$Sides])
					SetDebugLog(" -- MainSide to Attack : " & $sSideNames[$mainSide])
					; Let's check the for sides
					For $j = 0 To 3
						Local $LastBuilderSide = $mainSide
						If $QuantitiesDetected[$mainSide] = 0 Then
							$QuantitiesAttackSide[$mainSide] += 1
							SetDebugLog(" -- Confirming the MainSide [$mainSide]: " & $sSideNames[$mainSide])
							ExitLoop (2) ; exit to next Builder position [$Howmany]
						EndIf
						; Lets check other side
						$mainSide = Abs(($mainSide + 1) - 4)
						SetDebugLog(" --- New MainSide [$mainSide]: " & $sSideNames[$mainSide] & " last Side have a building!")
					Next
				EndIf
			Next
		Next
	Next
	For $i = 0 To 3
		If $QuantitiesDetected[$i] > 0 Then SetDebugLog("BuilderBaseAttackMainSide - $QuantitiesDetected : " & $sSideNames[$i] & " - " & $QuantitiesDetected[$i])
	Next
	For $i = 0 To 3
		If $QuantitiesAttackSide[$i] > 0 Then SetDebugLog("BuilderBaseAttackMainSide - $QuantitiesAttackSide : " & $sSideNames[$i] & " - " & $QuantitiesAttackSide[$i])
	Next

	Local $LessNumber = 0

	For $i = 0 To 3
		If $QuantitiesAttackSide[$i] > $LessNumber Then
			$LessNumber = $QuantitiesAttackSide[$i]
			$sMainSide = $sSideNames[$i]
		EndIf
	Next

	Return $sMainSide
EndFunc   ;==>BuilderBaseAttackMainSide

Func BuilderBaseBuildingsOnEdge($g_aDeployPoints)
	Local $sSideNames[4] = ["TopLeft", "TopRight", "BottomRight", "BottomLeft"]
	; $TempTopLeft[XX][2]
	If UBound($g_aDeployPoints) < 4 Then Return
	If Not $g_bRunState Then Return

	Local $TempTopLeft = $g_aDeployPoints[0]
	Local $TempTopRight = $g_aDeployPoints[1]
	Local $TempBottomRight = $g_aDeployPoints[2]
	Local $TempBottomLeft = $g_aDeployPoints[3]

	; Getting the Out Edges deploy points
	Local $TempOuterTL = $g_aOuterEdges[0]
	Local $TempOuterTR = $g_aOuterEdges[1]
	Local $TempOuterBR = $g_aOuterEdges[2]
	Local $TempOuterBL = $g_aOuterEdges[3]

	;Index 3 Contains Side Name Needed For Adding Tiles Pixel
	Local $ToReturn[0][3], $iLeft = False, $iTop = False, $iRight = False, $iBottom = False

	For $Index = 0 To UBound($TempTopLeft) - 1
		If Int($TempTopLeft[$Index][0]) < 195 Then
			If Not $iLeft Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterTL[0][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterTL[0][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[0]
				$iLeft = True
				Setlog("Possible Building at edge at LEFT corner " & $TempTopLeft[$Index][0] & "x" & $TempTopLeft[$Index][1], $COLOR_DEBUG)
			EndIf
		ElseIf Int($TempTopLeft[$Index][1]) < 265 Then
			If Not $iTop Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterTL[UBound($TempOuterTL) - 1][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterTL[UBound($TempOuterTL) - 1][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[0]
				$iTop = True
				Setlog("Possible Building at edge at TOP corner " & $TempTopLeft[$Index][0] & "x" & $TempTopLeft[$Index][1], $COLOR_DEBUG)
			EndIf
		EndIf
	Next

	If Not $g_bRunState Then Return

	For $Index = 0 To UBound($TempTopRight) - 1
		If Int($TempTopRight[$Index][0]) > 700 Then
			If Not $iRight Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterTR[UBound($TempOuterTR) - 1][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterTR[UBound($TempOuterTR) - 1][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[1]
				$iRight = True
				Setlog("Possible Building at edge at RIGHT corner " & $TempTopRight[$Index][0] & "x" & $TempTopRight[$Index][1], $COLOR_DEBUG)
			EndIf
		ElseIf Int($TempTopRight[$Index][1]) < 265 Then
			If Not $iTop Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterTR[0][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterTR[0][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[1]
				$iTop = True
				Setlog("Possible Building at edge at TOP corner " & $TempTopRight[$Index][0] & "x" & $TempTopRight[$Index][1], $COLOR_DEBUG)
			EndIf
		EndIf
	Next

	If Not $g_bRunState Then Return

	For $Index = 0 To UBound($TempBottomRight) - 1
		If Int($TempBottomRight[$Index][0]) > 700 Then
			If Not $iRight Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterBR[0][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterBR[0][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[2]
				$iRight = True
				Setlog("Possible Building at edge at RIGHT corner " & $TempBottomRight[$Index][0] & "x" & $TempBottomRight[$Index][1], $COLOR_DEBUG)
			EndIf
		ElseIf Int($TempBottomRight[$Index][1]) > 570 Then
			If Not $iBottom Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterBR[UBound($TempOuterBR) - 1][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterBR[UBound($TempOuterBR) - 1][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[2]
				$iBottom = True
				Setlog("Possible Building at edge at BOTTOM corner " & $TempBottomRight[$Index][0] & "x" & $TempBottomRight[$Index][1], $COLOR_DEBUG)
			EndIf
		EndIf
	Next

	If Not $g_bRunState Then Return

	For $Index = 0 To UBound($TempBottomLeft) - 1
		If Int($TempBottomLeft[$Index][0]) < 195 Then
			If Not $iLeft Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterBL[UBound($TempOuterBL) - 1][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterBL[UBound($TempOuterBL) - 1][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[3]
				$iLeft = True
				Setlog("Possible Building at edge at LEFT corner " & $TempBottomLeft[$Index][0] & "x" & $TempBottomLeft[$Index][1], $COLOR_DEBUG)
			EndIf
		ElseIf Int($TempBottomLeft[$Index][1]) > 570 Then
			If Not $iBottom Then
				ReDim $ToReturn[UBound($ToReturn) + 1][3]
				$ToReturn[UBound($ToReturn) - 1][0] = $TempOuterBL[0][0]
				$ToReturn[UBound($ToReturn) - 1][1] = $TempOuterBL[0][1]
				$ToReturn[UBound($ToReturn) - 1][2] = $sSideNames[3]
				$iBottom = True
				Setlog("Possible Building at edge at BOTTOM corner " & $TempBottomLeft[$Index][0] & "x" & $TempBottomLeft[$Index][1], $COLOR_DEBUG)
			EndIf
		EndIf
	Next

	If Not $g_bRunState Then Return

	Return UBound($ToReturn) > 0 ? $ToReturn : "-1"

EndFunc   ;==>BuilderBaseBuildingsOnEdge

Func findMultipleQuick($sDirectory, $iQuantityMatch = Default, $vArea2SearchOri = Default, $vForceCaptureOrPtr = True, $sOnlyFind = "", $bExactFind = False, $iDistance2check = 25, $bDebugLog = $g_bDebugImageSave, $minLevel = 0, $maxLevel = 1000, $vArea2SearchOri2 = Default)

	$g_aImageSearchXML = -1
	Local $iCount = 0, $returnProps = "objectname,objectlevel,objectpoints"

	Static $_hHBitmap = 0
	Local $bIsPtr = False
	If $vForceCaptureOrPtr = Default Or $vForceCaptureOrPtr = True Then
		; Capture the screen for comparison
		If $vForceCaptureOrPtr Then
			_CaptureRegion2() ;to have FULL screen image to work with
		EndIf
	ElseIf IsPtr($vForceCaptureOrPtr) Then
		$_hHBitmap = GetHHBitmapArea($vForceCaptureOrPtr)
		$bIsPtr = True
	EndIf

	If $vArea2SearchOri = Default Then $vArea2SearchOri = "FV"

	If $iQuantityMatch = Default Then $iQuantityMatch = 0
	If $sOnlyFind = Default Then $sOnlyFind = ""
	Local $bOnlyFindIsSpace = StringIsSpace($sOnlyFind)

	If (IsArray($vArea2SearchOri)) Then
		$vArea2SearchOri = GetDiamondFromArray($vArea2SearchOri)
	EndIf
	If 3 = ((StringReplace($vArea2SearchOri, ",", ",") <> "") ? (@extended) : (0)) Then
		$vArea2SearchOri = GetDiamondFromRect($vArea2SearchOri)
	EndIf

	Local $iQuantToMach = ($bOnlyFindIsSpace = True) ? ($iQuantityMatch) : (0)
	If IsDir($sDirectory) = False Then
		$sOnlyFind = StringRegExpReplace($sDirectory, "^.*\\|\..*$", "")
		If StringRight($sOnlyFind, 1) = "*" Then
			$sOnlyFind = StringTrimRight($sOnlyFind, 1)
		EndIf
		Local $aTring = StringSplit($sOnlyFind, "_", $STR_NOCOUNT + $STR_ENTIRESPLIT)
		If Not @error Then
			$sOnlyFind = $aTring[0]
		EndIf
		$bExactFind = False
		$sDirectory = StringRegExpReplace($sDirectory, "(^.*\\)(.*)", "\1")
		$iQuantToMach = 0
	EndIf

	If $vArea2SearchOri2 = Default Then
		$vArea2SearchOri2 = $vArea2SearchOri
	Else
		If (IsArray($vArea2SearchOri2)) Then
			$vArea2SearchOri2 = GetDiamondFromArray($vArea2SearchOri2)
		EndIf
		If 3 = ((StringReplace($vArea2SearchOri2, ",", ",") <> "") ? (@extended) : (0)) Then
			$vArea2SearchOri2 = GetDiamondFromRect($vArea2SearchOri2)
		EndIf
	EndIf

	Local $aCoords = "" ; use AutoIt mixed variable type and initialize array of coordinates to null
	Local $returnData = StringSplit($returnProps, ",", $STR_NOCOUNT + $STR_ENTIRESPLIT)
	Local $returnLine[UBound($returnData)]

	Local $error, $extError
	Local $result = DllCallMyBot("SearchMultipleTilesBetweenLevels", "handle", ($bIsPtr = True) ? ($_hHBitmap) : ($g_hHBitmap2), "str", $sDirectory, "str", $vArea2SearchOri, "Int", $iQuantToMach, "str", $vArea2SearchOri2, "Int", $minLevel, "Int", $maxLevel)
	$error = @error ; Store error values as they reset at next function call
	$extError = @extended
	If $_hHBitmap <> 0 Then
		GdiDeleteHBitmap($_hHBitmap)
	EndIf
	$_hHBitmap = 0
	If $error Then
		_logErrorDLLCall($g_sLibMyBotPath, $error)
		SetDebugLog(" imgloc DLL Error : " & $error & " --- " & $extError)
		SetError(2, $extError, $aCoords) ; Set external error code = 2 for DLL error
		Return -1
	EndIf

	If checkImglocError($result, "findMultipleQuick", $sDirectory) = True Then
		SetDebugLog("findMultipleQuick Returned Error or No values : ", $COLOR_DEBUG)
		Return -1
	EndIf

	Local $resultArr = StringSplit($result[0], "|", $STR_NOCOUNT + $STR_ENTIRESPLIT), $sSlipt = StringSplit($sOnlyFind, "|", $STR_NOCOUNT + $STR_ENTIRESPLIT)
	;_arraydisplay($resultArr)
	SetDebugLog(" ***  findMultipleQuick multiples **** ", $COLOR_ORANGE)
	If CompKick($resultArr, $sSlipt, $bExactFind) Then
		SetDebugLog(" ***  findMultipleQuick has no result **** ", $COLOR_ORANGE)
		Return -1
	EndIf

	Local $iD2C = $iDistance2check
	Local $aAR[0][4], $aXY
	For $rs = 0 To UBound($resultArr) - 1
		For $rD = 0 To UBound($returnData) - 1 ; cycle props
			$returnLine[$rD] = RetrieveImglocProperty($resultArr[$rs], $returnData[$rD])
			If $returnData[$rD] = "objectpoints" Then
				Local $aC = StringSplit($returnLine[2], "|", $STR_NOCOUNT + $STR_ENTIRESPLIT)
				For $i = 0 To UBound($aC) - 1
					$aXY = StringSplit($aC[$i], ",", $STR_NOCOUNT + $STR_ENTIRESPLIT)
					If UBound($aXY) <> 2 Then ContinueLoop 3
					If $iD2C > 0 Then
						If DMduplicated($aAR, Int($aXY[0]), Int($aXY[1]), UBound($aAR)-1, $iD2C) Then
							ContinueLoop
						EndIf
					EndIf
					ReDim $aAR[$iCount + 1][4]
					$aAR[$iCount][0] = $returnLine[0]
					$aAR[$iCount][1] = Int($aXY[0])
					$aAR[$iCount][2] = Int($aXY[1])
					$aAR[$iCount][3] = Int($returnLine[1])
					$iCount += 1
					If $iCount >= $iQuantityMatch And $iQuantityMatch > 0 Then ExitLoop 3
				Next
			EndIf
		Next
	Next

	$g_aImageSearchXML = $aAR
	If UBound($aAR) < 1 Then
		$g_aImageSearchXML = -1
		Return -1
	EndIf

	If $bDebugLog Then DebugImgArrayClassic($aAR, "findMultipleQuick")

	Return $aAR
EndFunc   ;==>findMultipleQuick

Func CompKick(ByRef $vFiles, $aof, $bType = False)
	If (UBound($aof) = 1) And StringIsSpace($aof[0]) Then Return False
	If $g_bDebugSetlog Then
		SetDebugLog("CompKick : " & _ArrayToString($vFiles))
		SetDebugLog("CompKick : " & _ArrayToString($aof))
		SetDebugLog("CompKick : " & "Exact mode : " & $bType)
	EndIf
	If ($bType = Default) Then $bType = False

	Local $aRS[0]

	If IsArray($vFiles) And IsArray($aof) Then
		SetDebugLog("CompKick compare : " & _ArrayToString($vFiles))
		If $bType Then
			For $s In $aof
				For $s2 In $vFiles
					Local $i2s = StringInStr($s2, "_") - 1
					If StringInStr(StringMid($s2, 1, $i2s), $s, 0) = 1 And $i2s = StringLen($s) Then _ArrayAdd($aRS, $s2)
				Next
			Next
		Else
			For $s In $aof
				For $s2 In $vFiles
					Local $i2s = StringInStr($s2, "_") - 1
					If StringInStr(StringMid($s2, 1, $i2s), $s) > 0 Then _ArrayAdd($aRS, $s2)
				Next
			Next
		EndIf
	EndIf
	$vFiles = $aRS
	Return (UBound($vFiles) = 0)
EndFunc   ;==>CompKick

Func DMduplicated($aXYs, $x1, $y1, $i3, $iD = 18)
	If $i3 > 0 Then
		For $i = 0 To $i3
			If Not $g_bRunState Then Return
			If Pixel_Distance($aXYs[$i][1], $aXYs[$i][2], $x1, $y1) < $iD Then Return True
		Next
	EndIf
	Return False
EndFunc   ;==>DMduplicated

Func DebugImgArrayClassic($aAR = 0, $sFrom = "")
	If $g_hHBitmap2 = 0 Then
		Return
	EndIf
	Local $sDir = ($sFrom <> "") ? ($sFrom) : ("DebugImgArrayClassic")
	Local $sSubDir = $g_sProfileTempDebugPath & $sDir

	DirCreate($sSubDir)

	Local $sDate = @YEAR & "-" & @MON & "-" & @MDAY, $sTime = @HOUR & "." & @MIN & "." & @SEC
	Local $sDebugImageName = String($sDate & "_" & $sTime & "_.png")
	Local $hEditedImage = _GDIPlus_BitmapCreateFromHBITMAP($g_hHBitmap2)
	Local $hGraphic = _GDIPlus_ImageGetGraphicsContext($hEditedImage)
	Local $hPenRED = _GDIPlus_PenCreate(0xFFFF0000, 1)

	For $i = 0 To UBound($aAR) - 1
		addInfoToDebugImage($hGraphic, $hPenRED, $aAR[$i][0] & "_" & $aAR[$i][3], $aAR[$i][1], $aAR[$i][2])
	Next

	_GDIPlus_ImageSaveToFile($hEditedImage, $sSubDir & "\" & $sDebugImageName )
	_GDIPlus_PenDispose($hPenRED)
	_GDIPlus_GraphicsDispose($hGraphic)
	_GDIPlus_BitmapDispose($hEditedImage)
EndFunc

Func IsDir($sFolderPath)
	Return (DirGetSize($sFolderPath) > 0 and not @error)
EndFunc   ;==>IsDir

Func IsFile($sFilePath)
	Return (FileGetSize($sFilePath) > 0 and not @error)
EndFunc   ;==>IsDir

