' Function to select a column with a specified value and save to a new workbook
Function SelectAndSaveColumn(excelFilePath, sheetName, columnName, selectedValue)

    Dim xlApp, xlBook, xlSheet, xlRange, xlNewBook
    Set xlApp = CreateObject("Excel.Application")
    Set xlBook = xlApp.Workbooks.Open(excelFilePath)
    Set xlSheet = xlBook.Worksheets(sheetName)
   
    ' Find the column with the selected value
    Set xlCell = xlSheet.Cells(2, columnName)

    ' Get the formula from the cell
    formula = xlCell.Validation.Formula1
    Set rng = xlSheet.Range(formula)
    WScript.Echo "Debug Message: cell count:" & rng.Cells.Count
    Dim cellValues()
    ReDim cellValues(rng.Cells.Count - 1)
    
     ' Loop over the cells in the range and see if it matches the selected value
    For i = 1 To rng.Cells.Count
    If rng.Cells(i).Value = selectedValue Then
          WScript.Echo "Debug Message: find in index:" & i
          xlCell.Value = rng.Cells(i).Value
       End If
    Next
    xlBook.Close True
    xlApp.Quit
    Set xlSheet = Nothing
    Set xlBook = Nothing
    Set xlApp = Nothing
End Function

Sub Main()
    Set FSO = CreateObject("Scripting.FileSystemObject")
    script_path = FSO.GetParentFolderName(WScript.ScriptFullName)
    input_value = WScript.Arguments(0)
    excelFilePath = FSO.BuildPath(script_path, WScript.Arguments(1))
    WScript.Echo "Debug Message: excel_path:" & excelFilePath
    SelectAndSaveColumn excelFilePath, "RegionSelect", "B", input_value
End Sub

' Call the Main subroutine when the script runs
Call Main()