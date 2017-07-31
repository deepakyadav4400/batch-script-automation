@echo off

REM Copyright 2017 Dell Inc. or its subsidiaries. All Rights Reserved.
REM Author : Debadatta Mishra
REM A batch script to create a setup file for NVT on the fly.

ECHO ********************************************************************
ECHO NVT Setp creation
ECHO Please wait a while, setup is in progress.
ECHO ********************************************************************


setlocal EnableDelayedExpansion

call:DeleteAll
call:CloneAll
call:BuildNVTUI
call:BuildNVTServer
call:MakeSetup
call:CopyAll
call::RunInnoSetup
call::CreateExe
goto:eof
EXIT /B


:DeleteAll 
	ECHO ** Deleting existing directories                                  **

	if exist "nvt-ui" rd /q /s "nvt-ui"

	if exist "network-validation-tool" rd /q /s "network-validation-tool"

	if exist "nvtinstaller" rd /q /s "nvtinstaller"

EXIT /B 0

:CloneAll 
	ECHO ** Cloning the nvt-ui (nvt-ui)                                    **
	git clone ssh://git@gssd-stash.isus.emc.com:7999/nvt/nvt-ui.git --branch develop

	ECHO ** Cloning the network validation tools (network-validation-tool) **
	
	git clone ssh://git@gssd-stash.isus.emc.com:7999/nvt/network-validation-tool.git --branch develop

	ECHO ** Cloning the NVT Installer (nvtinstaller)                       **

	git clone ssh://git@gssd-stash.isus.emc.com:7999/nvt/nvtinstaller.git --branch develop

EXIT /B 0

:BuildNVTUI
	cd nvt-ui

	echo { >> combine.txt
	echo  "directory": "app/bower_components", >> combine.txt
	echo. "strict-ssl":false >> combine.txt
	echo }  >> combine.txt

	del ".bowerrc"
	rename "combine.txt" ".bowerrc"

	call npm install

	call bower install
	call npm install electron-packager -g
	
	call electron-packager . --version-string.FileDescription=CE

	REM call electron-packager . --overwrite --asar=true --platform=win32 --arch=x64 --icon=assets/icons/win/icon.ico --prune=true --out=nvt-ui --version-string.CompanyName=EMC --version-string.FileDescription=CE --version-string.ProductName=\"NVT\"

	cd ..

EXIT /B 0

:BuildNVTServer
	cd network-validation-tool

	:Variables
	set InputFile=build.gradle
	echo %InputFile%
	set OutputFile=build1.gradle
	set "_strFind=apply plugin: 'titan-sonar' 
	set "_strInsert=//apply plugin: 'titan-sonar' 

	:Replace
	>"%OutputFile%" (
	  for /f "usebackq delims=" %%A in ("%InputFile%") do (
		if "%%A" equ "%_strFind%" (echo %_strInsert%) else (echo. %%A)
	  )
	)


	del "build.gradle"
	rename "build1.gradle" "build.gradle"

	ECHO ** Executing Gradle script for network-validation-tool            **
	call gradle clean build -x test

	cd ..
EXIT /B 0

:MakeSetup
	if exist "setup" rd /q /s "setup"
	REM mkdir "setup"
	mkdir "setup\nvt-ui"
	mkdir "setup\nvtinstaller"
	REM xcopy /e %cd%/nvt-ui/nvt-ui %cd%/setup
EXIT /B 0

:CopyAll
	REM xcopy ".\nvt-ui\nvt-ui" ".\setup\nvt-ui" /s
	xcopy ".\nvt-ui" ".\setup\nvt-ui" /s
	xcopy ".\nvtinstaller" ".\setup\nvtinstaller" /s
	xcopy ".\network-validation-tool\build\libs\*.jar" ".\setup\nvtinstaller" /s
EXIT /B 0	

:RunInnoSetup
	REM cd setup\nvtinstaller
	call ".\innosetup5\ISCC" ".\setup\nvtinstaller\NVTInstaller.iss"
EXIT /B 0

:CreateExe
	xcopy ".\setup\nvtinstaller\output\*.exe" ".\" /s
	ECHO ********************************************************************
	ECHO NVT Setp creation completed
	ECHO ********************************************************************
EXIT /B 0