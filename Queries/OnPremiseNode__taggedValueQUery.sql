SELECT OnPremiseNode.Object_ID, OnPremiseNode.ea_guid AS CLASSGUID , OnPremiseNode.Object_Type AS CLASSTYPE, OnPremiseNode.Name as OnPremiseNode
FROM t_object as OnPremiseNode
 WHERE OnPremiseNode.stereotype= 'dOnPremise'