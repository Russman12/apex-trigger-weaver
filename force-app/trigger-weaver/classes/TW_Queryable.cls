public interface TW_Queryable {
  TW_QuerySelectionable getSelection();
  void fromSObject(Schema.SObjectType sObjType);
  SObject[] run(Map<String, Object> queryParams);
}
