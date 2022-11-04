option explicit
 ' 
' Script Name: UML profile configuratrion
' Author:  Giu Platania
' Purpose: Scripts to transform metamodel into UML Profile, create classes for toolboxes (elements and relationships
' generates the quicklink file and a list of packages named after the stereotypes to be used as "TOGAF catalogs".
' Date: 2022 / 03 / 23
' Version: 4.20220323
 '
 ' TODO
 ' create a better management of alias/names for elements and relationships
 ' add the alias of the stereotype to the alias of the metatype
 
 ' USAGE:
 ' this is the companion script to the M2 MdG technology
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
!INC M3.Model Management Utilities
!INC M3 Local.configuration

const STREAM_FOR_READING = 1
const STREAM_FOR_WRITING = 2
const STREAM_FOR_APPENDING = 3

dim profilePackage 			as EA.Package
dim quickLinkFileStream	   'as Scripting.TextStream
dim toolboxClass 	as EA.Element
dim toolboxConnector as EA.Element

sub transformPackageGUID( metamodelPackageGUID, profilePackageGUID, fileName)

	dim metamodelPackage 	as EA.Package
		Repository.EnableUIUpdates = false
		quickLinkFileName = fileName
		createQuickLinkFile	
	set profilePackage = Repository.GetPackageByGuid( profilePackageGUID)
	set metamodelPackage = Repository.GetPackageByGuid( metamodelPackageGUID)
	set toolboxClass = Repository.GetElementByGuid(ProfileToolboxClassGUID) 
	set toolboxConnector = Repository.GetElementByGuid(ProfileToolboxConnectorGUID)
	clearProfileMetamodelTags profilePackage
	cleanToolboxesAttributes toolboxClass
	cleanToolboxConnectorAttributes  toolboxConnector
	transformPackage metamodelPackage
	quickLinkFileStream.Close
	updateQuickLinkDocument
	Repository.RefreshModelView profilePackage.PackageID
	Repository.EnableUIUpdates = true

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
	set quickLinkDoc = getProfileElement( "QuickLink")
	quickLinkDoc.LoadLinkedDocument quickLinkFileName	
	quickLinkDoc.Update
end sub

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
	Session.Output "Generating enumeration for '" & enumName & "' ..."
	set profileEnum = getProfileElement( enumName)
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

sub transformClass( metamodelClass)
	
	dim superClass					as EA.Element
	dim redefinedStereotypeName	  ' as String
	dim metaclassName			  ' as String
	dim stereotypeName		 	  ' as String
	dim stereotypeClass				as EA.Element
	dim metaType				 ' As String
	metaType = ""

	if metamodelClass.Stereotype = "Concept" then	
		set superClass = getRelatedSupplierElement2( metamodelClass, "Generalization", "", "Class", "")
		metaclassName = getTaggedValueValue( metamodelClass, "Metaclass")
		redefinedStereotypeName = getTaggedValueValue( metamodelClass, "Redefines")

		if redefinedStereotypeName <> vbNullString or metaclassName <> vbNullString or not( superClass is nothing) then																		   		
			Session.Output "Generating stereotype for '" & metamodelClass.Name & "' class..."					
				stereotypeName = metamodelClass.Name		
			set stereotypeClass = getProfileElement(stereotypeName)			
			if stereotypeClass is nothing then			
				set stereotypeClass = profilePackage.Elements.AddNew( stereotypeName, "Class")				
				stereotypeClass.Stereotype = "stereotype"			
				stereotypeClass.Update				
				profilePackage.Elements.Refresh			
			end if
			'setup the catalog name
		
			 	if metamodelClass.Alias <> "" then
				metaType = metamodelClass.Alias
			else
					' take off the prefix chars
			 'metaType = MID (stereotypeName, 2)
				metaType = metamodelClass.Name				
			end if			
			createCatalog metaType	
				
			setStereotypeProperties metamodelClass, stereotypeClass, metamodelClass.Name			
			setTaggedValueValue stereotypeClass, "Profile Type", "Element"
			setTaggedValueValue stereotypeClass, "Metamodel GUID", metamodelClass.ElementGUID		
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

sub createCatalog(stereotypeName)
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
end sub

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

sub setProfileSuperclass( stereotypeClass, metamodelSuperClass)

	dim stereotypeSuperClass	as EA.Element	
	set stereotypeSuperClass = getRelatedSupplierElement( stereotypeClass, "Generalization", "Stereotype")	
	if stereotypeSuperClass is nothing then	
		set stereotypeSuperClass = getProfileElement( metamodelSuperClass.Name)			
		if stereotypeSuperClass is nothing then		
			set stereotypeSuperClass = profilePackage.Elements.AddNew( metamodelSuperClass.Name, "Class")
			stereotypeSuperClass.Stereotype = "stereotype"
			stereotypeSuperClass.Update			
			profilePackage.Elements.Refresh			
		end if		
		addConnector stereotypeClass, "Generalization", "", stereotypeSuperClass		
	end if
end sub

sub setProfileRedefinedStereotype( stereotypeClass, redefinedStereotypeName)

	dim redefinedStereotypeClass	as EA.Element	
	set redefinedStereotypeClass = getRelatedSupplierElement2( stereotypeClass, "Generalization", "redefines", "Class", "stereotype")	
	if redefinedStereotypeClass is nothing then	
		set redefinedStereotypeClass = getProfileElement( redefinedStereotypeName)			
		if redefinedStereotypeClass is nothing then		
			set redefinedStereotypeClass = profilePackage.Elements.AddNew( redefinedStereotypeName, "Class")
			redefinedStereotypeClass.Stereotype = "stereotype"
			redefinedStereotypeClass.Update			
			profilePackage.Elements.Refresh
			
		end if		
		addConnector stereotypeClass, "Generalization", "redefines", redefinedStereotypeClass		
	end if
end sub

sub setStereotypeProperties( metamodelClass, stereotypeClass, stereotypeName)
	'set properties for elements and connectors
	setAttribute stereotypeClass, "_metatype", metamodelClass.Alias
	setAttribute stereotypeClass, "_strictness", "profile"	
	setAttribute stereotypeClass, "_Image", ""
	setAttribute stereotypeClass, "icon", IconPath + stereotypeName + ".bmp"
	deleteTaggedValueAttributes stereotypeClass	
	if metamodelClass.ObjectType = otElement then
		addTaggedValueAttributes metamodelClass, stereotypeClass
	end if
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
	set toolboxAttribute = ToolboxClass.Attributes.AddNew(ProfileName +"::"+metamodelClass.Name + "("+ metamodelClass.Type + ")", "string")
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
	set toolboxAttribute = ToolboxConnector.Attributes.AddNew(ProfileName +"::"+connector.Name + "(UML::"+ metaclassName + ")", "string")
	toolboxAttribute.Alias = connector.Alias
	toolboxAttribute.Default = connector.Alias
	toolboxAttribute.Update()
	ToolboxConnector.Attributes.Refresh	
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
		set stereotypeClass = getProfileElement( stereotypeName)		
		if stereotypeClass is nothing then		
			set stereotypeClass = profilePackage.Elements.AddNew( stereotypeName, "Class")
			stereotypeClass.Stereotype = "stereotype"	
			stereotypeClass.Update
			profilePackage.Elements.Refresh			
		end if		
		setStereotypeProperties metamodelConnector, stereotypeClass, metamodelConnector.Name
		set profileMetaclass = setProfileMetaclass( metamodelConnector, stereotypeClass)		
		if redefinedStereotypeName <> vbNullString then
			setProfileRedefinedStereotype stereotypeClass, redefinedStereotypeName
		end if
		
		setAttribute profileMetaclass, "_MeaningForwards", metamodelConnector.SupplierEnd.Role
		setAttribute profileMetaclass, "_MeaningBackwards", metamodelConnector.ClientEnd.Role
		setTaggedValueValue profileMetaclass, "Metamodel GUID", metamodelConnector.ConnectorGUID
		'setAttribute profileMetaclass, "_lineStyle", "orthogonalR"
		setAttribute profileMetaclass, "_relatedTo", metaclassAlias		
		setTaggedValueValue profileMetaclass, "Metamodel GUID", stereotypeClass.ElementGUID
		setTaggedValueValue stereotypeClass, "Profile Type", "Connector"
	
		
		updateQuickLink metamodelConnector
	end if	
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

	if connector.Alias <> "" then
		connStereotype = connector.Alias
	else
		connStereotype = connector.Name
	end if
	
	if connMetaclass = "Composition" or connMetaclass = "Aggregation" then
		toDirection = "from"
		fromDirection = "to"
	else
		toDirection = "directed"
		fromDirection = "from"
	end if

	set sourceElement = Repository.GetElementByID( connector.ClientID)
	sourceMetaclass = getTaggedValueValue( sourceElement, "Metaclass")
	if sourceElement.Alias <> "" then
		sourceStereotype = sourceElement.Alias
	else
		sourceStereotype = sourceElement.Name
	end if
	set targetElement = Repository.GetElementByID( connector.SupplierID)
	targetMetaclass = getTaggedValueValue( targetElement, "Metaclass")
	if targetElement.Alias <> "" then
		targetStereotype = targetElement.Alias
	else
		targetStereotype = targetElement.Name
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

function getProfileElement( profileElementName)

	dim profileElement 	as EA.Element
	dim element 		as EA.Element	
	set profileElement = nothing	
	for each element in profilePackage.Elements
	
		if element.Name = profileElementName then
			set profileElement = element
			exit for
		end if
		
	next
	
	set getProfileElement = profileElement
	
end function

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