/**
 * This functionality sets the account description to be a comma delimited list
 * of all child contacts whenever the account name changes.
 */
public with sharing class AccountTWNameChange extends TW_Action {
  private Map<Id, Account> accountsWithContacts;

  /**
   * Filter where the name has changed
   */
  public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Account.Name);
  }

  /**
   * Concatinate Contact names and set as Account Description
   */
  public override void beforeUpdate(SObject oldRecord, SObject newRecord) {
    Account newAccount = (Account) newRecord;
    Account queriedAccount = accountsWithContacts().get(newAccount.Id);

    String[] contactNames = new List<String>();
    for (Contact c : queriedAccount.Contacts) {
      contactNames.add(c.Name);
    }
    newAccount.Description = String.join(contactNames, ', ');
  }

  /**
   * Query child contacts once for all trigger records
   */
  private Map<Id, Account> accountsWithContacts() {
    if (accountsWithContacts == null) {
      Set<Id> accountIds = new Map<Id, SObject>(newRecords()).keySet();
      accountsWithContacts = new Map<Id, Account>([SELECT Id, (SELECT Name FROM Contacts) FROM Account WHERE Id IN :accountIds]);
    }
    return accountsWithContacts;
  }
}
