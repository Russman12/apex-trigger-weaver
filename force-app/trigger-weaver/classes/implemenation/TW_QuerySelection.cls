public with sharing class TW_QuerySelection implements TW_QuerySelectionable {
  private final Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>();
  private final Set<List<Schema.SObjectField>> parentFields = new Set<List<Schema.SObjectField>>();
  private final Map<Schema.SObjectField, Set<List<Schema.SObjectField>>> childRelationships = new Map<Schema.SObjectField, Set<List<Schema.SObjectField>>>();

  private final Schema.SObjectType sObjType;

  private Boolean isSet = false;

  public TW_QuerySelection(Schema.SObjectType sObjType) {
    this.sObjType = sObjType;
  }

  public Boolean isSet() {
    return this.isSet;
  }

  public void addField(Schema.SObjectField field) {
    this.fields.add(field);
    this.isSet = true;
  }

  public void addFields(Schema.SObjectField[] fields) {
    this.fields.addAll(fields);
    this.isSet = true;
  }

  public void addParentField(Schema.SObjectField[] relationshipPath) {
    this.parentFields.add(relationshipPath);
    this.isSet = true;
  }

  public void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField) {
    addChildParentField(relationshipField, new List<Schema.SObjectField>{ childField });
    this.isSet = true;
  }

  public void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath) {
    if (!this.childRelationships.containsKey(relationshipField)) {
      this.childRelationships.put(relationshipField, new Set<Schema.SObjectField[]>());
    }
    this.childRelationships.get(relationshipField).add(relationshipPath);
    this.isSet = true;
  }

  public String toClauseString() {
    List<String> fieldStrs = new List<String>();
    for (Schema.SObjectField field : this.fields) {
      fieldStrs.add(field.getDescribe().getName());
    }

    for (List<Schema.SObjectField> relationshipPath : this.parentFields) {
      fieldStrs.add(getParentRelationshipName(relationshipPath));
    }

    for (Schema.SObjectField relationship : this.childRelationships.keySet()) {
      String[] sqFieldStrs = new List<String>{};
      for (Schema.SobjectField[] relationshipPath : this.childRelationships.get(relationship)) {
        sqFieldStrs.add(getParentRelationshipName(relationshipPath));
      }
      fieldStrs.add('(SELECT ' + String.join(sqFieldStrs, ', ') + ' FROM ' + getChildRelationshipName(relationship) + ')');
    }

    return 'SELECT ' + String.join(fieldStrs, ', ');
  }

  private String getParentRelationshipName(Schema.SObjectField[] relationshipPath) {
    String[] pathStrs = new List<String>{};

    for (Integer i = 0; i < relationshipPath.size(); i++) {
      Schema.SObjectField field = relationshipPath[i];
      if (i < relationshipPath.size() - 1) {
        pathStrs.add(field.getDescribe().getRelationshipName());
      } else {
        pathStrs.add(field.getDescribe().getName());
      }
    }
    return String.join(pathStrs, '.');
  }

  private String getChildRelationshipName(Schema.SObjectField relationshipField) {
    for (Schema.ChildRelationship cr : relationshipField.getDescribe().getReferenceTo()[0].getDescribe().getChildRelationships()) {
      if (cr.getField() == relationshipField) {
        return String.valueOf(cr.getRelationshipName());
      }
    }

    throw new InvalidRelationshipException('No child relationship found for ' + relationshipField.getDescribe().getName());
  }

  class InvalidRelationshipException extends Exception {
  }
}
