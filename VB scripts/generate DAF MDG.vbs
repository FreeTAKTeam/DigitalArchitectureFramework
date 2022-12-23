option explicit

 ' Script to create MDG Tech XML file. Assumes that MDG Tech "header" has already been created by built-in MDG Tech generator and
 ' is saved off to its own file {MDGTechName}.def. 
 '
 ' DBC 2022, Inc. All rights reserved. info@sparxsystems.us

!INC Local Scripts.EAConstants-VBScript
!INC DAF M3 Conf
!INC Save diagram UML Profile

const STREAM_FOR_READING = 1
const STREAM_FOR_WRITING = 2
const STREAM_FOR_APPENDING = 3

dim fileSysObj   			'as Scripting.FileSystemObject
dim mdgTechFileName			'as String
'dim mdgTechFilePath			'as String
dim mdgTechXMLFileStream 	'as Scripting.TextStream
dim mdgTechSettingsXML		'as String

sub generateMDGTechXMLFile( fileName, filePath)

	mdgTechFileName = fileName
	mdgTechFilePath = filePath
	
	Session.Output vbCRLF & "Generating MDG Technology XML file for '" & mdgTechFileName & vbCRLF
	Session.Output "Path: " & mdgTechFilePath & vbCRLF

	set fileSysObj = CreateObject( "Scripting.FileSystemObject")
	
	getMDGTechSettings

	createMDGTechXMLFile
	
	addMDGTechHeader
	
	addUMLProfiles
	addUMLPatterns
	addDiagramProfiles
	addToolboxProfiles
	
	mdgTechXMLFileStream.WriteLine "</MDG.Technology>"
	
	mdgTechXMLFileStream.Close
	
	Session.Output vbCRLF & "Finished!"
	
end sub

sub getMDGTechSettings

	dim pathFileName  			  	'as String
	dim mdgTechSettingsFileStream 	'as Scripting.TextStream
	
	pathFileName = mdgTechFilePath & "\" & mdgTechFileName & ".mts"
	
	Session.Output "Getting MDG Technology settings..."

	set mdgTechSettingsFileStream = fileSysObj.OpenTextFile( pathFileName, STREAM_FOR_READING)
	
	mdgTechSettingsXML = mdgTechSettingsFileStream.ReadAll
	
	mdgTechSettingsFileStream.Close
	
end sub

function getXMLDocAttributeValue( xmlString, queryString)

	dim xmlDoc 			' as Microsoft.XMLDOM.XMLDocument
	dim xmlNodeList 	' as Microsoft.XMLDOM.XMLNodeList
	dim xmlNode 		' as Microsoft.XMLDOM.XMLNode
	dim attrValue		' as String
	
	set xmlDoc = CreateObject( "Microsoft.XMLDOM")
	
	xmlDoc.LoadXml(xmlString)
	
	set xmlNodeList = xmlDoc.SelectNodes( queryString)

	if xmlNodeList.Length > 0 Then
	
		set xmlNode = xmlNodeList.Item(0)
		
		attrValue = xmlNode.Value
		
	Else
		attrValue = vbNullString
	End If
	
	getXMLDocAttributeValue = attrValue

end function

sub createMDGTechXMLFile

	dim pathFileName 'as String

	pathFileName = mdgTechFilePath & "\" & mdgTechFileName & ".xml"
	
	Session.Output "Creating '" & mdgTechFileName & "' MDG Technology file in " & pathFileName 

	set mdgTechXMLFileStream = fileSysObj.CreateTextFile( pathFileName, STREAM_FOR_WRITING)
	
end sub

sub addMDGTechHeader

	dim pathFileName  	'as String
	dim fileStream 		'as Scripting.TextStream
	dim fileRow			'as String
	
	pathFileName = mdgTechFilePath & "\" & mdgTechFileName & ".def"
	
	Session.Output "Adding MDG Technology header '" & pathFileName & "'..."

	set fileStream = fileSysObj.OpenTextFile( pathFileName, STREAM_FOR_READING)
	
	do
		
		fileRow = fileStream.ReadLine
			
		mdgTechXMLFileStream.WriteLine fileRow

	loop until fileStream.AtEndOfStream
	
	fileStream.Close
	
end sub

sub addUMLProfiles

	Session.Output "Adding UML Profiles..."

	addSectionFiles "Profiles", "UMLProfiles", vbNullString
	
end sub

sub addUMLPatterns

	Session.Output "Adding UML Patterns..."

	addSectionFiles "Patterns", "UMLPatterns", "UMLPattern"
	
end sub

sub addDiagramProfiles

	Session.Output "Adding Diagram Profiles..."

	addSectionFiles "DiagramProfile", "DiagramProfile", vbNullString
	
end sub

sub addToolboxProfiles

	Session.Output "Adding Toolbox Profiles..."

	addSectionFiles "UIToolboxes", "UIToolboxes", vbNullString
	
end sub

sub addSectionFiles( sectionName, sectionXMLTag, subSectionXMLTag)

	dim filePath 	  'as String
	dim fileNameList  'as String
	dim fileNameArray 'as String()
	dim fileName	  'as String
	dim pathFileName  'as String
	dim fileStream 	  'as Scripting.TextStream
	dim fileRow		  'as String
	
	mdgTechXMLFileStream.WriteLine "<" & sectionXMLTag & ">"
	
	filePath = getXMLDocAttributeValue( mdgTechSettingsXML, "/MDG.Selections/" & sectionName & "/@directory")
	fileNameList = getXMLDocAttributeValue( mdgTechSettingsXML, "/MDG.Selections/" & sectionName & "/@files")

	fileNameArray = Split( fileNameList, ",")
	
	for each fileName in fileNameArray
	
		Session.Output "- " & fileName & "..."

		if subSectionXMLTag <> vbNullString then
			mdgTechXMLFileStream.WriteLine "<" & subSectionXMLTag & ">"
		end if
		
		pathFileName = filePath & "\" & fileName
		
		set fileStream = fileSysObj.OpenTextFile( pathFileName, STREAM_FOR_READING)
		
		do
		
			fileRow = fileStream.ReadLine
				
			if left( fileRow, 5) <> "<?xml" then ' Skip XML version line
				mdgTechXMLFileStream.WriteLine fileRow
			end if

		loop until fileStream.AtEndOfStream
		
		fileStream.Close
		
		if subSectionXMLTag <> vbNullString then
			mdgTechXMLFileStream.WriteLine "</" & subSectionXMLTag & ">"
		end if
	
	next
	
	mdgTechXMLFileStream.WriteLine "</" & sectionXMLTag & ">"

end sub

sub test

	dim fileName 	' as String
	dim filePath   	' as String
	fileName = "UPDM_DoDAF_MDGTech"
	filePath = "D:\Work\SSNA\Products\MDGTech\UPDM_DoDAF_v1_0"
	generateMDGTechXMLFile fileName, filePath
	
end sub


sub generateMDG
	GenerateMDGTechnology(mdgTechFilePath) 
	
end sub


generateMDG