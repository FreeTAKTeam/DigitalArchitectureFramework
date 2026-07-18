'*******************************************************************************
' Script Name: parse_plantuml_to_ea.vbs
' Author: ChatGPT (generated)
' Date: 16-SEP-2025
' Purpose:
'   Parse a subset of PlantUML class and component diagrams stored in the Notes
'   of a selected element (e.g. a Note) and create a corresponding structure of
'   packages, elements and connectors in the current Enterprise Architect
'   repository.  The script supports simple container constructs (package,
'   node, frame, cloud, folder, database), element definitions (component,
'   class, interface, abstract class, enum as well as square bracket syntax for
'   components), stereotypes, aliases, class members (attributes and
'   operations) and several connector types.  It is idempotent: existing
'   packages and elements will be reused and connectors will only be created
'   when they do not already exist.
'
' Usage:
'   1. Open or create a diagram and add a Note element.
'   2. Paste your PlantUML script between @startuml and @enduml into the Note's
'      Notes field.
'   3. Select the Note element on the diagram.
'   4. Run this script.  The model structure will be created under the same
'      package as the Note element.
'
' Limitations:
'   - Only class and component diagrams are supported.
'   - The parser is tolerant but not a complete PlantUML parser. Unsupported
'     directives are ignored.  Complex constructs (e.g. generics, templates,
'     advanced notes, cardinalities on connectors) are not interpreted.
'   - The script assumes names and aliases uniquely identify elements within
'     their package.  Forward references are resolved after all declarations
'     are processed.
'   - Connectors are mapped to EA types based on simple arrow patterns.
'
'********************************************************************************

Option Explicit

' Entry point for the script.  Retrieves the selected element containing
' PlantUML, determines the target package and invokes the parser.
Sub Main()
    Dim currentDiagram
    Set currentDiagram = Repository.GetCurrentDiagram()
    If currentDiagram Is Nothing Then
        MsgBox "There is no active diagram.  Please open a diagram and select the note containing PlantUML.", vbExclamation, "Parse PlantUML"
        Exit Sub
    End If

    Dim selectedObjects
    Set selectedObjects = currentDiagram.SelectedObjects
    If selectedObjects.Count = 0 Then
        MsgBox "Please select the note element containing the PlantUML script.", vbExclamation, "Parse PlantUML"
        Exit Sub
    End If

    ' Use the first selected object
    Dim diagObj, noteElement
    Set diagObj = selectedObjects.GetAt(0)
    Set noteElement = Repository.GetElementByID(diagObj.ElementID)
    If noteElement Is Nothing Then
        MsgBox "Unable to retrieve selected element.", vbExclamation, "Parse PlantUML"
        Exit Sub
    End If

    ' Obtain the PlantUML script from the notes
    Dim scriptText
    scriptText = noteElement.Notes
    If Len(Trim(scriptText)) = 0 Then
        MsgBox "The selected element contains no notes.", vbExclamation, "Parse PlantUML"
        Exit Sub
    End If

    ' Determine the target package.  Use the package of the note element.
    Dim targetPackage
    Set targetPackage = Repository.GetPackageByID(noteElement.PackageID)
    If targetPackage Is Nothing Then
        MsgBox "Unable to determine target package.", vbExclamation, "Parse PlantUML"
        Exit Sub
    End If

    ' Begin a transaction so that changes may be rolled back on error
    On Error Resume Next
    Repository.EnableUIUpdates = False
    Repository.SuppressSecurityDialog = True
    Dim tranStarted
    tranStarted = Repository.BeginTransaction()
    If Not tranStarted Then
        ' Transaction could not be started; proceed without explicit transaction
    End If

    Dim errMsg
    errMsg = ""
    If Not ParsePlantUMLScript(scriptText, targetPackage, errMsg) Then
        If tranStarted Then Repository.RollbackTransaction
        Repository.EnableUIUpdates = True
        Repository.SuppressSecurityDialog = False
        MsgBox "Error parsing PlantUML: " & errMsg, vbExclamation, "Parse PlantUML"
        Exit Sub
    End If
    If tranStarted Then Repository.CommitTransaction
    Repository.EnableUIUpdates = True
    Repository.SuppressSecurityDialog = False

    MsgBox "PlantUML import completed successfully.", vbInformation, "Parse PlantUML"
End Sub

' Parse a PlantUML script and create elements under the specified root package.
' Returns True on success or False on failure.  Any encountered error message
' is returned in errMsg.
Function ParsePlantUMLScript(ByVal text, ByVal rootPackage, ByRef errMsg)
    Dim lines, cleanedLines, i
    errMsg = ""
    ' Extract only the text between @startuml and @enduml
    Dim startIdx, endIdx
    startIdx = InStr(1, LCase(text), "@startuml", vbTextCompare)
    endIdx = InStr(1, LCase(text), "@enduml", vbTextCompare)
    If startIdx = 0 Or endIdx = 0 Or endIdx <= startIdx Then
        errMsg = "Missing @startuml or @enduml in the note text."
        ParsePlantUMLScript = False
        Exit Function
    End If
    Dim inner
    inner = Mid(text, startIdx + Len("@startuml"), endIdx - (startIdx + Len("@startuml")))

    ' Split into lines and clean whitespace
    lines = Split(inner, vbCrLf)
    ReDim cleanedLines(UBound(lines))
    Dim inBlockComment, line
    inBlockComment = False
    For i = 0 To UBound(lines)
        line = Trim(lines(i))
        ' default to empty
        cleanedLines(i) = ""
        If Len(line) = 0 Then
            ' skip empty line
        Else
            If inBlockComment Then
                ' inside block comment; look for end marker
                If InStr(line, "*/") > 0 Then
                    inBlockComment = False
                End If
                ' skip comment content
            ElseIf Left(line, 2) = "/*" Then
                ' start of block comment
                inBlockComment = True
                If Right(line, 2) = "*/" Then
                    ' comment begins and ends on same line
                    inBlockComment = False
                End If
            ElseIf Left(line, 2) = "//" Or Left(line, 1) = Chr(39) Then
                ' single line comment, skip
            Else
                cleanedLines(i) = line
            End If
        End If
    Next

    ' Data structures to hold parsed items
    Dim containerStack, containerCount
    ReDim containerStack(0)
    containerCount = 0
    ' Each entry holds: package (EA.Package), fullnamePrefix (string)
    containerStack(0) = Array(rootPackage, "")

    ' Dictionaries for packages and elements keyed by full name
    Dim pkgCache, elemCache
    Set pkgCache = CreateObject("Scripting.Dictionary")
    Set elemCache = CreateObject("Scripting.Dictionary")
    ' List for connectors; each entry is an array: sourceFullName, targetFullName, connType, direction, label
    Dim connectors
    connectors = Array()
    Dim connCount
    connCount = -1

    ' Prepopulate package cache with root package
    pkgCache.Add "", rootPackage

    ' Iterate lines to parse declarations
    Dim currentLine, lowerLine
    Dim j
    i = 0
    Do While i <= UBound(cleanedLines)
        currentLine = cleanedLines(i)
        If Len(Trim(currentLine)) = 0 Then
            i = i + 1
        Else
            lowerLine = LCase(currentLine)
            ' Container start: package, node, frame, cloud, folder, database
            If Left(lowerLine, 7) = "package" Or Left(lowerLine, 4) = "node" Or _
               Left(lowerLine, 5) = "frame" Or Left(lowerLine, 5) = "cloud" Or _
               Left(lowerLine, 6) = "folder" Or Left(lowerLine, 8) = "database" Then
                Dim contName, contType
                contType = Split(lowerLine)(0)
                ' Extract name, which may be quoted
                contName = ExtractNameAfterKeyword(currentLine, contType)
                If contName = "" Then
                    errMsg = "Could not parse container name on line: " & currentLine
                    ParsePlantUMLScript = False
                    Exit Function
                End If
                ' Remove trailing "{" if present
                If Right(contName, 1) = "{" Then
                    contName = Trim(Left(contName, Len(contName) - 1))
                End If
                ' Remove surrounding quotes
                If Left(contName, 1) = Chr(34) And Right(contName, 1) = Chr(34) Then
                    contName = Mid(contName, 2, Len(contName) - 2)
                End If
                ' Create or reuse package under current container
                Dim parentPkg, parentPrefix, newPkg, newPrefix, fullPkgName
                parentPkg = containerStack(containerCount)(0)
                parentPrefix = containerStack(containerCount)(1)
                fullPkgName = parentPrefix
                If fullPkgName <> "" Then fullPkgName = fullPkgName & "::"
                fullPkgName = fullPkgName & contName
                ' Check cache
                If pkgCache.Exists(fullPkgName) Then
                    Set newPkg = pkgCache(fullPkgName)
                Else
                    Set newPkg = GetOrCreatePackage(parentPkg, contName)
                    pkgCache.Add fullPkgName, newPkg
                End If
                newPrefix = fullPkgName
                ' Push onto stack
                containerCount = containerCount + 1
                ReDim Preserve containerStack(containerCount)
                containerStack(containerCount) = Array(newPkg, newPrefix)
                i = i + 1
            ' Container end
            ElseIf currentLine = "}" Then
                If containerCount > 0 Then
                    containerCount = containerCount - 1
                    ReDim Preserve containerStack(containerCount)
                End If
                i = i + 1
            ' Element declarations: abstract class
            ElseIf Left(lowerLine, 9) = "abstract " Then
                ' abstract class
                j = InStr(1, currentLine, "class", vbTextCompare)
                If j > 0 Then
                    Dim tmpLine
                    tmpLine = Trim(Mid(currentLine, j))
                    If Left(LCase(tmpLine), 5) = "class" Then
                        If Not ParseElementDeclaration(currentLine, containerStack(containerCount), elemCache, connectors, connCount, True, errMsg) Then
                            ParsePlantUMLScript = False
                            Exit Function
                        End If
                        i = i + 1
                    Else
                        i = i + 1
                    End If
                Else
                    i = i + 1
                End If
            ' Element declarations: class, interface, enum, component, bracket
            ElseIf Left(lowerLine, 7) = "class " Or Left(lowerLine, 10) = "interface " Or _
                   Left(lowerLine, 9) = "abstract " Or Left(lowerLine, 5) = "enum " Or _
                   Left(lowerLine, 9) = "component" Or Left(currentLine, 1) = "[" Then
                If Not ParseElementDeclaration(currentLine, containerStack(containerCount), elemCache, connectors, connCount, False, errMsg) Then
                    ParsePlantUMLScript = False
                    Exit Function
                End If
                ' Handle class body
                If Right(currentLine, 1) = "{" Then
                    ' Skip to find matching }
                    Dim braceDepth, bodyLines
                    braceDepth = 1
                    bodyLines = Array()
                    Do
                        i = i + 1
                        If i > UBound(cleanedLines) Then Exit Do
                        currentLine = cleanedLines(i)
                        ' Count braces
                        If InStr(currentLine, "{") > 0 Then braceDepth = braceDepth + 1
                        If InStr(currentLine, "}") > 0 Then braceDepth = braceDepth - 1
                        ' If still inside body
                        If braceDepth > 0 Then
                            ' accumulate body lines excluding comments
                            If Len(Trim(currentLine)) > 0 Then
                                Dim blIndex
                                blIndex = UBound(bodyLines) + 1
                                ReDim Preserve bodyLines(blIndex)
                                bodyLines(blIndex) = currentLine
                            End If
                        End If
                    Loop While braceDepth > 0
                    ' Process body lines for attributes and operations
                    Dim lastElem
                    lastElem = ParseLastCreatedElement(elemCache)
                    If Not lastElem Is Nothing Then
                        Call ParseClassBody(bodyLines, lastElem)
                    End If
                    ' do not increment i here: i already points to line after closing brace
                Else
                    i = i + 1
                End If
            ' Relations: look for arrow patterns.  We only support single-line relations.
            ElseIf (InStr(currentLine, "--") > 0 Or InStr(currentLine, "..") > 0) Then
                If Not ParseConnectorLine(currentLine, containerStack(containerCount), elemCache, connectors, connCount, errMsg) Then
                    ParsePlantUMLScript = False
                    Exit Function
                End If
                i = i + 1
            Else
                ' Ignore other lines
                i = i + 1
            End If
        End If
    Loop

    ' After processing all declarations, create connectors
    Dim cIdx
    For cIdx = 0 To connCount
        Dim conn
        conn = connectors(cIdx)
        Dim srcName, tgtName, cType, cDir, cLbl
        srcName = conn(0)
        tgtName = conn(1)
        cType = conn(2)
        cDir  = conn(3)
        cLbl  = conn(4)
        ' Ensure elements exist
        Dim srcElem, tgtElem
        If elemCache.Exists(srcName) Then
            Set srcElem = elemCache(srcName)
        Else
            ' attempt to find in repository using alias or name; fallback create
            Set srcElem = FindOrCreateElementByAlias(rootPackage, srcName)
            elemCache.Add srcName, srcElem
        End If
        If elemCache.Exists(tgtName) Then
            Set tgtElem = elemCache(tgtName)
        Else
            Set tgtElem = FindOrCreateElementByAlias(rootPackage, tgtName)
            elemCache.Add tgtName, tgtElem
        End If
        Call CreateConnectorIfMissing(srcElem, tgtElem, cType, cDir, cLbl)
    Next

    ParsePlantUMLScript = True
End Function

' Extract a name following a container keyword.  Handles quoted names and alias
' declarations.  For example: package "My Package" { returns My Package
Function ExtractNameAfterKeyword(ByVal line, ByVal keyword)
    Dim tmp
    tmp = Trim(Mid(line, Len(keyword) + 1))
    ' remove leading double quotes if present
    If Left(tmp, 1) = '"' Then
        Dim closing
        closing = InStr(2, tmp, '"')
        If closing > 0 Then
            ExtractNameAfterKeyword = Mid(tmp, 2, closing - 2)
            Exit Function
        End If
    End If
    ' Otherwise take up to first space or brace
    Dim parts
    parts = Split(tmp)
    If UBound(parts) >= 0 Then
        ExtractNameAfterKeyword = parts(0)
    Else
        ExtractNameAfterKeyword = tmp
    End If
End Function

' Parse an element declaration line and create or cache the element.  Accepts
' class, interface, component, enum or abstract class.  Returns True on
' success or False on failure.  If isAbstract parameter is true then an
' abstract class is forced.
Function ParseElementDeclaration(ByVal line, containerInfo, elemCache, ByRef connectors, ByRef connCount, ByVal forceAbstract, ByRef errMsg)
    Dim pkg, prefix
    pkg = containerInfo(0)
    Set pkg = containerInfo(0)
    prefix = containerInfo(1)
    Dim typeKeyword, remainder
    Dim originalLine
    originalLine = line
    line = Trim(line)
    Dim lowerLine
    lowerLine = LCase(line)
    Dim elementType
    elementType = ""
    Dim namePart, aliasPart, stereoPart
    namePart = ""
    aliasPart = ""
    stereoPart = ""
    Dim isAbstract
    isAbstract = False
    ' Determine element type
    If forceAbstract Then
        elementType = "Class"
        isAbstract = True
        ' remove "abstract" prefix from line
        Dim posClass
        posClass = InStr(1, lowerLine, "class", vbTextCompare)
        If posClass > 0 Then
            line = Trim(Mid(line, posClass))
            lowerLine = LCase(line)
        End If
    ElseIf Left(lowerLine, 9) = "abstract " Then
        isAbstract = True
        line = Trim(Mid(line, 10)) ' remove 'abstract '
        lowerLine = LCase(line)
        ' Expecting class
        If Left(lowerLine, 5) = "class" Then
            elementType = "Class"
            line = Trim(Mid(line, 6))
            lowerLine = LCase(line)
        End If
    End If
    If elementType = "" Then
        If Left(lowerLine, 7) = "class " Then
            elementType = "Class"
            line = Trim(Mid(line, 7))
            lowerLine = LCase(line)
        ElseIf Left(lowerLine, 10) = "interface " Then
            elementType = "Interface"
            line = Trim(Mid(line, 10))
            lowerLine = LCase(line)
        ElseIf Left(lowerLine, 9) = "component" Then
            elementType = "Component"
            line = Trim(Mid(line, 9))
            lowerLine = LCase(line)
        ElseIf Left(lowerLine, 5) = "enum " Then
            elementType = "Enumeration"
            line = Trim(Mid(line, 5))
            lowerLine = LCase(line)
        ElseIf Left(line, 1) = "[" Then
            elementType = "Component"
        Else
            errMsg = "Unsupported element declaration: " & originalLine
            ParseElementDeclaration = False
            Exit Function
        End If
    End If
    ' If bracket syntax
    If Left(line, 1) = "[" Then
        Dim closingBracket
        closingBracket = InStr(line, "]")
        If closingBracket = 0 Then
            errMsg = "Unmatched '[' in element declaration: " & originalLine
            ParseElementDeclaration = False
            Exit Function
        End If
        namePart = Mid(line, 2, closingBracket - 2)
        line = Trim(Mid(line, closingBracket + 1))
        ' alias may follow "as alias"
        If InStr(1, LCase(line), " as ", vbTextCompare) > 0 Then
            Dim parts
            parts = Split(line, " as ")
            aliasPart = Trim(parts(1))
        Else
            aliasPart = namePart
        End If
        ' Extract stereotype
        If InStr(line, "<<") > 0 Then
            stereoPart = ExtractStereotype(line)
        End If
    Else
        ' Normal syntax: Name [as alias] [<<stereotype>>]
        ' Name may be quoted
        If Left(line, 1) = '"' Then
            Dim endQuote
            endQuote = InStr(2, line, '"')
            If endQuote = 0 Then
                errMsg = "Missing closing quote in element name: " & originalLine
                ParseElementDeclaration = False
                Exit Function
            End If
            namePart = Mid(line, 2, endQuote - 2)
            line = Trim(Mid(line, endQuote + 1))
        Else
            ' name up to space or special
            Dim splits
            splits = Split(line)
            namePart = splits(0)
            line = Trim(Mid(line, Len(namePart) + 1))
        End If
        ' alias
        If InStr(1, LCase(line), " as ", vbTextCompare) > 0 Then
            Dim aliasParts
            aliasParts = Split(line, " as ")
            ' first element may contain stereotype; handle later
            aliasPart = Trim(aliasParts(1))
        Else
            aliasPart = namePart
        End If
        ' stereotype
        If InStr(line, "<<") > 0 Then
            stereoPart = ExtractStereotype(line)
        End If
    End If
    ' Compose full name
    Dim fullName
    fullName = prefix
    If fullName <> "" Then fullName = fullName & "::"
    fullName = fullName & aliasPart
    ' Create or find element
    Dim elem
    If elemCache.Exists(fullName) Then
        Set elem = elemCache(fullName)
    Else
        Set elem = GetOrCreateElement(pkg, namePart, elementType, stereoPart, aliasPart, isAbstract)
        elemCache.Add fullName, elem
    End If
    ParseElementDeclaration = True
End Function

' Extract stereotype enclosed in << >> from a line
Function ExtractStereotype(ByVal line)
    Dim startPos, endPos
    startPos = InStr(line, "<<")
    endPos = InStr(line, ">>")
    If startPos > 0 And endPos > startPos Then
        ExtractStereotype = Mid(line, startPos + 2, endPos - startPos - 2)
    Else
        ExtractStereotype = ""
    End If
End Function

' Parse a class body comprised of attribute/operation definitions and create
' corresponding attributes and operations on the given EA element.  Each line
' should be raw from the PlantUML script.
Sub ParseClassBody(ByVal bodyLines, ByVal elem)
    Dim k, line, trimmedLine
    For k = 0 To UBound(bodyLines)
        line = bodyLines(k)
        trimmedLine = Trim(line)
        If Len(trimmedLine) = 0 Then
            ' skip empty line
        ElseIf Left(trimmedLine, 2) = "//" Or Left(trimmedLine, 1) = Chr(39) Then
            ' skip comment line
        Else
            ' Determine visibility based on prefix + - # ~ (public, private, protected, package)
            Dim vis
            vis = "Public"
            Dim firstChar
            firstChar = Left(trimmedLine, 1)
            If firstChar = "+" Then
                vis = "Public"
                trimmedLine = Trim(Mid(trimmedLine, 2))
            ElseIf firstChar = "-" Then
                vis = "Private"
                trimmedLine = Trim(Mid(trimmedLine, 2))
            ElseIf firstChar = "#" Then
                vis = "Protected"
                trimmedLine = Trim(Mid(trimmedLine, 2))
            ElseIf firstChar = "~" Then
                vis = "Package"
                trimmedLine = Trim(Mid(trimmedLine, 2))
            End If
            ' Distinguish between attribute and operation by presence of parentheses
            If InStr(trimmedLine, "(") > 0 Then
                ' Operation
                Call ParseOperation(trimmedLine, elem, vis)
            Else
                ' Attribute
                Call ParseAttribute(trimmedLine, elem, vis)
            End If
        End If
    Next
End Sub

' Parse a single attribute definition and create the EA attribute.  Accepts
' syntax: name : type {modifier}
Sub ParseAttribute(ByVal defLine, ByVal elem, ByVal visibility)
    Dim parts, name, typeSpec, modifier
    parts = Split(defLine, ":")
    name = Trim(parts(0))
    If UBound(parts) >= 1 Then
        ' type part may include modifiers in {...}
        typeSpec = Trim(parts(1))
        If InStr(typeSpec, "{") > 0 Then
            modifier = Mid(typeSpec, InStr(typeSpec, "{") + 1, InStr(typeSpec, "}") - InStr(typeSpec, "{") - 1)
            typeSpec = Trim(Left(typeSpec, InStr(typeSpec, "{") - 1))
        End If
    Else
        typeSpec = ""
        modifier = ""
    End If
    ' Determine static from modifier
    Dim isStatic
    isStatic = False
    If LCase(modifier) = "static" Then isStatic = True
    ' Check existing attribute
    Dim att, found
    found = False
    For Each att In elem.Attributes
        If att.Name = name Then
            found = True
            Exit For
        End If
    Next
    If Not found Then
        Dim newAtt
        Set newAtt = elem.Attributes.AddNew(name, typeSpec)
        newAtt.Visibility = visibility
        newAtt.IsStatic = isStatic
        newAtt.Update
        elem.Attributes.Refresh
    End If
End Sub

' Parse a single operation definition and create the EA operation.  Accepts
' syntax: name(params) : returnType {modifier}
Sub ParseOperation(ByVal defLine, ByVal elem, ByVal visibility)
    Dim namePart, paramsPart, retPart, modifier
    ' Split on parentheses
    Dim openPos, closePos
    openPos = InStr(defLine, "(")
    closePos = InStr(defLine, ")")
    If openPos = 0 Or closePos = 0 Or closePos < openPos Then Exit Sub
    namePart = Trim(Left(defLine, openPos - 1))
    paramsPart = Mid(defLine, openPos + 1, closePos - openPos - 1)
    retPart = ""
    modifier = ""
    If InStr(closePos + 1, defLine, ":") > 0 Then
        Dim colonPos
        colonPos = InStr(closePos + 1, defLine, ":")
        retPart = Trim(Mid(defLine, colonPos + 1))
        ' Check for modifier
        If InStr(retPart, "{") > 0 Then
            modifier = Mid(retPart, InStr(retPart, "{") + 1, InStr(retPart, "}") - InStr(retPart, "{") - 1)
            retPart = Trim(Left(retPart, InStr(retPart, "{") - 1))
        End If
    End If
    ' Determine static and abstract from modifier
    Dim isStatic, isAbstract
    isStatic = False
    isAbstract = False
    If LCase(modifier) = "static" Then isStatic = True
    If LCase(modifier) = "abstract" Then isAbstract = True
    ' Check existing operation
    Dim op, found
    found = False
    For Each op In elem.Methods
        If op.Name = namePart Then
            found = True
            Exit For
        End If
    Next
    If Not found Then
        Dim newOp
        Set newOp = elem.Methods.AddNew(namePart, "")
        newOp.Visibility = visibility
        newOp.IsStatic = isStatic
        newOp.Abstract = isAbstract
        If retPart <> "" Then newOp.ReturnType = retPart
        ' Parse parameters
        Dim params
        params = Split(paramsPart, ",")
        Dim p
        For p = 0 To UBound(params)
            Dim paramDef, pName, pType
            paramDef = Trim(params(p))
            If paramDef <> "" Then
                If InStr(paramDef, ":") > 0 Then
                    pName = Trim(Left(paramDef, InStr(paramDef, ":") - 1))
                    pType = Trim(Mid(paramDef, InStr(paramDef, ":") + 1))
                Else
                    pName = paramDef
                    pType = ""
                End If
                Dim newPar
                Set newPar = newOp.Parameters.AddNew(pName, pType)
                newPar.Update
            End If
        Next
        newOp.Update
        elem.Methods.Refresh
    End If
End Sub

' Parse a single relation line into a connector definition.  Recognises
' patterns with --, .., *--, o--, <|--, ..|>, etc.  Populates the connectors
' array by reference.  Returns True on success.
Function ParseConnectorLine(ByVal line, containerInfo, elemCache, ByRef connectors, ByRef connCount, ByRef errMsg)
    Dim prefix
    prefix = containerInfo(1)
    ' PlantUML relations may include labels and qualifiers.  Use regex-like parsing.
    ' We attempt to split around the arrow token.
    Dim arrowTokens
    arrowTokens = Array("<|--", "--|>", "*--", "--*", "o--", "--o", "..|>", "<|..", "<--", "-->", "..>", "<..", "--")
    Dim foundToken, token
    foundToken = ""
    For Each token In arrowTokens
        If InStr(line, token) > 0 Then
            foundToken = token
            Exit For
        End If
    Next
    If foundToken = "" Then
        errMsg = "Could not determine relation type in line: " & line
        ParseConnectorLine = False
        Exit Function
    End If
    Dim parts
    parts = Split(line, foundToken)
    If UBound(parts) <> 1 Then
        errMsg = "Invalid relation definition: " & line
        ParseConnectorLine = False
        Exit Function
    End If
    Dim leftPart, rightPart
    leftPart = Trim(parts(0))
    rightPart = Trim(parts(1))
    ' Extract names and optional labels/qualifiers
    Dim leftName, rightName, label
    label = ""
    leftName = ParseRelationEndName(leftPart)
    rightName = ParseRelationEndName(rightPart)
    ' Extract label after ':' if present
    If InStr(rightPart, ":") > 0 Then
        Dim lblParts
        lblParts = Split(rightPart, ":")
        rightName = ParseRelationEndName(Trim(lblParts(0)))
        label = Trim(lblParts(1))
    End If
    ' Compose full names using current prefix unless name already contains ::
    Dim leftFull, rightFull
    If InStr(leftName, "::") > 0 Then
        leftFull = leftName
    Else
        If prefix <> "" Then leftFull = prefix & "::" & leftName Else leftFull = leftName
    End If
    If InStr(rightName, "::") > 0 Then
        rightFull = rightName
    Else
        If prefix <> "" Then rightFull = prefix & "::" & rightName Else rightFull = rightName
    End If
    ' Determine connector type and direction
    Dim cType, cDir
    Select Case foundToken
        Case "<|--", "--|>"
            cType = "Generalization"
            If foundToken = "<|--" Then cDir = "TargetToSource" Else cDir = "SourceToTarget"
        Case "*--", "--*"
            cType = "Composition"
            If foundToken = "*--" Then cDir = "SourceToTarget" Else cDir = "TargetToSource"
        Case "o--", "--o"
            cType = "Aggregation"
            If foundToken = "o--" Then cDir = "SourceToTarget" Else cDir = "TargetToSource"
        Case "..|>", "<|.."
            cType = "Realisation"
            If foundToken = "..|>" Then cDir = "SourceToTarget" Else cDir = "TargetToSource"
        Case "<--", "-->"
            cType = "Dependency"
            If foundToken = "-->" Then
                cDir = "SourceToTarget"
            Else
                cDir = "TargetToSource"
            End If
        Case "..>", "<.."
            cType = "Dependency"
            If foundToken = "..>" Then cDir = "SourceToTarget" Else cDir = "TargetToSource"
        Case "--"
            cType = "Association"
            cDir = "Unspecified"
        Case Else
            cType = "Association"
            cDir = "Unspecified"
    End Select
    ' Add to connectors array
    connCount = connCount + 1
    ReDim Preserve connectors(connCount)
    connectors(connCount) = Array(leftFull, rightFull, cType, cDir, label)
    ParseConnectorLine = True
End Function

' Parse a relation end, stripping quotes and cardinalities.  Returns the alias/name.
Function ParseRelationEndName(ByVal part)
    ' Remove cardinalities enclosed in quotes e.g. "1" or "0..*"
    Dim tmp
    tmp = part
    If Left(tmp, 1) = Chr(34) Then
        ' cardinality or quoted name
        Dim secondQuote
        secondQuote = InStr(2, tmp, Chr(34))
        If secondQuote > 0 Then
            tmp = Trim(Mid(tmp, secondQuote + 1))
        End If
    End If
    ' Remove any trailing cardinality on right side
    If InStr(tmp, Chr(34)) > 0 Then
        Dim lastQuote
        lastQuote = InStrRev(tmp, Chr(34))
        If lastQuote > 0 Then
            tmp = Trim(Left(tmp, lastQuote - 1))
        End If
    End If
    ' If alias is specified using "as"
    If InStr(1, LCase(tmp), " as ", vbTextCompare) > 0 Then
        Dim parts
        parts = Split(tmp, " as ")
        ParseRelationEndName = Trim(parts(1))
    Else
        ParseRelationEndName = Trim(tmp)
    End If
End Function

' Retrieve the last created element from the element cache.  Assumes insertion order.
Function ParseLastCreatedElement(elemCache)
    Dim key
    For Each key In elemCache
        ' intentionally empty; loop yields last key
    Next
    If key <> "" Then
        Set ParseLastCreatedElement = elemCache(key)
    Else
        Set ParseLastCreatedElement = Nothing
    End If
End Function

' Create or reuse a package with the specified name under the parent package.
' Returns the package object.
Function GetOrCreatePackage(ByVal parentPkg, ByVal name)
    Dim subPkg
    For Each subPkg In parentPkg.Packages
        If subPkg.Name = name Then
            Set GetOrCreatePackage = subPkg
            Exit Function
        End If
    Next
    Set subPkg = parentPkg.Packages.AddNew(name, "Package")
    subPkg.Update
    parentPkg.Packages.Refresh
    Set GetOrCreatePackage = subPkg
End Function

' Create or reuse an element with the specified properties.  Returns the element.
Function GetOrCreateElement(ByVal parentPkg, ByVal name, ByVal type, ByVal stereotype, ByVal aliasName, ByVal isAbstract)
    Dim elem
    For Each elem In parentPkg.Elements
        If elem.Name = name And elem.Type = type Then
            ' update alias/stereotype/abstract if missing
            If aliasName <> "" Then elem.Alias = aliasName
            If stereotype <> "" Then elem.Stereotype = stereotype
            If isAbstract Then elem.Abstract = "1" Else elem.Abstract = "0"
            elem.Update
            Set GetOrCreateElement = elem
            Exit Function
        End If
    Next
    Set elem = parentPkg.Elements.AddNew(name, type)
    elem.Alias = aliasName
    If stereotype <> "" Then elem.Stereotype = stereotype
    If isAbstract Then elem.Abstract = "1" Else elem.Abstract = "0"
    elem.Update
    parentPkg.Elements.Refresh
    Set GetOrCreateElement = elem
End Function

' Find an element anywhere under the root package by matching alias or name.
' If not found, creates a component under the root package with the given name.
Function FindOrCreateElementByAlias(ByVal rootPkg, ByVal aliasName)
    Dim foundElem
    Set foundElem = Nothing
    ' Depth-first search
    Set foundElem = SearchElementInPackage(rootPkg, aliasName)
    If Not foundElem Is Nothing Then
        Set FindOrCreateElementByAlias = foundElem
        Exit Function
    End If
    ' Create under root if not found
    Set foundElem = rootPkg.Elements.AddNew(aliasName, "Component")
    foundElem.Alias = aliasName
    foundElem.Update
    rootPkg.Elements.Refresh
    Set FindOrCreateElementByAlias = foundElem
End Function

' Recursively search for an element with the given alias or name in a package.
Function SearchElementInPackage(ByVal pkg, ByVal aliasOrName)
    Dim elem, subPkg, result
    For Each elem In pkg.Elements
        If elem.Alias = aliasOrName Or elem.Name = aliasOrName Then
            Set SearchElementInPackage = elem
            Exit Function
        End If
    Next
    For Each subPkg In pkg.Packages
        Set result = SearchElementInPackage(subPkg, aliasOrName)
        If Not result Is Nothing Then
            Set SearchElementInPackage = result
            Exit Function
        End If
    Next
    Set SearchElementInPackage = Nothing
End Function

' Create a connector between source and target if one does not already exist.  The
' connector type is mapped from PlantUML to EA connector type string.  The
' direction is either SourceToTarget, TargetToSource or Unspecified.
Sub CreateConnectorIfMissing(ByVal sourceElem, ByVal targetElem, ByVal cType, ByVal cDir, ByVal label)
    Dim conn
    For Each conn In sourceElem.Connectors
        If conn.SupplierID = targetElem.ElementID And conn.Type = cType Then
            ' Already exists
            Exit Sub
        End If
    Next
    Dim newConn
    Set newConn = sourceElem.Connectors.AddNew(label, cType)
    ' Explicitly set client and supplier IDs
    newConn.ClientID = sourceElem.ElementID
    newConn.SupplierID = targetElem.ElementID
    Select Case cDir
        Case "SourceToTarget"
            newConn.Direction = "Source -> Destination"
        Case "TargetToSource"
            newConn.Direction = "Destination -> Source"
        Case Else
            newConn.Direction = "Unspecified"
    End Select
    newConn.Update
    sourceElem.Connectors.Refresh
End Sub
