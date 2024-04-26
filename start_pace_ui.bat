cls
setlocal
@echo off
SET VERSION=1.0.0

REM Determine if this a git repository
IF EXIST ".git" (
    ECHO You are in a Git repository, please follow ReadMe Instruction to run app in Rstudio
    ECHO Press any key to terminate...
    PAUSE > nul
    exit
) 


REM Determine if this is offline mode
SET "OFFLINE_FOLDERS=R-4.2.2 R config"
SET offline=TRUE
FOR %%F IN (%OFFLINE_FOLDERS%) DO (
    IF NOT EXIST "%%F\" (
        SET offline=FALSE
    )
)
IF %offline%==TRUE (
   ECHO All folders exist. No instllation needed.
   SET R_PATH=.\R-4.2.2\bin\Rscript.exe
   SET SHINY_DIR=.
   GOTO app
) ELSE (
    ECHO You cannot run it with offline mode.
    GOTO prompt
)

:prompt
SET UPGRADE=FALSE
ECHO Online installation is needed, please specify installation folder:
SET root_dir=
SET /P root_dir="App Directory: "
REM Remove surrounding quotes from root_dir
SET "root_dir=%root_dir:"=%"
ECHO "You have entered: %root_dir%"

SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT "%root_dir%"=="" (
  SET "APP_DIR=!root_dir!\PACE-HRH-UI"
  ECHO "Setting app in !APP_DIR!"
)
SETLOCAL DISABLEDELAYEDEXPANSION


IF "%root_dir%"=="" (
    ECHO You must enter a root directory path.
    GOTO prompt
) ELSE IF NOT EXIST "%root_dir%" (
  MKDIR "%root_dir%"
  GOTO continue
) ELSE IF EXIST "%root_dir%\PACE-HRH-UI" (
  GOTO askUpgrade	
) ELSE (
  GOTO continue
)

:askUpgrade
ECHO.
ECHO Do you want to overwrite and update code in this folder?
ECHO Type Y to update and continue, or N to skip.
ECHO If you want to update the code, please make sure to save 'pace_results' directory in %APP_DIR% in case of failure
ECHO.
SET /p confirmation=Your choice:
IF /i "%confirmation%"=="Y" (
    ECHO "Start cleaning files..."
    SET UPGRADE=TRUE
    GOTO deleteFiles
) ELSE IF /i "%confirmation%"=="N" (
    GOTO prompt
) ELSE (
    echo "Invalid input. Please enter Y or N."
    GOTO askUpgrade
)


:continue
REM Download PACE-HRH-UI Release 
REM Prompt the user for the version number
set /p "VERSION_INPUT=Enter PACE-HRH-UI Release version number (default is %VERSION%): "

REM Check if user has provided a version number as input
if not "%VERSION_INPUT%"=="" (
    set "VERSION=%VERSION_INPUT%"
)

SET CODE_URL=https://github.com/InstituteforDiseaseModeling/PACE-HRH-UI/archive/refs/tags/%VERSION%.zip
SET DOWNLOAD_PATH="%root_dir%\pace-hrh-ui.zip"


IF NOT EXIST "%APP_DIR%" (
    ECHO "App will be created in: %APP_DIR%"
    MKDIR "%APP_DIR%"
)



ECHO "Setup will download and extract source code to %APP_DIR%"
IF NOT EXIST %DOWNLOAD_PATH% (
  curl -L -o %DOWNLOAD_PATH% "%CODE_URL%"
)

IF EXIST %DOWNLOAD_PATH% (
  tar -xf %DOWNLOAD_PATH% -C "%APP_DIR%"
) ELSE (
  ECHO Source code Download failed
  ECHO Please make sure the release version exists and try again!
  PAUSE > nul
  EXIT /b 1
)

IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Failed to extract %DOWNLOAD_PATH%
    ECHO Please make sure the release version exists and try again!
    PAUSE > nul
    DEL /F %DOWNLOAD_PATH%
    EXIT /b 1
)


REM SET the working directory
PUSHD "%APP_DIR%"
REM Change to the first directory found (extracted from zip)
for /d %%G in (*) do (
    SET WORKING_DIR=%%G
    ECHO Working directory in "%%G"
    GOTO :breakLoop
)

:breakLoop

:restore_results
if /i "%UPGRADE%"=="TRUE" (
    ECHO Restore pace_results
    IF EXIST "%TEMP%\tmp_pace_hrh_ui\pace_results" (
      MOVE "%TEMP%\tmp_pace_hrh_ui\pace_results" "%WORKING_DIR%" > NUL
    )
) 


:license
ECHO Please read the following license terms:
TYPE "%WORKING_DIR%\LICENSE"

ECHO.
ECHO Do you accept the license terms?
ECHO Type "accept" to accept and continue, or "cancel" to exit.
ECHO.

:askChoice
SET /p userChoice=Your choice (accept/cancel): 

REM Convert the input to lowercase for comparison
IF /i "%userChoice%"=="accept" GOTO accepted
IF /i "%userChoice%"=="cancel" GOTO cancelled

ECHO Invalid choice. Please type "accept" to accept the terms or "cancel" to decline.
GOTO askChoice

:accepted
ECHO You have accepted the terms.


POPD

SET R_PATH="%APP_DIR%\%WORKING_DIR%\R-4.2.2\bin\Rscript.exe"
SET SHINY_DIR="%APP_DIR%\%WORKING_DIR%"
ECHO %R_PATH%
ECHO "%SHINY_DIR%"

REM Check if R is installed
SET DOWNLOAD_R_PATH="%root_dir%\R-4.2.2-win.exe"
ECHO %DOWNLOAD_R_PATH%
IF EXIST "%R_PATH%" (
    ECHO R is already installed.
) ELSE (
    IF NOT EXIST %DOWNLOAD_R_PATH% (
       ECHO Downloading R 4.2.2...
       REM Replace the URL with the direct download link to the R installer you want to use
       curl -o %DOWNLOAD_R_PATH% https://cran.r-project.org/bin/windows/base/old/4.2.2/R-4.2.2-win.exe
    )

    ECHO Installing R...
    REM Run the installer silently
    %DOWNLOAD_R_PATH% /VERYSILENT /NORESTART /DIR="%APP_DIR%\%WORKING_DIR%\R-4.2.2"

    ECHO R 4.2.2 installation complete.

    ECHO Install packages...
    REM Run the R script in silent mode
   
    %R_PATH% --verbose --vanilla "%APP_DIR%\%WORKING_DIR%\install_packages.R"
)


REM Install a woking version 
curl -L -o pacehrh_1.1.0.zip https://github.com/InstituteforDiseaseModeling/PACE-HRH/releases/download/1.1.0/pacehrh_1.1.0.zip
%R_PATH% -e "if (!require('pacehrh', character.only=TRUE)) install.packages('pacehrh_1.1.0.zip', repos = NULL, type = 'source');library(pacehrh)"


REM remove installation files
DEL %DOWNLOAD_R_PATH%
DEL %DOWNLOAD_PATH%

REM Ask User to start again with Offline mode
IF %offline%==FALSE (
    ECHO Please go to %SHINY_DIR% and run the start_pace_ui.bat again
    ECHO Press any key to terminate ...
    PAUSE > nul
    exit
)


:app
REM Start The shinyapps in port 8888 and open the browser
SET PORT=8888

ECHO Starting Shiny app on port %PORT%...
ECHO Using %R_PATH% ON %SHINY_DIR%

START /MIN "" %R_PATH% -e "shiny::runApp(appDir='%SHINY_DIR%', port=%PORT%, launch.browser=TRUE)"
ECHO Your default browser will be opened for PACE-HRH-UI in a few seconds ...

GOTO end

:cancelled
ECHO You have cancelled the operation. Goodbye!
ECHO Press any key to terminate ...
PAUSE > nul
exit

:end
REM Prompt the user to close the Shiny app
ECHO Press any key to terminate the PACE-HRH app...
PAUSE > nul

REM Find and terminate the Rscript process that runs the Shiny app
ECHO Terminating the Shiny app...
TASKKILL /FI "IMAGENAME eq %R_PATH%" /f 2>nul

ECHO PACE-HRH app terminated.
exit

:deleteFiles
REM Delete old files and move 'pace_results' directory
ECHO Deleting directories in "%APP_DIR%" except 'pace_results'
ECHO Searching for 'pace_results' directories under "%APP_DIR%"
REM Use /r for recursive directory traversal
FOR /d /r "%APP_DIR%" %%i in (*) do (
    REM Check if the current directory is named 'pace_results'
    if "%%~nxi"=="pace_results" (
        ECHO 'pace_results' found at: "%%i"
        move "%%i" "%TEMP%\tmp_pace_hrh_ui" || (
            ECHO Failed to move 'pace_results' to %TEMP%
            ECHO Please close your application and try again.
            ECHO If there is a permission issue, please contact your IT administrator.
            ECHO Alternatively, manually remove "%TEMP%\tmp_pace_hrh_ui".
            PAUSE > nul
            exit /b 1
        )
    )
)


FOR /d %%i in ("%APP_DIR%\*") do (
    REM Check if the directory name is 'pace_results'
    ECHO Deleting "%%i"
    rd /s /q "%%i" || (
        ECHO There was an error deleting the folder "%%i".
        ECHO If there is a permission issue, please contact your IT administrator.
        ECHO If the problem is not resolved, you will need to delete "%APP_DIR%" manually.
        ECHO Manually deleting "%APP_DIR%" will result in loss of your previous results.
        PAUSE > nul
        exit /b 1
    )
)

REM Check the exit code of delete section to be sure
IF %ERRORLEVEL% NEQ 0 (
    ECHO Cleanup failed to delete existing files
    ECHO Please rerun the script, if the problem exists, you will need to delete "%APP_DIR%" manually.
    PAUSE > nul
    exit /b 1
)

GOTO continue
