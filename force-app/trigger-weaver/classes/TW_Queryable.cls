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
   * @param queryParams The query parameters.
   * @return The query results.
   */
  SObject[] run(Map<String, Object> queryParams);
}
