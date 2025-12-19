public interface TW_Queryable {
  void fromObject(Schema.SObjectType sObjType);

  void addField(Schema.SObjectField field);
  void addFields(Schema.SObjectField[] fields);
  void addParentField(Schema.SObjectField[] relationshipPath);
  void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField);
  void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField childField);

  SObject[] run(Map<String, Object> queryParams);
}
