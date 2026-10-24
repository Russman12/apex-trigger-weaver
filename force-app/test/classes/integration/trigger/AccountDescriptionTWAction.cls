/**
 * @description Sets the account description to be a comma delimited list of all the account's
 * contacts' names.
 */
public class AccountDescriptionTWAction extends TW_Action {
  private Map<Id, Account> accountsWithContacts;

  public override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Account.Description);
  }

  public override void afterUpdate(SObject oldRecord, SObject newRecord) {
    Account newAcc = (Account) newRecord;
    List<String> names = new List<String>();
    for (Contact c : accountsWithContacts().get(newAcc.Id).Contacts) {
      names.add(c.Name);
    }

    newAcc.Description = String.join(names, ', ');
  }

  private Map<Id, Account> accountsWithContacts() {
    if (accountsWithContacts == null) {
      Set<Id> accountIds = new Map<Id, SObject>(newRecords()).keySet();
      accountsWithContacts = new Map<Id, Account>([SELECT Id, (SELECT Name FROM Contacts) FROM Account WHERE Id IN :accountIds]);
    }
    return accountsWithContacts;
  }
}
