/**
 * @description Represents functionality that can be queried.
 */
public interface TW_Queryable {
  /**
   * @description Returns the query selection.
   * @return The query selection.
   */
  TW_QuerySelectionable getSelection();
  /**
   * @description Assigns the FROM clause for query to given SObject.
   * @param sObjType The SObject type to query.
   */
  void fromSObject(Schema.SObjectType sObjType);
  /**
   * @description Runs the query and returns the results.
   * @param records The records to query.
   * @return The query results.
   */
  SObject[] run(List<SObject> records);
}
