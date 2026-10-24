/**
 * Provides integration testing for before update context
 */
@IsTest
public class BeforeUpdateITest {
  static {
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction1.class);
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction2.class);
  }

  @TestSetup
  static void setupTest() {
    Account a = new Account(Name = 'acc1', Description = 'acc description');
    insert a;

    insert new List<Contact>{
      new Contact(FirstName = 'old firstname1', LastName = 'old lastname1', Description = 'old description 1', AccountId = a.Id),
      new Contact(FirstName = 'old firstname2', LastName = 'old lastname2', Description = 'old description 2', AccountId = a.Id),
      new Contact(FirstName = 'old firstname3', LastName = 'old lastname3', Description = 'old description 3', AccountId = a.Id),
      new Contact(FirstName = 'skip', LastName = 'skip', Description = 'skip', AccountId = a.Id)
    };
  }

  /**
   * Ensures simple functionality executes as expected
   */
  @IsTest
  static void base() {
    Map<String, Contact> contactsByDesc = contactsByDescription();
    List<Contact> updateContacts = new List<Contact>{
      new Contact(Id = contactsByDesc.get('old description 1').Id, FirstName = 'new firstname1'),
      new Contact(Id = contactsByDesc.get('old description 2').Id, LastName = 'new lastname2'),
      new Contact(Id = contactsByDesc.get('old description 3').Id, FirstName = 'new firstname3', LastName = 'new lastname3'),
      new Contact(Id = contactsByDesc.get('skip').Id, Description = 'new description')
    };

    Test.startTest();
    update updateContacts;
    System.Assert.areEqual(2, System.Limits.getQueries());
    System.Assert.areEqual(8, System.Limits.getQueryRows());
    System.Assert.areEqual(1, System.Limits.getDmlStatements());
    System.Assert.areEqual(4, System.Limits.getDmlRows());
    Test.stopTest();

    Map<Id, Contact> results = new Map<Id, Contact>([SELECT FirstName, LastName, Description, Title FROM Contact]);

    //Contact1: FirstName changed
    Contact c1 = results.get(updateContacts[0].Id);
    System.Assert.areEqual('old firstname1 old lastname1 acc1', c1.Description, 'description not set as expected');
    System.Assert.isNull(c1.Title, 'title should be unset');

    //Contact2: LastName changed
    Contact c2 = results.get(updateContacts[1].Id);
    System.Assert.areEqual('old description 2', c2.Description, 'description should be unchanged');
    System.Assert.areEqual('old firstname2 old lastname2 acc description', c2.Title, 'title not set as expected');

    //Contact3: FirstName and LastName changed
    Contact c3 = results.get(updateContacts[2].Id);
    System.Assert.areEqual('old firstname3 new lastname3 acc1', c3.Description, 'description not set as expected');
    System.Assert.areEqual('new firstname3 old lastname3 acc description', c3.Title, 'title not set as expected');

    //Contact4: neither name changed
    Contact c4 = results.get(updateContacts[3].Id);
    System.Assert.areEqual('new description', c4.Description, 'description not set as expected');
    System.Assert.isNull(c4.Title, 'title should be unset');
  }

  private static Map<String, Contact> contactsByDescription() {
    Map<String, Contact> contactsByDesc = new Map<String, Contact>();
    for (Contact c : [SELECT Id, Description FROM Contact]) {
      contactsByDesc.put(c.Description, c);
    }
    return contactsByDesc;
  }

  /**
   * Sets description to old firstname, new lastname, and account name when FirstName changes
   */
  public class MyAction1 extends TW_Action {
    private Map<Id, Contact> queriedContacts;

    public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
      return isChanged(Contact.FirstName);
    }

    public override void beforeUpdate(SObject oldRecord, SObject newRecord) {
      Contact oContact = (Contact) oldRecord;
      Contact nContact = (Contact) newRecord;
      Contact qContact = queriedContacts().get(nContact.Id);

      nContact.Description = oContact.FirstName + ' ' + nContact.LastName + ' ' + qContact.Account.Name;
    }

    private Map<Id, Contact> queriedContacts() {
      if (queriedContacts == null) {
        Set<Id> contactIds = new Map<Id, SObject>(newRecords()).keySet();
        queriedContacts = new Map<Id, Contact>([SELECT Id, Account.Name FROM Contact WHERE Id IN :contactIds]);
      }
      return queriedContacts;
    }
  }

  /**
   * Sets title to new firstname, old lastname, and account description when LastName changes
   */
  public class MyAction2 extends TW_Action {
    private Map<Id, Contact> queriedContacts;

    public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
      return ((Contact) oldRecord).LastName != ((Contact) newRecord).LastName;
    }

    public override void beforeUpdate(SObject oldRecord, SObject newRecord) {
      Contact oContact = (Contact) oldRecord;
      Contact nContact = (Contact) newRecord;
      Contact qContact = queriedContacts().get(nContact.Id);

      nContact.Title = nContact.FirstName + ' ' + oContact.LastName + ' ' + qContact.Account.Description;
    }

    private Map<Id, Contact> queriedContacts() {
      if (queriedContacts == null) {
        Set<Id> contactIds = new Map<Id, SObject>(newRecords()).keySet();
        queriedContacts = new Map<Id, Contact>([SELECT Id, Account.Description FROM Contact WHERE Id IN :contactIds]);
      }
      return queriedContacts;
    }
  }
}
