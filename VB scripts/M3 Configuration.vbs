' Script Name: UML profile configuration
' Author: brothercorvo@gmail.com
 ' this is the companion script to the M2 MdG technology
' Purpose: use this script to configure the targets for the M3 MDG scripts 
'			Copy and rename this script in another group. Customize with proper local paths 
' Date: 2022 / 03 / 18
' Version: 4.20220318
'

	dim metamodelPackageGUID ' as String
	dim profilePackageGUID   ' as String
	dim quickLinkFileName    ' as String
	dim ProfileName    ' as String
	dim mdgTechFilePath    ' as String
	dim ProfileDiagramGUID ' as String 
	dim UMLProfileFilename' as String
	dim ProfileToolboxClassGUID ''as String
	dim ProfileToolboxConnectorGUID 'as String
	dim GenerateCatalogs ' as boolean
	dim IconPath  'as String

	metamodelPackageGUID = "{999A1E59-97AD-4301-AABF-515F6C82DC02}" ' Metamodel package, default is the template GUID
	profilePackageGUID = "{1BE8BA27-0DF4-4a63-A015-EFC37AB7D95D}" ' Profile Package, default is the template GUID
	ProfileDiagramGUID="{E55262DA-B743-49ae-A6E4-57B9E04FF3A2}" ' GUID of the diagram where the MDG  profile is locate, default is the template GUID
	ProfileToolboxClassGUID="{F6D0FC11-8D91-4a67-BF27-C262335214AD}" ' the GUId of a stereotyped element containing tollboxes
	ProfileToolboxConnectorGUID="{62D4B13D-72F9-41f9-A7EC-D1D2A627EE4B}" ' the GUId of a stereotyped element containing tollboxes
	quickLinkFileName = "D:\Documents\work\TM forum\2021\model\Mdg\QuickLink\QuickLink.csv" ' location of the Quicklinker file
	ProfileName = "TMF" 'name of the profile being generated
	mdgTechFilePath="D:\Documents\work\TM forum\2021\model\Mdg\mdg.mts" 'technology MTS location
	UMLProfileFilename="D:\Documents\work\TM forum\2021\model\Mdg\profile\Profile.xml" 'location of the UML profile saved
	IconPath="D:\Documents\work\TM forum\2021\model\Mdg\Icons\"
	GenerateCatalogs = 1
	
