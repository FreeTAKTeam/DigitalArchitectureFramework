!INC Local Scripts.EAConstants-JScript
// Replace the file below with another element list to reuse this script.
//!INC Conversion Scripts.ConversionTable

function TypeConversion(sourceObject,sourceStereotype,targetObject, targetStereotype)
{
    this.sourceObject = sourceObject;
    this.sourceStereotype = sourceStereotype;
    this.targetObject = targetObject;
    this.targetStereotype = targetStereotype;
}

var Conversions = new Array();

//Convert standards to MDG standard
Conversions[0] = new TypeConversion("Attribute", "ChiValue", "Class", "Chronos::ChiNode");

// =================================================================================
// Name: Element Conversion
// Converts elements type and stereotype as defined in the element conversation table.
// The table is included as a file so it may be changed for other mappings
// Navigates from selected package and recursively modifies each element
// NOTE: Requires a package to be selected in the Project Browser
//
// Related APIs
// =================================================================================
// Element API - http://www.sparxsystems.com/enterprise_architect_user_guide/10/automation_and_scripting/element2.html
// Repository API http://www.sparxsystems.com/enterprise_architect_user_guide/10/automation_and_scripting/repository3.html
// Tagged Value API http://www.sparxsystems.com/enterprise_architect_user_guide/10/automation_and_scripting/taggedvalue.html

function StartWithSelectedPackage()
{
    // Show the script output window
    Repository.EnsureOutputVisible( "Script" );

    Session.Output( "JScript TypeConverstion" );
    Session.Output( "===========================" );

    var thePackage as EA.Package;
    thePackage = Repository.GetTreeSelectedPackage();
   
    if ( thePackage != null && thePackage.ParentID != 0 )
    {
        NavigatePackage( "", thePackage );
    }
    else
    {
        Session.Prompt( "This script requires a package to be selected in the Project Browser.\n" +
            "Please select a package in the Project Browser and try again.", promptOK );
    }
   
    Session.Output( "Done!" );
}

//
// Outputs the packages name and elements, and then recursively processes any child
// packages
//
// Parameters:
// - indent A string representing the current level of indentation
// - thePackage The package object to be processed
//
function NavigatePackage( indent, thePackage )
{
    // Cast thePackage to EA.Package so we get intellisense
    var currentPackage as EA.Package;
    currentPackage = thePackage;
   
    // Add the current package's name to the list
    Session.Output( indent + currentPackage.Name + " (PackageID=" +
        currentPackage.PackageID + ")" );
   
    // Convert the elements this package contains
    ConvertElementsInPackage( indent + "    ", currentPackage );
   
    // Recursively process any child packages
    var childPackageEnumerator = new Enumerator( currentPackage.Packages );
    while ( !childPackageEnumerator.atEnd() )
    {
        var childPackage as EA.Package;
        childPackage = childPackageEnumerator.item();
        NavigatePackage( indent + "    ", childPackage );
       
        childPackageEnumerator.moveNext();
    }
}

//
// Converts the elements of the provided package to the Script output window
//
// Parameters:
// - indent A string representing the current level of indentation
// - thePackage The package object to be processed
//
function ConvertElementsInPackage( indent, thePackage )
{
    // Cast thePackage to EA.Package so we get intellisense
    var currentPackage as EA.Package;
    currentPackage = thePackage;
   
    // Iterate through all elements and add them to the list
    var elementEnumerator = new Enumerator( currentPackage.Elements );
    while ( !elementEnumerator.atEnd() )
    {
        var currentElement as EA.Element;
        currentElement = elementEnumerator.item();
        ConvertElements(indent+"    ",currentElement );

        elementEnumerator.moveNext();
    }
}

function ConvertElements( indent, theElement )
{
    // Cast theElement to EA.Element so we get intellisense
    var currentElement as EA.Element;
    currentElement = theElement;
    currentElement.ObjectType
    ConvertElement(indent+"    ",currentElement );
    // Iterate through all embedded elements and add them to the list
    var elementEnumerator = new Enumerator( currentElement.Elements );
    while ( !elementEnumerator.atEnd() )
    {
        var currentElement as EA.Element;
        currentElement = elementEnumerator.item();
        ConvertElements(indent+"    ",currentElement );
        elementEnumerator.moveNext();
    }
}

// Converts the element from BSIF to
//
// Parameters:
// - indent A string representing the current level of indentation
// - theElement The element object to be processed
function ConvertElement( indent, theElement )
{
// Debug Comment out when run for real
    //Session.Output( indent + "CALLED: ConvertElement with " + theElement.Name + " [" + theElement.Type + ", " + theElement.Stereotype + " )" );

    for ( var i = 0 ; i < Conversions.length ; i++ )
    {
        // If want to limit to stereotype that matches source list then convert
 //       if ( (theElement.Stereotype == Conversions[i].sourceStereotype) && (theElement.Type == Conversions[i].sourceObject ))
        {
            Session.Output( indent + "CONVERTED: " + theElement.Name + " (" + theElement.Type + ", " + theElement.Stereotype + ")" + "=>" +"("+Conversions[i].targetObject+","+Conversions[i].targetStereotype+")" );
             theElement.Type = Conversions[i].targetObject;
            //Overright the stereotype list to have only one stereotype
            theElement.StereotypeEx = Conversions[i].targetStereotype;
            theElement.Update();
            break; // once found cease iterating through for-loop.
        }
    }
}

StartWithSelectedPackage();