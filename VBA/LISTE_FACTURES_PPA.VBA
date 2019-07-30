Sub setTableFromCSV(FilePath As String)
Open FilePath For Input As #1
row_number = 0

Dim TitreFix As Variant
TitreFix = Array()

Set wsh = Workbooks(2).Sheets.Add(After:=Sheets(1))


Do Until EOF(1)
    Line Input #1, LineFromFile
    LineItems = Split(LineFromFile, ";")
    nLastCol = UBound(LineItems) - 1
    
    If UBound(LineItems) < 1 Then
        Exit Do
    End If
    
   
    Select Case Trim(LineItems(0))
    
    Case "##T" ' le premier Titre
        ReDim Preserve TitreFix(UBound(TitreFix) + nLastCol)
        TitreFix(0) = LineItems(1)
        TitreFix(1) = LineItems(2)
        TitreFix(2) = LineItems(3)
        TitreFix(3) = LineItems(4)
        TitreFix(4) = LineItems(5)
        
    Case "##L" ' Longeur des Columns
        For L = 1 To nLastCol
            With wsh
                .Columns(L).ColumnWidth = Val(LineItems(L))
                .Columns(L).HorizontalAlignment = xlCenter
            End With
        Next L
        
    Case "##AL" ' Alignement des Columns
        For i = 1 To nLastCol
            With wsh
                 ELE = Val(LineItems(i))
                .Columns(i).HorizontalAlignment = Switch(ELE = 1, xlLeft, ELE = 2, xlCenter, ELE = 3, xlRight, True, xlCenter)
            End With
        Next i

        
    Case "##P" 'Paramteres
      
        For i = 5 To 7
                   With wsh.Cells(i, 1)
                        .Value = TitreFix(i - 3)
                        .HorizontalAlignment = xlLeft
                        .BorderAround ColorIndex:=1
                    End With
                    With wsh.Cells(i, 2)
                        .Value = LineItems(i - 4)
                        .HorizontalAlignment = xlCenter
                        .BorderAround ColorIndex:=1
                    End With
        Next i

        With wsh.Cells(3, 1)
             .Value = .Value & LineItems(4)
        End With
      
   Case "##H" ' Header : Les entêtes
            With wsh
                    ActiveWindow.FreezePanes = False
                    .Range(.Cells(10, 1), .Cells(10, nLastCol)).Select
                    Selection.Columns.AutoFit
                    .Range(.Cells(11, 1), .Cells(11, nLastCol)).Select
                    ActiveWindow.FreezePanes = True
                    
                    
                    ' Cette partie pour ecrire le Titre "ETATE COMMERCIAL" , sa doit d'etre ma car on doit compter le nombre de column avant de la ecrire
                     With .Range(.Cells(1, 1), .Cells(1, nLastCol))
                         .Merge
                         .Value = TitreFix(0)
                         .Font.Size = 20
                         .Font.Bold = True
                         .HorizontalAlignment = xlCenter
                         
                     End With
                     
                    With .Range(.Cells(3, 1), .Cells(3, nLastCol))
                         .Merge
                         .Value = TitreFix(1)
                         .Font.Size = 20
                         .Font.Bold = True
                         .HorizontalAlignment = xlCenter
                    End With
            End With
            
            ' cette partie s'occupe  des entêtes
            Dim headerCellwidth As Integer
            For i = 1 To nLastCol
                With wsh
                    'headerCellwidth = Switch(i = 1 Or i = 3 Or i = 4, 25, i = 2, 15, i = 5, 70, i = 6, 20, i = 7, 16, i = 8 Or i = 9 Or i = 11, 20, i = 10, 35, i = 12, 100, True, 25)
                    '.Columns(i).ColumnWidth = headerCellwidth
                    With .Cells(10, i)
                        .Value = LineItems(i)
                        .BorderAround ColorIndex:=1
                        .WrapText = True
                    End With
                    
                End With
            Next i

      
   Case "##R" ' ROW : Ligne
        For i = 1 To nLastCol
                    With wsh.Cells(row_number + 8, i)
                       ' Align = Switch((i >= 1 And i <= 5) Or i = 100, xlLeft, True, xlCenter) ' activer cette ligne pour aligner les colonne , et changer et la borne de variable i pour specifier le numero des colonne
                        ' .HorizontalAlignment = Align
                        .Value = LineItems(i)
                        .BorderAround ColorIndex:=1
                        .WrapText = True
                    End With
        Next i
   End Select
   
   row_number = row_number + 1
Loop

Close #1


Application.DisplayAlerts = False
Workbooks(2).Sheets(1).Delete
Application.DisplayAlerts = True

End Sub



