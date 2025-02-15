; #FUNCTION# ====================================================================================================================
; Name ..........: checkObstacles
; Description ...: Checks whether something is blocking the pixel for mainscreen and tries to unblock
; Syntax ........: checkObstacles()
; Parameters ....:
; Return values .: Returns True when there is something blocking
; Author ........: Hungle (2014)
; Modified ......: KnowJack (2015), Sardo (08-2015), TheMaster1st(10-2015), MonkeyHunter (08-2016), MMHK (12-2016)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
;
Func checkObstacles($bBuilderBase = Default) ;Checks if something is in the way for mainscreen
	FuncEnter(checkObstacles)
	If $bBuilderBase = Default Then $bBuilderBase = $g_bStayOnBuilderBase
	Static $iRecursive = 0

	If Not TestCapture() And WinGetAndroidHandle() = 0 Then
		; Android not available
		Return FuncReturn(True)
	EndIf

	Local $wasForce = OcrForceCaptureRegion(False)
	$iRecursive += 1
	Local $Result = _checkObstacles($bBuilderBase, $iRecursive > 5)
	OcrForceCaptureRegion($wasForce)
	$iRecursive -= 1
	Return FuncReturn($Result)
EndFunc   ;==>checkObstacles

Func _checkObstacles($bBuilderBase = False, $bRecursive = False) ;Checks if something is in the way for mainscreen
	Local $msg, $x, $y, $Result
	$g_bMinorObstacle = False
	_CaptureRegions()

	If Not $bRecursive Then
		If checkObstacles_Network() Then Return True
		;If checkObstacles_GfxError() Then Return True
	EndIf
	Local $bIsOnBuilderIsland = isOnBuilderBase()
	Local $bIsOnMainVillage = isOnMainVillage()
	If $bBuilderBase <> $bIsOnBuilderIsland And ($bIsOnBuilderIsland Or $bIsOnBuilderIsland <> $bIsOnMainVillage) Then
		If $bIsOnBuilderIsland Then
			SetLog("Detected Builder Base, trying to switch back to Main Village")
			AndroidAdbScript("ZoomOut")
			ZoomOut()
		Else
			SetLog("Detected Main Village, trying to switch back to Builder Base")
			ZoomOut()
		EndIf
		If SwitchBetweenBases() Then
			$g_bMinorObstacle = True
			If _Sleep($DELAYCHECKOBSTACLES1) Then Return
			Return False
		EndIf
	EndIf

	If $g_sAndroidGameDistributor <> $g_sGoogle Then ; close an ads window for non google apks
		Local $aXButton = FindAdsXButton()
		If IsArray($aXButton) Then
			SetDebugLog("checkObstacles: Found " & $g_sAndroidGameDistributor & " ADS X button to close")
			PureClickP($aXButton)
			$g_bMinorObstacle = True
			If _Sleep($DELAYCHECKOBSTACLES1) Then Return
			Return False
		EndIf
	EndIf
	
	Local $ascidConnectButton = decodeSingleCoord(findImage("SCID", $g_sImgSupercellIDConnect, GetDiamondFromRect("100,20,700,100"), 1, True))
	If IsArray($ascidConnectButton) And UBound($ascidConnectButton, 1) >= 2 Then
	;If WaitforPixel(685, 30, 686, 31, Hex(0xE6E6E6, 6), 6, 3) Then
		SetDebugLog("checkObstacles: Found SCID popup connect suggestion", $COLOR_ACTION)
		Click($ascidConnectButton[0], $ascidConnectButton[1])
		If _Sleep(1000) Then Return
		Local $aSuperCellIDWindowsUI, $bSCIDWindowOpened = False
		For $i = 0 To 30 ; Checking "New SuperCellID UI" continuously in 30sec
			If Mod($i, 2) = 0 Then
				$aSuperCellIDWindowsUI = decodeSingleCoord(findImage("SupercellID Windows", $g_sImgSupercellIDWindows, GetDiamondFromRect("550,60,760,160"), 1, True, Default))
			Else
				$aSuperCellIDWindowsUI = decodeSingleCoord(findImage("SupercellID Windows", $g_sImgSupercellIDBlack, GetDiamondFromRect("550,450,760,550"), 1, True, Default))
			EndIf
			If IsArray($aSuperCellIDWindowsUI) And UBound($aSuperCellIDWindowsUI, 1) >= 2 Then
				SetLog("SupercellID Window Opened", $COLOR_DEBUG)
				$bSCIDWindowOpened = True
				ExitLoop
			EndIf
			If Not $g_bRunState Then Return
			If _Sleep(900) Then Return
		Next
		If $bSCIDWindowOpened Then
			AndroidBackButton() ;Send back button to android
			If _Sleep(1000) Then Return
			If IsEndBattlePage() Then
				AndroidBackButton()
			EndIf
		EndIf
	EndIf

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Detect All Reload Button errors => 1- Another device, 2- Take a break, 3- Connection lost or error, 4- Out of sync, 5- Inactive, 6- Maintenance, 7- SCID Login Screen
	Local $aMessage = _PixelSearch($aIsReloadError[0], $aIsReloadError[1], $aIsReloadError[0] + 3, $aIsReloadError[1] + 11, Hex($aIsReloadError[2], 6), $aIsReloadError[3], $g_bNoCapturePixel)
	If IsArray($aMessage) Or (UBound(decodeSingleCoord(FindImageInPlace("Error", $g_sImgError, "630,300(2,20)", False, $g_iAndroidLollipop))) > 1) Then
		SetDebugLog("(DC=" & _GetPixelColor($aIsConnectLost[0], $aIsConnectLost[1]) & ")(OoS=" & _GetPixelColor($aIsCheckOOS[0], $aIsCheckOOS[1]) & ")", $COLOR_DEBUG)
		SetDebugLog("33B5E5=>true, 282828=>false", $COLOR_DEBUG)

		;;;;;;;##### 1- Another device #####;;;;;;;
		$Result = getOcrReloadMessage(184, 325, "Another Device OCR:") ; OCR text to find Another device message
		If StringInStr($Result, "device", $STR_NOCASESENSEBASIC) Or _
				UBound(decodeSingleCoord(FindImageInPlace("Device", $g_sImgAnotherDevice, "220,300(130,60)", False))) > 1 Then
			If TestCapture() Then Return "Another Device has connected"
			If $g_iAnotherDeviceWaitTime > 3600 Then
				SetLog("Another Device has connected, waiting " & Floor(Floor($g_iAnotherDeviceWaitTime / 60) / 60) & " hours " & Floor(Mod(Floor($g_iAnotherDeviceWaitTime / 60), 60)) & " minutes " & Floor(Mod($g_iAnotherDeviceWaitTime, 60)) & " seconds", $COLOR_ERROR)
				PushMsg("AnotherDevice3600")
			ElseIf $g_iAnotherDeviceWaitTime > 60 Then
				SetLog("Another Device has connected, waiting " & Floor(Mod(Floor($g_iAnotherDeviceWaitTime / 60), 60)) & " minutes " & Floor(Mod($g_iAnotherDeviceWaitTime, 60)) & " seconds", $COLOR_ERROR)
				PushMsg("AnotherDevice60")
			Else
				SetLog("Another Device has connected, waiting " & Floor(Mod($g_iAnotherDeviceWaitTime, 60)) & " seconds", $COLOR_ERROR)
				PushMsg("AnotherDevice")
			EndIf
			If ProfileSwitchAccountEnabled() And $g_bChkSwitchOnAnotherDevice And Not $g_bChkSmartSwitch And $g_bChkSharedPrefs Then
				SetLog("---- Forced Switch, Another device connected ----")
				$g_iNextAccount = $g_iCurAccount + 1
				If $g_iNextAccount > $g_iTotalAcc Then $g_iNextAccount = 0
				$g_bRestart = True
				SwitchForceAnotherDevice($g_iNextAccount)
				Return True
			EndIf
			If _SleepStatus($g_iAnotherDeviceWaitTime * 1000) Then Return ; Wait as long as user setting in GUI, default 120 seconds
			checkObstacles_ReloadCoC($aReloadButton, "#0127", $bRecursive)
			If $g_bForceSinglePBLogoff Then $g_bGForcePBTUpdate = True
			checkObstacles_ResetSearch()
			Return True
		EndIf

		;;;;;;;##### 2- Take a break #####;;;;;;;
		If UBound(decodeSingleCoord(FindImageInPlace("Break", $g_sImgPersonalBreak, "165,257,335,315", False))) > 1 Then ; used for all 3 different break messages
			SetLog("Village must take a break, wait", $COLOR_ERROR)
			If TestCapture() Then Return "Village must take a break"
			PushMsg("TakeBreak")
			If ProfileSwitchAccountEnabled() Then
				$g_iNextAccount = $g_iCurAccount + 1
				If $g_iNextAccount > $g_iTotalAcc Then $g_iNextAccount = 0
				$g_bRestart = True
				SwitchForceAnotherDevice($g_iNextAccount)
				Return True
			Else
				If _SleepStatus($DELAYCHECKOBSTACLES4) Then Return ; 2 Minutes
			EndIf
			checkObstacles_ReloadCoC($aReloadButton, "#0128", $bRecursive) ;Click on reload button
			If $g_bForceSinglePBLogoff Then $g_bGForcePBTUpdate = True
			checkObstacles_ResetSearch()
			Return True
		EndIf

		;;;;;;;##### Connection Lost & OoS & Inactive & Maintenance #####;;;;;;;
		Select
			Case UBound(decodeSingleCoord(FindImageInPlace("AnyoneThere", $g_sImgAnyoneThere, "440,310,580,360", False))) > 1 ; Inactive only
				SetLog("Village was Inactive, Reloading CoC", $COLOR_ERROR)
				If $g_bForceSinglePBLogoff Then $g_bGForcePBTUpdate = True
			Case _CheckPixel($aIsConnectLost, $g_bNoCapturePixel) Or UBound(decodeSingleCoord(FindImageInPlace("ConnectionLost", $g_sImgConnectionLost, "160,270,700,420", False))) > 1 ; Connection Lost
				;  Add check for banned account :(
				$Result = getOcrReloadMessage(171, 358, "Check Obstacles OCR 'policy at super'=") ; OCR text for "policy at super"
				If StringInStr($Result, "policy", $STR_NOCASESENSEBASIC) Then
					$msg = "Sorry but account has been banned, Bot must stop!"
					BanMsgBox()
					Return checkObstacles_StopBot($msg)
				EndIf
				$Result = getOcrReloadMessage(171, 337, "Check Obstacles OCR 'prohibited 3rd'= ") ; OCR text for "prohibited 3rd party"
				If StringInStr($Result, "3rd", $STR_NOCASESENSEBASIC) Then
					$msg = "Sorry but account has been banned, Bot must stop!"
					BanMsgBox()
					Return checkObstacles_StopBot($msg) ; stop bot
				EndIf
				SetLog("Connection lost, Reloading CoC", $COLOR_ERROR)
				If $g_bChkSharedPrefs And HaveSharedPrefs() Then
					SetLog("Please wait for loading CoC!")
					PushSharedPrefs()
					If Not $bRecursive Then OpenCoC()
					Return True
				EndIf
			Case _CheckPixel($aIsCheckOOS, $g_bNoCapturePixel) Or (UBound(decodeSingleCoord(FindImageInPlace("OOS", $g_sImgOutOfSync, "355,300,435,365", False, $g_iAndroidLollipop))) > 1) ; Check OoS
				SetLog("Out of Sync Error, Reloading CoC", $COLOR_ERROR)
			Case (UBound(decodeSingleCoord(FindImageInPlace("ImportantNotice", $G_sImgImportantNotice, "150,220,430,290", False))) > 1)
				SetLog("Found the 'Important Notice' window, closing it", $COLOR_INFO)
			Case Else
				;  Add check for game update and Rate CoC error messages
				If $g_bDebugImageSave Then SaveDebugImage("ChkObstaclesReloadMsg_", False) ; debug only
				;$Result = getOcrRateCoc(228, 390, "Check Obstacles getOCRRateCoC= ")
				Local $sRegion = "220,380(60,25)"
				If $g_iAndroidVersionAPI >= $g_iAndroidLollipop Then
					$sRegion = "550,370(70,35)"
				EndIf
				$Result = decodeSingleCoord(FindImageInPlace("RateNever", $g_sImgAppRateNever, $sRegion, False, True))
				If UBound($Result) > 1 Then
					SetLog("Clash feedback window found, permanently closed!", $COLOR_ERROR)
					PureClick($Result[0] + 5, $Result[1] + 5, 1, 0, "#9999") ; Click on never to close window and stop reappear. Never=248,408 & Later=429,408
					$g_bMinorObstacle = True
					Return True
				EndIf
				$Result = getOcrReloadMessage(171, 325, "Check Obstacles OCR 'Good News!'=") ; OCR text for "Good News!"
				If StringInStr($Result, "new", $STR_NOCASESENSEBASIC) Then
					$msg = "Game Update is required, Bot must stop!"
					Return checkObstacles_StopBot($msg) ; stop bot
				ElseIf StringInStr($Result, "rate", $STR_NOCASESENSEBASIC) Then ; back up check for rate CoC reload window
					SetLog("Clash feedback window found, permanently closed!", $COLOR_ERROR)
					PureClick(248, 408, 1, 0, "#9999") ; Click on never to close window and stop reappear. Never=248,408 & Later=429,408
					$g_bMinorObstacle = True
					Return True
				EndIf
				;  Add check for banned account :(
				$Result = getOcrReloadMessage(171, 358, "Check Obstacles OCR 'policy at super'=") ; OCR text for "policy at super"
				If StringInStr($Result, "policy", $STR_NOCASESENSEBASIC) Then
					$msg = "Sorry but account has been banned, Bot must stop!"
					BanMsgBox()
					Return checkObstacles_StopBot($msg) ; stop bot
				EndIf
				$Result = getOcrReloadMessage(171, 337, "Check Obstacles OCR 'prohibited 3rd'= ") ; OCR text for "prohibited 3rd party"
				If StringInStr($Result, "3rd", $STR_NOCASESENSEBASIC) Then
					$msg = "Sorry but account has been banned, Bot must stop!"
					BanMsgBox()
					Return checkObstacles_StopBot($msg) ; stop bot
				EndIf
				SetLog("Warning: Cannot find type of Reload error message", $COLOR_ERROR)
		EndSelect
		If TestCapture() Then Return "Village is out of sync or inactivity or connection lost or maintenance"
		Return checkObstacles_ReloadCoC($aReloadButton, "#0131", $bRecursive) ; Click for out of sync or inactivity or connection lost or maintenance
	EndIf

	If UBound(decodeSingleCoord(FindImageInPlace("Maintenance", $g_sImgMaintenance, "270,40,640, 140", False))) > 1 Then ; Maintenance Break
		$Result = getOcrMaintenanceTime(300, 550, "Check Obstacles OCR Maintenance Break=")         ; OCR text to find wait time
		Local $iMaintenanceWaitTime = 0
		Local $avTime = StringRegExp($Result, "([\d]+)[Mm]|(soon)|([\d]+[Hh])", $STR_REGEXPARRAYMATCH)
		If UBound($avTime, 1) = 1 And Not @error Then
			If UBound($avTime, 1) = 3 Then
				$iMaintenanceWaitTime = $DELAYCHECKOBSTACLES10
			Else
				$iMaintenanceWaitTime = Int($avTime[0]) * 60000
				If $iMaintenanceWaitTime > $DELAYCHECKOBSTACLES10 Then $iMaintenanceWaitTime = $DELAYCHECKOBSTACLES10
			EndIf
		Else
			$iMaintenanceWaitTime = $DELAYCHECKOBSTACLES4         ; Wait 2 min
			If @error Then SetLog("Error reading Maintenance Break time?", $COLOR_ERROR)
		EndIf
		SetLog("Maintenance Break, waiting: " & $iMaintenanceWaitTime / 60000 & " minutes", $COLOR_ERROR)
		If $g_bNotifyTGEnable And $g_bNotifyAlertMaintenance = True Then NotifyPushToTelegram("Maintenance Break, waiting: " & $iMaintenanceWaitTime / 60000 & " minutes....")
		If $g_bForceSinglePBLogoff Then $g_bGForcePBTUpdate = True
		If _SleepStatus($iMaintenanceWaitTime) Then Return
		If ClickB("ReloadButton") Then SetLog("Trying to reload game after maintenance break", $COLOR_INFO)
		checkObstacles_ResetSearch()
	EndIf

	;;;;;;;##### 7- SCID Login Screen #####;;;;;;;
	CheckLoginWithSupercellID()
	; optional game update
	If UBound(decodeSingleCoord(FindImageInPlace("OptUpdateCoC", $g_sImgOptUpdateCoC, "155, 190, 705, 480", False))) > 1 Then ; Found Optional Game Update Message
		SetLog("Found Optional Game Update - Clicking No Thanks", $COLOR_INFO)

		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		PureClick(520, 475, 1, 0) ; Click No Thanks
		$g_bMinorObstacle = True

		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		Return False
	EndIf

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	If TestCapture() = 0 And GetAndroidProcessPID() = 0 Then
		; CoC not running
		Return checkObstacles_ReloadCoC(Default, "", $bRecursive) ; just start CoC (but first close it!)
	EndIf

	If WaitforPixel(400, 526, 440, 530, Hex(0x75BE2F, 6), 6, 1) Then
		SetDebugLog("checkObstacles: Found WelcomeBack Chief Window to close", $COLOR_ACTION)
		Click(440, 526)
		If _Sleep($DELAYCHECKOBSTACLES2) Then Return
	EndIf
	
	If IsFullScreenWindow() Then
		Click(825,45)
		If _Sleep($DELAYCHECKOBSTACLES2) Then Return
	EndIf

	If _ColorCheck(_GetPixelColor(792, 39), Hex(0xDC0408, 6), 20) Then
		SetDebugLog("checkObstacles: Found Window with Close Button to close")
		PureClick(792, 39, 1, 0, "#0134") ;Clicks X
		$g_bMinorObstacle = True
		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		Return False
	EndIf
	If _CheckPixel($aCancelFight, $g_bNoCapturePixel) Or _CheckPixel($aCancelFight2, $g_bNoCapturePixel) Then
		SetDebugLog("checkObstacles: Found Cancel Fight to close")
		PureClickP($aCancelFight, 1, 0, "#0135") ;Clicks X
		$g_bMinorObstacle = True
		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		Return False
	EndIf
	If _CheckPixel($aChatTab, True) Then
		SetDebugLog("checkObstacles: Found Chat Tab to close")
		PureClickP($aChatTab, 1, 0, "#0136") ;Clicks chat tab
		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		Return False
	EndIf
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	If _CheckPixel($aEndFightSceneBtn, $g_bNoCapturePixel) Then
		SetDebugLog("checkObstacles: Found End Fight Scene to close")
		PureClickP($aEndFightSceneBtn, 1, 0, "#0137") ;If in that victory or defeat scene
		Return True
	EndIf
	If _CheckPixel($aSurrenderButton, $g_bNoCapturePixel) Then
		SetDebugLog("checkObstacles: Found End Battle to close")
		ReturnHome(False, False) ;If End battle is available
		Return True
	EndIf
	If _CheckPixel($aNoCloudsAttack, $g_bNoCapturePixel) Then ; Prevent drop of troops while searching
		$aMessage = _PixelSearch(23, 566, 36, 580, Hex(0xF4F7E3, 6), 10, False)
		If IsArray($aMessage) Then
			SetDebugLog("checkObstacles: Found Return Home button")
			; If _ColorCheck(_GetPixelColor(67,  602), Hex(0xDCCCA9, 6), 10) = False Then  ; add double check?
			PureClick(67, 602, 1, 0, "#0138") ;Check if Return Home button available
			If _Sleep($DELAYCHECKOBSTACLES2) Then Return
			Return True
		EndIf
	EndIf

	If IsPostDefenseSummaryPage() Then
		SetDebugLog("checkObstacles: Found Post Defense Summary to close")
		PureClick(67, 602, 1, 0, "#0138") ;Check if Return Home button available
		Return True
	EndIf
	
	If IsAttackPage() Then
		SetDebugLog("checkObstacles: Found AttackPage, return to home")
		Click(65, 540, 1, 0, "#0099")
		If _Sleep(500) Then Return
		Return True
	EndIf

	Local $CSFoundCoords = decodeSingleCoord(FindImageInPlace("CocStopped", $g_sImgCocStopped, "250,358,618,432", False))
	If UBound($CSFoundCoords) > 1 Then
		SetLog("CoC Has Stopped Error .....", $COLOR_ERROR)
		If TestCapture() Then Return "CoC Has Stopped Error ....."
		PushMsg("CoCError")
		If _Sleep($DELAYCHECKOBSTACLES1) Then Return
		;PureClick(250 + $x, 328 + $y, 1, 0, "#0129");Check for "CoC has stopped error, looking for OK message" on screen
		PureClick($CSFoundCoords[0], $CSFoundCoords[1], 1, 0, "#0129") ;Check for "CoC has stopped error, looking for OK message" on screen
		If _Sleep($DELAYCHECKOBSTACLES2) Then Return
		Return checkObstacles_ReloadCoC(Default, "", $bRecursive)
	EndIf

	;If $g_bOnlySCIDAccounts Then
	;	SetDebugLog("check Log in with Supercell ID login by Clicks")
	;	; check Log in with Supercell ID login screen by Clicks
	;	CheckLoginWithSupercellIDScreen()
	;EndIf

	; check if google account list shown and select first
	;If Not CheckGoogleSelectAccount() Then
	;	SetDebugLog("check Log in with Supercell ID login by shared_prefs")
	;	; check Log in with Supercell ID login screen by shared_prefs
	;	If CheckLoginWithSupercellID() Then Return True
	;EndIf

	Return False
EndFunc   ;==>_checkObstacles

Func SwitchForceAnotherDevice($NextAccount)
	Local $bResult = True
	$g_bReMatchAcc = False
	Local $abAccountNo = AccountNoActive()
	If Not $abAccountNo[$NextAccount] Then $NextAccount = 0
	$g_iNextAccount = $NextAccount
	If Not $g_bRunState Then Return

	SetLog("Switching to Account [" & $g_iNextAccount + 1 & "]")
	Local $bSharedPrefs = $g_bChkSharedPrefs And HaveSharedPrefs($g_asProfileName[$g_iNextAccount])
	SwitchAccountVariablesReload("Save")
	If $g_ahTimerSinceSwitched[$g_iCurAccount] <> 0 Then
		If Not $g_bReMatchAcc Then SetSwitchAccLog(" - Acc " & $g_iCurAccount + 1 & ", online: " & Int(__TimerDiff($g_ahTimerSinceSwitched[$g_iCurAccount]) / 1000 / 60) & "m")
		SetTime(True)
		$g_aiRunTime[$g_iCurAccount] += __TimerDiff($g_ahTimerSinceSwitched[$g_iNextAccount])
		$g_ahTimerSinceSwitched[$g_iCurAccount] = 0
	EndIf

	SwitchAccountVariablesReload()

	$g_ahTimerSinceSwitched[$g_iCurAccount] = __TimerInit()
	If $g_sProfileCurrentName <> $g_asProfileName[$g_iNextAccount] Then
		If $g_iGuiMode = 1 Then
			; normal GUI Mode
			_GUICtrlComboBox_SetCurSel($g_hCmbProfile, _GUICtrlComboBox_FindStringExact($g_hCmbProfile, $g_asProfileName[$g_iNextAccount]))
			cmbProfile()
			DisableGUI_AfterLoadNewProfile()
		Else
			; mini or headless GUI Mode
			saveConfig()
			$g_sProfileCurrentName = $g_asProfileName[$g_iNextAccount]
			LoadProfile(False)
		EndIf
	EndIf
	If $bSharedPrefs Then
		SetLog("Please wait for loading CoC")
		PushSharedPrefs()
		OpenCoC()
		waitMainScreen()
	EndIf

	SetSwitchAccLog("Switched to Acc [" & $NextAccount + 1 & "]", $COLOR_SUCCESS)
	CreateLogFile() ; Cause use of the right log file after switch
	If Not $g_bRunState Then Return
EndFunc

; It's more stable to restart CoC app than click the message restarting the game
Func checkObstacles_ReloadCoC($point = Default, $debugtxt = "", $bRecursive = False)
	If TestCapture() Then Return "Reload CoC"
	ForceCaptureRegion(True)
	OcrForceCaptureRegion(True)
	If $point = Default Then
		If Not $bRecursive Then CloseCoC(True)
	Else
		If UBound($point) > 1 Then
			PureClickP($point, 1, 0, $debugtxt)
		EndIf
		If Not $bRecursive Then OpenCoC()
	EndIf
	If _Sleep($DELAYCHECKOBSTACLES3) Then Return
	Return True
EndFunc   ;==>checkObstacles_ReloadCoC

; It's more stable to restart CoC app than click the message restarting the game
Func checkObstacles_RebootAndroid()
	If TestCapture() Then Return "Reboot Android"
	ForceCaptureRegion(True)
	OcrForceCaptureRegion(True)
	$g_bGfxError = True
	CheckAndroidReboot()
	Return True
EndFunc   ;==>checkObstacles_RebootAndroid

Func checkObstacles_StopBot($msg)
	SetLog($msg, $COLOR_ERROR)
	If TestCapture() Then Return $msg
	If $g_bNotifyTGEnable And $g_bNotifyAlertMaintenance Then NotifyPushToTelegram($msg)
	OcrForceCaptureRegion(True)
	Btnstop() ; stop bot
	Return True
EndFunc   ;==>checkObstacles_StopBot

Func checkObstacles_ResetSearch()
	; reset fast restart flags to ensure base is rearmed after error event that has base offline for long duration, like PB or Maintenance
	$g_bIsClientSyncError = False
	$g_bIsSearchLimit = False
	$g_abNotNeedAllTime[0] = True
	$g_abNotNeedAllTime[1] = True
	$g_bRestart = True ; signal all calling functions to return to runbot
EndFunc   ;==>checkObstacles_ResetSearch

Func BanMsgBox()
	Local $MsgBox
	Local $stext = "Sorry, your account is banned!!" & @CRLF & "Bot will stop now..."
	If TestCapture() Then Return $stext
	While 1
		PushMsg("BAN")
		_ExtMsgBoxSet(4, 1, 0x004080, 0xFFFF00, 20, "Comic Sans MS", 600)
		$MsgBox = _ExtMsgBox(48, "Ok", "Banned", $stext, 1)
		If $MsgBox = 1 Then Return
		_ExtMsgBoxSet(4, 1, 0xFFFF00, 0x004080, 20, "Comic Sans MS", 600)
		$MsgBox = _ExtMsgBox(48, "Ok", "Banned", $stext, 1)
		If $MsgBox = 1 Then Return
	WEnd
EndFunc   ;==>BanMsgBox

Func checkObstacles_Network($bForceCapture = False, $bReloadCoC = True)
	Static $hCocReconnectingTimer = 0 ; TimerHandle of first CoC reconnecting animation

	If UBound(decodeSingleCoord(FindImageInPlace("CocReconnecting", $g_sImgCocReconnecting, "420,325,440,345", $bForceCapture))) > 1 Then
		If $hCocReconnectingTimer = 0 Then
			SetLog("Network Connection lost...", $COLOR_ERROR)
			$hCocReconnectingTimer = __TimerInit()
		ElseIf __TimerDiff($hCocReconnectingTimer) > $g_iCoCReconnectingTimeout Then
			SetLog("Network Connection really lost, Reloading CoC...", $COLOR_ERROR)
			$hCocReconnectingTimer = 0
			If $bReloadCoC Then CloseCoC(True)
			Return True
		Else
			SetLog("Network Connection lost, waiting...", $COLOR_ERROR)
		EndIf
	Else
		$hCocReconnectingTimer = 0
	EndIf

	Return False
EndFunc   ;==>checkObstacles_Network

;Func checkObstacles_GfxError($bForceCapture = False, $bRebootAndroid = True)
;	Local $aResult = decodeMultipleCoords(FindImage("GfxError", $g_sImgGfxError, "ECD", 100, $bForceCapture), 100, 100)
;	If UBound($aResult) >= 8 Then
;		SetLog(UBound($aResult) & " Gfx Errors detected, Reloading Android...", $COLOR_ERROR)
;		; Save debug image
;		SaveDebugImage("GfxError", False)
;		If $bRebootAndroid Then Return checkObstacles_RebootAndroid()
;		Return True
;	EndIf
;
;	Return False
;EndFunc   ;==>checkObstacles_GfxError


