public class TW_Query implements TW_Queryable {
  Set<Schema.SObjectField> fields = new Set<Schema.SobjectField>();
  Set<List<Schema.SObjectField>> parentFields = new Set<List<Schema.SobjectField>>();
  Map<Schema.SObjectField, Set<List<Schema.SObjectField>>> childRelationships = new Map<String, Set<List<Schema.SObjectField>>>();

  Schema.SObjectType sObjType;

  public void fromObject(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
  }
  void addField(Schema.SObjectField field) {
    this.fields.add(field);
  }
  void addFields(Schema.SObjectField[] fields) {
    this.fields.addAll(fields);
  }
  void addParentField(Schema.SObjectField[] relationshipPath) {
    this.parentFields.add(relationshipPath);
  }
  void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField) {
    addChildParentField(relationshipField, new List<Schema.SObjectField>{ childField });
  }
  void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath) {
    if (!this.childRelationships.containsKey(relationshipField)) {
      this.childRelationships.put(relationshipField, new Set<Schema.SObjectField>());
    }
    this.childRelationships.get(relationshipField).add(relationshipPath);
  }

  SObject[] run(Map<String, Object> queryParams) {
    System.debug(this.buildQuery());
    return Database.queryWithBinds(this.buildQuery(), queryParams, AccessLevel.SYSTEM_MODE);
  }

  private String buildQuery() {
    String queryStr = 'SELECT ';
    List<String> fieldStrs = new List<String>();
    for (Schema.SObjectField field : this.fields) {
      fieldStrs.add(field.getDescribe().getName());
    }

    for (List<Schema.SObjectField> relationshipPath : this.parentFields) {
      queryStr += getParentRelationshipName(relationshipPath);
    }

    for (Schema.SObjectField relationship : this.childRelationships.keySet()) {
      String fieldStrs = new List<String>{};
      for (Schema.SobjectField[] relationshipPath : this.childRelationships.get(relationship)) {
        fieldStrs.add(getParentRelationshipName(relationshipPath));
      }
      subQuery += '(' + fieldStrs.join(', ') + ' FROM ' + getChildRelationshipName(relationship) + ')';
    }

    queryStr += fieldStrs.join(', ');

    return queryStr + 'Id IN :recordIds';
  }

  private String getParentRelationshipName() {
    String[] pathStrs = new List<String>{};
    for (Schema.SObjectField field : relationshipPath) {
      pathStrs.add(field.getDescribe().getName() + '.');
    }
    return pathStrs.join('.');
  }

  private String getChildRelationshipName() {
    for (Schema.ChildRelationship cr : this.SObjectType.getChildRelationships()) {
      if (cr.getRelationshipName() == null) {
        continue;
      }
      return String.valueOf(cr.getRelationshipName());
    }
  }
}
