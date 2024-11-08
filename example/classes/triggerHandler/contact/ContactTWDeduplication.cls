public with sharing class ContactTWDeduplication extends TW_Function {
  public ContactTWDeduplication() {
    super(ContactTWDeduplication.class);
  }

  private static final ASB_Select SELECTION = ASB_Select.make()
    .stitch(
      ASB_StitchQuery.relatedBy(new List<Schema.SObjectField>{ Contact.AccountId, Contact.AccountId })
        .selection(ASB_Select.make().field(Contact.AccountId).field(Contact.LastName).field(Contact.FirstName))
    );

  protected override void afterInsertPreProcess(TW_Context ctx) {
    ctx.addQuerySelection(SELECTION);
  }

  protected override Boolean afterInsertFilter(TW_Context ctx, SObject newRecord) {
    return ((Contact) newRecord).AccountId != null;
  }

  protected override List<SObject> afterInsert(TW_Context ctx, SObject newRecord, SObject queriedRecord) {
    validate((Contact) newRecord, (List<Contact>) ctx.getNew(), ((Contact) queriedRecord).Account.Contacts);
    return null;
  }

  protected override void afterUpdatePreProcess(TW_Context ctx) {
    ctx.addQuerySelection(SELECTION);
  }

  /**
   * If has parent account and firstname or lastname has changed
   */
  protected override Boolean afterUpdateFilter(TW_Context ctx, SObject oldRecord, SObject newRecord) {
    Contact oldContact = (Contact) oldRecord;
    Contact newContact = (Contact) newRecord;
    return oldContact.AccountId != null &&
      (oldContact.FirstName != newContact.FirstName ||
      oldContact.LastName != newContact.LastName);
  }

  protected override List<SObject> afterUpdate(TW_Context ctx, SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    System.debug((Contact) queriedRecord);
    System.debug(((Contact) queriedRecord).Account);
    System.debug(((Contact) queriedRecord).Account.Contacts);
    validate((Contact) newRecord, (List<Contact>) ctx.getNew(), ((Contact) queriedRecord).Account.Contacts);
    return null;
  }

  private void validate(Contact newContact, List<Contact> dmlContacts, List<Contact> siblings) {
    System.debug('validating...');
    System.debug(newContact);
    System.debug(siblings);
    for (Contact contact : (List<Contact>) dmlContacts) {
      if (isDuplicate(newContact, contact)) {
        newContact.addError('duplicate Contact detected within this batch');
      }
    }
    for (Contact contact : siblings) {
      System.debug(contact);
      if (isDuplicate(newContact, contact)) {
        newContact.addError('existing duplicate detected with id "' + contact.Id + '"');
      }
    }
  }

  private Boolean isDuplicate(Contact c1, Contact c2) {
    return c1 !== c2 &&
      c1.Id != c2.Id &&
      c1.Id != null &&
      c1.AccountId == c2.AccountId &&
      c1.LastName == c2.LastName &&
      c1.FirstName == c2.FirstName;
  }
}