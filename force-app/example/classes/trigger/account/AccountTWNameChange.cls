/**
 * This functionality sets the account description to be a comman delimited list
 * of all child contacts whenever the account name changes.
 */
public with sharing class AccountTWNameChange extends TW_Action {
  /**
   * Add child contacts to the query with Name
   */
  protected override void beforeUpdateSetup(TW_QuerySelectionable selection) {
    selection.addField(Account.Name);
    selection.addChildField(Contact.AccountId, Contact.Name);
  }

  /**
   * Filter where the name has changed
   */
  protected override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return ((Account) oldRecord).Name != ((Account) newRecord).Name;
  }

  /**
   * Concatinate Contact names and set as Account Description
   */
  protected override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Account newAccount = (Account) newRecord;
    Account queriedAccount = (Account) queriedRecord;

    String[] contactNames = new List<String>();
    for (Contact c : queriedAccount.Contacts) {
      contactNames.add(c.Name);
    }
    newAccount.Description = String.join(contactNames, ', ');
  }
}
