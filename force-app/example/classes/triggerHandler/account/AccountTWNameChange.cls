public with sharing class AccountTWNameChange extends TW_Function {
  public AccountTWNameChange() {
    super(AccountTWNameChange.class);
  }

  protected override void beforeUpdatePreProcess(ASB_Select selection) {
    selection.field(Account.Name).subQuery(ASB_SubQuery.relatedBy(Contact.AccountId).selectField(Contact.Name));
  }

  protected override Boolean beforeUpdatefilter(SObject oldRecord, SObject newRecord) {
    return ((Account) oldRecord).Name != ((Account) newRecord).Name;
  }

  protected override List<SObject> beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
    Account newAccount = (Account) newRecord;
    Account queriedAccount = (Account) queriedRecord;

    newAccount.Tradestyle = AccountBusinessLogic.contactNames(queriedAccount);

    return null;
  }
}
