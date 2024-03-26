cls
setlocal
@echo off


:: Determine if this a git repository
IF EXIST ".git" (
    ECHO You are in a Git repository, please follow ReadMe Instruction to run app in Rstudio
    ECHO Press any key to terminate...
    PAUSE > nul
    exit
) 


:: Determine if this is offline mode
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
ECHO Online installation is needed, please specify installation folder:
SET root_dir=
SET /P root_dir="App Directory: "
ECHO "You have entered: %root_dir%"

IF "%root_dir%"=="" (
    ECHO You must enter a root directory path.
    GOTO prompt
) ELSE (
    IF EXIST "%root_dir%" (
      ECHO "The folder %root_dir% already exists, please choose a new one:"
      GOTO prompt
    ) ELSE (
      MKDIR "%root_dir%"
    )
)


:: Download PACE-HRH-UI Release 
SET APP_DIR=%root_dir%\PACE-HRH-UI
SET CODE_URL=https://github.com/InstituteforDiseaseModeling/PACE-HRH-UI/archive/refs/tags/1.0.0.zip
SET DOWNLOAD_PATH="%root_dir%\pace-hrh-ui.zip"


IF NOT EXIST "%APP_DIR%" (
    ECHO App will be created in: %APP_DIR%
    MKDIR "%APP_DIR%"
)



ECHO Setup will download and extract source code to %APP_DIR%
if not exist %DOWNLOAD_PATH% (
  curl -L -o %DOWNLOAD_PATH% "%CODE_URL%"
)

tar -xf %DOWNLOAD_PATH% -C "%APP_DIR%"


PUSHD "%APP_DIR%"
:: Change to the first directory found (extracted from zip)
for /d %%G in (*) do (
    SET WORKING_DIR=%%G
    ECHO Working directory in "%%G"
    GOTO :breakLoop
)

:breakLoop


:license
ECHO Please read the following license terms:
TYPE "%WORKING_DIR%\LICENSE"

ECHO.
ECHO Do you accept the license terms?
ECHO Type "accept" to accept and continue, or "cancel" to exit.
ECHO.

:askChoice
SET /p userChoice=Your choice (accept/cancel): 

:: Convert the input to lowercase for comparison
IF /i "%userChoice%"=="accept" GOTO accepted
IF /i "%userChoice%"=="cancel" GOTO cancelled

ECHO Invalid choice. Please type "accept" to accept the terms or "cancel" to decline.
GOTO askChoice

:accepted
ECHO You have accepted the terms.


POPD

SET R_PATH="%APP_DIR%\%WORKING_DIR%\R-4.2.2\bin\Rscript.exe"
SET SHINY_DIR="%APP_DIR%\%WORKING_DIR%"

:: Check if R is installed
SET DOWNLOAD_R_PATH="%root_dir%\R-4.2.2-win.exe"
IF EXIST "%R_PATH%" (
    ECHO R is already installed.
) ELSE (
    IF NOT EXIST %DOWNLOAD_R_PATH% (
       ECHO Downloading R 4.2.2...
       :: Replace the URL with the direct download link to the R installer you want to use
       curl -o %DOWNLOAD_R_PATH% https://cran.r-project.org/bin/windows/base/old/4.2.2/R-4.2.2-win.exe
    )

    ECHO Installing R...
    :: Run the installer silently
    %DOWNLOAD_R_PATH% /VERYSILENT /NORESTART /DIR="%SHINY_DIR%\R-4.2.2"

    ECHO R 4.2.2 installation complete.

    ECHO Install packages...
    :: Run the R script in silent mode
   
    %R_PATH% --vanilla "%SHINY_DIR%\install_packages.R"
)

:app
:: Start The shinyapps in port 8888 and open the browser
SET PORT=8888

ECHO Starting Shiny app on port %PORT%...
ECHO Using %R_PATH% ON %SHINY_DIR%

START /MIN "" %R_PATH% -e "shiny::runApp(appDir='%SHINY_DIR%', port=%PORT%, launch.browser=FALSE)"

:: Wait for a few seconds to ensure the Shiny app has started
ECHO Wait for 5 seconds for app launching ...
TIMEOUT /T 5

:: Open the default web browser to the Shiny app
START http://localhost:%PORT%

GOTO end

:cancelled
ECHO You have cancelled the operation. Goodbye!
ECHO Press any key to terminate ...
PAUSE > nul
exit

:end
:: Prompt the user to close the Shiny app
ECHO Press any key to terminate the PACE-HRH app...
PAUSE > nul

:: Find and terminate the Rscript process that runs the Shiny app
ECHO Terminating the Shiny app...
TASKKILL /IM Rscript.exe /f 2>nul

ECHO PACE-HRH app terminated.