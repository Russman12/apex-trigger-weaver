/**
 * @description Represents functionality that can be queried.
 */
public interface TW_Query {
  /**
   * @description Returns the query selection.
   * @return The query selection.
   */
  TW_QuerySelector getSelector();

  /**
   * @description Runs the query and returns the results.
   * @param records The records to query.
   * @return The query results.
   */
  SObject[] run(List<SObject> records);
}
