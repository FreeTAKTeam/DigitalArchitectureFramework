option explicit

'
' Script Name: M3 Normalize Legacy Concept Property Types
' Purpose:
'   Normalize legacy DAF M3 Concept property types.
'
'   For every Attribute owned by an M3 element stereotyped "Concept":
'
'       empty type  -> String
'       "void"      -> String
'       "int"       -> String      (legacy "not set" convention)
'       "Integer"   -> Int32
'       property name starts with "is" -> Boolean
'           This rule takes precedence over the existing type/classifier.
'
'   The script recursively traverses the configured DAF metamodel package.
'
' Date: 2026 / 08 / 07
' Version: 1.2.0
'
' Configuration:
'   Uses metamodelPackageGUID from:
'       DAF MDG.DAF M3 Conf
'
' Notes:
'   - Only M3::Concept elements are modified.
'   - Attributes with an explicit ClassifierID are normally NOT modified.
'   - Exception: properties whose name starts with "is" are forced to the
'     primitive UML2 Boolean type; any classifier reference is cleared.
'   - Attribute GUIDs, names, multiplicities, defaults, stereotypes and notes
'     are preserved.
'   - Changes are written directly to the EA repository.
'

!INC Local Scripts.EAConstants-VBScript
!INC DAF MDG.DAF M3 Conf

const SCRIPT_NAME = "M3 Normalize Legacy Concept Property Types"
const SCRIPT_VERSION = "1.2.0"

dim inspectedConceptCount
dim inspectedAttributeCount
dim changedToStringCount
dim changedToInt32Count
dim changedToBooleanCount
dim alreadyBooleanCount
dim clearedClassifierForBooleanCount
dim skippedClassifierCount
dim failedUpdateCount

sub main()

    dim metamodelPackage as EA.Package

    inspectedConceptCount = 0
    inspectedAttributeCount = 0
    changedToStringCount = 0
    changedToInt32Count = 0
    changedToBooleanCount = 0
    alreadyBooleanCount = 0
    clearedClassifierForBooleanCount = 0
    skippedClassifierCount = 0
    failedUpdateCount = 0

    Session.Output "============================================================"
    Session.Output SCRIPT_NAME & " v" & SCRIPT_VERSION
    Session.Output "============================================================"
    Session.Output "Metamodel package GUID: " & metamodelPackageGUID
    Session.Output ""
    Session.Output "Conversions:"
    Session.Output "  <empty> -> String"
    Session.Output "  void    -> String"
    Session.Output "  int     -> String"
    Session.Output "  Integer -> Int32"
    Session.Output "  name starts with is -> Boolean (highest precedence)"
    Session.Output ""

    set metamodelPackage = Repository.GetPackageByGuid(metamodelPackageGUID)

    if metamodelPackage is nothing then
        Session.Output "ERROR: Cannot find configured metamodel package: " & metamodelPackageGUID
        exit sub
    end if

    Repository.EnableUIUpdates = false

    normalizePackage metamodelPackage

    Repository.EnableUIUpdates = true
    Repository.RefreshModelView metamodelPackage.PackageID

    Session.Output ""
    Session.Output "============================================================"
    Session.Output "NORMALIZATION COMPLETE"
    Session.Output "============================================================"
    Session.Output "M3 Concept classes inspected:           " & inspectedConceptCount
    Session.Output "Concept properties inspected:           " & inspectedAttributeCount
    Session.Output "Changed to String:                      " & changedToStringCount
    Session.Output "Changed Integer -> Int32:               " & changedToInt32Count
    Session.Output "Changed is* properties -> Boolean:      " & changedToBooleanCount
    Session.Output "Already-valid is* Boolean properties:   " & alreadyBooleanCount
    Session.Output "Classifier references cleared for is*: " & clearedClassifierForBooleanCount
    Session.Output "Skipped due to explicit ClassifierID:   " & skippedClassifierCount
    Session.Output "Failed attribute updates:               " & failedUpdateCount
    Session.Output ""

    if failedUpdateCount > 0 then
        Session.Output "RESULT: COMPLETED WITH UPDATE ERRORS."
    else
        Session.Output "RESULT: SUCCESS."
    end if

end sub


sub normalizePackage(pkg)

    dim element as EA.Element
    dim childPackage as EA.Package

    for each element in pkg.Elements
        if isM3Concept(element) then
            normalizeConcept element
        end if
    next

    for each childPackage in pkg.Packages
        normalizePackage childPackage
    next

end sub


sub normalizeConcept(concept)

    dim attribute as EA.Attribute

    inspectedConceptCount = inspectedConceptCount + 1

    Session.Output "Inspecting Concept: " & humanReadableElementName(concept) _
        & " [DAF name=" & concept.Name & ", GUID=" & concept.ElementGUID & "]"

    for each attribute in concept.Attributes
        normalizeAttribute concept, attribute
    next

    concept.Attributes.Refresh

end sub


sub normalizeAttribute(owner, attribute)

    dim currentType
    dim normalizedType
    dim oldTypeDisplay
    dim targetType

    inspectedAttributeCount = inspectedAttributeCount + 1

    currentType = Trim(CStr(attribute.Type))
    normalizedType = LCase(currentType)
    targetType = ""

    if currentType = "" then
        oldTypeDisplay = "<empty>"
    else
        oldTypeDisplay = currentType
    end if

    '
    ' Naming convention rule:
    ' Every Concept property whose name starts with "is" is a Boolean.
    '
    ' This rule intentionally takes precedence over any existing textual type
    ' or classifier-based type. A primitive UML2 Boolean must not retain a
    ' ClassifierID, because ClassifierID denotes a non-primitive classifier.
    '
    if startsWithIs(attribute.Name) then

        if LCase(Trim(CStr(attribute.Type))) = "boolean" _
            and attribute.ClassifierID = 0 then

            alreadyBooleanCount = alreadyBooleanCount + 1

        else

            Session.Output "  BOOLEAN: " & attribute.Name _
                & " [GUID=" & attribute.AttributeGUID & "]" _
                & " : " & oldTypeDisplay & " -> Boolean" _
                & classifierChangeText(attribute.ClassifierID)

            if attribute.ClassifierID > 0 then
                attribute.ClassifierID = 0
                clearedClassifierForBooleanCount = clearedClassifierForBooleanCount + 1
            end if

            attribute.Type = "Boolean"

            if attribute.Update then
                changedToBooleanCount = changedToBooleanCount + 1
            else
                failedUpdateCount = failedUpdateCount + 1

                Session.Output "  ERROR: EA failed to update Boolean property " _
                    & owner.Name & "." & attribute.Name _
                    & " [GUID=" & attribute.AttributeGUID & "]"
            end if

        end if

        exit sub
    end if

    '
    ' Explicit classifier-based typing takes precedence over the legacy
    ' textual type field.
    '
    if attribute.ClassifierID > 0 then

        if normalizedType = "" _
            or normalizedType = "void" _
            or normalizedType = "int" _
            or normalizedType = "integer" then

            skippedClassifierCount = skippedClassifierCount + 1

            Session.Output "  SKIP: " & attribute.Name _
                & " [GUID=" & attribute.AttributeGUID & "]" _
                & " has legacy textual type '" & oldTypeDisplay & "'" _
                & " but has explicit ClassifierID=" & attribute.ClassifierID
        end if

        exit sub
    end if

    '
    ' Legacy "not set" values.
    '
    if normalizedType = "" _
        or normalizedType = "void" _
        or normalizedType = "int" then

        targetType = "String"

    '
    ' Legacy integer primitive.
    '
    elseif normalizedType = "integer" then

        targetType = "Int32"

    end if

    if targetType <> "" then

        Session.Output "  CHANGE: " & attribute.Name _
            & " [GUID=" & attribute.AttributeGUID & "]" _
            & " : " & oldTypeDisplay & " -> " & targetType

        attribute.Type = targetType

        if attribute.Update then

            if targetType = "String" then
                changedToStringCount = changedToStringCount + 1
            elseif targetType = "Int32" then
                changedToInt32Count = changedToInt32Count + 1
            end if

        else
            failedUpdateCount = failedUpdateCount + 1

            Session.Output "  ERROR: EA failed to update attribute " _
                & owner.Name & "." & attribute.Name _
                & " [GUID=" & attribute.AttributeGUID & "]"
        end if

    end if

end sub



function startsWithIs(propertyName)

    dim n
    n = LCase(Trim(CStr(propertyName)))

    startsWithIs = (Len(n) >= 2 and Left(n, 2) = "is")

end function


function classifierChangeText(classifierID)

    if classifierID > 0 then
        classifierChangeText = " ; ClassifierID " & CStr(classifierID) & " -> 0"
    else
        classifierChangeText = ""
    end if

end function

function isM3Concept(element)

    dim stereotypeName
    stereotypeName = LCase(Trim(CStr(element.Stereotype)))

    isM3Concept = (stereotypeName = "concept" _
        or stereotypeName = "m3::concept")

end function


function humanReadableElementName(element)

    if Trim(CStr(element.Alias)) <> "" then
        humanReadableElementName = element.Alias
    else
        humanReadableElementName = element.Name
    end if

end function


main
