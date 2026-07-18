'[path=\Projects\Project EC\EAC scripts]
'[group=EAC scripts]

option explicit

!INC Local Scripts.EAConstants-VBScript
!INC Wrappers.Include

'
' Script Name: Export Capabilities Tree to Excel
' Author: giu Platania
' Purpose: Exports the list of Capabilities to  an excel file
' Date: 2024-12-06
'
'name of the output tab
const outPutName = "Export components"
dim excelOutput

sub main

	'create output tab
	Repository.CreateOutputTab outPutName
	Repository.ClearOutput outPutName
	Repository.EnsureOutputVisible outPutName

		'create the excel file
		set excelOutput = new ExcelFile
	
		'tell the user we are starting
		Session.Output now() & " Starting components Export "
		'do the actual export
		exportProgrammeTree()
	
		excelOutput.save
		excelOutput.close
		'tell the user we are finished
		Session.Output  now() & " Finished Export components Tree '"
	
end sub

function defineHeader()
    dim messageHeaders(9)
    messageHeaders(0) = "Function Block"
    messageHeaders(1) = "Component Name"
    messageHeaders(2) = "Short Name" 
    messageHeaders(3) = "ID"
    messageHeaders(4) = "Status" 
    messageHeaders(5) = "Version"
    messageHeaders(6) = "Release" 
    messageHeaders(7) = "Description" 
	messageHeaders(8) ="Remarks"
    ' Return the messageHeaders array
    defineHeader = messageHeaders
end function

function exportProgrammeTree()

	dim getPogrammeTreeContents
	dim getComponentList
	dim getComponentList2
	
	getComponentList2 = "SELECT ODAFunctionBlock.Name as  'ODA_FunctionslBlock', TMF_ODAComponents.Name as 'ComponentsName', TMF_ODAComponents.Alias as 'ComponentshortName',                                             " & vbNewLine & _
						" CompID.value as 'ID', TMF_ODAComponents.status as 'status',                                                                                                                                      " & vbNewLine & _
						" TMF_ODAComponents.version as 'version', TMF_ODAComponents.phase as 'Release', TMF_ODAComponents.Note as 'Description' , CompIssue.notes as 'Remarks'                                             " & vbNewLine & _
						" FROM t_object AS TMF_ODAComponents                                                                                                                                                               " & vbNewLine & _
						" INNER JOIN t_connector as connector ON TMF_ODAComponents.Object_ID = connector.Start_Object_ID                                                                                                   " & vbNewLine & _
						" INNER JOIN t_object AS ODAFunctionBlock ON connector.End_Object_ID =  ODAFunctionBlock.Object_ID                                                                                                 " & vbNewLine & _
						" INNER JOIN  t_objectproperties AS CompID ON (CompID.Object_ID = TMF_ODAComponents.Object_ID AND CompID.property = 'ID')                                                                          " & vbNewLine & _
						" INNER JOIN  t_objectproperties AS CompIssue ON (CompIssue.Object_ID = TMF_ODAComponents.Object_ID AND CompIssue.property = 'issue')															   " & vbNewLine & _
						" WHERE TMF_ODAComponents.Stereotype='TMF_ISC'                                                                                                                                                     " & vbNewLine & _
						" AND  ODAFunctionBlock.Stereotype='TMF_ODAFunctionBlock'                                                                                                                                          " & vbNewLine & _
						" AND connector.Stereotype='TMF_BlockContainsFunction'                                                                                                                                             "
	dim arrayResult 
	arrayResult = getArrayFromQuery(getComponentList2)
	dim messageHeaders
	messageHeaders = defineHeader()
	
	
	if Ubound(arrayResult) > 0 then
		dim mergedArray
		mergedArray = AddRowToArray(arrayResult, messageHeaders)
		
		excelOutput.createTab "Components", mergedArray, true, "TableStyleMedium13"
		'excelOutput.save
		
	else
			Session.Output  now() & " Empty query!"
	end if
end function

main