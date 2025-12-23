/**
 * Sets the parent account to match the contact's full name when
 * the contact's name changes
 */
public with sharing class ContactTWAccNameMismatch extends TW_Action {
  /**
   * Select the parent account with its name field
   */
  public override void afterUpdateSetup(TW_QuerySelector selection) {
    selection.addParentField(new List<Schema.SObjectField>{ Contact.AccountId, Account.Name });
  }

  /**
   * Only execute when FirstName or LastName has changed
   */
  public override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    Contact oldContact = (Contact) oldRecord;
    Contact newContact = (Contact) newRecord;
    return oldContact.FirstName != newContact.FirstName || oldContact.LastName != newContact.LastName;
  }

  /**
   * If parent account name does not match the contact's full name, update it
   */
  public override void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Contact oldContact = (Contact) oldRecord;
    Contact newContact = (Contact) newRecord;
    Contact queriedContact = (Contact) queriedRecord;

    if (queriedContact.Account.Name != newContact.Name) {
      this.getDMLQueue().enqueueUpdate(new Account(Id = newContact.AccountId, Name = ContactBusinessLogic.fullName(newContact)));
    }
  }
}
