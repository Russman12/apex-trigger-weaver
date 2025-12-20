/**
 * @description Represents functionality that is pass to
 */
public interface TW_QuerySelectionable {
  /**
   * @description Returns true if fields have been selected.
   * @return True if fields are selected.
   */
  Boolean isSet();
  /**
   * @description Adds a field to the query selection.
   * @param field Field to add.
   */
  void addField(Schema.SObjectField field);
  /**
   * @description Adds multiple fields to the query selection.
   * @param fields Fields to add.
   */
  void addFields(Schema.SObjectField[] fields);
  /**
   * @description Adds a parent field to the query selection.
   * @param relationshipPath Relationship fields to get to selection field.
   */
  void addParentField(Schema.SObjectField[] relationshipPath);
  /**
   * @description Adds a child field to the query selection.
   * @param relationshipField Relationship field from the child SObject.
   * @param childField Field to select from child.
   */
  void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField);
  /**
   * @description Adds a parent field from a child relationship. eg, SELECT (SELECT Account.Name FROM Contacts) FROM Account
   * @param relationshipField Relationship field from the child SObject.
   * @param relationshipPath Relationship fields to get to selection field.
   */
  void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath);

  /**
   * @description Returns the query selection as a string.
   * @return The query selection as a string.
   */
  String toClauseString();
}
