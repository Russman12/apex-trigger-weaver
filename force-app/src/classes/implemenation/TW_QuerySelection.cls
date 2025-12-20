/**
 * @description This class provides a basic implementation of a query selection.
 * @group Default Implementation
 *
 * @example
 * ```
 * TW_QuerySelection query = new TW_QuerySelection(Account.SObjectType);
 * query.addField(Account.Name);
 * ```
 */
public with sharing class TW_QuerySelection implements TW_QuerySelectionable {
  private final Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>();
  private final Set<List<Schema.SObjectField>> parentFields = new Set<List<Schema.SObjectField>>();
  private final Map<Schema.SObjectField, Set<List<Schema.SObjectField>>> childRelationships = new Map<Schema.SObjectField, Set<List<Schema.SObjectField>>>();
  private Boolean isSet = false;

  /**
   * @description Returns true if the query selection has been set.
   *
   * @return Boolean
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addField(Account.Name);
   * System.Assert.isTrue(query.isSet());
   * ```
   */
  public Boolean isSet() {
    return this.isSet;
  }

  /**
   * @description Adds a field to the query selection.
   *
   * @param field The field to add.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addField(Account.Name);
   * System.Assert.isTrue(query.isSet());
   * ```
   */
  public void addField(Schema.SObjectField field) {
    this.fields.add(field);
    this.isSet = true;
  }

  /**
   * @description Adds multiple fields to the query selection.
   *
   * @param fields The fields to add.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addFields(new List<Schema.SObjectField>{ Account.Name, Account.Phone });
   * ```
   */
  public void addFields(Schema.SObjectField[] fields) {
    this.fields.addAll(fields);
    this.isSet = true;
  }

  /**
   * @description Adds a parent field to the query selection.
   *
   * @param relationshipPath The relationship path to add.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addParentField(new List<Schema.SObjectField>{ Account.ParentId, Account.Phone });
   * ```
   */
  public void addParentField(Schema.SObjectField[] relationshipPath) {
    this.parentFields.add(relationshipPath);
    this.isSet = true;
  }

  /**
   * @description Adds a child field to the query selection.
   *
   * @param relationshipField The relationship field to add.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addChildField(Contact.AccountId, Contact.FirstName);
   * ```
   */
  public void addChildField(Schema.SObjectField relationshipField, Schema.SObjectField childField) {
    addChildParentField(relationshipField, new List<Schema.SObjectField>{ childField });
    this.isSet = true;
  }

  /**
   * @description Adds a child field to the query selection.
   *
   * @param relationshipField The relationship field to add.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addChildParentField(Contact.AccountId, new List<Schema.SObjectField>{ Contact.AccountId, Account.Phone });
   */
  public void addChildParentField(Schema.SObjectField relationshipField, Schema.SObjectField[] relationshipPath) {
    if (!this.childRelationships.containsKey(relationshipField)) {
      this.childRelationships.put(relationshipField, new Set<Schema.SObjectField[]>());
    }
    this.childRelationships.get(relationshipField).add(relationshipPath);
    this.isSet = true;
  }

  /**
   * @description Returns the query selection as a string.
   *
   * @return The query selection as a string.
   *
   * @example
   * ```
   * TW_QuerySelection query = new TW_QuerySelection();
   * query.addField(Account.Name);
   * query.addChildField(Contact.AccountId, Contact.FirstName);
   * query.toClauseString(); //returns "SELECT Name, (SELECT FirstName FROM Contacts)"
   * ```
   */
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
