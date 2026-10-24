/**
 * Sets the parent account to match the contact's full name when
 * the contact's name changes
 */
public with sharing class ContactTWAccNameMismatch extends TW_Action {
  private Map<Id, Account> parentAccounts;

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
  public override void afterUpdate(SObject oldRecord, SObject newRecord) {
    Contact newContact = (Contact) newRecord;
    Account parentAccount = parentAccounts().get(newContact.AccountId);

    if (parentAccount != null && parentAccount.Name != newContact.Name) {
      this.getDMLQueue().enqueueUpdate(new Account(Id = newContact.AccountId, Name = ContactBusinessLogic.fullName(newContact)));
    }
  }

  /**
   * Query parent accounts once for all trigger records
   */
  private Map<Id, Account> parentAccounts() {
    if (parentAccounts == null) {
      Set<Id> accountIds = new Set<Id>();
      for (Contact c : (List<Contact>) newRecords()) {
        accountIds.add(c.AccountId);
      }
      parentAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accountIds]);
    }
    return parentAccounts;
  }
}
