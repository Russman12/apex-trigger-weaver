/**
 * Sets  the account description to be a comma delimited list of all the account's
 * contacts' names.
 */
public class ContactSetAccDescTWAction extends TW_Action {
  public override Boolean afterUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Contact.Name);
  }

  /**
   * "Bump" the parent account description to allow the account description to be updated.
   */
  public override void afterUpdate(SObject oldRecord, SObject newRecord) {
    TW_Plugin_DML dml = (TW_Plugin_DML) getPlugin(TW_Plugin_DML.class);
    dml.enqueueUpdate(new Account(Id = ((Contact) newRecord).AccountId, Description = ''));
  }
}
