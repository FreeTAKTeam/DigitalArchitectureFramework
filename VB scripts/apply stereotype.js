!INC Local Scripts.EAConstants-JScript
!INC EAScriptLib.JScript-Dialog


/*
* Project Browser Script main function
* select elements in the project Broser then execute the script
*/
function OnProjectBrowserScript()
{
  	// Show the script output window
	Repository.EnsureOutputVisible( "Script" );
	
     // Get the type of element selected in the Project Browser
     var selElem as EA.Collection;

     var input=DLGInputBox( 'Enter new stereotype', 'Multi-select element update', '');
     
     selElem = Repository.GetTreeSelectedElements();
     for (i=0; i < selElem.Count; i++) {
			var e as EA.Element;
			e = selElem.GetAt(i);
			e.Stereotype = input;
			Session.Output('Element changed: '+e.Name+' changed stereotype to '+e.Stereotype);
			e.Update();
			e.Refresh();
     }
	 Session.Output('All selected elements updated.');
}

OnProjectBrowserScript();