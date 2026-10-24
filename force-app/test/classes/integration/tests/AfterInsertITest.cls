/**
 * Provides integration testing for after insert context
 */
@IsTest
public class AfterInsertITest {
  private static String accName = 'acc1';

  static {
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction.class);
  }

  @TestSetup
  static void setupTest() {
    insert new Account(Name = 'acc1');
  }

  /**
   * Ensures simple functionality executes as expected
   */
  @IsTest
  static void base() {
    Id accId = [SELECT Id FROM Account WHERE Name = :accName].Id;

    List<Contact> contacts = new List<Contact>{
      new Contact(FirstName = 'firstname1', LastName = 'lastname1', AccountId = accId),
      new Contact(FirstName = 'firstname2', LastName = 'lastname2', AccountId = accId),
      new Contact(FirstName = 'skip', LastName = 'skip', AccountId = accId)
    };

    Test.startTest();
    insert contacts;
    System.Assert.areEqual(1, System.Limits.getQueries());
    System.Assert.areEqual(3, System.Limits.getQueryRows());
    System.Assert.areEqual(2, System.Limits.getDmlStatements());
    System.Assert.areEqual(5, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(
      accName,
      [SELECT Description FROM Contact WHERE Id = :contacts[0].Id].Description,
      'description not set as expected'
    );
    System.Assert.areEqual(
      accName,
      [SELECT Description FROM Contact WHERE Id = :contacts[1].Id].Description,
      'description not set as expected'
    );
    System.Assert.areEqual(
      accName,
      [SELECT Description FROM Contact WHERE Id = :contacts[1].Id].Description,
      'description not set as expected'
    );
  }

  /**
   * Assigns description to parent account name
   */
  public class MyAction extends TW_Action implements DMLQueueAware {
    private Map<Id, Contact> queriedContacts;
    private DMLQueue dml;

    public void setDMLQueue(DMLQueue queue) {
      this.dml = queue;
    }

    public override Boolean afterInsertFilter(SObject newRecord) {
      return ((Contact) newRecord).FirstName != 'skip';
    }

    public override void afterInsert(SObject newRecord) {
      Contact nContact = (Contact) newRecord;
      Contact qContact = queriedContacts().get(nContact.Id);

      dml.enqueueUpdate(new Contact(Id = nContact.Id, Description = qContact.Account.Name));
    }

    private Map<Id, Contact> queriedContacts() {
      if (queriedContacts == null) {
        Set<Id> contactIds = new Map<Id, SObject>(newRecords()).keySet();
        queriedContacts = new Map<Id, Contact>([SELECT Id, Account.Name FROM Contact WHERE Id IN :contactIds]);
      }
      return queriedContacts;
    }
  }
}
