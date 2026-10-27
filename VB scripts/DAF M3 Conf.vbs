' Script Name: UML profile configuration

' Purpose: use this script to configure the targets for the M3 MDG scripts
' Date: 2025 / 08/ 25
' Version: 1.2025825
'

dim metamodelPackageGUID ' as String
dim profilePackageGUID   ' as String
dim relationshipPackageGUID ' as String
dim stereotypePackageGUID ' as String
dim metaclassPackageGUID ' as String
dim enumerationPackageGUID ' as String
dim quickLinkFileName    ' as String
dim ProfileName    ' as String
dim mdgTechFilePath    ' as String
dim ProfileDiagramGUID ' as String 
dim UMLProfileFilename' as String
dim ProfileToolboxClassGUID ''as String
dim ProfileToolboxConnectorGUID 'as String
dim GenerateCatalogs ' as boolean
dim generateSLQ ' as boolean
dim IconPath  'as String
dim SQLPath 'as String
dim GenerateCSV 'as String
dim CSVPath 'as String
dim TechFilePath ' as string
dim RenameMappingFile ' as string

metamodelPackageGUID = "{02BC7973-A0CB-4865-A42E-ECA442FF2D0D}" ' DAF Metamodel package
profilePackageGUID = "{9A178708-DB6B-4bd1-9BF5-57E636D90A6B}" ' DAF Profile Package (DAF-MDG / DAF); was {BEFFD7D1-82EE-478f-A0EE-5670EC836630} (Utility / DAF) as a safety copy
relationshipPackageGUID = "{C3097ACD-177F-4d58-B51F-771989DAFF70}" ' package where to store relationships
' subpackages of the profile, one per generated type; empty to use the profile package
stereotypePackageGUID = "{9825B692-2233-47ca-90BA-B84A4CC0BCC6}" ' DAF / Stereotypes: element stereotypes
metaclassPackageGUID = "{6C3F7478-3283-4a5c-81C2-9C055BAAFFAB}" ' DAF / Metaclasses: extended UML metaclasses
enumerationPackageGUID = "{4D9E54E1-8964-4311-A4C8-4229E7887D14}" ' DAF / Enumerations: tagged value types
quickLinkFileName = "C:\Users\broth\Dropbox\work\Method\EA method\3.1\quicklinker\QuickLink.csv" ' DAF location of the Quicklinker file
ProfileName = "DAF"
mdgTechFilePath="C:\Users\broth\Dropbox\work\Method\EA method\3.1\DAF40.mts" 'DAF MTS location
TechFilePath = "C:\Users\broth\Dropbox\work\Method\EA method\3.1\technology" ' where to store the technology in XML format
ProfileDiagramGUID="{B91435BE-4D2E-4511-8A96-481522342E3A}" ' GUID of the diagram where the DAF profile is located
UMLProfileFilename="C:\Users\broth\Dropbox\work\Method\EA method\3.1\profile\DAFProfile.xml" 'location of the UML profile saved
ProfileToolboxClassGUID="{5D7B181D-D531-42d2-9B13-0E0A77BD5522}" 'the class GUID containing all the links to Elements
ProfileToolboxConnectorGUID="{5FE30409-43C0-4444-B469-28337E579EFA}" 'the class GUID containing all the links to connectors
IconPath="C:\tmp\Icons\"
SQLPath="C:\Users\broth\Dropbox\work\Method\EA method\3.1\queries\"
CSVPath ="C:\Users\broth\Dropbox\work\Method\EA method\3.1\csv\"
GenerateCatalogs = 0
generateSLQ = 0
GenerateCSV = 0
' CSV of stereotype renames, one 'oldName,newName' per line, for concepts without a Metamodel GUID link; empty to disable
RenameMappingFile = ""
