option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: CreateUsecaseControllerclassfromDiagram.vbs
' Author: Kumar
' Purpose: This method creates a Controller class and adds the activities under the use case as methods. 
' Date: 29-Mar-2016
'

'
' Project Browser Script main function
'
Dim usecaseElementCount, usecaseControllerClassCreated 'Used to check if there are any use case element are available and throw an error when no use case element is present. 
usecaseElementCount = 0
usecaseControllerClassCreated = 0

sub OnProjectBrowserScript()

	' Get the type of element selected in the Project Browser
	dim treeSelectedType
	treeSelectedType = Repository.GetTreeSelectedItemType()
	
	' Handling Code: Uncomment any types you wish this script to support
	' NOTE: You can toggle comments on multiple lines that are currently
	' selected with [CTRL]+[SHIFT]+[C].
	select case treeSelectedType
	
		case otPackage
			dim basePackageElement as EA.Element
			dim packagesubElement as EA.Element
			dim packageElementIndex, packageElementCount 
			set basePackageElement = Repository.GetTreeSelectedObject()
			
			packageElementCount = basePackageElement.Elements.Count - 1
			
			set basePackageElement = Repository.GetTreeSelectedObject()
			
			for packageElementIndex = 0 to packageElementCount
				set packagesubElement = basePackageElement.Elements.GetAt(packageElementIndex)
				checkUsecaseElement(packagesubElement)
			next 'packageElementIndex
	
		case otElement
			'The root usecase element
			dim usecaseElement as EA.Element
			
			'The controller class created for the usecase element. 
			dim controllerClass as EA.Element
			
			'The name for the controller class. This will be use case name + Controller. All the spaces are removed. 
			dim className 
			
			'Temporary variable and not used. 
			dim retVal 
			
			'Getting the use case element. 
			set usecaseElement = Repository.GetTreeSelectedObject()
			
			checkUsecaseElement(usecaseElement)
			
	end select
	
	if usecaseElementCount > 0 then
		Session.Prompt "Controller class created for " & usecaseControllerClassCreated &  " out of " &  usecaseElementCount & " usecases.", promptOK		
	else
		Session.Prompt "Controllers can ONLY be created for elements of type dBusinessUseCase or dBusinessUseCaseCore.", promptOK		
	end if
	
end sub


Function checkUsecaseElement(usecaseElement) 
	'The controller class created for the usecase element. 
	dim controllerClass as EA.Element
	
	'The name for the controller class. This will be use case name + Controller. All the spaces are removed. 
	dim className 
	
	'Temporary value
	dim retVal
	'The elements should be Business Use Case or Busness Use Case Core. When any other element is selected it will throw an error message to user. 
	if (usecaseElement.Stereotype = "dBusinessUseCase")  then
		'When the controller class already exist for Usecase. Throw an error. 
		if(checkUseCaseControllerClass(usecaseElement)) = 1 then
			Session.Prompt "Controller class already exist for usecase " + usecaseElement.Name, promptOK		
		'When the controller class is NOT available, then create the class. 
		else 
			className = usecaseElement.Name + "Controller"
			className = Replace(className, " ", "") 
			set controllerClass = usecaseElement.Elements.AddNew(className, "dController")
			controllerClass.stereotype = "dController"
			controllerClass.Notes = usecaseElement.Notes
			CreateConnector usecaseElement, controllerClass
			controllerClass.Update
			'Call the add Methods method which will add all the activity under the usecase as methods to the Controller class. 
			retVal = addMethods(usecaseElement, controllerClass) 
			usecaseControllerClassCreated = usecaseControllerClassCreated + 1
		end if
		usecaseElementCount = usecaseElementCount + 1
	'else 
	'	Session.Prompt "Controllers can ONLY be created for elements of type dBusinessUseCase or dBusinessUseCaseCore.", promptOK		
	end if
end function


'Function to check if the usecase element if it has an controller element with name usecase name + Controller
Function checkUseCaseControllerClass(usecaseElement)
	dim elementCount, elementIndex
	dim controllerClassElement as EA.Element
	dim className 
	
	elementCount = usecaseElement.Elements.Count - 1
	if elementCount > 0 then 
		for elementIndex = 0 to elementCount
			className = replace(usecaseElement.Name + "Controller", " ", "")
			set controllerClassElement = usecaseElement.Elements.GetAt(elementIndex)
			if (controllerClassElement.stereotype = "dController") and (controllerClassElement.Name = className) then
				checkUseCaseControllerClass = 1
				Exit For
			end if
		next 'elementCount
	else 
		checkUseCaseControllerClass = 0
	end if
end Function

'Function to add the activities under usecase to controller as methods. 
Function addMethods(usecaseElement, controllerClass) 
	dim activityElement as EA.Element
	dim elementCount, elementIndex 
	dim activityName, method
	
		elementCount = usecaseElement.Elements.Count - 1
		if elementCount > 0 then 
			for elementIndex = 0 to elementCount
				set activityElement = usecaseElement.Elements.GetAt(elementIndex)
				if activityElement.stereotype = "dActivity" or (activityElement.stereotype  = "")  then
					activityName = activityElement.Name
					activityName = Replace(activityName, " ", "") 
					set method = controllerClass.Methods.AddNew(activityName, "")
					'The notes available in activity is copied to the method notes. 
					method.Notes = activityElement.Notes
					method.Update
					addMethods = 1
				end if
			next 'elementCount
		else 
			addMethods = 0
		end if
end Function


Function CreateConnector( usecaseElement, controllerClass)


	dim connMetaclass		
	dim source as EA.Element
	dim target as EA.Element
	dim con as EA.Connector

	connMetaclass = "Realization"
	set source = Repository.GetElementByID( usecaseElement.ElementId)
	set target = Repository.GetElementByID( controllerClass.ElementId)

	set con = target.Connectors.AddNew (connMetaclass, connMetaclass )
	con.Stereotype="DAF::IsImplementedBy"
	con.SupplierID = source.ElementID
	con.Update
	source.Connectors.Refresh
	target.Connectors.Refresh
	
end Function

OnProjectBrowserScript
