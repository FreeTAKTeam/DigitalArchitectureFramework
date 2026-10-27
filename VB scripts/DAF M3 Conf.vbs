' Script Name: UML profile configuration

' Purpose: use this script to configure the targets for the M3 MDG scripts
' Date: 2025 / 08/ 25
' Version: 1.2025825
'

dim metamodelPackageGUID ' as String
dim profilePackageGUID   ' as String
dim relationshipPackageGUID ' as String
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

metamodelPackageGUID = "{02BC7973-A0CB-4865-A42E-ECA442FF2D0D}" ' DAF Metamodel package
profilePackageGUID = "{BEFFD7D1-82EE-478f-A0EE-5670EC836630}" ' DAF Profile Package
relationshipPackageGUID = "{C3097ACD-177F-4d58-B51F-771989DAFF70}" ' package where to store relationships
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