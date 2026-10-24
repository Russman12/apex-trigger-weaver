/**
 * @description Sets the account description to be a comma delimited list of all the account's
 * contacts' names.
 */
public class AccountDescriptionTWAction extends TW_Action {
  public override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Account.Description);
  }

  public override void afterUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Account newAcc = (Account) newRecord;
    List<String> names = new List<String>();
    for (Contact c : ((Account) queriedRecord).Contacts) {
      names.add(c.Name);
    }

    newAcc.Description = String.join(names, ', ');
  }
}
