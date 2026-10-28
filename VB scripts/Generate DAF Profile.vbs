option explicit
 '  DO NOT USE
' Script Name: UML profile configuration
' Author:  Giu Platania
' Purpose: Scripts to transform metamodel into UML Profile, create classes for toolboxes (elements and relationships
' generates the quicklink file and a list of packages named after the stereotypes to be used as "TOGAF catalogs".
' generates toolboxes
' generate SQL queries ('' create a SQL script that check for required but missing relationships)
' generate CSV import
' generate tagged value query
' generate a list of packages GUID and associated stereotypes
' strip
' last review Date: 2025 / 01 / 21
' Version: 6.20250121
 '
 ' USAGE:
 ' this is the companion script to the M3 MdG technology
'    Create a package called Metamodel or use the template
'    customize the the GUID of the Metamodel package, UML profile , Tolboxes classes and connectors in the script "Configuration"
'    create a M3 diagram or use the template
'	 use the M3 toolbox to create *Concepts*
'    in alternative  add the tagged values 'Metaclass' and 'Redefines' to regular UML classes. The tagged values are case sensitive (!) 
'    script will add a _metaype property automatically
 '   script will add a _strictness property automatically. it defines the degree to which a stereotyped element can have more than one stereotype applied to it.
 '   (if required) add the refines tag e.g. "ArchiMate3::Archimate_BusinessProcess" /
 '   Create relationships using the *relationship* connector . You can also use an UML::association and add the tags the UML type is only cosmetic because is defined in the "metaclass" tagged value. 
 ' 	Aggregation in the profile is always placed at the *source End* of the relationship / UML::association, ignoring the model. 
 '   Create a package called like your target language with the stereotype "profile" or use the template
 '   customize the the GUId of the Metamodel package in the configuration script
 '   inside the Stereotype package create a document called "QuickLink" or use the template
 ' 	Copy the provided M3 configuration script in a new script
 '   Customize the target folder in the configuration script for the quicklink document output
 '   Execute the script Generate UML profile
 
!INC Local Scripts.EAConstants-VBScript
!INC DAF MDG.Model Management Utilities
!INC DAF MDG.DAF M3 Conf
!INC Wrappers.Include

const STREAM_FOR_READING = 1
const STREAM_FOR_WRITING = 2
const STREAM_FOR_APPENDING = 3

dim profilePackage 			as EA.Package
dim relationshipPackage		as EA.Package
dim stereotypePackage		as EA.Package
dim metaclassPackage		as EA.Package
dim enumerationPackage		as EA.Package
dim quickLinkFileStream	   'as Scripting.TextStream
dim CSVImportString 		' as place where to store packages GUIDs and stereotypes
dim toolboxClass 	as EA.Element
dim toolboxConnector as EA.Element

' lookup tables built once per run, so the profile is never scanned element by element
dim profileIndexByGuid	' Package_ID & ":" & Metamodel GUID -> profile Object_ID
dim profileGuidAnywhere	' Metamodel GUID -> profile Object_ID in any indexed package
dim profileIndexByName	' Package_ID & ":" & Name -> profile Object_ID
dim profileLinkedIDs	' profile Object_ID -> Metamodel GUID tag it carried at start
dim profileTouched		' profile Object_IDs matched or created in this run
dim attributeSourceGuid	' profile attribute ID -> Metamodel GUID of the source attribute
dim renameMap			' new name -> old name, from RenameMappingFile
dim metamodelElementCache ' metamodel Element ID -> EA.Element
dim metaclassCache		' metamodel Element ID -> Metaclass tag value
' the UML profile is saved from this diagram, so every stereotype, metaclass and enumeration must be on it
dim profileDiagram			as EA.Diagram
dim profileDiagramIndex	' Element ID -> true for elements on the profile diagram
dim diagramSlotLeft, diagramSlotTop, diagramRowBottom ' next free place for a new element, below the existing content

sub transformPackageGUID( metamodelPackageGUID, profilePackageGUID, fileName)

	dim metamodelPackage 	as EA.Package
		Repository.EnableUIUpdates = false
		quickLinkFileName = fileName
		createQuickLinkFile
		' initialize  the import file variable
		CSVImportString = "stereotype, GUID"

	set profilePackage = Repository.GetPackageByGuid( profilePackageGUID)
	set metamodelPackage = Repository.GetPackageByGuid( metamodelPackageGUID)
	set relationshipPackage = Repository.GetPackageByGuid( relationshipPackageGUID)
	set stereotypePackage = getTargetPackage( stereotypePackageGUID)
	set metaclassPackage = getTargetPackage( metaclassPackageGUID)
	set enumerationPackage = getTargetPackage( enumerationPackageGUID)
	set toolboxClass = Repository.GetElementByGuid(ProfileToolboxClassGUID)
	set toolboxConnector = Repository.GetElementByGuid(ProfileToolboxConnectorGUID)
	loadRenameMap
	buildProfileIndex
	buildProfileDiagramIndex
	cleanToolboxAttributes toolboxClass
	cleanToolboxAttributes toolboxConnector
	transformPackage metamodelPackage
	toolboxClass.Attributes.Refresh
	toolboxConnector.Attributes.Refresh
	handleUnmatchedStereotypes
	quickLinkFileStream.Close
	updateQuickLinkDocument
	' write import string to file
	writeCSVImportFile(CSVImportString)
		
		
	Repository.RefreshModelView profilePackage.PackageID
	if not profileDiagram is nothing then Repository.ReloadDiagram profileDiagram.DiagramID
	Repository.EnableUIUpdates = true
	Session.Output "Done at " & Now()
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' PROFILE INDEX AND MATCHING
'''''''''''''''''''''''

' a per-type target package from the configuration; the profile package when not configured
function getTargetPackage( packageGUID)
	set getTargetPackage = profilePackage
	if packageGUID <> "" then set getTargetPackage = Repository.GetPackageByGuid( packageGUID)
end function

' run a query and return its rows as an XML node list
function sqlRows( sqlString)
	dim xmlDoc
	set xmlDoc = CreateObject( "Microsoft.XMLDOM")
	xmlDoc.LoadXml Repository.SQLQuery( sqlString)
	set sqlRows = xmlDoc.SelectNodes( "/EADATA/Dataset_0/Data/Row")
end function

' column names come back in different case depending on the database
function rowValue( row, columnName)
	dim node
	rowValue = ""
	for each node in row.ChildNodes
		if LCase( node.NodeName) = columnName then
			rowValue = node.Text
			exit for
		end if
	next
end function

' read "oldName,newName" lines; lines starting with # are comments
sub loadRenameMap
	dim fileSysObj, stream, textLine, parts
	set renameMap = CreateObject( "Scripting.Dictionary")
	if RenameMappingFile = "" then exit sub
	set fileSysObj = CreateObject( "Scripting.FileSystemObject")
	if not fileSysObj.FileExists( RenameMappingFile) then
		Session.Output "WARNING: rename mapping file not found: " & RenameMappingFile
		exit sub
	end if
	set stream = fileSysObj.OpenTextFile( RenameMappingFile, STREAM_FOR_READING)
	do until stream.AtEndOfStream
		textLine = Trim( stream.ReadLine)
		parts = Split( textLine, ",")
		if Left( textLine, 1) <> "#" and UBound( parts) = 1 then
			renameMap( Trim( parts(1))) = Trim( parts(0))
		end if
	loop
	stream.Close
	Session.Output "Loaded " & renameMap.Count & " rename mappings"
end sub

' index every stereotype and enumeration of the profile and its target packages, with their Metamodel GUID tags
sub buildProfileIndex
	dim row, objectID, guid, packageIDs
	set profileIndexByGuid = CreateObject( "Scripting.Dictionary")
	set profileGuidAnywhere = CreateObject( "Scripting.Dictionary")
	set profileIndexByName = CreateObject( "Scripting.Dictionary")
	set profileLinkedIDs = CreateObject( "Scripting.Dictionary")
	set profileTouched = CreateObject( "Scripting.Dictionary")
	set attributeSourceGuid = CreateObject( "Scripting.Dictionary")
	set metamodelElementCache = CreateObject( "Scripting.Dictionary")
	set metaclassCache = CreateObject( "Scripting.Dictionary")
	packageIDs = profilePackage.PackageID & "," & relationshipPackage.PackageID & "," & stereotypePackage.PackageID & "," & enumerationPackage.PackageID

	for each row in sqlRows( "SELECT o.Object_ID AS oid, o.Name AS oname, o.Package_ID AS pid, tv.Value AS mmguid" & _
			" FROM t_object o LEFT JOIN t_objectproperties tv ON (tv.Object_ID = o.Object_ID AND tv.Property = 'Metamodel GUID')" & _
			" WHERE o.Package_ID IN (" & packageIDs & ") AND (o.Stereotype = 'stereotype' OR o.Object_Type = 'Enumeration')")
		objectID = CLng( rowValue( row, "oid"))
		profileIndexByName( rowValue( row, "pid") & ":" & rowValue( row, "oname")) = objectID
		guid = rowValue( row, "mmguid")
		if guid <> "" then
			profileIndexByGuid( rowValue( row, "pid") & ":" & guid) = objectID
			profileGuidAnywhere( guid) = objectID
			profileLinkedIDs( objectID) = guid
		end if
	next

	for each row in sqlRows( "SELECT t.ElementID AS aid, t.VALUE AS mmguid" & _
			" FROM (t_attributetag t INNER JOIN t_attribute a ON a.ID = t.ElementID) INNER JOIN t_object o ON o.Object_ID = a.Object_ID" & _
			" WHERE t.Property = 'Metamodel GUID' AND o.Package_ID IN (" & packageIDs & ")")
		attributeSourceGuid( CLng( rowValue( row, "aid"))) = rowValue( row, "mmguid")
	next
	Session.Output "Indexed " & profileIndexByName.Count & " profile stereotypes, " & profileLinkedIDs.Count & " linked by Metamodel GUID"
end sub

' find the profile element for a metamodel item in its target package: same name (unlinked or linked to this GUID),
' then Metamodel GUID, then Metamodel GUID in another profile package (moved here), then old name from the rename mapping.
' Renames a match whose name differs, creates the element when nothing matches.
' A second copy linked to the same GUID stays unmatched and ends up in the Obsolete package.
function resolveProfileElement( metamodelGUID, profileName, package, elementType)
	dim objectID, nameKey, oldKey
	dim profileElement as EA.Element
	objectID = 0
	nameKey = package.PackageID & ":" & profileName
	if profileIndexByName.Exists( nameKey) then
		objectID = profileIndexByName( nameKey)
		if profileLinkedIDs.Exists( objectID) then
			if profileLinkedIDs( objectID) <> metamodelGUID then objectID = 0
		end if
	end if
	if objectID = 0 and metamodelGUID <> "" then
		if profileIndexByGuid.Exists( package.PackageID & ":" & metamodelGUID) then
			objectID = profileIndexByGuid( package.PackageID & ":" & metamodelGUID)
		elseif profileGuidAnywhere.Exists( metamodelGUID) then
			objectID = profileGuidAnywhere( metamodelGUID)
			if profileTouched.Exists( objectID) then objectID = 0
		end if
	end if
	if objectID = 0 and renameMap.Exists( profileName) then
		oldKey = package.PackageID & ":" & renameMap( profileName)
		if profileIndexByName.Exists( oldKey) then objectID = profileIndexByName( oldKey)
	end if

	if objectID = 0 then
		set profileElement = package.Elements.AddNew( profileName, elementType)
		if elementType = "Class" then profileElement.Stereotype = "stereotype"
		profileElement.Update
		Session.Output "  created " & elementType & " '" & profileName & "'"
	else
		set profileElement = Repository.GetElementByID( objectID)
		if profileElement.PackageID <> package.PackageID then moveProfileElement profileElement, package
		if profileElement.Name <> profileName then renameProfileElement profileElement, profileName
	end if
	profileIndexByName( profileElement.PackageID & ":" & profileElement.Name) = profileElement.ElementID
	if metamodelGUID <> "" then
		profileIndexByGuid( profileElement.PackageID & ":" & metamodelGUID) = profileElement.ElementID
		profileGuidAnywhere( metamodelGUID) = profileElement.ElementID
	end if
	profileTouched( profileElement.ElementID) = true
	if elementType = "Class" then ensureOnProfileDiagram profileElement
	set resolveProfileElement = profileElement
end function

'''''''''''''''''''''''
'''''''''''''''''''''' PROFILE DIAGRAM
'''''''''''''''''''''''

sub buildProfileDiagramIndex
	dim diagramObject	as EA.DiagramObject
	set profileDiagramIndex = CreateObject( "Scripting.Dictionary")
	set profileDiagram = nothing
	if ProfileDiagramGUID <> "" then set profileDiagram = Repository.GetDiagramByGuid( ProfileDiagramGUID)
	if profileDiagram is nothing then
		Session.Output "WARNING: profile diagram " & ProfileDiagramGUID & " not found, new stereotypes are not placed on it"
		exit sub
	end if
	diagramRowBottom = 0
	for each diagramObject in profileDiagram.DiagramObjects
		profileDiagramIndex( diagramObject.ElementID) = true
		if diagramObject.Bottom < diagramRowBottom then diagramRowBottom = diagramObject.Bottom
	next
	' new elements go in rows below everything already on the diagram (EA stores top and bottom as negative values)
	diagramSlotLeft = 20
	diagramSlotTop = -diagramRowBottom + 80
	diagramRowBottom = diagramSlotTop
end sub

' add the element to the profile diagram in the next free place, unless it is already there
sub ensureOnProfileDiagram( element)
	dim diagramObject	as EA.DiagramObject
	dim height
	if profileDiagram is nothing then exit sub
	if profileDiagramIndex.Exists( element.ElementID) then exit sub
	height = 50 + 16 * element.Attributes.Count
	if diagramSlotLeft > 7000 then
		diagramSlotLeft = 20
		diagramSlotTop = diagramRowBottom + 30
	end if
	set diagramObject = profileDiagram.DiagramObjects.AddNew( "l=" & diagramSlotLeft & ";r=" & ( diagramSlotLeft + 180) & ";t=" & diagramSlotTop & ";b=" & ( diagramSlotTop + height) & ";", "")
	diagramObject.ElementID = element.ElementID
	diagramObject.Update
	profileDiagramIndex( element.ElementID) = true
	diagramSlotLeft = diagramSlotLeft + 210
	if diagramSlotTop + height > diagramRowBottom then diagramRowBottom = diagramSlotTop + height
	Session.Output "  added '" & element.Name & "' to the profile diagram"
end sub

' obsolete stereotypes must not be saved with the profile
sub removeFromProfileDiagram( element)
	dim objectIndex
	if profileDiagram is nothing then exit sub
	if not profileDiagramIndex.Exists( element.ElementID) then exit sub
	for objectIndex = profileDiagram.DiagramObjects.Count - 1 to 0 step -1
		if profileDiagram.DiagramObjects.GetAt( objectIndex).ElementID = element.ElementID then
			profileDiagram.DiagramObjects.DeleteAt objectIndex, false
		end if
	next
	profileDiagram.DiagramObjects.Refresh
	profileDiagramIndex.Remove element.ElementID
	Session.Output "  removed '" & element.Name & "' from the profile diagram"
end sub

' a linked stereotype found in the wrong profile package, e.g. a relationship stereotype among the element stereotypes
sub moveProfileElement( profileElement, package)
	Session.Output "  moved '" & profileElement.Name & "' from '" & Repository.GetPackageByID( profileElement.PackageID).Name & "' to '" & package.Name & "'"
	dim oldKey
	oldKey = profileElement.PackageID & ":" & profileElement.Name
	if profileIndexByName.Exists( oldKey) then
		if profileIndexByName( oldKey) = profileElement.ElementID then profileIndexByName.Remove oldKey
	end if
	profileElement.PackageID = package.PackageID
	profileElement.Update
end sub

sub renameProfileElement( profileElement, newName)
	dim newKey
	newKey = profileElement.PackageID & ":" & newName
	if profileIndexByName.Exists( newKey) then
		if profileIndexByName( newKey) <> profileElement.ElementID then
			Session.Output "  CONFLICT: cannot rename '" & profileElement.Name & "' to '" & newName & "', the name is already used in the profile"
			exit sub
		end if
	end if
	Session.Output "  renamed '" & profileElement.Name & "' -> '" & newName & "' (model elements still carry the old stereotype name)"
	profileIndexByName.Remove profileElement.PackageID & ":" & profileElement.Name
	profileElement.Name = newName
	profileElement.Update
end sub

' linked stereotypes that no V7 concept matched go to the Obsolete package; unlinked ones may be hand made, so only report them
sub handleUnmatchedStereotypes
	dim key, objectID
	dim obsoletePackage		as EA.Package
	dim profileElement		as EA.Element
	dim profileMetaclass	as EA.Element
	set obsoletePackage = nothing
	for each key in profileIndexByName.Keys
		objectID = profileIndexByName( key)
		if not profileTouched.Exists( objectID) then
			set profileElement = Repository.GetElementByID( objectID)
			if profileLinkedIDs.Exists( objectID) then
				if obsoletePackage is nothing then set obsoletePackage = getObsoletePackage()
				if profileTouched.Exists( profileGuidAnywhere( profileLinkedIDs( objectID))) then
					Session.Output "Obsolete: moving '" & profileElement.Name & "' from '" & Repository.GetPackageByID( profileElement.PackageID).Name & "' to '" & obsoletePackage.Name & "' (duplicate, same Metamodel GUID as the one kept)"
				else
					Session.Output "Obsolete: moving '" & profileElement.Name & "' to '" & obsoletePackage.Name & "'"
				end if
				set profileMetaclass = getRelatedSupplierElement( profileElement, "Extension", "Metaclass")
				if not profileMetaclass is nothing then
					removeFromProfileDiagram profileMetaclass
					profileMetaclass.PackageID = obsoletePackage.PackageID
					profileMetaclass.Update
				end if
				removeFromProfileDiagram profileElement
				profileElement.PackageID = obsoletePackage.PackageID
				profileElement.Update
			else
				Session.Output "Kept (no metamodel concept, no Metamodel GUID): '" & profileElement.Name & "'"
			end if
		end if
	next
end sub

' sibling of the profile package, so obsolete stereotypes stay out of the profile
function getObsoletePackage()
	dim parentPackage	as EA.Package
	dim package			as EA.Package
	set parentPackage = Repository.GetPackageByID( profilePackage.ParentID)
	for each package in parentPackage.Packages
		if package.Name = ProfileName & " Obsolete" then
			set getObsoletePackage = package
			exit function
		end if
	next
	set package = parentPackage.Packages.AddNew( ProfileName & " Obsolete", "Package")
	package.Update
	parentPackage.Packages.Refresh
	set getObsoletePackage = package
end function

' like setTaggedValueValue, but writes only when the value changes
sub ensureTag( eaItem, taggedValueName, taggedValueValue)
	dim taggedValue
	set taggedValue = nothing
	on error resume next
	set taggedValue = eaItem.TaggedValues.GetByName( taggedValueName)
	if err.Number <> 0 then set taggedValue = nothing
	err.Clear
	on error goto 0
	if taggedValue is nothing then
		set taggedValue = eaItem.TaggedValues.AddNew( taggedValueName, "")
		taggedValue.Value = taggedValueValue
		taggedValue.Update
		eaItem.TaggedValues.Refresh
	elseif taggedValue.Value <> taggedValueValue then
		taggedValue.Value = taggedValueValue
		taggedValue.Update
	end if
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' SQL script
''''''''''''''''''''''' TODO move to new file
'''''''''''''''''''''''

'' SQL Query Element for validation
sub SQLQueryElement( SourceStereotype, TargetStereotype, connectortype)
	dim sqlGetString 'as string
	dim scriptFile
	sqlGetString = "SELECT o1.ea_guid AS ItemGuid                                                      " & vbNewLine & _
" FROM ((((((t_object as o1                                                         " & vbNewLine & _
" INNER JOIN t_Package p ON p.Package_ID = o1.Package_ID)                           " & vbNewLine & _
" LEFT JOIN t_Package Package_p1 ON Package_p1.Package_id = p.parent_id)            " & vbNewLine & _
" LEFT JOIN t_Package Package_p2 ON Package_p2.Package_id = Package_p1.parent_id)   " & vbNewLine & _
" LEFT JOIN t_Package Package_p3 ON Package_p3.Package_id = Package_p2.parent_id)   " & vbNewLine & _
" LEFT JOIN t_Package Package_p4 ON Package_p4.Package_id = Package_p3.parent_id)   " & vbNewLine & _
" LEFT JOIN t_Package Package_p5 ON Package_p5.Package_id = Package_p4.parent_id)   " & vbNewLine & _
"                                                                                   " & vbNewLine & _
" where o1.stereotype = '"& SourceStereotype &"' 									"

			set scriptFile = New TextFile
			scriptfile.Contents = sqlGetString
			'save the script
			scriptFile.FullPath = SQLPath & SourceStereotype& "_"  & "BasicQuery.sql"
			scriptFile.Save
			'debug info
			'Session.Output "saving  Basic Query script: " & scriptFile.FullPath
end sub

'' SQL Simple relationship
sub SQLSimpleRelationship( SourceStereotype, TargetStereotype, connectortype)
	dim sqlGetString 'as string
	dim scriptFile
	sqlGetString = 		"-- Generated "  & now() & vbNewLine &_
						"--  " & SourceStereotype & " (GroupName) connected with  " & TargetStereotype & " (series)" & vbNewLine &_
						"SELECT " & SourceStereotype & ".Name as " & SourceStereotype & ",  " & TargetStereotype & ".Name as  " & TargetStereotype  & vbNewLine &_
						"FROM t_object AS " & TargetStereotype & vbNewLine & _
						"INNER JOIN t_connector as connector ON " & TargetStereotype &".Object_ID = connector.Start_Object_ID" & vbNewLine &_
						"INNER JOIN t_object AS " & SourceStereotype & " ON connector.End_Object_ID =  " & SourceStereotype & ".Object_ID" & vbNewLine &_
						"WHERE " & SourceStereotype & ".Stereotype='" & SourceStereotype  &"'" & vbNewLine &_ 
						"AND  " & TargetStereotype & ".Stereotype='" & TargetStereotype  & "'" & vbNewLine &_ 
						"AND connector.Stereotype='" & ConnectorType &"'"
	
			set scriptFile = New TextFile
			scriptfile.Contents = sqlGetString
			'save the script
			scriptFile.FullPath = SQLPath & SourceStereotype& "_" & connectortype  & "_" & TargetStereotype & ".sql"
			scriptFile.Save
			'debug info
			'Session.Output "saving script: " & scriptFile.FullPath
end sub


'' create a SQL script that check for required but missing relationships
'' TODO: connectortype is really the stereotype
sub SQLmissingRelationship( SourceStereotype, TargetStereotype, connectortype)
	dim sqlGetString 'as string
	dim scriptFile
	sqlGetString = 		"-- Generated "  & now() & vbNewLine &_
						"SELECT o.name AS ItemName,  o.ea_guid AS CLASSGUID  , o.Object_Type  AS [CLASSTYPE]            " & vbNewLine & _
						" FROM t_object AS o                                                                            " & vbNewLine & _
						" WHERE o.StereoType = '" & SourceStereotype & "'                                               " & vbNewLine & _
						" AND o.ea_guid not  in                                                                         " & vbNewLine & _
						" (                                                                                             " & vbNewLine & _
						" 	Select  o1.ea_guid                                                                          " & vbNewLine & _
						" 	from t_object as o1                                                                         " & vbNewLine & _
						" 	Inner join t_connector c on                                                                 " & vbNewLine & _
						" 							(o1.Object_ID = c.Start_Object_ID AND                               " & vbNewLine & _
						" 								c.Stereotype = '" & ConnectorType &"'   		                " & vbNewLine & _
						" 								)                                                               " & vbNewLine & _
						" 	inner join t_object o2 on (c.End_object_ID = o2.Object_ID 	AND o2.Stereotype = '" & TargetStereotype  &"')   " & vbNewLine & _
						" 	WHERE o1.Stereotype = '" & SourceStereotype & "'	                                        " & vbNewLine & _
						" )                                                                                             "
						
	
			set scriptFile = New TextFile
			scriptfile.Contents = sqlGetString
			'save the script
			scriptFile.FullPath = SQLPath & SourceStereotype& "_" & connectortype  & "_" & TargetStereotype & "_Missing.sql"
			scriptFile.Save
			'debug info
			'Session.Output "saving missing Relationship script: " & scriptFile.FullPath
end sub

'' create a SQL script that check for presence of this element is a diagram

sub SQLmissingDiagram( SourceStereotype, TargetStereotype, connectortype)
	dim sqlGetString 'as string
	dim scriptFile
	
	sqlGetString =  "SELECT o.Name AS ItemName                                                          " & vbNewLine & _
					" , 'object' as ItemType                                                            " & vbNewLine & _
					" , o.ea_guid AS ItemGuid                                                           " & vbNewLine & _
					" , o.Object_Type AS ElementType                                                    " & vbNewLine & _
					" , o.StereoType AS ElementStereotype                                               " & vbNewLine & _
					" , p.name AS PackageName                                                           " & vbNewLine & _
					" , package_p1.name AS PackageParentLevel1                                          " & vbNewLine & _
					" , package_p2.name AS PackageParentLevel2                                          " & vbNewLine & _
					" , package_p3.name AS PackageParentLevel3                                          " & vbNewLine & _
					" , package_p4.name AS PackageParentLevel4                                          " & vbNewLine & _
					" , package_p5.name AS PackageParentLevel5                                          " & vbNewLine & _
					" FROM ((((((t_object o                                                             " & vbNewLine & _
					" INNER JOIN t_package p ON p.Package_ID = o.Package_ID)                            " & vbNewLine & _
					" LEFT JOIN t_package package_p1 ON package_p1.package_id = p.parent_id)            " & vbNewLine & _
					" LEFT JOIN t_package package_p2 ON package_p2.package_id = package_p1.parent_id)   " & vbNewLine & _
					" LEFT JOIN t_package package_p3 ON package_p3.package_id = package_p2.parent_id)   " & vbNewLine & _
					" LEFT JOIN t_package package_p4 on package_p4.package_id = package_p3.parent_id)   " & vbNewLine & _
					" LEFT JOIN t_package package_p5 on package_p5.package_id = package_p4.parent_id)   " & vbNewLine & _
					" WHERE o.ea_guid in (#ElementGuids#)                                               " & vbNewLine & _
					" AND o.ea_guid NOT IN (                                                            " & vbNewLine & _
					" Select o1.ea_GUID                                                                 " & vbNewLine & _
					" from t_object as o1                                                               " & vbNewLine & _
					" Inner Join t_diagramobjects d on d.Object_ID = o1.Object_ID                       " & vbNewLine & _
					" where o1.stereotype = '"& SourceStereotype &"'                                     " & vbNewLine & _
					" )"    
			set scriptFile = New TextFile
			scriptfile.Contents = sqlGetString
			'save the script
			scriptFile.FullPath = SQLPath & SourceStereotype& "_"  & "_MissingDiagram.sql"
			scriptFile.Save
			'debug info
			'Session.Output "saving missing Diagram script: " & scriptFile.FullPath
end sub

'' create a SQL script that checks for documentation (ea notes)
sub SQLmissingNotes( SourceStereotype, TargetStereotype, connectortype)
	dim sqlGetString 'as string
	dim scriptFile
	
	sqlGetString =  "SELECT o.Name AS ItemName                                      " & vbNewLine & _
" , 'object' as ItemType                                                            " & vbNewLine & _
" , o.ea_guid AS ItemGuid                                                           " & vbNewLine & _
" , o.Object_Type AS ElementType                                                    " & vbNewLine & _
" , o.StereoType AS ElementStereotype                                               " & vbNewLine & _
" , p.name AS PackageName                                                           " & vbNewLine & _
" , package_p1.name AS PackageParentLevel1                                          " & vbNewLine & _
" , package_p2.name AS PackageParentLevel2                                          " & vbNewLine & _
" , package_p3.name AS PackageParentLevel3                                          " & vbNewLine & _
" , package_p4.name AS PackageParentLevel4                                          " & vbNewLine & _
" , package_p5.name AS PackageParentLevel5                                          " & vbNewLine & _
" FROM ((((((t_object o                                                             " & vbNewLine & _
" INNER JOIN t_package p ON p.Package_ID = o.Package_ID)                            " & vbNewLine & _
" LEFT JOIN t_package package_p1 ON package_p1.package_id = p.parent_id)            " & vbNewLine & _
" LEFT JOIN t_package package_p2 ON package_p2.package_id = package_p1.parent_id)   " & vbNewLine & _
" LEFT JOIN t_package package_p3 ON package_p3.package_id = package_p2.parent_id)   " & vbNewLine & _
" LEFT JOIN t_package package_p4 on package_p4.package_id = package_p3.parent_id)   " & vbNewLine & _
" LEFT JOIN t_package package_p5 on package_p5.package_id = package_p4.parent_id)   " & vbNewLine & _
" WHERE o.ea_guid in (#ElementGuids#)                                               " & vbNewLine & _
" AND o.ea_guid in (                                                                " & vbNewLine & _
" Select o1.ea_guid from t_object as o1                                             " & vbNewLine & _
" where o1.Note IS NULL                                                             " & vbNewLine & _
" and o1.stereotype = '"& SourceStereotype &"' )                                      "
  
			set scriptFile = New TextFile
			scriptfile.Contents = sqlGetString
			'save the script
			scriptFile.FullPath = SQLPath & SourceStereotype& "_"  & "_MissingNotes.sql"
			scriptFile.Save
			'debug info
			'Session.Output "saving missing notes script: " & scriptFile.FullPath
end sub

''' generate a query with all tagged values
sub SQLQueryAllTaggedValues(metamodelClass)
		dim scriptFile
		dim attribute 		as EA.Attribute	
		dim taggedValueQuery 'as string
		dim sqlInitialString 'as string
		dim SQLFrom
		dim sqlFinalString
		dim taggedValueselect ' as string
		dim strippedattribute 
			dim strippedAlias
			
		strippedAlias = StripToAlphanumeric(metamodelClass.Alias )
		sqlInitialString = "SELECT "  & strippedAlias &".Object_ID, "  & strippedAlias &".ea_guid AS CLASSGUID , "& strippedAlias &".Object_Type AS CLASSTYPE, "& strippedAlias &".Name as "  & strippedAlias  
		SQLFrom = vbNewLine &"FROM t_object as "  & strippedAlias
		
		sqlFinalString = vbNewLine & " WHERE "  & strippedAlias &".stereotype= '"  & metamodelClass.Name &"'"
		
		for each attribute in metamodelClass.Attributes
			' Check if the attribute name does not start with "_" and is not named "icon"
			if Not (Left(attribute.Name, 1) = "_" Or attribute.Name = "icon") then
				
				strippedattribute = StripToAlphanumeric(attribute.Name )
				'Session.Output " tag value: "  & attribute.Name
				taggedValueQuery = taggedValueQuery  & vbNewLine & _  	
				"INNER JOIN t_objectproperties AS " & strippedattribute & "  ON (" & strippedattribute & ".Object_ID =" & strippedAlias & ".Object_ID AND " & strippedattribute & ".Property = ('" & attribute.Name & "'))"
				taggedValueselect = taggedValueselect & ", " & strippedattribute & ".value AS '" & strippedattribute & "'"
			end if
		next
						
			set scriptFile = New TextFile
			scriptfile.Contents = sqlInitialString  &taggedValueselect & SQLFrom & taggedValueQuery & sqlFinalString
			'save the script
			scriptFile.FullPath = SQLPath & strippedAlias& "_"  & "_taggedValueQUery.sql"
			scriptFile.Save
			'debug info
			''Session.Output "saving tagged values query: " & scriptFile.FullPath
			
			
end sub

Function StripToAlphanumeric(inputString)
    Dim regEx, matches, match
    Set regEx = New RegExp
    regEx.Pattern = "[^a-zA-Z0-9]"
    regEx.Global = True
    StripToAlphanumeric = regEx.Replace(inputString, "")
End Function


'''''''''' end of SQL
'''''''''''''''''''''''


'''''''''''''''''''''''
''''''''''''''''''''''  Transform package
'''''''''''''''''''''''

sub transformPackage( metamodelPackage)

	dim element		as EA.Element
	dim subPackage 	as EA.Package
	Session.Output "Generating profile elements for '" & metamodelPackage.Name & "' package..."
	for each element in metamodelPackage.Elements
		select case element.Type
		case "Class"
			transformClass element
			''create the toolbox for elements
			addToolboxesAttributes element, toolboxClass
		case "Enumeration"
			transformEnumeration element
		end select
	next	
	for each subPackage in metamodelPackage.Packages
		transformPackage subPackage
	next	
end sub

sub transformEnumeration( metamodelEnum)

	dim profileEnum as EA.Element
	dim attribute	as EA.Attribute
	dim literalPos	' literal name -> position in the metamodel
	dim literalName, attributeIndex
	' stereotype properties copy their classifier from the metamodel, so the profile diagram shows the metamodel enumeration
	ensureOnProfileDiagram metamodelEnum
	set profileEnum = resolveProfileElement( metamodelEnum.ElementGUID, metamodelEnum.Name, enumerationPackage, "Enumeration")
	set literalPos = CreateObject( "Scripting.Dictionary")
	for each attribute in metamodelEnum.Attributes
		literalPos( attribute.Name) = literalPos.Count
	next
	' update literals in place: keep, reorder, delete removed ones
	for attributeIndex = profileEnum.Attributes.Count - 1 to 0 step -1
		set attribute = profileEnum.Attributes.GetAt( attributeIndex)
		if literalPos.Exists( attribute.Name) then
			if attribute.Pos <> literalPos( attribute.Name) then
				attribute.Pos = literalPos( attribute.Name)
				attribute.Update
			end if
			literalPos.Remove attribute.Name
		else
			profileEnum.Attributes.Delete attributeIndex
		end if
	next
	for each literalName in literalPos.Keys
		set attribute = profileEnum.Attributes.AddNew( literalName, "int")
		attribute.Stereotype = "enum"
		attribute.Pos = literalPos( literalName)
		attribute.Update
	next
	ensureTag profileEnum, "Profile Type", "Element"
	ensureTag profileEnum, "Metamodel GUID", metamodelEnum.ElementGUID
end sub

sub transformClassGUID( classGUID, profilePackageGUID, fileName)

	dim metamodelClass as EA.Element  	
	quickLinkFileName = fileName
	createQuickLinkFile
	set profilePackage = Repository.GetPackageByGuid( profilePackageGUID)
	set metamodelClass = Repository.GetElementByGuid( classGUID)
	transformClass metamodelClass
	quickLinkFileStream.Close
	Repository.RefreshModelView profilePackage.PackageID
end sub

' Subroutine to transform a class element based on its metamodel definition
sub transformClass( metamodelClass)
	
	dim superClass					as EA.Element
	dim redefinedStereotypeName	  ' as String
	dim metaclassName			  ' as String
	dim stereotypeName		 	  ' as String
	dim stereotypeClass				as EA.Element
	dim metaType				 ' As String
	metaType = ""
' Check if the provided class has the M3 stereotype of "Concept"
	if metamodelClass.Stereotype = "Concept" then	
		' any superclass stereotype: metamodel superclasses are Concepts, so an empty stereotype filter never matched
		set superClass = getRelatedSupplierElement2( metamodelClass, "Generalization", "", "Class", Null)
		metaclassName = getTaggedValueValue( metamodelClass, "Metaclass")
		redefinedStereotypeName = getTaggedValueValue( metamodelClass, "Redefines")

		if redefinedStereotypeName <> vbNullString or metaclassName <> vbNullString or not( superClass is nothing) then																		   		
			Session.Output "Generating stereotype for '" & metamodelClass.Name & "' class..."					
				stereotypeName = metamodelClass.Name
			set stereotypeClass = resolveProfileElement( metamodelClass.ElementGUID, stereotypeName, stereotypePackage, "Class")

			'setup the catalog name
			if GenerateCatalogs = 1 then
					if metamodelClass.Alias <> "" then
					metaType = metamodelClass.Alias
				else
						' take off the prefix chars
				 'metaType = MID (stereotypeName, 2)
					metaType = metamodelClass.Name				
				end if			
				createCatalog metaType,	metamodelClass.Name	
			end if			
			setStereotypeProperties metamodelClass, stereotypeClass, metamodelClass.Name
			ensureTag stereotypeClass, "Profile Type", "Element"
			ensureTag stereotypeClass, "Metamodel GUID", metamodelClass.ElementGUID
			if GenerateCSV = 1 then
				' generate a set of CSV files for import of the element type into EA
				generateCSVImportFile stereotypeClass
				' end generate a set of CSV files
			end if

			' the three cases are exclusive: drop the links of the other two, V7 may have switched case
			if redefinedStereotypeName <> vbNullString then
				setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
				syncGeneralization stereotypeClass, "", nothing
				removeProfileMetaclass stereotypeClass
			elseif superClass is nothing then
				setProfileMetaclass metamodelClass, stereotypeClass
				syncGeneralization stereotypeClass, "redefines", nothing
				syncGeneralization stereotypeClass, "", nothing
			else
				setProfileSuperclass stereotypeClass, superClass
				syncGeneralization stereotypeClass, "redefines", nothing
				removeProfileMetaclass stereotypeClass
			end if
			'if redefinedStereotypeName <> vbNullString then
			'	setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
			'end if		
			transformRelationships metamodelClass, stereotypeClass			
		end if  
	end if	
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' Catalogs
'''''''''''''''''''''''

''generate a CSV file associating packages GUIDS with stereotype names
'' this is called at the end of the script
sub writeCSVImportFile(CSVImportString)
		dim scriptFile
		set scriptFile = New TextFile
	
			scriptfile.Contents = CSVImportString
			'save the script
			scriptFile.FullPath = CSVPath &  "DAFCatalogs.csv"
			scriptFile.Save
			'debug info
			Session.Output "saved  CSV with catalogs script: " & scriptFile.FullPath
end sub

'' this is called for each catalog
sub addlinetoCSVImportFile(metamodelClass, packageGUID)
	CSVImportString = CSVImportString & vbCrLf & metamodelClass  & "," & packageGUID
end sub


sub createCatalog(stereotypeName, techname)
' create a list of packages wit the same name of the stereotypes
' this can be included in the technology to create a repository structure according to the metamodel
			 On Error Resume Next
			dim subPackage as EA.Package
			set subPackage = profilePackage.Packages.GetByName(stereotypeName)
			''if  subPackage is nothing then
			If Err.Number <> 0 Then			
				set subPackage = profilePackage.Packages.AddNew(stereotypeName,"Package")
				
				Session.Output "Generating catalog for " & stereotypeName
				subPackage.Update
				Err.Clear
			end if
			addlinetoCSVImportFile  techname, subPackage.PackageGUID
end sub

'' set the class that extend the UML type with a stereotype
function setProfileMetaclass( metamodelItem, stereotypeClass)
' add the metaclass to the stereotype
	dim metaclassName  ' as String
	dim profileMetaclass as EA.Element	
	metaclassName = metamodelItem.TaggedValues.GetByName( "Metaclass").Value	
	set profileMetaclass = getRelatedSupplierElement( stereotypeClass, "Extension", "Metaclass")
	
	if profileMetaclass is nothing then
		set profileMetaclass = addStereotypeMetaclass( stereotypeClass, metaclassName)
	else	
		if profileMetaclass.Name <> metaclassName then			
			deleteElement profileMetaclass			
			set profileMetaclass = addStereotypeMetaclass( stereotypeClass, metaclassName)			
		end if		
	end if	
	' add the GUID
	ensureTag profileMetaClass, "Metamodel GUID", stereotypeClass.ElementGUID
	ensureOnProfileDiagram profileMetaClass
	set setProfileMetaclass = profileMetaClass
end function

sub removeProfileMetaclass( stereotypeClass)
	dim profileMetaclass as EA.Element
	set profileMetaclass = getRelatedSupplierElement( stereotypeClass, "Extension", "Metaclass")
	if not profileMetaclass is nothing then
		Session.Output "  removed metaclass extension " & stereotypeClass.Name & " -> " & profileMetaclass.Name
		deleteElement profileMetaclass
	end if
end sub

'' set the super class that extend the stereotype
sub setProfileSuperclass( stereotypeClass, metamodelSuperClass)
	' resolve by GUID so a renamed superclass is found even before its own concept is processed
	syncGeneralization stereotypeClass, "", resolveProfileElement( metamodelSuperClass.ElementGUID, metamodelSuperClass.Name, stereotypePackage, "Class")
end sub

' keep exactly one Generalization with this connector stereotype from stereotypeClass to target; none when target is nothing
sub syncGeneralization( stereotypeClass, connStereotype, target)
	dim connector as EA.Connector
	dim connectorIndex, found, keep, deleted
	found = false
	deleted = false
	for connectorIndex = stereotypeClass.Connectors.Count - 1 to 0 step -1
		set connector = stereotypeClass.Connectors.GetAt( connectorIndex)
		if connector.Type = "Generalization" and connector.Stereotype = connStereotype and connector.ClientID = stereotypeClass.ElementID then
			keep = false
			if not found and not target is nothing then
				keep = ( connector.SupplierID = target.ElementID)
			end if
			if keep then
				found = true
			else
				Session.Output "  removed " & connStereotype & " Generalization " & stereotypeClass.Name & " -> " & Repository.GetElementByID( connector.SupplierID).Name
				stereotypeClass.Connectors.Delete connectorIndex
				deleted = true
			end if
		end if
	next
	if deleted then stereotypeClass.Connectors.Refresh
	if not found and not target is nothing then
		addConnector stereotypeClass, "Generalization", connStereotype, target
	end if
end sub


'' The setProfileRedefinedStereotype subroutine establishes a "Generalization" 
'' relationship between a given stereotypeClass and a redefined stereotype 
'' identified by redefinedStereotypeName. If the redefined stereotype does not exist, it creates one in the stereotypePackage.
sub setProfileRedefinedStereotype( stereotypeClass, redefinedStereotypeName)

	syncGeneralization stereotypeClass, "redefines", resolveProfileElement( "", redefinedStereotypeName, stereotypePackage, "Class")
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' ATRIBUTES
'''''''''''''''''''''''
' profile-only attributes (_image, _metatype, icon, stereotyped) are never deleted by the sync
function isProfileOnlyAttribute( attribute)
	isProfileOnlyAttribute = ( Left( attribute.Name, 1) = "_" or attribute.Name = "icon" or attribute.Stereotype <> vbNullString)
end function

function getAttributesByName( element)
	dim attribute as EA.Attribute
	set getAttributesByName = CreateObject( "Scripting.Dictionary")
	for each attribute in element.Attributes
		if not getAttributesByName.Exists( attribute.Name) then getAttributesByName.Add attribute.Name, attribute
	next
end function

' like setAttribute, but uses the name lookup and writes only when the value changes
sub ensureAttribute( element, attributesByName, attributeName, defaultValue, onlyIfEmpty)
	dim attribute as EA.Attribute
	if attributesByName.Exists( attributeName) then
		set attribute = attributesByName( attributeName)
		if attribute.Default = defaultValue then exit sub
		if onlyIfEmpty and attribute.Default <> "" then exit sub
	else
		set attribute = element.Attributes.AddNew( attributeName, "")
		attributesByName.Add attributeName, attribute
	end if
	attribute.Default = defaultValue
	attribute.Update
end sub

sub setStereotypeProperties( metamodelClass, stereotypeClass, stereotypeName)
	'set properties for elements and connectors
	dim attributesByName
	if metamodelClass.ObjectType = otElement then
		syncTaggedValueAttributes metamodelClass, stereotypeClass
	end if
	set attributesByName = getAttributesByName( stereotypeClass)
	ensureAttribute stereotypeClass, attributesByName, "_metatype", metamodelClass.Alias, false
	ensureAttribute stereotypeClass, attributesByName, "_strictness", "profile", false
	ensureAttribute stereotypeClass, attributesByName, "icon", IconPath + stereotypeName + ".bmp", true
end sub

' update the stereotype attributes in place from the metamodel attributes, matched by source GUID then name.
' Deletes only attributes an earlier run generated (they carry a Metamodel GUID); other extras are kept and reported.
sub syncTaggedValueAttributes( metamodelClass, stereotypeClass)
	dim attribute		as EA.Attribute
	dim sourceAttribute	as EA.Attribute
	dim target			as EA.Attribute
	dim byName, bySource, matches, used, attributeIndex, deleted
	set byName = CreateObject( "Scripting.Dictionary")
	set bySource = CreateObject( "Scripting.Dictionary")
	set matches = CreateObject( "Scripting.Dictionary")
	set used = CreateObject( "Scripting.Dictionary")
	for each attribute in stereotypeClass.Attributes
		if not byName.Exists( attribute.Name) then byName.Add attribute.Name, attribute
		if attributeSourceGuid.Exists( attribute.AttributeID) then
			if not bySource.Exists( attributeSourceGuid( attribute.AttributeID)) then bySource.Add attributeSourceGuid( attribute.AttributeID), attribute
		end if
	next

	' match first, so deletes happen before any AddNew changes the collection
	for each sourceAttribute in metamodelClass.Attributes
		if not sourceAttribute.IsDerived and sourceAttribute.Name <> "icon" then
			set target = nothing
			if bySource.Exists( sourceAttribute.AttributeGUID) then
				set target = bySource( sourceAttribute.AttributeGUID)
			elseif byName.Exists( sourceAttribute.Name) then
				set target = byName( sourceAttribute.Name)
			end if
			if not target is nothing then used( target.AttributeID) = true
			matches.Add sourceAttribute.AttributeGUID, target
		end if
	next

	deleted = false
	for attributeIndex = stereotypeClass.Attributes.Count - 1 to 0 step -1
		set attribute = stereotypeClass.Attributes.GetAt( attributeIndex)
		if not used.Exists( attribute.AttributeID) and not isProfileOnlyAttribute( attribute) then
			if attributeSourceGuid.Exists( attribute.AttributeID) then
				Session.Output "  removed property " & stereotypeClass.Name & "." & attribute.Name
				stereotypeClass.Attributes.Delete attributeIndex
				deleted = true
			else
				Session.Output "  kept extra property " & stereotypeClass.Name & "." & attribute.Name & " (not in metamodel)"
			end if
		end if
	next
	if deleted then stereotypeClass.Attributes.Refresh

	for each sourceAttribute in metamodelClass.Attributes
		if matches.Exists( sourceAttribute.AttributeGUID) then
			set target = matches( sourceAttribute.AttributeGUID)
			if target is nothing then
				set target = stereotypeClass.Attributes.AddNew( sourceAttribute.Name, "")
				target.Update
			end if
			copyAttributeValues stereotypeClass, target, sourceAttribute
			ensureTag target, "Metamodel GUID", sourceAttribute.AttributeGUID
		end if
	next
end sub

' like copyAttribute, but on a known target and writes only when something changes
sub copyAttributeValues( stereotypeClass, target, sourceAttribute)
	if target.Name = sourceAttribute.Name and target.Default = sourceAttribute.Default and target.Type = sourceAttribute.Type _
			and target.ClassifierID = sourceAttribute.ClassifierID and target.Notes = sourceAttribute.Notes then exit sub
	if target.Name <> sourceAttribute.Name then
		Session.Output "  renamed property " & stereotypeClass.Name & "." & target.Name & " -> " & sourceAttribute.Name
	end if
	target.Name = sourceAttribute.Name
	target.Default = sourceAttribute.Default
	target.Type = sourceAttribute.Type
	target.ClassifierID = sourceAttribute.ClassifierID
	target.Notes = sourceAttribute.Notes
	target.Update
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' CSV
'''''''''''''''''''''''

''generate a CSV file for Import a metamodel  element
sub generateCSVImportFile(metamodelClass)
		dim scriptFile
		dim attribute 		as EA.Attribute	
		dim CSVString '' AS string
		CSVString = "Name, Notes, Version, Status"
		set scriptFile = New TextFile
		for each attribute in metamodelClass.Attributes
			' Check if the attribute name does not start with "_" and is not named "icon"
			if Not (Left(attribute.Name, 1) = "_" Or attribute.Name = "icon") then
				Session.Output " CSV property: "  & attribute.Name
				CSVString = CSVString & "," & "TagValue_" & ProfileName & "::" & attribute.Name
			end if
		next
			scriptfile.Contents = CSVString
			'save the script
			scriptFile.FullPath = CSVPath & metamodelClass.Name & "_"  & "import.csv"
			scriptFile.Save
			'debug info
			'Session.Output "saving  CSV import script: " & scriptFile.FullPath
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' TOOLBOX
'''''''''''''''''''''''
sub cleanToolboxAttributes( toolbox)
' delete all the generated attributes of a toolbox class; the toolbox is fully regenerated each run
	dim attribute 		as EA.Attribute
	dim attributeIndex 'as Integer
	Session.Output "Cleaning toolbox " & toolbox.Name & " ... "
	for attributeIndex = toolbox.Attributes.Count - 1 to 0 step -1
		set attribute = toolbox.Attributes.GetAt( attributeIndex)
		if not isProfileOnlyAttribute( attribute) then
			toolbox.Attributes.Delete attributeIndex
		end if
	next
	toolbox.Attributes.Refresh
end sub

' the toolbox collections are refreshed once at the end of transformPackageGUID
sub addToolboxesAttributes( metamodelClass, ToolboxClass)
	dim toolboxAttribute as EA.Attribute
	set toolboxAttribute = ToolboxClass.Attributes.AddNew(ProfileName +"::"+metamodelClass.Name + "(UML::"+ metamodelClass.Type + ")", "")
	toolboxAttribute.Alias = metamodelClass.Alias
	toolboxAttribute.Default = metamodelClass.Alias
	toolboxAttribute.Update()
end sub

sub createtoolboxConnector(connector)
'' create a set of connectors in a standard toolbox class defined in the configuration
	dim toolboxAttribute as EA.Attribute
	dim metaclassName ' as string
	metaclassName = getTaggedValueValue( connector, "Metaclass")
	set toolboxAttribute = ToolboxConnector.Attributes.AddNew(ProfileName +"::"+connector.Name + "(UML::"+ metaclassName + ")", "")
	toolboxAttribute.Alias = connector.Alias
	toolboxAttribute.Default = connector.Alias
	toolboxAttribute.Update()
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' RELATIONSHIPS
'''''''''''''''''''''''

sub transformRelationships( metamodelClass, stereotypeClass)
	dim connector as EA.Connector	
	for each connector in metamodelClass.Connectors
	
		if connector.ClientID = metamodelClass.ElementID then
			transformRelationship connector
			'' create toolbox relationships	
			createtoolboxConnector connector
		end if	
	next
end sub

' This subroutine transforms a metamodel relationship (connector) into a corresponding UML stereotype in Sparx EA
sub transformRelationship( metamodelConnector)

	dim metaclassName			  ' as String
	dim metaclassAlias				'as string
	dim redefinedStereotypeName	  ' as String
	dim stereotypeName		 	  ' as String
	dim stereotypeClass				as EA.Element
	dim profileMetaclass			as EA.Element
	dim metaclassAttributes

	metaclassName = getTaggedValueValue( metamodelConnector, "Metaclass")
	metaclassAlias = metamodelConnector.alias
	redefinedStereotypeName = getTaggedValueValue( metamodelConnector, "Redefines")
		
	if redefinedStereotypeName <> vbNullString or metaclassName <> vbNullString then	
		Session.Output "Generating stereotype for '" & metamodelConnector.Name & "' relationship..."		
		'if metamodelConnector.Alias <> "" then
		'	stereotypeName = metamodelConnector.Alias
		'else
			stereotypeName = metamodelConnector.Name
		'end if		
		set stereotypeClass = resolveProfileElement( metamodelConnector.ConnectorGUID, stereotypeName, relationshipPackage, "Class")
		setStereotypeProperties metamodelConnector, stereotypeClass, metamodelConnector.Name
		set profileMetaclass = setProfileMetaclass( metamodelConnector, stereotypeClass)
		if redefinedStereotypeName <> vbNullString then
			setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
		else
			syncGeneralization stereotypeClass, "redefines", nothing
		end if

		'set tags and properties in the metaclass
		set metaclassAttributes = getAttributesByName( profileMetaclass)
		ensureAttribute profileMetaclass, metaclassAttributes, "_MeaningForwards", metamodelConnector.SupplierEnd.Role, false
		ensureAttribute profileMetaclass, metaclassAttributes, "_MeaningBackwards", metamodelConnector.ClientEnd.Role, false
		'setAttribute profileMetaclass, "_lineStyle", "orthogonalR"
		ensureAttribute profileMetaclass, metaclassAttributes, "_relatedTo", metaclassAlias, false

		' set tags to link the connector to the original metamodel relationship
		ensureTag stereotypeClass, "Metamodel GUID",  metamodelConnector.ConnectorGUID
		ensureTag stereotypeClass, "Profile Type", "Connector"
		updateQuickLink metamodelConnector
	end if	
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' QuickLink
'''''''''''''''''''''''

sub createQuickLinkFile

	dim fileSysObj 'as Scripting.FileSystemObject
	set fileSysObj = CreateObject( "Scripting.FileSystemObject")
	set quickLinkFileStream = fileSysObj.CreateTextFile( quickLinkFileName, STREAM_FOR_WRITING)
	quickLinkFileStream.WriteLine "//Source Element Type,Source Stereotype Filter,Target Element Type,Target Stereotype Filter,Diagram Filter,New Element Type,New Element Stereotype,New Link Type,New Link Stereotype,New Link Direction,New Link Caption,New Link & Element Caption,Create Link,Create Element,Disallow Self connector,No inherit from Metatype,Menu Group,Complexity Level,Target Must Be Parent,Embed element,Precedes Separator LEAF,Precedes Separator GROUP,Dummy Column"
	quickLinkFileStream.WriteLine "//generated:" & now()
end sub

sub updateQuickLinkDocument
	dim quickLinkDoc	as EA.Element
	Session.Output "Updating QuickLink document..."	
	set quickLinkDoc = getProfileElement( "QuickLink", profilePackage) 'search for an element called quicklink in the profilePackage
	if quickLinkDoc is nothing then
		Session.Output "WARNING: no 'QuickLink' document in '" & profilePackage.Name & "', QuickLink file written to " & quickLinkFileName & " only"
		exit sub
	end if
	quickLinkDoc.LoadLinkedDocument quickLinkFileName
	quickLinkDoc.Update
end sub

sub updateQuickLink( connector)
	dim connMetaclass      'as String
	dim connStereotype	   'as String
	dim toDirection		   'as String
	dim fromDirection	   'as String
	dim sourceElement 		as EA.Element
	dim sourceMetaclass	   'as String
	dim sourceStereotype   'as String	
	dim targetElement 		as EA.Element
	dim targetMetaclass	   'as String
	dim targetStereotype   'as String
	dim row( 22)		   'as String
	dim textRow			   'as String

	connMetaclass = getTaggedValueValue( connector, "Metaclass")

	'if connector.Alias <> "" then
		'connStereotype = connector.Alias
	'else
		connStereotype = connector.Name
	'end if
	if connMetaclass = "Composition" or connMetaclass = "Aggregation" then
		toDirection = "from"
		fromDirection = "to"
	else
		toDirection = "directed"
		fromDirection = "from"
	end if
	set sourceElement = getMetamodelElement( connector.ClientID)
	sourceMetaclass = metaclassCache( connector.ClientID)
	sourceStereotype = sourceElement.Name
	set targetElement = getMetamodelElement( connector.SupplierID)
	targetMetaclass = metaclassCache( connector.SupplierID)
	targetStereotype = targetElement.Name
	
	' create SQL queries
	if generateSLQ = 1 then
		 SQLSimpleRelationship sourceStereotype, targetStereotype, connStereotype
		 SQLmissingRelationship sourceStereotype, targetStereotype, connStereotype
		'SQLmissingDiagram sourceStereotype, targetStereotype, connStereotype
		SQLQueryElement sourceStereotype, targetStereotype, connStereotype
		SQLmissingNotes sourceStereotype, targetStereotype, connStereotype
		SQLQueryAllTaggedValues sourceElement
		
	end if	
		
	' Create relationship group comment row
	
	quickLinkFileStream.WriteLine "// " & sourceStereotype & " -> " & connector.Name & " -> " & targetStereotype
	
	' Create from-existing-source-to-existing-target row
	
	row(0)  = sourceMetaclass 	' Source Element Type
	row(1)  = sourceStereotype	' Source Stereotype Filter
	row(2)  = targetMetaclass	' Target Element Type
	row(3)  = targetStereotype	' Target Stereotype Filter
	row(4)  = vbNullString		' Diagram Filter
	row(5)  = vbNullString		' New Element Type
	row(6)  = vbNullString		' New Element Stereotype
	row(7)  = connMetaclass		' New Link Type
	row(8)  = connStereotype	' New Link Stereotype
	row(9)  = toDirection		' New Link Direction
	row(10) = connector.SupplierEnd.Role ' New Link Caption INVERTED FOR DAF
	row(11) = vbNullString		' New Link & Element Caption
	row(12) = "TRUE"			' Create Link
	row(13) = vbNullString		' Create Element
	row(14) = "TRUE"			' Disallow Self connector
	row(15) = "TRUE"			' No inherit from Metatype
	row(16) = ProfileName		' Menu Group
	row(17) = "0" 				' Complexity Level
	row(18) = vbNullString		' Target Must Be Parent
	row(19) = vbNullString		' Embed element
	row(20) = vbNullString		' Precedes Separator LEAF
	row(21) = vbNullString		' Precedes Separator GROUP
	
	textRow = Join( row, ",")
	
	quickLinkFileStream.WriteLine textRow
	
	' Create from-existing-target-to-existing-source row
	
	row(0)  = targetMetaclass	' Target Element Type
	row(1)  = targetStereotype	' Target Stereotype Filter
	row(2)  = sourceMetaclass 	' Source Element Type
	row(3)  = sourceStereotype	' Source Stereotype Filter
	row(4)  = vbNullString		' Diagram Filter
	row(5)  = vbNullString		' New Element Type
	row(6)  = vbNullString		' New Element Stereotype
	row(7)  = connMetaclass		' New Link Type
	row(8)  = connStereotype	' New Link Stereotype
	row(9)  = fromDirection		' New Link Direction
	row(10) =  connector.ClientEnd.Role ' New Link Caption INVERTED FOR DAF
	row(11) = vbNullString		' New Link & Element Caption
	row(12) = "TRUE"			' Create Link
	row(13) = vbNullString		' Create Element
	row(14) = "TRUE"			' Disallow Self connector
	row(15) = "TRUE"			' No inherit from Metatype
	row(16) = ProfileName		' Menu Group
	row(17) = "0" 				' Complexity Level
	row(18) = vbNullString		' Target Must Be Parent
	row(19) = vbNullString		' Embed element
	row(20) = vbNullString		' Precedes Separator LEAF
	row(21) = vbNullString		' Precedes Separator GROUP
	
	textRow = Join( row, ",")
	
	quickLinkFileStream.WriteLine textRow
	
	' Create from-existing-source-to-new-target row
	
	row(0)  = sourceMetaclass 	' Source Element Type
	row(1)  = sourceStereotype	' Source Stereotype Filter
	row(2)  = vbNullString		' Target Element Type
	row(3)  = vbNullString		' Target Stereotype Filter
	row(4)  = vbNullString		' Diagram Filter
	row(5)  = targetMetaclass	' New Element Type
	row(6)  = targetStereotype	' New Element Stereotype
	row(7)  = connMetaclass		' New Link Type
	row(8)  = connStereotype	' New Link Stereotype
	row(9)  = toDirection		' New Link Direction
	row(10) = vbNullString		' New Link Caption
	row(11) =  connector.SupplierEnd.Role '' New Link & Element Caption  INVERTED FOR DAF
	row(12) = "TRUE"			' Create Link
	row(13) = "TRUE"			' Create Element
	row(14) = "TRUE"			' Disallow Self connector
	row(15) = "TRUE"			' No inherit from Metatype
	row(16) = ProfileName ' Menu Group
	row(17) = "0" 				' Complexity Level
	row(18) = vbNullString		' Target Must Be Parent
	row(19) = vbNullString		' Embed element
	row(20) = vbNullString		' Precedes Separator LEAF
	row(21) = vbNullString		' Precedes Separator GROUP
	
	textRow = Join( row, ",")
	
	quickLinkFileStream.WriteLine textRow

	' Create from-existing-target-to-new-source row
	
	row(0)  = targetMetaclass 	' Source Element Type
	row(1)  = targetStereotype	' Source Stereotype Filter
	row(2)  = vbNullString		' Target Element Type
	row(3)  = vbNullString		' Target Stereotype Filter
	row(4)  = vbNullString		' Diagram Filter
	row(5)  = sourceMetaclass	' New Element Type
	row(6)  = sourceStereotype 	' New Element Stereotype
	row(7)  = connMetaclass		' New Link Type
	row(8)  = connStereotype	' New Link Stereotype
	row(9)  = fromDirection		' New Link Direction
	row(10) = vbNullString		' New Link Caption
	row(11) = connector.ClientEnd.Role' New Link & Element Caption  INVERTED FOR DAF
	row(12) = "TRUE"			' Create Link
	row(13) = "TRUE"			' Create Element
	row(14) = "TRUE"			' Disallow Self connector
	row(15) = "TRUE"			' No inherit from Metatype
	row(16) = ProfileName		 ' Menu Group
	row(17) = "0" 				' Complexity Level
	row(18) = vbNullString		' Target Must Be Parent
	row(19) = vbNullString		' Embed element
	row(20) = vbNullString		' Precedes Separator LEAF
	row(21) = vbNullString		' Precedes Separator GROUP
	
	textRow = Join( row, ",")	
	quickLinkFileStream.WriteLine textRow
end sub

' every connector end is looked up several times; load each metamodel element and its Metaclass tag once
function getMetamodelElement( elementID)
	if not metamodelElementCache.Exists( elementID) then
		metamodelElementCache.Add elementID, Repository.GetElementByID( elementID)
		metaclassCache.Add elementID, getTaggedValueValue( metamodelElementCache( elementID), "Metaclass")
	end if
	set getMetamodelElement = metamodelElementCache( elementID)
end function


Function getProfileElement(profileElementName, relationshipPackage)
    ' Declare variables
    Dim profileElement ' As EA.Element
    Dim element ' As EA.Element
    Set profileElement = Nothing

    ' Use the provided relationshipPackage if specified, otherwise default to profilePackage
    Dim targetPackage
    If IsObject(relationshipPackage) Then
        Set targetPackage = relationshipPackage ' Use the specified package
    Else
        Set targetPackage = profilePackage ' Default to global profilePackage
    End If

    ' Search for the element in the selected package
    For Each element In targetPackage.Elements
        If element.Name = profileElementName Then
            Set profileElement = element
            Exit For ' Exit once the element is found
        End If
    Next

    ' Return the found profile element
    Set getProfileElement = profileElement
End Function


function addStereotypeMetaClass( stereotypeClass, metaclassName)

	dim profileMetaclass as EA.Element
	set profileMetaclass = metaclassPackage.Elements.AddNew( metaclassName, "Class")
	profileMetaclass.Stereotype = "metaclass"
	profileMetaclass.Update
	addConnector stereotypeClass, "Extension", "", profileMetaclass
	set addStereotypeMetaClass = profileMetaclass	
end function

sub testTransformClassGUID
	dim classGUID		   ' as String
	dim profilePackageGUID ' as String
	dim quickLinkFileName    ' as String
	
	'DEPRECATED:  USE THE CONFIGURATION SCRIPT
	'classGUID = ""'e.g "{BD4895B5-CA1E-4420-8849-51B5C0C349F6}"  Metamodel package
	'profilePackageGUID =  ""'e.g "{A570D667-E328-470a-A8B4-482813E31493}" Profile Package
	'quickLinkFileName = "c:\tmp\QuickLink.csv" ' location of the Quicklinker file
	
	if Not profilePackageGUID is nothing  then
		transformClassGUID classGUID, profilePackageGUID
	else
		Session.Prompt "Please configure the script .", promptOK
			
	end if
end sub

sub testTransformPackageGUID
		transformPackageGUID metamodelPackageGUID, profilePackageGUID, quickLinkFileName
	
	Session.Output "Done!"	
end sub

testTransformPackageGUID