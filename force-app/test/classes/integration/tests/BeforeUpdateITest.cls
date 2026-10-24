@IsTest
public class BeforeUpdateITest {
  private static Integer setupCalls = 0;
  private static String accName = 'acc1';
  private static List<Contact> contacts = new List<Contact>{
    new Contact(FirstName = 'old firstname1', LastName = 'old lastname1', Description = 'old description 1'),
    new Contact(FirstName = 'old firstname2', LastName = 'old lastname2', Description = 'old description 2'),
    new Contact(FirstName = 'old firstname3', LastName = 'old lastname3', Description = 'old description 3'),
    new Contact(FirstName = 'skip', LastName = 'skip', Description = 'skip')
  };

  static {
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction1.class);
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction2.class);
  }

  @TestSetup
  static void setupTest() {
    Account a = new Account(Name = 'acc1', Description = 'acc description');

    for (Contact c : contacts) {
      c.AccountId = a.Id;
    }

    insert contacts;
  }

  /**
   * Ensures simple functionality executes as expected
   */
  @IsTest
  static void base() {
    List<Contact> updateContacts = [SELECT Id FROM Contact];
    updateContacts[0].FirstName = 'new firstname1';
    updateContacts[1].LastName = 'new lastname2';
    updateContacts[2].FirstName = 'new firstname3';
    updateContacts[2].LastName = 'new lastname3';
    updateContacts[3].Description = 'new description';

    Test.startTest();
    update updateContacts;
    System.Assert.areEqual(1, System.Limits.getQueries());
    System.Assert.areEqual(3, System.Limits.getQueryRows());
    System.Assert.areEqual(2, System.Limits.getDmlStatements());
    System.Assert.areEqual(5, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(2, setupCalls, 'setup should be called once');

    //Contact1
    Contact c1 = [SELECT FirstName, LastName, Description FROM Contact WHERE Id = :contacts[0].Id];
    System.Assert.areEqual('new firstname1', c1.FirstName, 'firstname not set as expected');
    System.Assert.areEqual('old lastname1', c1.LastName, 'lastname not set as expected');
    System.Assert.areEqual('', c1.Description, 'description not set as expected');
    System.Assert.areEqual('', c1.Title, 'title not set as expected');

    //Contact2
    Contact c2 = [SELECT FirstName, LastName, Description FROM Contact WHERE Id = :contacts[1].Id];
    System.Assert.areEqual('', c2.FirstName, 'firstname not set as expected');
    System.Assert.areEqual('', c2.LastName, 'lastname not set as expected');
    System.Assert.areEqual('', c2.Description, 'description not set as expected');
    System.Assert.areEqual('', c2.Title, 'title not set as expected');
  }

  /**
   * Sets desription to old first name new lastname and account name when LastName changes
   */
  public class MyAction1 extends TW_Action {
    public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
      return isChanged(Contact.FirstName);
    }

    public override void beforeUpdateSetup(TW_QuerySelector selector) {
      setupCalls++;
      selector.addParentField(new List<SObjectField>{ Contact.AccountId, Account.Name });
    }

    public override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
      Contact oContact = (Contact) oldRecord;
      Contact nContact = (Contact) newRecord;
      Contact qContact = (Contact) queriedRecord;

      String description = oContact.FirstName + ' ' + nContact.LastName + ' ' + qContact.Account.Name;
    }
  }

  /**
   * Sets title to new firstname, old lastname, and account description when Description changes
   */
  public class MyAction2 extends TW_Action {
    public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
      return ((Contact) oldRecord).LastName != ((Contact) newRecord).LastName;
    }

    public override void beforeUpdateSetup(TW_QuerySelector selector) {
      setupCalls++;
      selector.addParentField(new List<SObjectField>{ Contact.AccountId, Account.Description });
    }

    public override void beforeUpdate(SObject oldRecord, SObject newRecord, SObject queriedRecord) {
      Contact oContact = (Contact) oldRecord;
      Contact nContact = (Contact) newRecord;
      Contact qContact = (Contact) queriedRecord;

      nContact.Title = nContact.FirstName + ' ' + oContact.LastName + ' ' + qContact.Account.Description;
    }
  }
}
