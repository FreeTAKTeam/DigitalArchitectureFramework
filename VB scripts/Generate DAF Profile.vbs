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
dim quickLinkFileStream	   'as Scripting.TextStream
dim CSVImportString 		' as place where to store packages GUIDs and stereotypes
dim toolboxClass 	as EA.Element
dim toolboxConnector as EA.Element

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
	set toolboxClass = Repository.GetElementByGuid(ProfileToolboxClassGUID) 
	set toolboxConnector = Repository.GetElementByGuid(ProfileToolboxConnectorGUID)
	clearProfileMetamodelTags profilePackage
	cleanToolboxesAttributes toolboxClass
	cleanToolboxConnectorAttributes  toolboxConnector
	transformPackage metamodelPackage
	quickLinkFileStream.Close
	updateQuickLinkDocument
	' write import string to file
	writeCSVImportFile(CSVImportString)
		
		
	Repository.RefreshModelView profilePackage.PackageID
	Repository.EnableUIUpdates = true
	Session.Output "Done at " & Now() 
end sub

sub clearProfileMetamodelTags( profilePackage)

	dim profileClass as EA.Element	
	Session.Output "Clearing profile metamodel tags..."
	for each profileClass in profilePackage.Elements
		if profileClass.MetaType = "Stereotype" then		
			deleteTaggedValue profileClass, "Metamodel GUID"
			deleteTaggedValue profileClass, "Profile Type"			
		end if		
	next	
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
	dim enumName   'as String
	enumName = metamodelEnum.Name
	'Session.Output "Generating enumeration for '" & enumName & "' ..."
	set profileEnum = getProfileElement( enumName, profilePackage)
	if profileEnum is nothing then
		set profileEnum = copyEnumeration( metamodelEnum, profilePackage)
	else	
		deleteElement profileEnum
		set profileEnum = copyEnumeration( metamodelEnum, profilePackage)		
	end if
end sub

function copyEnumeration( enumeration, package)

	dim newEnumeration	as EA.Element
	dim attribute 		as EA.Attribute
	dim newAttribute	as EA.Attribute
	set newEnumeration = package.Elements.AddNew( enumeration.Name, "Enumeration")	
	newEnumeration.Update	
	for each attribute in enumeration.Attributes
		set newAttribute = newEnumeration.Attributes.AddNew( attribute.Name, "int")
		newAttribute.Stereotype = "enum"
		newAttribute.Update		
	next	
	newEnumeration.Attributes.Refresh
	setTaggedValueValue newEnumeration, "Profile Type", "Element"
	setTaggedValueValue newEnumeration, "Metamodel GUID", enumeration.ElementGUID
	profilePackage.Elements.Refresh
	set copyEnumeration = newEnumeration
end function

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
		set superClass = getRelatedSupplierElement2( metamodelClass, "Generalization", "", "Class", "")
		metaclassName = getTaggedValueValue( metamodelClass, "Metaclass")
		redefinedStereotypeName = getTaggedValueValue( metamodelClass, "Redefines")

		if redefinedStereotypeName <> vbNullString or metaclassName <> vbNullString or not( superClass is nothing) then																		   		
			Session.Output "Generating stereotype for '" & metamodelClass.Name & "' class..."					
				stereotypeName = metamodelClass.Name
			 ' Check if the stereotype already exists in the profile package
			set stereotypeClass = getProfileElement(stereotypeName, profilePackage)			
			if stereotypeClass is nothing then			
				set stereotypeClass = profilePackage.Elements.AddNew( stereotypeName, "Class")				
				stereotypeClass.Stereotype = "stereotype"			
				stereotypeClass.Update				
				profilePackage.Elements.Refresh			
			end if

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
			setTaggedValueValue stereotypeClass, "Profile Type", "Element"
			setTaggedValueValue stereotypeClass, "Metamodel GUID", metamodelClass.ElementGUID
			if GenerateCSV = 1 then
				' generate a set of CSV files for import of the element type into EA
				generateCSVImportFile stereotypeClass
				' end generate a set of CSV files
			end if
					
			if redefinedStereotypeName <> vbNullString then
				setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
			elseif superClass is nothing then
				setProfileMetaclass metamodelClass, stereotypeClass
			else
				setProfileSuperclass stereotypeClass, superClass
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
	setTaggedValueValue profileMetaClass, "Metamodel GUID", stereotypeClass.ElementGUID	
	set setProfileMetaclass = profileMetaClass	
end function

'' set the super class that extend the stereotype
sub setProfileSuperclass( stereotypeClass, metamodelSuperClass)
'' set a superclass for the stereotype
	dim stereotypeSuperClass	as EA.Element	
	set stereotypeSuperClass = getRelatedSupplierElement( stereotypeClass, "Generalization", "Stereotype")	
	if stereotypeSuperClass is nothing then	
		set stereotypeSuperClass = getProfileElement( metamodelSuperClass.Name, profilePackage)			
		if stereotypeSuperClass is nothing then		
			set stereotypeSuperClass = profilePackage.Elements.AddNew( metamodelSuperClass.Name, "Class")
			stereotypeSuperClass.Stereotype = "stereotype"
			stereotypeSuperClass.Update			
			profilePackage.Elements.Refresh			
		end if		
		addConnector stereotypeClass, "Generalization", "", stereotypeSuperClass		
	end if
end sub


'' The setProfileRedefinedStereotype subroutine establishes a "Generalization" 
'' relationship between a given stereotypeClass and a redefined stereotype 
'' identified by redefinedStereotypeName. If the redefined stereotype does not exist, it creates one in the profilePackage.
sub setProfileRedefinedStereotype( stereotypeClass, redefinedStereotypeName)

	dim redefinedStereotypeClass	as EA.Element	
	set redefinedStereotypeClass = getRelatedSupplierElement2( stereotypeClass, "Generalization", "redefines", "Class", "stereotype")	
	if redefinedStereotypeClass is nothing then	
		set redefinedStereotypeClass = getProfileElement( redefinedStereotypeName, profilePackage)			
		if redefinedStereotypeClass is nothing then		
			set redefinedStereotypeClass = profilePackage.Elements.AddNew( redefinedStereotypeName, "Class")
			redefinedStereotypeClass.Stereotype = "stereotype"
			redefinedStereotypeClass.Update			
			profilePackage.Elements.Refresh
			
		end if		
		addConnector stereotypeClass, "Generalization", "redefines", redefinedStereotypeClass		
	end if
end sub

'''''''''''''''''''''''
'''''''''''''''''''''' ATRIBUTES
'''''''''''''''''''''''
sub setStereotypeProperties( metamodelClass, stereotypeClass, stereotypeName)
	'set properties for elements and connectors
	dim imageAttribute 	as  EA.Attribute
	setAttribute stereotypeClass, "_metatype", metamodelClass.Alias		
	setAttribute stereotypeClass, "_strictness", "profile"	
	'' check if image exists
	'setAttribute stereotypeClass, "_Image", ""		
	setAttribute stereotypeClass, "icon", IconPath + stereotypeName + ".bmp"
	deleteTaggedValueAttributes stereotypeClass	
	if metamodelClass.ObjectType = otElement then
		addTaggedValueAttributes metamodelClass, stereotypeClass
	end if
end sub

sub deleteTaggedValueAttributes( stereotypeClass)

	dim attribute 		as EA.Attribute
	dim attributeCount 'as Integer
	dim attributeIndex 'as Integer	
	attributeCount = stereotypeClass.Attributes.Count
	for attributeIndex = attributeCount - 1 to 0 step -1	
		set attribute = stereotypeClass.Attributes.GetAt( attributeIndex)	
		if left( attribute.Name, 1) <> "_" and attribute.Name <> "icon" then		
			if attribute.Stereotype = vbNullString then
				stereotypeClass.Attributes.Delete attributeIndex
			end if		
		end if		
	next	
	stereotypeClass.Attributes.Refresh
end sub

sub addTaggedValueAttributes( metamodelClass, stereotypeClass)

	dim attribute 		as EA.Attribute	
	for each attribute in metamodelClass.Attributes	
		if not attribute.IsDerived then
			copyAttribute stereotypeClass, attribute
		end if	
	next	
	metamodelClass.Attributes.Refresh	
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
sub cleanToolboxesAttributes(ToolboxClass)
' delete all the attrribute of the template ToolboxClass
	dim attribute 		as EA.Attribute
	dim attributeCount 'as Integer
	dim attributeIndex 'as Integer	
	Session.Output "Cleaning Element toolbox ... "
	attributeCount = ToolboxClass.Attributes.Count
	for attributeIndex = attributeCount - 1 to 0 step -1	
		set attribute = ToolboxClass.Attributes.GetAt( attributeIndex)	
		if left( attribute.Name, 1) <> "_" and attribute.Name <> "icon" then		
			if attribute.Stereotype = vbNullString then
				ToolboxClass.Attributes.Delete attributeIndex
			end if		
		end if		
	next	
	ToolboxClass.Attributes.Refresh
end sub

sub cleanToolboxConnectorAttributes(ToolboxConnector)
' delete all the attrribute of the template ToolboxConnector
	dim attribute 		as EA.Attribute
	dim attributeCount 'as Integer
	dim attributeIndex 'as Integer	
	Session.Output "Cleaning Connector toolbox ... "
	attributeCount = ToolboxConnector.Attributes.Count
	for attributeIndex = attributeCount - 1 to 0 step -1	
		set attribute = ToolboxConnector.Attributes.GetAt( attributeIndex)	
		if left( attribute.Name, 1) <> "_" and attribute.Name <> "icon" then		
			if attribute.Stereotype = vbNullString then
				ToolboxConnector.Attributes.Delete attributeIndex
			end if		
		end if		
	next	
	ToolboxConnector.Attributes.Refresh
end sub

sub addToolboxesAttributes( metamodelClass, ToolboxClass)
' Add all the attrribute of the template ToolboxConnector
		Session.Output "adding toolbox for " +  metamodelClass.Name + " toolboxClass " + ToolboxClass.Name
	dim attribute 		as EA.Attribute	
	dim toolboxAttribute as EA.Attribute
	set toolboxAttribute = ToolboxClass.Attributes.AddNew(ProfileName +"::"+metamodelClass.Name + "(UML::"+ metamodelClass.Type + ")", "")
	toolboxAttribute.Alias = metamodelClass.Alias
	toolboxAttribute.Default = metamodelClass.Alias
	toolboxAttribute.Update()
	ToolboxClass.Attributes.Refresh	
end sub

sub createtoolboxConnector(connector)
'' create a set of connectors in a standard toolbox class defined in the configuration
	Session.Output "adding toolbox for " +  connector.Name + " toolboxClass " + ToolboxConnector.Name
	dim toolboxAttribute as EA.Attribute
	dim metaclassName ' as string
	metaclassName = getTaggedValueValue( connector, "Metaclass")
	set toolboxAttribute = ToolboxConnector.Attributes.AddNew(ProfileName +"::"+connector.Name + "(UML::"+ metaclassName + ")", "")
	toolboxAttribute.Alias = connector.Alias
	toolboxAttribute.Default = connector.Alias
	toolboxAttribute.Update()
	ToolboxConnector.Attributes.Refresh	
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
		set stereotypeClass = getProfileElement( stereotypeName, relationshipPackage)		
		if stereotypeClass is nothing then		
			set stereotypeClass = relationshipPackage.Elements.AddNew( stereotypeName, "Class")
			stereotypeClass.Stereotype = "stereotype"	
			stereotypeClass.Update
			relationshipPackage.Elements.Refresh			
		end if		
		setStereotypeProperties metamodelConnector, stereotypeClass, metamodelConnector.Name
		set profileMetaclass = setProfileMetaclass( metamodelConnector, stereotypeClass)		
		if redefinedStereotypeName <> vbNullString then
			setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
		end if
		
		'set tags and properties in the metaclass
		setAttribute profileMetaclass, "_MeaningForwards", metamodelConnector.SupplierEnd.Role
		setAttribute profileMetaclass, "_MeaningBackwards", metamodelConnector.ClientEnd.Role
	
	setTaggedValueValue profileMetaclass, "Metamodel GUID", stereotypeClass.ElementGUID

		'setAttribute profileMetaclass, "_lineStyle", "orthogonalR"
		setAttribute profileMetaclass, "_relatedTo", metaclassAlias		
		
		' set tags to link the connector to the original metamodel relationship
		setTaggedValueValue stereotypeClass, "Metamodel GUID",  metamodelConnector.ConnectorGUID
		setTaggedValueValue stereotypeClass, "Profile Type", "Connector"
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
	set sourceElement = Repository.GetElementByID( connector.ClientID)
	sourceMetaclass = getTaggedValueValue( sourceElement, "Metaclass")
	sourceStereotype = sourceElement.Name	
	set targetElement = Repository.GetElementByID( connector.SupplierID)
	targetMetaclass = getTaggedValueValue( targetElement, "Metaclass")	
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

function getProfileElement1( profileElementName)

	dim profileElement 	as EA.Element
	dim element 		as EA.Element	
	set profileElement = nothing	
	for each element in profilePackage.Elements
	
		if element.Name = profileElementName then
			set profileElement = element
			exit for
		end if		
	next
    ' Return the found profile element
    set getProfileElement = profileElement
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
	set profileMetaclass = profilePackage.Elements.AddNew( metaclassName, "Class")
	profileMetaclass.Stereotype = "metaclass"
	profileMetaclass.Update
	profilePackage.Elements.Refresh
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