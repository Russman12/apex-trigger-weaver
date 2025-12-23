/**
 * This functionality sets the account description to be a comma delimited list
 * of all child contacts whenever the account name changes.
 */
public with sharing class AccountTWNameChange extends TW_Action {
  /**
   * Filter where the name has changed
   */
  public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Account.Name);
  }

  /**
   * Add child contacts to the query with Name
   */
  public override void beforeUpdateSetup(TW_QuerySelector selection) {
    selection.addField(Account.Name);
    selection.addChildField(Contact.AccountId, Contact.Name);
  }

  /**
   * Concatinate Contact names and set as Account Description
   */
  public override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Account newAccount = (Account) newRecord;
    Account queriedAccount = (Account) queriedRecord;

    String[] contactNames = new List<String>();
    for (Contact c : queriedAccount.Contacts) {
      contactNames.add(c.Name);
    }
    newAccount.Description = String.join(contactNames, ', ');
  }
}
