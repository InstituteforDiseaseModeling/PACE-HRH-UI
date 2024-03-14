cls

ECHO Please read the following license terms:
TYPE LICENSE

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

@echo off
SET R_PATH=%LOCALAPPDATA%\Programs\R\R-4.2.2\bin\Rscript.exe

:: Check if R is installed by attempting to run Rscript.exe
IF EXIST "%R_PATH%" (
    ECHO R is already installed.
) ELSE (
    ECHO Downloading R 4.2.2...
    :: Replace the URL with the direct download link to the R installer you want to use
    curl -o R-4.2.2-win.exe https://cran.r-project.org/bin/windows/base/old/4.2.2/R-4.2.2-win.exe

    ECHO Installing R...
    :: Run the installer silently
    R-4.2.2-win.exe /VERYSILENT /NORESTART

    ECHO R 4.2.2 installation complete.
)

SETX PATH "%R_PATH%;%PATH%"

ECHO Install packages...
:: Run the R script in silent mode
"%R_PATH%\Rscript.exe" --vanilla install_packages.R

:: Start The shinyapps in port 8888 and open the browser
SET PORT=8888

ECHO Starting Shiny app on port %PORT%...
START "" "%R_PATH%\Rscript.exe" -e "shiny::runApp(appDir='%R_SCRIPT_PATH%', port=%PORT%, launch.browser=FALSE)"

:: Wait for a few seconds to ensure the Shiny app has started
TIMEOUT /T 5

:: Open the default web browser to the Shiny app
START http://localhost:%PORT%

GOTO end

:cancelled
ECHO You have cancelled the operation. Goodbye!
exit

:end
:: Prompt the user to close the Shiny app
ECHO Press any key to terminate the PACE-HRH app...
PAUSE > nul

:: Find and terminate the Rscript process that runs the Shiny app
ECHO Terminating the Shiny app...
TASKKILL /IM Rscript.exe /f 2>nul

ECHO PACE-HRH app terminated.



