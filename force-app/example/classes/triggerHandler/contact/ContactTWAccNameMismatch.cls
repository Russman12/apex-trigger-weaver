public with sharing class ContactTWAccNameMismatch extends TW_Function {
  public ContactTWAccNameMismatch() {
    super(ContactTWAccNameMismatch.class);
  }

  protected override void afterUpdatePreProcess(ASB_Select selection) {
    selection.parent(Contact.AccountId, Account.Name);
  }

  /**
   * Only when FirstName or LastName has changed
   */
  protected override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    Contact oldContact = (Contact) oldRecord;
    Contact newContact = (Contact) newRecord;
    return oldContact.FirstName != newContact.FirstName || oldContact.LastName != newContact.LastName;
  }

  protected override List<SObject> afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Contact oldContact = (Contact) oldRecord;
    Contact newContact = (Contact) newRecord;
    Contact queriedContact = (Contact) queriedRecord;

    if (queriedContact.Account.Name != newContact.Name) {
      updateRecord(new Account(Id = queriedContact.Account.Id, Name = ContactBusinessLogic.fullName(newContact)));
    }

    return null;
  }
}
