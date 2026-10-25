/**
 * Provides integration testing for before insert context
 */
@IsTest
public class BeforeInsertITest {
  static {
    TW_ActionRegistry.register(Contact.getSObjectType(), MyAction.class);
  }

  /**
   * Ensures simple functionality executes as expected
   */
  @IsTest
  static void base() {
    List<Contact> contacts = new List<Contact>{
      new Contact(FirstName = 'firstname1', LastName = 'lastname1'),
      new Contact(FirstName = 'firstname2', LastName = 'lastname2'),
      new Contact(FirstName = 'skip', LastName = 'skip')
    };
    String expectedEmail1 = 'firstname1.lastname1@example.com';
    String expectedEmail2 = 'firstname2.lastname2@example.com';

    Test.startTest();
    insert contacts;
    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.areEqual(0, System.Limits.getQueryRows());
    System.Assert.areEqual(2, System.Limits.getDmlStatements());
    System.Assert.areEqual(5, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(expectedEmail1, [SELECT Email FROM Contact WHERE Id = :contacts[0].Id].Email, 'email not set as expected');
    System.Assert.areEqual(expectedEmail2, [SELECT Email FROM Contact WHERE Id = :contacts[1].Id].Email, 'email not set as expected');
    System.Assert.areEqual(null, [SELECT Email FROM Contact WHERE Id = :contacts[2].Id].Email, 'email not set as expected');
  }

  /**
   * Ensures trigger action is bypassed
   */
  @IsTest
  static void bypass() {
    List<Contact> contacts = new List<Contact>{
      new Contact(FirstName = 'firstname1', LastName = 'lastname1'),
      new Contact(FirstName = 'firstname2', LastName = 'lastname2')
    };

    TW_Handler.addBypass(MyAction.class);

    Test.startTest();
    insert contacts;
    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.areEqual(0, System.Limits.getQueryRows());
    System.Assert.areEqual(1, System.Limits.getDmlStatements());
    System.Assert.areEqual(2, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(null, [SELECT Email FROM Contact WHERE Id = :contacts[0].Id].Email, 'email should be unset');
  }

  /**
   * Ensures trigger action is not bypassed when removed
   */
  @IsTest
  static void removedBypass() {
    List<Contact> contacts = new List<Contact>{
      new Contact(FirstName = 'firstname1', LastName = 'lastname1'),
      new Contact(FirstName = 'firstname2', LastName = 'lastname2')
    };
    String expectedEmail = 'firstname1.lastname1@example.com';

    TW_Handler.addBypass(MyAction.class);
    TW_Handler.removeBypass(MyAction.class);

    Test.startTest();
    insert contacts;
    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.areEqual(0, System.Limits.getQueryRows());
    System.Assert.areEqual(2, System.Limits.getDmlStatements());
    System.Assert.areEqual(4, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(expectedEmail, [SELECT Email FROM Contact WHERE Id = :contacts[0].Id].Email, 'email not set as expected');
  }

  /**
   * Ensures trigger action is not bypassed when all bypasses are cleared
   */
  @IsTest
  static void clearedBypass() {
    List<Contact> contacts = new List<Contact>{
      new Contact(FirstName = 'firstname1', LastName = 'lastname1'),
      new Contact(FirstName = 'firstname2', LastName = 'lastname2')
    };
    String expectedEmail = 'firstname1.lastname1@example.com';

    TW_Handler.addBypass(MyAction.class);
    TW_Handler.clearBypasses();

    Test.startTest();
    insert contacts;
    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.areEqual(0, System.Limits.getQueryRows());
    System.Assert.areEqual(2, System.Limits.getDmlStatements());
    System.Assert.areEqual(4, System.Limits.getDmlRows());
    Test.stopTest();

    System.Assert.areEqual(expectedEmail, [SELECT Email FROM Contact WHERE Id = :contacts[0].Id].Email, 'email not set as expected');
  }

  /**
   * Automatically assigns email based on first/last name
   */
  public class MyAction extends TW_Action {
    public override Boolean beforeInsertFilter(SObject newRecord) {
      return ((Contact) newRecord).FirstName != 'skip';
    }

    public override void beforeInsert(SObject record) {
      Contact contact = (Contact) record;
      contact.Email = contact.FirstName + '.' + contact.LastName + '@example.com';

      TW_Plugin_DML dml = (TW_Plugin_DML) getPlugin(TW_Plugin_DML.class);
      dml.enqueueInsert(new Account(Name = contact.Email));
    }
  }
}
