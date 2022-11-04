option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: CreateUsecaseUserStoryfromDiagram.vbs
' Version : 4.1
' Author: Giu 
' Purpose: This method creates a User Story from a package, and connect the new UserStory with the Use case using a association. 
' in the project browser, right click on a package containing Use Cases, 
'  select "Create User Story from Use Case" 
'  Move the created user stories in the proper package
' Date: 15-May-2020
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
		Session.Prompt "User Story created for " & usecaseControllerClassCreated &  " out of " &  usecaseElementCount & " use cases.", promptOK		
	else
		Session.Prompt "User Story  can ONLY be created for elements of type dBusinessUseCase or dBusinessUseCaseCore.", promptOK		
	end if
	
end sub


Function checkUsecaseElement(usecaseElement) 
	'The controller class created for the usecase element. 
	dim controllerClass as EA.Element
	
	'The name for the controller class. This will be use case name + Controller. All the spaces are removed. 
	dim className 
	
	'Temporary value
	dim retVal
	'The elements should be dFeature. When any other element is selected it will throw an error message to user. 
	if (usecaseElement.Stereotype = "dFeature")  then
		'When the Use Case already exist for feature. Throw an error. 
		if(checkUseCaseControllerClass(usecaseElement)) = 1 then
			Session.Prompt "usecase  already exist for Feature " + usecaseElement.Name, promptOK		
		'When the controller class is NOT available, then create the class. 
		else 
			className = usecaseElement.Name + "Use Case"
			className = Replace(className, " ", "") 
			set controllerClass = usecaseElement.Elements.AddNew(className, "dUserStory")
			controllerClass.stereotype = "dBusinessUseCase"
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
			className = replace(usecaseElement.Name + "UserStory", " ", "")
			set controllerClassElement = usecaseElement.Elements.GetAt(elementIndex)
			if (controllerClassElement.stereotype = "dBusinessUseCase") and (controllerClassElement.Name = className) then
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

end Function


Function CreateConnector( usecaseElement, controllerClass)
' create a connector between the feature and the use case

	dim connMetaclass		
	dim source as EA.Element
	dim target as EA.Element
	dim con as EA.Connector

	connMetaclass = "Realization"
	set source = Repository.GetElementByID( usecaseElement.ElementId)
	set target = Repository.GetElementByID( controllerClass.ElementId)

	set con = target.Connectors.AddNew (connMetaclass, connMetaclass )
	con.Stereotype="DAF::is realized by Use Case"
	con.SupplierID = source.ElementID
	con.Update
	source.Connectors.Refresh
	target.Connectors.Refresh
	
end Function

OnProjectBrowserScript
