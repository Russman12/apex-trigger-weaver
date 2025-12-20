public interface TW_QuerySelectionable {
  Boolean isSet();
  void addField(Schema.SObjectField field);
  void addFields(Schema.SObjectField[] fields);
  void addParentField(Schema.SObjectField[] relationshipPath);
  void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField);
  void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath);
  String toClauseString();
}
