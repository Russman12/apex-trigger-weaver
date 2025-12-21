/**
 * @description This class provides a basic implementation of a query. Queries
 * are always executed in system mode.
 * @group Default Implementation
 *
 * @example
 * ```
 * TW_Query query = new TW_Query();
 * query.fromSObject(Account.getSObjectType());
 * query.getSelection(); //returns TW_QuerySelectionable
 * query.run(); //returns SObject[] query results
 * ```
 */
public class TW_Query implements TW_Queryable {
  private final TW_QuerySelection selection = new TW_QuerySelection();
  private Schema.SObjectType sObjType;

  /**
   * @description Assigns the FROM clause for query to given SObject.
   *
   * @param sObjType The SObject type to query.
   *
   * @example
   * ```
   * TW_Query query = new TW_Query();
   * query.fromSObject(Account.getSObjectType());
   * ```
   */
  public void fromSObject(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
  }

  /**
   * @description Returns the query selection.
   *
   * @return The query selection.
   *
   * @example
   * ```
   * TW_Query query = new TW_Query();
   * query.fromSObject(Account.getSObjectType());
   * TW_QuerySelection selection = query.getSelection();
   * ```
   */
  public TW_QuerySelection getSelection() {
    return this.selection;
  }

  /**
   * @description Runs the query and returns the results.
   *
   * @param records The records to query.
   * @return The query results.
   */
  public SObject[] run(List<SObject> records) {
    String queryStr = this.selection.toClauseString() + ' FROM ' + this.sObjType.getDescribe().getName() + ' WHERE Id IN :records';

    return Database.queryWithBinds(queryStr, new Map<String, Object>{ 'records' => records }, AccessLevel.SYSTEM_MODE);
  }
}
