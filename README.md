# Digital Architecture Framework
## Welcome!
Welcome to the repository for the DAF MDG (Model Driven Generator) for Sparx Enterprise Architect. This repository contains various resources to enhance  users modeling experience in Sparx EA.

## About
The Digital Architecture Framework (DAF),  is a set modeling tools for Digital Engineering. 
His Metamodel describes a modeling language which defines the notation for all elements used in the different stages of an organization life cycle to support the concept of Digital Engineering (DE), from the requirement to the application.
![image](https://github.com/FreeTAKTeam/DigitalArchitectureFramework/assets/60719165/47281215-ca1e-45f1-8020-1885955156ab)
DAF metamodel can be supported by frameworks in any language that support good object orientation. 
An example is [DigitalPy](https://github.com/FreeTAKTeam/DigitalPy) .

# Folder Structure
* Add-In: Contains additional functionalities that can be integrated into Sparx EA. (e.g. the Relationship Manager)
* checks: code for model validation and quality checks to be used with the EA Validator.
* CSV Imports: Templates for importing TMF metamodel data into EA using CSV files.
* Diagram Patterns: Predefined diagram patterns for quick modeling.
* docs: Documentation related to the Metamodel
* Document Generation Templates: Templates for generating documents from EA models.
* Icons: TMF icons used in the MDG.
* Model: Project containing the Definitions of the metamodel used by the MDG.
* Model Test: Project for testing TMF Metamodel model integrity and functionality.
* MS Office Profiles: Integration profiles for Microsoft Office Addin.
* Profile Diagram:  profiles defining Diagrams tyoes  used in the MDG.
* Profile Ecore: Ecore variant of TMF UML  profile.
* Profile Toolbox: Profile for the Toolboxes containing the tools used in the MDG.
* Profile UML: UML profiles specific to the TMF MDG.
* Quick link: implementation of the Metamodel as Quicklink definitions for faster model navigation.
* Reference Data: Reference data used in the MDG.
* Scripts: Scripts to automate tasks within EA. Most scripts are not versioned here
* Shape Scripts: Scripts to define custom shapes for TMF model elements.
* SQL Queries: SQL queries for extracting and manipulating metamodel data.
* Technology: this contains the Core technology files for the MDG.
* transformations: Model transformation scripts.
* xslt: XSLT scripts for transforming and generating content and producing a HTMl diff file.
  
# Getting Started
To get started with this MDG:

* Clone the repository.
* Import the relevant profiles and scripts into Sparx EA.
* Follow the [MDG documentation](https://sparxsystems.com/resources/user-guides/modeling/mdg-technologies.pdf)  for detailed usage instructions.

# License
This project is licensed under the EPL License. See the LICENSE file for details.
