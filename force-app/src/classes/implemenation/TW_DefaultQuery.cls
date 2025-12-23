/**
 * @description This class provides a basic implementation of a query. Queries
 * are always executed in system mode.
 * @group Default Implementation
 *
 * @example
 * ```
 * TW_Query query = new TW_Query();
 * query.fromSObject(Account.getSObjectType());
 * query.getSelector(); //returns TW_QuerySelectionable
 * query.run(); //returns SObject[] query results
 * ```
 */
public class TW_DefaultQuery implements TW_Query {
  private final TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();
  private Schema.SObjectType sObjType;

  public TW_DefaultQuery(Schema.SObjectType sObjType) {
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
   * TW_QuerySelection selection = query.getSelector();
   * ```
   */
  public TW_DefaultQuerySelector getSelector() {
    return this.selector;
  }

  /**
   * @description Runs the query and returns the results.
   *
   * @param records The records to query.
   * @return The query results.
   */
  public SObject[] run(List<SObject> records) {
    String queryStr = this.selector.toClauseString() + ' FROM ' + this.sObjType.getDescribe().getName() + ' WHERE Id IN :records';

    return Database.queryWithBinds(queryStr, new Map<String, Object>{ 'records' => records }, AccessLevel.SYSTEM_MODE);
  }
}
