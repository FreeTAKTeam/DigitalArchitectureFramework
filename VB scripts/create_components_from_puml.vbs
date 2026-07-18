Option Explicit

'-----------------------------------------------------------------------------
' Script Name : CreateComponentsFromPlantUML
' Author      : Giu Platania
' Purpose     : Parse PlantUML component diagrams embedded in the Notes of the
'               selected EA element and create matching EA Component elements
'               along with their relationships.  Lines containing group
'               declarations (package, node, cloud, database, folder, frame)
'               are optionally converted into EA packages based on
'               USE_GROUPING_AS_PACKAGES.  The script logs its progress to a
'               dedicated output tab and prompts the user when complete.
' Methods     : CreateComponentsFromPlantUML, ParseEntityName
' Date        : 15-Sep-2025
' Version     : 1.1
'-----------------------------------------------------------------------------

'============================= Configurable Options =============================
Const DEFAULT_COMPONENT_TYPE       = "Component"      ' EA element type for created components
Const DEFAULT_COMPONENT_STEREOTYPE = ""              ' Stereotype for created components (empty means none)
Const DEFAULT_CONNECTOR_TYPE       = "Association"    ' EA connector type for all relationships
Const DEFAULT_CONNECTOR_STEREOTYPE = ""              ' Stereotype for created connectors (empty means none)

Const USE_GROUPING_AS_PACKAGES     = False            ' True: turn PlantUML groups into EA packages
Const OUTPUT_TAB_NAME              = "PlantUML Parser" ' Tab name used for logging
'===============================================================================

' Main entry point.  Parse PlantUML text from the selected element's Notes and
' create EA components and connectors.  This sub performs the entire import.
Sub CreateComponentsFromPlantUML()
    ' Ensure a clean output window
    Repository.CreateOutputTab OUTPUT_TAB_NAME
    Repository.ClearOutput OUTPUT_TAB_NAME
    Repository.EnsureOutputVisible OUTPUT_TAB_NAME

    ' Obtain the selected element from the project browser
    Dim selectedElement
    Set selectedElement = Repository.GetTreeSelectedObject()
    If selectedElement Is Nothing Then
        Session.Prompt "Please select an element containing PlantUML text in its Notes.", promptOK
        Exit Sub
    End If

    ' Read PlantUML code from the Notes field
    Dim plantUML
    plantUML = selectedElement.Notes
    If Len(Trim(plantUML)) = 0 Then
        Session.Prompt "The selected element does not contain any PlantUML text.", promptOK
        Exit Sub
    End If

    Repository.WriteOutput OUTPUT_TAB_NAME, Now() & ": Parsing PlantUML from '" & selectedElement.Name & "'...", 0

    ' Split the PlantUML code into individual lines
    Dim lines
    lines = Split(plantUML, vbCrLf)

    ' Map of component names to EA elements
    Dim componentMap
    Set componentMap = CreateObject("Scripting.Dictionary")

    ' Temporarily hold relationships before creation; each entry holds
    ' (sourceName, arrowType, targetName)
    Dim relationList
    Set relationList = CreateObject("System.Collections.ArrayList")

    ' Determine the package to add new elements into.  By default this is the
    ' package containing the selected element.  When grouping is enabled,
    ' currentPackage will be updated as groups are entered and exited.
    Dim currentPackage As EA.Package
    Dim rootPackage As EA.Package
    Set rootPackage = Repository.GetPackageByID(selectedElement.PackageID)
    Set currentPackage = rootPackage

    ' Stack for nested groups when USE_GROUPING_AS_PACKAGES = True
    Dim pkgStack()
    Dim stackDepth
    ReDim pkgStack(0)
    stackDepth = 0

    Dim i
    For i = 0 To UBound(lines)
        Dim skipLine
        skipLine = False
        Dim line
        line = Trim(lines(i))

        ' Skip blank lines and comment lines
        If line = "" Then
            skipLine = True
        ElseIf Left(line, 1) = "'" Then
            skipLine = True
        ElseIf InStr(1, LCase(line), "@startuml") > 0 Or InStr(1, LCase(line), "@enduml") > 0 Then
            skipLine = True
        End If

        '====================== Group handling ======================
        If Not skipLine Then
            If USE_GROUPING_AS_PACKAGES Then
                Dim lowerLine
                lowerLine = LCase(line)
                ' Detect group start keywords
                If Left(lowerLine, 7) = "package" Or _
                   Left(lowerLine, 4) = "node" Or _
                   Left(lowerLine, 5) = "cloud" Or _
                   Left(lowerLine, 8) = "database" Or _
                   Left(lowerLine, 6) = "folder" Or _
                   Left(lowerLine, 5) = "frame" Then
                    Dim grpName
                    grpName = ""
                    Dim firstQuote
                    Dim lastQuote
                    firstQuote = InStr(line, Chr(34))
                    If firstQuote > 0 Then
                        lastQuote = InStr(firstQuote + 1, line, Chr(34))
                        If lastQuote > firstQuote Then
                            grpName = Mid(line, firstQuote + 1, lastQuote - firstQuote - 1)
                        End If
                    End If
                    If grpName = "" Then
                        Dim parts
                        parts = Split(line, " ")
                        If UBound(parts) >= 1 Then grpName = parts(1)
                    End If
                    If grpName <> "" Then
                        Dim newPkg
                        Set newPkg = currentPackage.Packages.AddNew(grpName, "")
                        newPkg.Update
                        ' Push current and switch to new package
                        ReDim Preserve pkgStack(stackDepth)
                        Set pkgStack(stackDepth) = currentPackage
                        stackDepth = stackDepth + 1
                        Set currentPackage = newPkg
                    End If
                    skipLine = True
                ElseIf line = "}" Then
                    If stackDepth > 0 Then
                        stackDepth = stackDepth - 1
                        Set currentPackage = pkgStack(stackDepth)
                    End If
                    skipLine = True
                End If
            Else
                ' Without grouping, ignore braces
                If line = "{" Or line = "}" Then
                    skipLine = True
                End If
            End If
        End If
        '================== End group handling ======================

        If Not skipLine Then
            '================ Component declarations ====================
            ' Component declarations use bracket notation [Name].
            If Left(line, 1) = "[" Then
                Dim compName
                compName = ParseEntityName(line)
                If compName <> "" And Not componentMap.Exists(compName) Then
                    Dim compElem
                    Set compElem = currentPackage.Elements.AddNew(compName, DEFAULT_COMPONENT_TYPE)
                    If DEFAULT_COMPONENT_STEREOTYPE <> "" Then
                        compElem.Stereotype = DEFAULT_COMPONENT_STEREOTYPE
                    End If
                    compElem.Update
                    componentMap.Add compName, compElem
                    Repository.WriteOutput OUTPUT_TAB_NAME, "Created component: " & compName, 0
                End If
                skipLine = True
            End If
        End If

        If Not skipLine Then
            '==================== Relationship detection =================
            ' Identify connectors by arrow or dash
            Dim delim
            Dim arrowType
            delim = ""
            arrowType = "none"
            If InStr(line, "-->") > 0 Then
                delim = "-->"
                arrowType = "forward"
            ElseIf InStr(line, "<--") > 0 Then
                delim = "<--"
                arrowType = "backward"
            ElseIf InStr(line, "->") > 0 Then
                delim = "->"
                arrowType = "forward"
            ElseIf InStr(line, "<-") > 0 Then
                delim = "<-"
                arrowType = "backward"
            ElseIf InStr(line, "-") > 0 Then
                delim = "-"
                arrowType = "none"
            End If
            If delim <> "" Then
                Dim parts
                parts = Split(line, delim)
                If UBound(parts) >= 1 Then
                    Dim leftPart
                    Dim rightPart
                    leftPart = Trim(parts(0))
                    rightPart = Trim(parts(1))
                    ' Trim labels after colon
                    If InStr(leftPart, ":") > 0 Then
                        leftPart = Trim(Split(leftPart, ":")(0))
                    End If
                    If InStr(rightPart, ":") > 0 Then
                        rightPart = Trim(Split(rightPart, ":")(0))
                    End If
                    ' Extract entity names
                    Dim leftName
                    Dim rightName
                    leftName = ParseEntityName(leftPart)
                    rightName = ParseEntityName(rightPart)
                    ' Create missing components
                    If leftName <> "" And Not componentMap.Exists(leftName) Then
                        Dim lElem
                        Set lElem = currentPackage.Elements.AddNew(leftName, DEFAULT_COMPONENT_TYPE)
                        If DEFAULT_COMPONENT_STEREOTYPE <> "" Then
                            lElem.Stereotype = DEFAULT_COMPONENT_STEREOTYPE
                        End If
                        lElem.Update
                        componentMap.Add leftName, lElem
                        Repository.WriteOutput OUTPUT_TAB_NAME, "Created component: " & leftName, 0
                    End If
                    If rightName <> "" And Not componentMap.Exists(rightName) Then
                        Dim rElem
                        Set rElem = currentPackage.Elements.AddNew(rightName, DEFAULT_COMPONENT_TYPE)
                        If DEFAULT_COMPONENT_STEREOTYPE <> "" Then
                            rElem.Stereotype = DEFAULT_COMPONENT_STEREOTYPE
                        End If
                        rElem.Update
                        componentMap.Add rightName, rElem
                        Repository.WriteOutput OUTPUT_TAB_NAME, "Created component: " & rightName, 0
                    End If
                    ' Record relation data for later
                    Dim rel(2)
                    rel(0) = leftName
                    rel(1) = arrowType
                    rel(2) = rightName
                    relationList.Add rel
                End If
            End If
            '================== End relationship detection ==================
        End If
    Next

    '=================== Create connectors ==========================
    Dim ri
    For ri = 0 To relationList.Count - 1
        Dim relData
        relData = relationList.Item(ri)
        Dim sName
        Dim tName
        Dim aType
        sName = relData(0)
        aType = relData(1)
        tName = relData(2)
        Dim sourceElem As EA.Element
        Dim targetElem As EA.Element
        ' Determine client/supplier based on arrow type
        If aType = "forward" Then
            Set sourceElem = componentMap(sName)
            Set targetElem = componentMap(tName)
        ElseIf aType = "backward" Then
            Set sourceElem = componentMap(tName)
            Set targetElem = componentMap(sName)
        Else
            Set sourceElem = componentMap(sName)
            Set targetElem = componentMap(tName)
        End If
        ' Avoid creating duplicate connectors
        Dim connExists
        connExists = False
        Dim existingConn As EA.Connector
        For Each existingConn In sourceElem.Connectors
            If existingConn.Type = DEFAULT_CONNECTOR_TYPE And _
               existingConn.SupplierID = sourceElem.ElementID And _
               existingConn.ClientID = targetElem.ElementID Then
                connExists = True
                Exit For
            End If
        Next
        If Not connExists Then
            Dim newConn As EA.Connector
            Set newConn = sourceElem.Connectors.AddNew("", DEFAULT_CONNECTOR_TYPE)
            newConn.SupplierID = sourceElem.ElementID
            newConn.ClientID = targetElem.ElementID
            If DEFAULT_CONNECTOR_STEREOTYPE <> "" Then
                newConn.Stereotype = DEFAULT_CONNECTOR_STEREOTYPE
            End If
            newConn.Update
            Repository.WriteOutput OUTPUT_TAB_NAME, "Created connector: " & sName & " -> " & tName, 0
        End If
    Next
    '==================== End connector creation =======================

    Repository.WriteOutput OUTPUT_TAB_NAME, Now() & ": PlantUML import completed.", 0
    Session.Prompt "PlantUML import completed.  See '" & OUTPUT_TAB_NAME & "' tab for details.", promptOK
End Sub

'-----------------------------------------------------------------------------
' Helper: ParseEntityName
' Extracts a component name from a PlantUML token.  Handles bracket
' notation [Name] and alias notation [Name] as Alias.  Removes any
' surrounding quotes and returns the clean component name.
' Parameters:
'   part (String) – token to parse (e.g., "[Component]", "HTTP")
' Returns:
'   String – the extracted component name
'-----------------------------------------------------------------------------
Function ParseEntityName(part)
    Dim namePart
    namePart = Trim(part)
    ' If bracketed, remove the brackets and use alias if present
    If Left(namePart, 1) = "[" Then
        Dim closePos
        closePos = InStr(namePart, "]")
        If closePos > 0 Then
            Dim inside
            inside = Mid(namePart, 2, closePos - 2)
            ' Check for alias after " as "
            If InStr(inside, " as ") > 0 Then
                Dim arr
                arr = Split(inside, " as ")
                namePart = arr(1)
            Else
                namePart = inside
            End If
        Else
            namePart = Mid(namePart, 2)
        End If
    End If
    ' Remove surrounding quotes
    If Left(namePart, 1) = Chr(34) And Right(namePart, 1) = Chr(34) Then
        namePart = Mid(namePart, 2, Len(namePart) - 2)
    End If
    ParseEntityName = Trim(namePart)
End Function

' Immediately run the import routine
CreateComponentsFromPlantUML()