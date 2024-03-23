@echo off
setlocal enableextensions enabledelayedexpansion
set AIK=AIK_3.8
set BIN=%AIK%\android_win_tools
set LETTERS=ABCDEFGHIJKLMNOPQRSTUVWXYZ
set DIR=%~dp0
cd /d %~dp0
mkdir Output > nul 2>&1
title Duck Tools 1.0
>nul 2>&1 net session || (
	echo Error.
	echo.
	echo This script uses some tools that require admin rights.
	echo Run again as admin.
	echo.
	pause
	exit
)
if not exist Files (
	echo Error.
	echo.
	echo Files directory is missing.
	echo Can not proceed without it.
	echo Please, download Duck Patcher again.
	echo.
	pause
	exit
)
adb version > nul 2>&1 || (
	echo Error.
	echo.
	echo adb.exe is missing.
	echo.
	echo D. Go to 15 Seconds Adb installer download page
	echo S. Select adb.exe directory
	echo E. Exit
	echo.
	echo|set /p="Choose: " & choice /c dse /n
	if !errorlevel!==1 (
		start https://androidmtk.com/download-15-seconds-adb-installer
		echo.
		pause
		exit
	) else if !errorlevel!==2 (
		:PICK_ADB
		for /f "delims=" %%A in ('powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Filter = '|adb.exe'; $openFileDialog.Title = 'Select adb.exe'; $openFileDialog.InitialDirectory = '!DIR!'; $openFileDialog.ShowDialog() | Out-Null; $openFileDialog.FileName}"') do set "ADB_DIR=%%~dpA"
		echo.
		if not exist "!ADB_DIR!" (
			echo|set /p="Do you want to try again? [y/n]: " & choice /c yn /n
			if !errorlevel!==1 (
				goto PICK_ADB
			) else (
				exit
			)
		)
		set "PATH=!PATH!;!ADB_DIR!"
		echo|set /p="Do you want to add such path into PATH environment variable? [y/n]: " & choice /c yn /n
		if !errorlevel!==1 (
			for /f "tokens=2,*" %%A in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v Path ^| find /i "Path"') do (
				set "reg_path=%%B;!ADB_DIR!"
			)
			echo.
			echo Adding adb path into PATH...
			reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /f /v Path /t REG_SZ /d "!reg_path!\">nul 2>&1&& (
				echo      Done.
				echo      Since you keep adb binary in this same path, you will not be prompet about it.
				echo      This change will take effect in the next logon.
			) || (
				echo      Failed.
			)
			echo.
			pause
		)
	) else if !errorlevel!==3 (
		exit
	)
)


call :MAIN
exit

::FUNCTIONS ############################################################################################################
:MAIN
	call :CLEAN_TMP
	cls
	echo Home page
	echo.
	echo.
	echo P. Patch recovery ^(Orange Fox recommended^)
	echo D. Deploy Windows image ^(.img or .esd^)
	echo S. Send DuckPart files to current recovery
	echo R. Run DuckPart
	echo G. Get Windows image
	echo.
	echo E. Exit
	echo.
	echo|set /p="Choose: " & choice /c pdsrge /n
	if !errorlevel!==1 (
		call :PATCH_RECOVERY
	) else if !errorlevel!==2 (
		call :DEPLOY_IMAGE
	) else if !errorlevel!==4 (
		cls
		echo ^> R. Run DuckPart
		echo.
		echo.
		echo 1. Open a new CMD window
		echo 2. Run: adb shell
		echo 3. In adb shell run: duckpart
		echo.
		echo It must be launched this way due some adb limitations.
		echo Use it wisely.
	) else if !errorlevel!==3 (
		call :CONNECT_RECOVERY
		cls
		echo ^> S. Send DuckPart files to current recovery
		echo.
		echo Pushing files to device...
		echo ______________________________________
		adb shell mkdir /sbin/duckpartdir && (
			set push_error=
			adb push Files\dmsetup /sbin/ || set push_error=dmsetup
			adb shell chmod 755 /sbin/dmsetup
			adb push Files\duckpart /sbin/ || set push_error=!push_error!, duckpart
			adb shell chmod 755 /sbin/duckpart
			adb push Files\parted /sbin/ || set push_error=!push_error!, parted
			adb shell chmod 755 /sbin/parted
			adb push Files\sgdisk /sbin/ || set push_error=!push_error!, sgdisk
			adb shell chmod 755 /sbin/sgdisk
			adb push Files\toybox /sbin/duckpartdir/ || set push_error=!push_error!, toybox
			adb push Files\busybox /sbin/duckpartdir/ || set push_error=!push_error!, busybox
			adb shell chmod -R 755 /sbin/duckpartdir
			echo ______________________________________
			if not "!push_error!"=="" (
				echo      Error.
				echo      Could not push the following files: !push_error!
				echo      Duckpart may not work this way.
			)
		) || (
			echo      Error.
			echo      Could not create duckpart directory in /sbin
		)
	) else if !errorlevel!==5 (
		set site_error=
		start https://worproject.com/esd || set site_error=1
		cls
		echo ^> G. Get Windows image
		echo.
		echo.
		echo How to download:
		echo.
		if !site_error!==1 echo Access^: https^:^/^/worproject.com^/esd
		echo Version^: Select Windows 11
		echo Build^: Select the first one
		echo Architecture^: Select ARM64
		echo Edition^: Select CLIENT
		echo Language^: Select a desired language
	) else if !errorlevel!==6 (
		exit
	)
	echo.
	pause
	call :MAIN
goto :EOF

:DEPLOY_IMAGE
	set INDEXES=0
	set "INDEXLIST="
	cls
	echo ^> D. Deploy Windows image ^(.img or .esd^)
	echo.
	echo.
	echo|set /p="Do you want to put device in Mass Storage mode? [y/n]: " & choice /c yn /n
	if !errorlevel! == 1 (
		call :CONNECT_RECOVERY
		cls
		echo ^> D. Deploy Windows image ^(.img or .esd^)
		echo.
		echo.
		adb shell ls /sbin/duckpart > nul 2>&1 || (
			echo Could not locate duckpart on your device.
			echo.
			echo|set /p="Do you want to patch your recovery? [y/n]: " & choice /c yn /n
			if !errorlevel! == 1 (
				call :PATCH_RECOVERY
			)
			pause
			call :MAIN
		)
		echo Be sure your recovery screen is unlocked.
		echo.
		pause
		echo.
		adb shell duckpart msc > nul 2>&1 && (
			echo Done.
			echo If there is no device drive on This PC^:
			echo 1. Blame your recovery. Some recoveries does not support mass storage class.
			echo 2. Blame Windows usb^/mtp drivers. I wrote this just after reinstalling Windows due mtp driver mess caused by a driver update.
		) || (
			echo Error.
			echo Try to enable it on DuckPart ^> U option.
		)
		echo.
		pause
	)

	cls
	echo ^> D. Deploy Windows image (.img or .esd)
	echo.
	echo Step 1 - Select device Windows drive: RUNNING
	echo Step 2 - Select device ESP drive:     WAITING
	echo Step 3 - Select an image:             WAITING
	echo.
	echo.
	
	:: Get PC Windows drive letter
	for /F "skip=1 tokens=2 delims==:" %%a in ('wmic os get "SystemDrive" /value') do set "HOSTDRIVE=%%a"

	:: Check if HOSTDRIVE exists
	if not exist !HOSTDRIVE!: (
		echo.
		echo Couldn't find PC Windows drive.
		echo.
		pause
		call :MAIN
	)
	
	:: Open Computer screen to help use get drive letters
	explorer ::{20D04FE0-3AEA-1069-A2D8-08002B30309D}

	:: Ask user if he can see Windows device drive letter
	echo|set /p="Is device Windows partition visible on This PC? [y/n]: " & choice /c yn /n
	if !errorlevel!==2 (
		:ENTER_WIN_LETTER_TO_ASSIGN
		echo.
		echo|set /p="Enter an available drive letter to assign to device Windows volume: " & choice /c !LETTERS! /n
		call :NUMBER2LETTER WINDRIVE !errorlevel!
		echo.
		if exist !WINDRIVE!: (
			echo !WINDRIVE!: is already in use.
			echo Please, be careful next time.
			call :ENTER_WIN_LETTER_TO_ASSIGN
		)
		set VOL=0
		set "NUMVOLS="
		echo Now you must be pretty sure about what you are doing.
		echo Do not select an incorrect volume number.
		echo.
		for /f "tokens=*" %%a in ('echo list volume ^| diskpart ^| findstr "Volume "') do (
			echo %%a
			set /a VOL+=1
		)
		set /a VOL-=2
		for /L %%a in (0,1,!VOL!) do (
			set "NUMVOLS=!NUMVOLS!%%a"
		)
		:ASSIGN_WINDOWS_LETTER
		echo.
		echo|set /p="Select the device Windows volume number: " & choice /c !NUMVOLS! /n
		set SELVOL=!errorlevel!
		set /a SELVOL-=1
		echo.
		echo|set /p="Are you sure device Windows volume is !SELVOL!? [y/n]: " & choice /c yn /n
		if !errorlevel!==2 (
			call :ASSIGN_WINDOWS_LETTER
		)
		echo.
		(
			echo select volume !SELVOL!
			echo assign letter !WINDRIVE!
		) > diskpart_script.tmp
		echo Assigning Volume !SELVOL! as !WINDRIVE!:...
		diskpart /s diskpart_script.tmp >nul 2>&1 && (
			echo      Done.
		) || (
			del diskpart_script.tmp
			echo      Error.
			echo.
			pause
			call :MAIN
		)
		del diskpart_script.tmp
	) else if !errorlevel!==1 (
		set DRIVES_LIST=
		set DRIVES_LIST_CHOICE=
		for /l %%i in (0,1,26) do (
			set /a "SEQUENCE=%%i + 1"
			set "LETTER=!LETTERS:~%%i,1!"
			if exist !LETTER!: (
				set DRIVES_LIST=!DRIVES_LIST! !LETTER!
				set DRIVES_LIST_CHOICE=!DRIVES_LIST_CHOICE!!LETTER!
			)
		)
		echo.
		echo|set /p="Enter device Windows drive letter: " & choice /c !DRIVES_LIST_CHOICE! /n
		set WIN_DRIVE_NUMBER=!errorlevel!
		set ROUND=1
		for %%i in (!DRIVES_LIST!) do (
			if !ROUND!==!WIN_DRIVE_NUMBER! (
				set WINDRIVE=%%i
			)
			set /a ROUND+=1
		)
	)

	:: Check if user chose PC Windows to install wim file
	if /I !WINDRIVE!==!HOSTDRIVE! (
		echo.
		echo !HOSTDRIVE!: is already being used by PC Windows.
		echo Pay more attention next time.
		echo.
		pause
		call :MAIN
	)

	:: Check Win drive letter chose by user is empty
	dir !WINDRIVE!:\* >nul 2>&1 && (
		echo.
		echo Device Windows drive !WINDRIVE!: is not empty.
		echo Can not proceed this way.
		echo Format it as NTFS using DuckPart and try again.
		echo.
		pause
		call :MAIN
	)

	cls
	echo ^> D. Deploy Windows image (.img or .esd)
	echo.
	echo Step 1 - Select device Windows drive: !WINDRIVE!
	echo Step 2 - Select device ESP drive:     RUNNING
	echo Step 3 - Select an image:             WAITING
	echo.
	echo.
	:: Ask user if he can see device ESP drive letter
	echo|set /p="Is device ESP partition visible on My PC? [y/n]: " & choice /c yn /n
	if !errorlevel!==2 (
		:ENTER_ESP_LETTER_TO_ASSIGN
		echo.
		echo|set /p="Enter an available drive letter to assign to device ESP volume: " & choice /c !LETTERS! /n
		call :NUMBER2LETTER ESPDRIVE !errorlevel!
		echo.
		if exist !ESPDRIVE!: (
			echo !ESPDRIVE!: is already in use.
			echo Please, be careful next time.
			call :ENTER_ESP_LETTER_TO_ASSIGN
		)
		set VOL=0
		set "NUMVOLS="
		echo Now you must be pretty sure about what you are doing.
		echo Do not select an incorrect volume number.
		echo.
		for /f "tokens=*" %%a in ('echo list volume ^| diskpart ^| findstr "Volume "') do (
			echo %%a
			set /a VOL+=1
		)
		set /a VOL-=2
		for /L %%a in (0,1,!VOL!) do (
			set "NUMVOLS=!NUMVOLS!%%a"
		)
		:ASSIGN_ESP_LETTER
		echo.
		echo|set /p="Select the device ESP volume number: " & choice /c !NUMVOLS! /n
		set SELVOL=!errorlevel!
		set /a SELVOL-=1
		echo.
		echo|set /p="Are you sure device ESP volume is !SELVOL!? [y/n]: " & choice /c yn /n
		if !errorlevel!==2 (
			call :ASSIGN_ESP_LETTER
		)
		echo.
		(
			echo select volume !SELVOL!
			echo assign letter !ESPDRIVE!
		) > diskpart_script.tmp
		echo Assigning Volume !SELVOL! as !ESPDRIVE!:...
		diskpart /s diskpart_script.tmp >nul 2>&1 && (
			echo      Done.
		) || (
			del diskpart_script.tmp
			echo      Error.
			echo.
			pause
			call :MAIN
		)
		del diskpart_script.tmp
	) else if !errorlevel!==1 (
		set DRIVES_LIST=
		set DRIVES_LIST_CHOICE=
		for /l %%i in (0,1,26) do (
			set /a "SEQUENCE=%%i + 1"
			set "LETTER=!LETTERS:~%%i,1!"
			if exist !LETTER!: (
				set DRIVES_LIST=!DRIVES_LIST! !LETTER!
				set DRIVES_LIST_CHOICE=!DRIVES_LIST_CHOICE!!LETTER!
			)
		)
		echo.
		echo|set /p="Enter device ESP drive letter: " & choice /c !DRIVES_LIST_CHOICE! /n
		set ESP_DRIVE_NUMBER=!errorlevel!
		set ROUND=1
		for %%i in (!DRIVES_LIST!) do (
			if !ROUND!==!ESP_DRIVE_NUMBER! (
				set ESPDRIVE=%%i
			)
			set /a ROUND+=1
		)
	)

	:: Check if user chose PC Windows to install wim file
	if /I !ESPDRIVE!==!HOSTDRIVE! (
		echo.
		echo !HOSTDRIVE!: is already being used by PC Windows.
		echo Pay more attention next time.
		echo.
		pause
		call :MAIN
	)

	:: Check ESP drive is empty
	dir !ESPDRIVE!:\* >nul 2>&1 && (
		echo.
		echo Device ESP drive !ESPDRIVE!: is not empty.
		echo Can not proceed this way.
		echo Format it as FAT32 using DuckPart and try again.
		echo.
		pause
		call :MAIN
	)

	:: Check if ESP drive chose is the same device Windows letter
	if /I !ESPDRIVE!==!WINDRIVE! (
		echo.
		echo Windows and ESP can't be in same partition.
		echo Pay more attention next time.
		echo.
		pause
		call :MAIN
	)

	:WIM_FILE_SELECTION
	cls
	echo ^> D. Deploy Windows image ^(.img or .esd^)
	echo.
	echo Step 1 - Select device Windows drive: !WINDRIVE!
	echo Step 2 - Select device ESP drive:     !ESPDRIVE!
	echo Step 3 - Select an image:             WAITING
	echo.
	echo.
	echo Now press any key to pick the Windows image file to be deployed.
	echo.
	pause

	for /f "delims=" %%I in ('powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Filter = 'Windows Imaging Format (.wim; .esd)|*.wim;*.esd'; $openFileDialog.Title = 'Select a image file'; $openFileDialog.InitialDirectory = '!DIR!'; $openFileDialog.ShowDialog() | Out-Null; $openFileDialog.FileName}"') do set "WIMFILE=%%I"
	if not exist "!WIMFILE!" (
		echo.
		echo It seems you didn't select any file.
		echo.
		echo|set /p="Do you want to try again? [y/n]: " & choice /c yn /n
		if "!errorlevel!"=="2" (
			echo.
			echo Okay then.
			echo See you later.
			echo.
			pause
			call :MAIN
		)
		goto WIM_FILE_SELECTION
	)

	cls
	echo ^> D. Deploy Windows image ^(.img or .esd^)
	echo.
	echo Step 1 - Select device Windows drive: !WINDRIVE!
	echo Step 2 - Select device ESP drive:     !ESPDRIVE!
	echo Step 3 - Select an image:             WAITING
	echo.
	echo.
	echo Listing Windows versions index...
	echo.
	dism /Get-WimInfo /WimFile:"!WIMFILE!"
	echo.
	echo.
	for /F "tokens=2 delims=:" %%A in ('dism /Get-WimInfo /WimFile:"!WIMFILE!"') do (
		set /a INDEXES+=1
	)
	set /a INDEXES=(INDEXES-2)/4

	if !INDEXES! GTR 1 (
		for /L %%i in (1,1,!INDEXES!) do set "INDEXLIST=!INDEXLIST!%%i"
		echo|set /p="Choose a version to install [1 to !INDEXES!]: " & choice /c !INDEXLIST! /n
		set INDEX=!errorlevel!
	) else (
		set INDEX=1
	)

	cls
	echo ^> D. Deploy Windows image ^(.img or .esd^)
	echo.
	echo.
	echo Device Windows drive:      !WINDRIVE!:
	echo Device ESP drive:          !ESPDRIVE!:
	echo Windows installation file: !WIMFILE!
	echo Windows version index:     !INDEX!
	echo.
	echo|set /p="Proceed with deployment? [y/n]: " & choice /c yn /n
	if !errorlevel!==2 (
		call :MAIN
	)

	echo.
	echo.
	echo Deploying Windows image into !WINDRIVE!: drive...
	echo I'll notify you when it get done.
	echo.
	dism /apply-image /ImageFile:!WIMFILE! /index:!INDEX! /ApplyDir:!WINDRIVE!:\ && (
		echo      Done.
		msg * Windows deployment done.
	) || (
		echo      Failed.
		echo      Check the log.
		msg * Windows deployment failed.
		echo.
		pause
		call :MAIN
	)

	echo.
	echo.
	echo Creating boot entry on device ESP partition...
	bcdboot !WINDRIVE!:\Windows /s !ESPDRIVE!: /f UEFI > nul 2>&1 && (
		echo      Done.
	) || (
		echo      Failed.
		echo      Check the screen.
		echo.
		pause
		call :MAIN
	)

	reg query "HKLM\WOASYSTEM" >nul 2>&1
	if not !errorlevel!==0 reg load HKLM\WOASYSTEM !WINDRIVE!:\Windows\System32\config\System > nul 2>&1
	reg query "HKLM\WOASOFTWARE" >nul 2>&1
	if not !errorlevel!==0 reg load HKLM\WOASOFTWARE !WINDRIVE!:\Windows\System32\config\SOFTWARE > nul 2>&1

	:REGISTRY_OPTIONS
	bcdedit /store %ESPDRIVE%:\EFI\Microsoft\BOOT\BCD /enum {default} > bcdedit.tmp
	cls
	echo ^> D. Deploy Windows image ^(.img or .esd^)
	echo  ^'-^> Post-installation set up
	echo.
	echo.

REM	USB fix
	reg query "HKLM\WOASYSTEM\ControlSet001\Control\USB" /v OsDefaultRoleSwitchMode >nul 2>&1
	if !errorlevel!==0 (
		for /f "tokens=3" %%a in ('reg query "HKLM\WOASYSTEM\ControlSet001\Control\USB" /v "OsDefaultRoleSwitchMode" 2^>nul ^| findstr /i /c:"OsDefaultRoleSwitchMode"') do (
			if "%%a"=="0x1" (
				echo U. USB host mode enforcement is^: ON ^(OsDefaultRoleSwitchMode^)
				set usb_fix=1
			) else (
				echo U. USB host mode enforcement is^: OFF ^(OsDefaultRoleSwitchMode^)
				set usb_fix=0
			)
		)
	) else (
		echo echo U. USB host mode enforcement is^: OFF ^(OsDefaultRoleSwitchMode^)
		set usb_fix=0
	)
	echo    If your device has driverless USB support, set this ON.
	echo.

REM	OOBE bypass
	reg query "HKLM\WOASOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" >nul 2>&1
	if !errorlevel!==0 (
		for /f "tokens=3" %%a in ('reg query "HKLM\WOASOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" 2^>nul ^| findstr /i /c:"BypassNRO"') do (
			if "%%a"=="0x1" (
				echo O. Bypass Windows Out of Box Experience is^: ON ^(OOBE bypass^)
				set oobe_fix=1
			) else (
				echo O. Bypass Windows Out of Box Experience is^: OFF ^(OOBE bypass^)
				set oobe_fix=0
			)
		)
	) else (
		echo O. Bypass Windows Out of Box Experience is^: OFF ^(OOBE bypass^)
		set oobe_fix=0
	)
	echo    If your device doesn^'t have any internet connection ^(wi-fi or internet connection through USB^), set this ON.
	echo.

REM	Driver signature check
	findstr /c:"testsigning" bcdedit.tmp | findstr /c:"Yes" > nul && (
		echo D. Allow unsigned drivers^: Yes ^(testsigning^)
		set test_signing=1
	) || (
		echo D. Allow unsigned drivers^: No ^(testsigning^)
		set test_signing=0
	)
	echo    If your device uses any unsigned driver, set it Yes.
	echo.

REM	System files integrity test
	findstr /c:"nointegritychecks" bcdedit.tmp | findstr /c:"Yes" > nul && (
		echo S. System files integrity check^: No ^(nointegritychecks^)
		set no_integrity_checks=1
	) || (
		echo S. System files integrity check^: Yes ^(nointegritychecks^)
		set no_integrity_checks=0
	)
	echo    If your device uses any unsigned driver, set it No.
	echo.

REM	Recovery capabilities
	findstr /c:"recoveryenabled" bcdedit.tmp | findstr /c:"No" > nul && (
		echo R. Recovery status is^: OFF ^(recoveryenabled^)
		set recovery_enabled=0
	) || (
		echo R. Recovery status is^: ON ^(recoveryenabled^)
		set recovery_enabled=1
	)
	echo    Sometimes Windows breaks UFS GPT layout on trying to fix a boot failure. I recommend set it OFF.
	echo.
	
	echo I. Import a .reg file.
	echo.

	echo P. Proceed
	echo    Just proceed ^:^)
	echo.
	echo|set /p="Choose: " & choice /c uodsrip /n
	if !errorlevel!==1 (
		if !usb_fix!==1 (
			reg add "HKLM\WOASYSTEM\ControlSet001\Control\USB" /v OsDefaultRoleSwitchMode /t REG_DWORD /d 6 /f >nul 2>&1 && set usb_fix=0
		) else (
			reg add "HKLM\WOASYSTEM\ControlSet001\Control\USB" /v OsDefaultRoleSwitchMode /t REG_DWORD /d 1 /f >nul 2>&1 && set usb_fix=1
		)
		goto REGISTRY_OPTIONS
	) else if !errorlevel!==2 (
		if !oobe_fix!==1 (
			reg add "HKLM\WOASOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 0 /f >nul 2>&1 && set oobe_fix=0
		) else (
			reg add "HKLM\WOASOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f >nul 2>&1 && set oobe_fix=1
		)
		goto REGISTRY_OPTIONS
	) else if !errorlevel!==3 (
		echo.
		echo Please wait...
		if !test_signing!==1 (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} testsigning off >nul 2>&1 && set test_signing=0
		) else (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} testsigning on >nul 2>&1 && set test_signing=1
		)
		goto REGISTRY_OPTIONS
	) else if !errorlevel!==4 (
		echo.
		echo Please wait...
		if !no_integrity_checks!==1 (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} nointegritychecks off >nul 2>&1 && set no_integrity_checks=0
		) else (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} nointegritychecks on >nul 2>&1 && set no_integrity_checks=1
		)
		goto REGISTRY_OPTIONS
	) else if !errorlevel!==5 (
		echo.
		echo Please wait...
		if !recovery_enabled!==1 (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} recoveryenabled no >nul 2>&1 && set recovery_enabled=0
		) else (
			bcdedit /store !ESPDRIVE!:\EFI\Microsoft\BOOT\BCD /set {default} recoveryenabled yes >nul 2>&1 && set recovery_enabled=1
		)
		goto REGISTRY_OPTIONS
	) else if !errorlevel!==6 (
		:PICK_REG_FILE
		for /f "delims=" %%I in ('powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Filter = 'Registry file (.reg)|*.reg'; $openFileDialog.Title = 'Select a registry file'; $openFileDialog.InitialDirectory = '!DIR!'; $openFileDialog.ShowDialog() | Out-Null; $openFileDialog.FileName}"') do set "REG_FILE=%%I"
		if not exist "!REG_FILE!" (
			echo.
			echo It seems you didn't select any file.
			echo|set /p="Do you want to try again? [y/n]: " & choice /c yn /n
			if !errorlevel!==1 (
				goto PICK_REG_FILE
			)
		)
		for %%a in ("!REG_FILE!") do (
			set "REG_FILE_NAME=%%~nxa"
			set "REG_FILE_NAME_FIXED=Fixed-%%~nxa"
		)
		
		cls
		echo ^> D. Deploy Windows image ^(.img or .esd^)
		echo  ^'-^> Post-installation set up
		echo    ^'-^> I. Import a .reg file.
		echo.
		echo.
		echo !REG_FILE_NAME! content:
		echo ______________________________________
		echo.
		type "!REG_FILE!"
		echo.
		echo ______________________________________
		echo.
		echo.
		echo|set /p="Import this file into device Windows? [y/n]: " & choice /c yn /n
		if !errorlevel!==2 (
			goto REGISTRY_OPTIONS
		)
		(
			for /f "tokens=*" %%a in ('type "!REG_FILE!"') do (
				set "line=%%a"
				set "line=!line:HKEY_LOCAL_MACHINE\System=HKEY_LOCAL_MACHINE\WOASYSTEM!"
				set "line=!line:HKEY_LOCAL_MACHINE\Software=HKEY_LOCAL_MACHINE\WOASOFTWARE!"
				echo(!line!
			)
		) > "!REG_FILE_NAME_FIXED!"
		set reg_error=0
		for /f "usebackq delims=" %%a in ("!REG_FILE_NAME_FIXED!") do (
			echo %%a | findstr /C:"HKEY_LOCAL_MACHINE\System" >nul && set reg_error=1
			echo %%a | findstr /C:"HKEY_LOCAL_MACHINE\Software" >nul && set reg_error=1
		)
		echo.
		if !reg_error!==1 (
			echo Could not load !REG_FILE_NAME!.
		) else (
			echo Importing !REG_FILE_NAME!...
			regedit /s !REG_FILE_NAME_FIXED! > nul 2>&1 && (
				echo      Done.
			) || (
				echo      Failed.
			)
		)
		echo.
		pause
		if exist !REG_FILE_NAME_FIXED! del !REG_FILE_NAME_FIXED!
		goto REGISTRY_OPTIONS
	)
	reg unload HKLM\WOASYSTEM > nul 2>&1 || (
		echo.
		echo Could not unload device Windows System hive.
		echo Do it manually.
		echo 1. Open Registry Editor
		echo 2. Select HKEY_LOCAL_MACHINE ^> WOASYSTEM
		echo 3. Click on File
		echo 4. Click on Unload Hive...
	)
	reg unload HKLM\WOASOFTWARE > nul 2>&1 || (
		echo.
		echo Could not unload device Windows Software hive.
		echo Do it manually.
		echo 1. Open Registry Editor
		echo 2. Select HKEY_LOCAL_MACHINE ^> WOASOFTWARE
		echo 3. Click on File ^(or whatever is ^"file^" in your language^)
		echo 4. Click on Unload Hive...
	)
	if exist bcdedit.tmp del bcdedit.tmp > nul 2>&1

	echo.
	echo.
	echo Removing ESP drive as it^'s usually kept as dummy drive...
	mountvol !ESPDRIVE!: /d && (
		echo      Done.
	) || (
		echo      Failed.
		echo      Check the screen.
	)
	echo.
	echo.
	echo That^'s all.
	echo.
	pause
	call :MAIN
goto :EOF

:PATCH_RECOVERY
	call :CLEAN_TMP
	cls
	echo ^> P. Patch recovery
	echo.
	echo.
	echo P. Pull recovery from device
	echo U. Use a recovery file ^(.img^)
	echo.
	echo R. Return
	echo.
	echo|set /p="Choose: " & choice /c pur /n
	if !errorlevel!==1 (
		set "PATCH_RECOERY_ORIGIN=P. Pull recovery from device"
		cls
		echo ^> P. Patch recovery 
		echo  ^'-^> !PATCH_RECOERY_ORIGIN!
		echo.
		echo.
		echo Select the partition where your recovery is placed.
		echo Do not worry about the slot now.
		echo.
		echo 1. boot_^(a/b^)
		echo 3. recovery_^(a/b^)
		echo 5. vendor_boot_^(a/b^)
		echo 7. recovery
		echo 9. boot
		echo.
		echo R. Return
		echo.
		echo|set /p="Enter the number: " & choice /c 13579R /n
		if !errorlevel!==1 (
			set recovery_partition=boot_
		) else if !errorlevel!==2 (
			set recovery_partition=recovery_
		) else if !errorlevel!==3 (
			set recovery_partition=vendor_boot_
		) else if !errorlevel!==4 (
			set recovery_partition=recovery
		) else if !errorlevel!==5 (
			set recovery_partition=boot
		) else if !errorlevel!==6 (
			call :PATCH_RECOVERY
		)
		call :PULL
	) else if !errorlevel!==2 (
		set "PATCH_RECOERY_ORIGIN=U. Use a recovery file (.img)"
		call :USE
	) else if /i !errorlevel!==3 (
		call :MAIN
	)
goto :EOF
::######################################################################################################################
:USE
	for /f "delims=" %%I in ('powershell -Command "& {Add-Type -AssemblyName System.Windows.Forms; $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $openFileDialog.Filter = 'Android recovery image (.img)|*.img'; $openFileDialog.Title = 'Select a image file'; $openFileDialog.InitialDirectory = '!DIR!'; $openFileDialog.ShowDialog() | Out-Null; $openFileDialog.FileName}"') do set "recovery_file=%%I"
	if not exist "!recovery_file!" (
		echo.
		echo It seems you didn't select any file.
		echo.	
		choice /C YN /N /M "Do you want to try again? [y/n]: "
		if !errorlevel!==2 (
			call :MAIN
		)
		call :USE
	)
	copy "!recovery_file!" !AIK! > nul 2>&1 || (
		echo Could not copy recovery file to working directory.
		echo.
		pause
		call :MAIN
	)
	for %%A in ("!recovery_file!") do (
		set "recovery_file=!AIK!\%%~nxA"
		set "recovery_filename=%%~nxA"
	)
	call :PATCH_RECOVERY_FILE
goto :EOF
::######################################################################################################################
:PULL
	call :CONNECT_RECOVERY
	echo !recovery_partition! | find "_" > nul 2>&1 && (
		for /f "usebackq delims=_" %%A in (`"adb shell getprop ro.boot.slot_suffix"`) do (
			set recovery_partition=!recovery_partition!%%A
		)
	)
	adb shell ls /dev/block/by-name | findstr /R "\!recovery_partition!\>" || (
		echo There is no such !recovery_partition! partition.
		echo.
		pause
		call :PATCH_RECOVERY
	)

	for /f "usebackq delims=" %%a in (`"adb shell getprop ro.build.product"`) do (
		set "device_name=%%a"
	)
	if "!device_name!"=="" (
		for /f "usebackq delims=" %%a in (`"adb shell getprop ro.product.device"`) do (
			set "device_name=%%a"
		)
	)
	if "!device_name!"=="" (
		for /f "usebackq delims=" %%a in (`"adb shell getprop ro.product.odm.device"`) do (
			set "device_name=%%a"
		)
	)
	if "!device_name!"=="" (
		for /f "usebackq delims=" %%a in (`"adb shell getprop ro.product.vendor.device"`) do (
			set "device_name=%%a"
		)
	)
	
	call :UPPERCASE device_name
	cls
	echo ^> Patch recovery
	echo  ^'-^> !PATCH_RECOERY_ORIGIN!
	echo.
	echo.
	echo Device: !device_name!
	echo.
	echo Dumping recovery from /dev/block/by-name/!recovery_partition!...
	echo ______________________________________
	adb shell dd if=/dev/block/by-name/!recovery_partition! of=/sdcard/recovery.img
	set dump_result=!errorlevel!
	echo ______________________________________
	if !dump_result!==1 (
		echo      Error on dumping recovery.img from !recovery_partition!
		echo.
		pause
		adb shell rm /sdcard/recovery.img > nul 2>&1
		call :PATCH_RECOVERY
	) else (
		echo      Done.
	)
	echo.
	echo Pulling recovery.img from device...
	echo ______________________________________
	adb pull /sdcard/recovery.img !AIK!\recovery.img
	set pull_result=!errorlevel!
	echo ______________________________________
	adb shell rm /sdcard/recovery.img > nul 2>&1
	if !pull_result!==1 (
		echo      Error on pulling recovery.img
		echo.
		pause
		call :PATCH_RECOVERY
	) else (
		echo      Done.
	)
	set recovery_file=!AIK!\recovery.img
	set recovery_filename=recovery.img
	echo.
	echo.
	echo|set /p="Do you want to boot back to Android? (y/n): " & choice /c yn /n
	if !errorlevel!==1 (
		adb reboot
	)
	call :PATCH_RECOVERY_FILE
goto :EOF
::######################################################################################################################
:PATCH_RECOVERY_FILE
	cls
	echo ^> P. Patch recovery
	echo  ^'-^> !PATCH_RECOERY_ORIGIN!
	echo.
	echo.
	echo Unpacking !recovery_filename!...
	if exist !AIK!\ramdisk\ (
		cmd /C !AIK!\cleanup.bat > nul 2>&1
	)
	start /B cmd /C !AIK!\unpackimg.bat !recovery_file! > nul 2>&1
	:loop_unpacking
	if not exist !AIK!\error.tmp (
		if not exist !AIK!\done.tmp (
			<nul set /p"=."
			timeout 1 /nobreak > nul 2>&1
			goto loop_unpacking
		)
	)
	echo.
	
	for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"ro.build.product=" "!AIK!\ramdisk\prop.default"') do (
		set "device_name=%%b"
	)
	if "!device_name!"=="" (
		for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"ro.product.device=" "!AIK!\ramdisk\prop.default"') do (
			set "device_name=%%b"
		)
	)
	if "!device_name!"=="" (
		for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"ro.product.odm.device=" "!AIK!\ramdisk\prop.default"') do (
			set "device_name=%%b"
		)
	)
	if "!device_name!"=="" (
		for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"ro.product.vendor.device=" "!AIK!\ramdisk\prop.default"') do (
			set "device_name=%%b"
		)
	)

	call :UPPERCASE device_name

	if exist !AIK!\error.tmp (
		cmd /C !AIK!\cleanup.bat > nul 2>&1
		call :CLEAN_TMP
		echo      Error on unpacking "!recovery_filename!".
		echo.
		pause
		call :PATCH_RECOVERY
	)
	echo      Done.
	echo.
	echo.

	echo Copying DuckPart files...
	xcopy /E /I /Y Files !AIK!\ramdisk\sbin\duckpartdir\ > nul 2>&1 && (
		echo      Done.
	) || (
		cmd /C !AIK!\cleanup.bat > nul 2>&1
		echo      Error on copying DuckPart files.
		echo.
		pause
		call :PATCH_RECOVERY
	)
	echo.
	echo Organizing files...
	(
		move !AIK!\ramdisk\sbin\duckpartdir\duckpart !AIK!\ramdisk\sbin\ > nul 2>&1
		move !AIK!\ramdisk\sbin\duckpartdir\dmsetup !AIK!\ramdisk\sbin\ > nul 2>&1
		move !AIK!\ramdisk\sbin\duckpartdir\parted !AIK!\ramdisk\sbin\ > nul 2>&1
		move !AIK!\ramdisk\sbin\duckpartdir\sgdisk !AIK!\ramdisk\sbin\ > nul 2>&1
	) && (
		echo      Done.
	) || (
		echo      Error.
	)
	echo.
	if exist !AIK!\ramdisk\etc\recovery.fstab (
		set fstab=!AIK!\ramdisk\etc\recovery.fstab
	) else if exist !AIK!\ramdisk\system\etc\twrp.flags (
		set fstab=!AIK!\ramdisk\system\etc\twrp.flags
	)
	if not exist !fstab! (
		echo      Could not locate file system table file.
		echo      Mount point will not work.
	) else (
		echo Adding partitions mount points...
		echo ______________________________________
		echo      File system table file: FOUND

		set /A first=0
		>nul find "/esp " !fstab! || (
			call :FSTABREGION
			echo /esp vfat /dev/block/bootdevice/by-name/esp flags=display="ESP!device_name!";storage;removable >> !fstab! && (
				echo      esp   mount point: CREATED
			) || (
				echo      esp   mount point: FAILED
			)
		)
		>nul find "/win " !fstab! || (
			call :FSTABREGION
			echo /win ntfs /dev/block/bootdevice/by-name/win flags=display="WIN!device_name!";storage;removable >> !fstab! && (
				echo      win   mount point: CREATED
			) || (
				echo      win   mount point: FAILED
			)
		)
		>nul find "/winpe " !fstab! || (
			call :FSTABREGION
			echo /winpe vfat /dev/block/bootdevice/by-name/winpe flags=display="WINPE!device_name!";storage;removable >> !fstab! && (
				echo      winpe mount point: CREATED
			) || (
				echo      winpe mount point: FAILED
			)
		)
		>nul find "/logfs " !fstab! || (
			call :FSTABREGION
			echo /logfs vfat /dev/block/bootdevice/by-name/logfs flags=display="LogFS";storage;removable >> !fstab! && (
				echo      logfs mount point: CREATED
			) || (
				echo      logfs mount point: FAILED
			)
		)
		>nul find "/linux " !fstab! || (
			call :FSTABREGION
			echo /linux ext4 /dev/block/bootdevice/by-name/linux flags=display="LINUX!device_name!";storage;removable >> !fstab! && (
				echo      linux mount point: CREATED
			) || (
				echo      linux mount point: FAILED
			)
		)
		echo ______________________________________
	)
	echo.
	del !AIK!\error.tmp > nul 2>&1
	del !AIK!\done.tmp > nul 2>&1
	echo Repacking !recovery_filename!...
	start /B cmd /C !AIK!\repackimg.bat > nul 2>&1
	:loop_repacking
	if not exist !AIK!\error.tmp (
		if not exist !AIK!\done.tmp (
			<nul set /p"=."
			timeout 1 /nobreak > nul 2>&1
			goto loop_repacking
		)
	)
	echo.
	if exist !AIK!\error.tmp (
		cmd /C !AIK!\cleanup.bat > nul 2>&1
		call :CLEAN_TMP
		echo      Error on repacking !recovery_filename!.
		echo.
		pause
		call :PATCH_RECOVERY
	)
	echo      Done.
	echo.
	echo.
	set "recovery_file=Output\PATCHED-!recovery_filename!"
	echo Moving patched recovery to !recovery_file!...
	move !AIK!\image-new.img !recovery_file! > nul 2>&1 && (
		echo      Done.
	) || (
		set recovery_file=!AIK!\image-new.img
		echo      Error.
		echo      You must copy it manually from !AIK! directory.
		echo      It's the file: image.new
		echo      We can proceed here anyway.
		echo.
		pause
	)
	echo.
	start /B cmd /C !AIK!\cleanup.bat > nul 2>&1
	call :CLEAN_TMP
	pause
	cls
	echo ^> P. Patch recovery
	echo ^'-^> !PATCH_RECOERY_ORIGIN!
	echo    ^'-^> Patched recovery: !recovery_filename!
	echo.
	echo.
	echo B. Boot patched recovery
	echo F. Flash patched recovery
	echo.
	echo R. Return
	echo.
	echo|set /p="Choose: " & choice /c bfr /n
	set option=!errorlevel!
	if !option!==3 (
		call :MAIN
	)

	call :CONNECT_FASTBOOT
	for /f "tokens=2 delims=: " %%a in ('fastboot getvar unlocked 2^>^&1 ^| findstr "unlocked: "') do (
		if not "%%a"=="yes" (
			echo It seems your bootloader is not unlocked yet.
			echo Can not proceed this way.
			echo Unlock it and try again.
			echo ^"fastboot getvar unlocked^" must return ^"yes^"
			echo.
			pause
			call :MAIN
		)
	)
	echo.
	echo.
	if !option!==1 (
		cls
		echo ^> P. Patch recovery
		echo ^'-^> !PATCH_RECOERY_ORIGIN!
		echo    ^'-^> Boot recovery: !recovery_filename!
		echo.
		echo.
		echo Booting patched recovery...
		echo ______________________________________
		fastboot boot "!recovery_file!"
		echo ______________________________________
	) else if !option!==2 ( 
		for /f "tokens=2 delims=: " %%a in ('fastboot getvar current-slot 2^>^&1 ^| findstr "current-slot: "') do set "current_slot=%%a"
		cls
		echo ^> P. Patch recovery
		echo ^'-^> !PATCH_RECOERY_ORIGIN!
		echo    ^'-^> Flash recovery: !recovery_filename!
		echo.
		echo.
		echo Select a partition to flash patched recovery image.
		echo Current slot: !current_slot!
		echo If you don^'t know what is your recovery partition, return.
		echo.
		echo 1. boot_a
		echo 2. boot_b
		echo 3. recovery_a
		echo 4. recovery_b
		echo 5. vendor_boot_a
		echo 6. vendor_boot_b
		echo 7. recovery
		echo 8. boot
		echo.
		echo R. Return
		echo.
		echo|set /p="Enter the number: " & choice /c 12345678R /n
		if !errorlevel!==1 (
			set recovery_partition=boot_a
		) else if !errorlevel!==2 (
			set recovery_partition=boot_b
		) else if !errorlevel!==3 (
			set recovery_partition=recovery_a
		) else if !errorlevel!==4 (
			set recovery_partition=recovery_b
		) else if !errorlevel!==5 (
			set recovery_partition=vendor_boot_a
		) else if !errorlevel!==6 (
			set recovery_partition=vendor_boot_b
		) else if !errorlevel!==7 (
			set recovery_partition=recovery
		) else if !errorlevel!==8 (
			set recovery_partition=boot
		) else if !errorlevel!==9 (
			call :PATCH_RECOVERY
		)
		echo.
		echo.
		fastboot getvar partition-type:!recovery_partition! 2>&1 | findstr "partition-type:!recovery_partition!:" > nul && (
			echo ______________________________________
			fastboot flash !recovery_partition! "!recovery_file!"
			echo ______________________________________
			echo.
			echo|set /p="Do you want to put device in Mass Storage mode? [y/n]: " & choice /c yn /n
			if !errorlevel! == 1 (
				echo.
				echo ______________________________________
				fastboot reboot recovery
				echo ______________________________________
				echo.
				pause
			)
		) || (
			echo Could not locate !recovery_partition! partition.
			echo Check if it^'s correct try again.
		)
	)
	start /B cmd /C !AIK!\cleanup.bat > nul 2>&1 :: run this on background
	echo.
	pause
	call :CLEAN_TMP
	call :MAIN
goto :EOF
::######################################################################################################################
:UPPERCASE
	for %%a in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "1=1" "2=2" "3=3" "4=4" "5=5" "6=6" "7=7" "8=8" "9=9" "0=0") do (
		call set %~1=%%%~1:%%~a%%
	)
goto :EOF
::######################################################################################################################
:FSTABREGION
	if !first!==0 (
		echo. >> !fstab!
		echo. >> !fstab!
		echo #Non Android partitions mount points >> !fstab!
		set /A first=1
	)
goto :EOF
::######################################################################################################################
:CLEAN_TMP
	del !AIK!\error.tmp > nul 2>&1
	del !AIK!\done.tmp > nul 2>&1
	for %%a in ("%AIK%\*.img") do (
		del /Q "%%a" > nul 2>&1
	)
goto :EOF
::######################################################################################################################
:CONNECT_FASTBOOT
	set message=   CONNECT YOUR DEVICE IN FASTBOOT MODE
	:fastboot_loop
	adb devices > !TEMP!\adb.txt
	fastboot devices > !TEMP!\fastboot.txt
	set "fastboot="
	set /p fastboot=<!TEMP!\fastboot.txt
	if "!fastboot!"=="" (
		cls
		for %%A in ("!TEMP!\adb.txt") do (
			if %%~zA LEQ 28 (
				set first_char=!message:~0,1!
				set remaining_text=!message:~1!
				set message=!remaining_text!!first_char!
				echo !message!
				timeout 1 /nobreak > nul 2>&1
				goto fastboot_loop
			) else (
				for /f "usebackq delims=" %%A in (`"type "!TEMP!\adb.txt" | find "" /v /c"`) do (
					set /a devices=%%A-2
				)
				del "!TEMP!\adb.txt"
				if !devices! GTR 1 (
					echo !devices! devices were detected.
					echo Please keep only the target device connected.
					echo.
					pause
					call :CONNECT_FASTBOOT
				)
				echo Reboot your device into fastboot mode
				echo.		
				echo|set /p="Do you want to reboot it now? [y/n]: " & choice /c yn /n
				if !errorlevel!==1 (
					adb reboot bootloader
				) else (
					call :PATCH_RECOVERY
				)
				goto fastboot_loop
			)
		)
	)
goto :EOF
::######################################################################################################################
:CONNECT_RECOVERY
	set message=   CONNECT YOUR DEVICE IN RECOVERY MODE
	:recovery_loop
	adb devices > !TEMP!\adb.txt
	fastboot devices > !TEMP!\fastboot.txt
	set "fastboot="
	set /p fastboot=<!TEMP!\fastboot.txt
	if not "!fastboot!"=="" (
		echo Please reboot device into recovery mode.
		pause
		goto PATCH_RECOVERY
	)
	cls
	for %%A in ("%TEMP%\adb.txt") do (
		if %%~zA LEQ 28 (
			set first_char=!message:~0,1!
			set remaining_text=!message:~1!
			set message=!remaining_text!!first_char!
			echo !message!
			timeout 1 /nobreak > nul 2>&1
			goto recovery_loop
		)
	)
	for /f "usebackq delims=" %%A in (`"type "%TEMP%\adb.txt" | find "" /v /c"`) do set /a devices=%%A-2
	del "%TEMP%\adb.txt"
	if !devices! GTR 1 (
		echo !devices! devices were detected.
		echo Please keep only the target device connected.
		echo.
		pause
		call :CONNECT_RECOVERY
	)

	adb shell ls /data > nul 2>&1 || (
		echo You need to reboot your device into recovery mode.
		echo.		
		echo|set /p="Do you want to reboot it now? [y/n]: " & choice /c yn /n
		if !errorlevel!==1 (
			adb reboot recovery
		) else (
			goto PATCH_RECOVERY
		)
		goto recovery_loop
	)
goto :EOF

:NUMBER2LETTER
	set "LETTER_NUMBER=%~2"
	set "LETTER="
	if "!LETTER_NUMBER!" neq "" (
		for /l %%i in (0,1,26) do (
			set /a "SEQUENCE=%%i + 1"
			set "LETTER=!LETTERS:~%%i,1!"
			if !SEQUENCE!==!LETTER_NUMBER! (
				goto :ESCAPE_N2L_LOOP
			)
		)
	)
	:ESCAPE_N2L_LOOP
	set %~1=!LETTER!
goto :EOF