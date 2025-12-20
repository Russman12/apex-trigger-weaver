public class TW_Query implements TW_Queryable {
  TW_QuerySelection selection;
  Schema.SObjectType sObjType;

  public void fromSObject(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
    this.selection = new TW_QuerySelection(sObjType);
  }

  public TW_QuerySelection getSelection() {
    return this.selection;
  }

  public SObject[] run(Map<String, Object> queryParams) {
    String queryStr = this.selection.toClauseString() + ' FROM ' + this.sObjType.getDescribe().getName() + ' WHERE Id IN :recordIds';

    return Database.queryWithBinds(queryStr, queryParams, AccessLevel.SYSTEM_MODE);
  }
}
