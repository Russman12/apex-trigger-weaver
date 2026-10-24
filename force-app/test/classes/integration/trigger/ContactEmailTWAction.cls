/**
 * Automatically assigns email based on first/last name
 */
public class ContactEmailTWAction extends TW_Action {
  public override void beforeInsert(SObject record) {
    Contact contact = (Contact) record;
    contact.Email = contact.FirstName + '.' + contact.LastName + '@example.com';
  }

  public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return anyChanged(new List<Schema.SObjectField>{ Contact.FirstName, Contact.LastName });
  }

  public override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Contact contact = (Contact) newRecord;
    contact.Email = contact.FirstName + '-' + contact.LastName + '@example.com';
  }
}
