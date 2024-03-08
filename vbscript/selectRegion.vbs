' Function to retrieve a column with dropdown values and return them as a list
Function GetDropdownList(excelFilePath, sheetName, columnName)
    WScript.Echo "Debug Message: Script is running..."
    Dim xlApp, xlBook, xlSheet, xlColumn
    Set xlApp = CreateObject("Excel.Application")
    Set xlBook = xlApp.Workbooks.Open(excelFilePath)
    Set xlSheet = xlBook.Worksheets(sheetName)
    
    WScript.Echo "Debug Message: sheet: " & xlSheet.Name
    ' Find the column with dropdown
    On Error Resume Next
    Set xlCell = xlSheet.Cells(2, columnName) ' Change 1 to the row number you want
    validationFormula = xlCell.Validation.Formula1
    WScript.Echo "Debug Message: valiation:" & validationFormula
    On Error GoTo 0
            
    Set rng = xlSheet.Range(validationFormula)
     WScript.Echo "Debug Message: cell count:" & rng.Cells.Count
    Dim cellValues()
    ReDim cellValues(rng.Cells.Count - 1)
    
     ' Loop over the cells in the range and store their values in the array
    For i = 1 To rng.Cells.Count
        cellValues(i - 1) = rng.Cells(i).Value
    Next
    WScript.Echo "Debug Message: first cell:" & cellValues(0)

    xlBook.Close False
    xlApp.Quit
    Set xlSheet = Nothing
    Set xlBook = Nothing
    Set xlApp = Nothing

    GetDropdownList = cellValues
End Function


Sub Main()
    Set FSO = CreateObject("Scripting.FileSystemObject")
    script_path = FSO.GetParentFolderName(WScript.ScriptFullName)
    WScript.Echo "Debug Message: script_path:" & script_path
    input_folder = FSO.GetParentFolderName(WScript.Arguments(0))
    excelFilePath = FSO.BuildPath(script_path, WScript.Arguments(0))
    
    values = GetDropdownList(excelFilePath, "RegionSelect", "B")
    Set outfile = FSO.OpenTextFile(FSO.BuildPath(input_folder, "regions.txt"), 2, True)

    For Each value In values
        outfile.WriteLine value
    Next
    outfile.Close()
End Sub

' Call the Main subroutine when the script runs
Call Main()