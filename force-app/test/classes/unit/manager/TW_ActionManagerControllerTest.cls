/**
 * @description Provides unit test coverage for TW_ActionManagerController
 */
@IsTest
public class TW_ActionManagerControllerTest {
  private static final Id JOB_ID = '0Af000000000001AAA';

  /**
   * Ensures sObjectOptions lists SObjects with a framework trigger or actions, with their action count
   */
  @IsTest
  static void sObjectOptions() {
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('AccountDescriptionTWAction', 'account', '2'),
      record('ContactEmailTWAction', 'Task', '1')
    };

    Test.startTest();
    Map<String, TW_ActionManagerController.SObjectOption> optionsByName = new Map<String, TW_ActionManagerController.SObjectOption>();
    for (TW_ActionManagerController.SObjectOption o : TW_ActionManagerController.sObjectOptions()) {
      optionsByName.put(o.apiName, o);
    }
    Test.stopTest();

    System.Assert.isTrue(optionsByName.get('Account').hasFrameworkTrigger, 'Account trigger not detected');
    System.Assert.areEqual(2, optionsByName.get('Account').actionCount, 'unexpected Account action count');
    // Listed for its action whether or not the org has a Task trigger
    System.Assert.areEqual(1, optionsByName.get('Task').actionCount, 'unexpected Task action count');
    for (TW_ActionManagerController.SObjectOption o : optionsByName.values()) {
      System.Assert.isTrue(o.hasFrameworkTrigger || o.actionCount > 0, o.apiName + ' has no framework trigger or actions');
    }
  }

  /**
   * Ensures actionClassOptions lists classes that extend TW_Action, including those that already have actions
   */
  @IsTest
  static void actionClassOptions() {
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'Account', '1') };

    Test.startTest();
    List<String> names = TW_ActionManagerController.actionClassOptions();
    Test.stopTest();

    System.Assert.isTrue(names.contains('ContactEmailTWAction'), 'action class not listed');
    System.Assert.isTrue(names.contains('AccountTWNameChange'), 'class with an action not listed');
    System.Assert.isFalse(names.contains('TW_Handler'), 'class that does not extend TW_Action listed');
    System.Assert.isFalse(names.contains('TW_Action'), 'TW_Action listed');
  }

  /**
   * Ensures actions returns the SObject's actions in execution order with any problems
   */
  @IsTest
  static void actions() {
    TW_Action__mdt inactive = record('ContactEmailTWAction', 'Account', 'a');
    inactive.Active__c = false;
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', 'b'),
      record('TW_DoesNotExist', 'Account', null),
      inactive,
      record('AccountDescriptionTWAction', 'Account', 'b'),
      record('ContactSetAccDescTWAction', 'Contact', '1')
    };

    Test.startTest();
    List<TW_ActionManagerController.ActionRow> rows = TW_ActionManagerController.actions('account');
    Test.stopTest();

    List<String> names = new List<String>();
    for (TW_ActionManagerController.ActionRow r : rows) {
      names.add(r.developerName);
    }
    System.Assert.areEqual(
      new List<String>{ 'ContactEmailTWAction', 'AccountDescriptionTWAction', 'AccountTWNameChange', 'TW_DoesNotExist' },
      names,
      'actions not in execution order'
    );
    System.Assert.isFalse(rows[0].active, 'inactive action reported as active');
    System.Assert.isTrue(rows[0].problems.isEmpty(), 'unexpected problems: ' + rows[0].problems);
    System.Assert.areEqual(
      new List<String>{ 'Shares its order with AccountTWNameChange.' },
      rows[1].problems,
      'duplicate not reported'
    );
    System.Assert.areEqual(
      new List<String>{ 'No order is set.', 'No Apex class named TW_DoesNotExist extends TW_Action.' },
      rows[3].problems,
      'problems not reported'
    );
  }

  /**
   * Ensures saveOrder deploys only the actions whose order changes
   */
  @IsTest
  static void saveOrder() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('AccountDescriptionTWAction', 'Account', '2'),
      record('ContactEmailTWAction', 'Account', '3')
    };

    Test.startTest();
    String jobId = TW_ActionManagerController.saveOrder(
      'Account',
      new List<String>{ 'AccountDescriptionTWAction', 'AccountTWNameChange', 'ContactEmailTWAction' }
    );
    Test.stopTest();

    System.Assert.areEqual(JOB_ID, jobId, 'job ID not returned');
    List<Metadata.CustomMetadata> deployed = deployer.deployed();
    System.Assert.areEqual(1, deployed.size(), 'unexpected number of records deployed');
    Metadata.CustomMetadata md = deployed[0];
    String orderKey = (String) valueOf(md, 'Order__c');
    System.Assert.isTrue('2'.compareTo(orderKey) < 0 && orderKey.compareTo('3') < 0, 'order not between neighbours: ' + orderKey);
    System.Assert.areEqual('Account', valueOf(md, 'SObject_Name__c'), 'SObject not kept');
    System.Assert.areEqual(true, valueOf(md, 'Active__c'), 'active flag not kept');
  }

  /**
   * Ensures saveOrder deploys nothing when the order does not change
   */
  @IsTest
  static void saveOrderUnchanged() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('AccountDescriptionTWAction', 'Account', '2')
    };

    Test.startTest();
    String jobId = TW_ActionManagerController.saveOrder(
      'Account',
      new List<String>{ 'AccountTWNameChange', 'AccountDescriptionTWAction' }
    );
    Test.stopTest();

    System.Assert.isNull(jobId, 'unexpected deployment');
    System.Assert.isNull(deployer.container, 'unexpected deployment');
  }

  /**
   * Ensures saveOrder throws when the given actions do not match the SObject's actions
   */
  @IsTest
  static void saveOrderStale() {
    useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('AccountDescriptionTWAction', 'Account', '2')
    };

    Test.startTest();
    assertError(new SaveOrder(new List<String>{ 'AccountTWNameChange' }), 'changed since the list loaded');
    assertError(new SaveOrder(new List<String>{ 'AccountTWNameChange', 'AccountTWNameChange' }), 'changed since the list loaded');
    assertError(new SaveOrder(null), 'changed since the list loaded');
    Test.stopTest();
  }

  /**
   * Ensures createAction deploys a new action with a generated name and label, ordered after the
   * SObject's existing actions
   */
  @IsTest
  static void createAction() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'Account', '1') };

    Test.startTest();
    String jobId = TW_ActionManagerController.createAction(' contactemailtwaction ', 'account', true, ' Sends email ');
    Test.stopTest();

    System.Assert.areEqual(JOB_ID, jobId, 'job ID not returned');
    List<Metadata.CustomMetadata> deployed = deployer.deployed();
    System.Assert.areEqual(1, deployed.size(), 'unexpected number of records deployed');
    Metadata.CustomMetadata md = deployed[0];
    System.Assert.areEqual('TW_Action.Account_ContactEmailTWAction', md.fullName, 'unexpected record name');
    System.Assert.areEqual('ContactEmailTWAction (Account)', md.label, 'unexpected label');
    System.Assert.areEqual('ContactEmailTWAction', valueOf(md, 'Apex_Class__c'), 'class name not normalized');
    System.Assert.areEqual('Account', valueOf(md, 'SObject_Name__c'), 'SObject name not normalized');
    System.Assert.isTrue('1'.compareTo((String) valueOf(md, 'Order__c')) < 0, 'new action not ordered last');
    System.Assert.areEqual(true, valueOf(md, 'Active__c'), 'unexpected active flag');
    System.Assert.areEqual('Sends email', valueOf(md, 'Description__c'), 'unexpected description');
  }

  /**
   * Ensures createAction allows a class that already runs for another SObject
   */
  @IsTest
  static void createActionClassOnOtherSObject() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'Account', '1') };

    Test.startTest();
    TW_ActionManagerController.createAction('AccountTWNameChange', 'Contact', true, 'Logs changes');
    Test.stopTest();

    Metadata.CustomMetadata md = deployer.deployed()[0];
    System.Assert.areEqual('TW_Action.Contact_AccountTWNameChange', md.fullName, 'unexpected record name');
    System.Assert.areEqual('AccountTWNameChange', valueOf(md, 'Apex_Class__c'), 'unexpected class');
  }

  /**
   * Ensures createAction rejects invalid input
   */
  @IsTest
  static void createActionInvalid() {
    useCapturingDeployer();
    TW_Action__mdt otherClass = record('Account_Name', 'Account', '2');
    otherClass.Apex_Class__c = 'ContactEmailTWAction';
    // A hand-made record that already uses the name generated for Contact and ContactSetAccDescTWAction
    TW_Action__mdt takenName = record('Contact_ContactSetAccDescTWAction', 'Lead', '1');
    takenName.Apex_Class__c = 'ContactTWAccNameMismatch';
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      otherClass,
      takenName
    };

    Test.startTest();
    assertError(new CreateAction(' ', 'Account', null), 'Select an Apex class');
    assertError(new CreateAction('TW_DoesNotExist', 'Account', null), 'extends TW_Action');
    assertError(new CreateAction('TW_Handler', 'Account', null), 'extends TW_Action');
    assertError(new CreateAction('TW_Action', 'Account', null), 'extends TW_Action');
    assertError(new CreateAction('ContactSetAccDescTWAction', 'Acount', null), 'is not an SObject');
    assertError(new CreateAction('ContactSetAccDescTWAction', null, null), 'Select an SObject');
    assertError(new CreateAction('ContactSetAccDescTWAction', 'Account', ' '), 'Enter a description');
    assertError(new CreateAction('ContactSetAccDescTWAction', 'Account', 'D'.repeat(256)), 'description must be');
    assertError(new CreateAction('accounttwnamechange', 'Account', null), 'already runs for Account as AccountTWNameChange');
    assertError(new CreateAction('ContactEmailTWAction', 'Account', null), 'already runs for Account as Account_Name');
    assertError(
      new CreateAction('ContactSetAccDescTWAction', 'Contact', null),
      'An action named Contact_ContactSetAccDescTWAction already exists'
    );
    Test.stopTest();
  }

  /**
   * Ensures actionName previews the generated name, or returns null for an invalid class or SObject
   */
  @IsTest
  static void actionName() {
    Test.startTest();
    System.Assert.areEqual(
      'Account_AccountTWNameChange',
      TW_ActionManagerController.actionName('accounttwnamechange', 'account'),
      'unexpected name'
    );
    System.Assert.isNull(TW_ActionManagerController.actionName('TW_Handler', 'Account'), 'name for a class that is not an action');
    System.Assert.isNull(TW_ActionManagerController.actionName('AccountTWNameChange', 'Acount'), 'name for an invalid SObject');
    Test.stopTest();
  }

  /**
   * Ensures generated names replace special characters and shorten long names with a hash
   */
  @IsTest
  static void generatedName() {
    System.Assert.areEqual(
      'Account_AccountTWNameChange',
      TW_ActionManagerController.generatedName('Account', 'AccountTWNameChange'),
      'short name changed'
    );
    System.Assert.areEqual(
      'Invoice_c_ns_Logger',
      TW_ActionManagerController.generatedName('Invoice__c', 'ns.Logger'),
      'special characters not replaced'
    );
    String longName = TW_ActionManagerController.generatedName('Account', 'MySuper.SuperLongClassNameThatTakesATonOfChars');
    System.Assert.areEqual('Account_MySuper_SuperLongClassN_66dce1e2', longName, 'long name not shortened with a hash');
    // Names keep the case they are given, but the hash ignores it, as record names do
    System.Assert.isTrue(
      TW_ActionManagerController.generatedName('ACCOUNT', 'mysuper.superlongclassnamethattakesatonofchars').endsWith('_66dce1e2'),
      'hash depends on case'
    );
    System.Assert.areNotEqual(
      TW_ActionManagerController.generatedName('Account', 'MySuper.SuperLongClassNameThatTakesATonOfCharsA'),
      TW_ActionManagerController.generatedName('Account', 'MySuper.SuperLongClassNameThatTakesATonOfCharsB'),
      'long names that start the same are not unique'
    );
  }

  /**
   * Ensures generated labels keep the SObject when the class part must be shortened
   */
  @IsTest
  static void generatedLabel() {
    System.Assert.areEqual('Logger (Account)', TW_ActionManagerController.generatedLabel('Account', 'ns.Logger'), 'unexpected label');
    String longLabel = TW_ActionManagerController.generatedLabel('Account', 'MySuper.SuperLongClassNameThatTakesATonOfChars');
    System.Assert.areEqual('SuperLongClassNameThatTakesAT… (Account)', longLabel, 'class part not shortened');
    System.Assert.areEqual(40, longLabel.length(), 'label not 40 characters');
    String longSObjectLabel = TW_ActionManagerController.generatedLabel('A'.repeat(40) + '__c', 'Logger');
    System.Assert.areEqual(40, longSObjectLabel.length(), 'label over 40 characters');
    System.Assert.isTrue(longSObjectLabel.endsWith('…'), 'shortened label not marked');
  }

  /**
   * Ensures updateAction deploys the new active setting and description, keeping the rest
   */
  @IsTest
  static void updateAction() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_Action__mdt existing = record('Name_Change', 'Account', 'b');
    existing.Apex_Class__c = 'AccountTWNameChange';
    existing.Description__c = 'Old description';
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ existing };

    Test.startTest();
    String jobId = TW_ActionManagerController.updateAction('Name_Change', false, ' New description ');
    Test.stopTest();

    System.Assert.areEqual(JOB_ID, jobId, 'job ID not returned');
    Metadata.CustomMetadata md = deployer.deployed()[0];
    System.Assert.areEqual('TW_Action.Name_Change', md.fullName, 'name changed');
    System.Assert.areEqual('Name_Change', md.label, 'label changed');
    System.Assert.areEqual(false, valueOf(md, 'Active__c'), 'active flag not updated');
    System.Assert.areEqual('New description', valueOf(md, 'Description__c'), 'description not updated');
    System.Assert.areEqual('b', valueOf(md, 'Order__c'), 'order changed');
    System.Assert.areEqual('AccountTWNameChange', valueOf(md, 'Apex_Class__c'), 'class changed');
    System.Assert.areEqual('Account', valueOf(md, 'SObject_Name__c'), 'SObject changed');
  }

  /**
   * Ensures updateAction deploys nothing when nothing changes
   */
  @IsTest
  static void updateActionUnchanged() {
    CapturingDeployer deployer = useCapturingDeployer();
    TW_Action__mdt existing = record('Name_Change', 'Account', '1');
    existing.Description__c = 'Description';
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ existing };

    Test.startTest();
    String jobId = TW_ActionManagerController.updateAction('Name_Change', true, 'Description');
    Test.stopTest();

    System.Assert.isNull(jobId, 'unexpected deployment');
    System.Assert.isNull(deployer.container, 'unexpected deployment');
  }

  /**
   * Ensures updateAction rejects invalid input and missing actions
   */
  @IsTest
  static void updateActionInvalid() {
    useCapturingDeployer();
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>{ record('Name_Change', 'Account', '1') };

    Test.startTest();
    assertError(new UpdateAction('Name_Change', ' '), 'Enter a description');
    assertError(new UpdateAction('Missing', 'Description'), 'no longer exists');
    Test.stopTest();
  }

  /**
   * Ensures a deployment that cannot start is reported
   */
  @IsTest
  static void deployFailure() {
    CapturingDeployer deployer = useCapturingDeployer();
    deployer.failure = new MyException('not allowed');
    TW_ActionManagerController.actionRecords = new List<TW_Action__mdt>();

    Test.startTest();
    assertError(new CreateAction('ContactEmailTWAction', 'Account', null), 'could not start: not allowed');
    Test.stopTest();
  }

  /**
   * Ensures the deploy callback publishes the deployment result
   */
  @IsTest
  static void deployCallback() {
    Metadata.DeployResult succeeded = new Metadata.DeployResult();
    succeeded.id = JOB_ID;
    succeeded.status = Metadata.DeployStatus.SUCCEEDED;

    Metadata.DeployMessage failure = new Metadata.DeployMessage();
    failure.fullName = 'TW_Action.Account_AccountTWNameChange';
    failure.problem = 'bad value';
    Metadata.DeployResult failed = new Metadata.DeployResult();
    failed.id = JOB_ID;
    failed.status = Metadata.DeployStatus.FAILED;
    failed.details = new Metadata.DeployDetails();
    failed.details.componentFailures = new List<Metadata.DeployMessage>{ failure };

    Test.startTest();
    new TW_ActionManagerController.DeployCallback().handleResult(succeeded, null);
    new TW_ActionManagerController.DeployCallback().handleResult(failed, null);
    System.Assert.areEqual(2, Limits.getPublishImmediateDML(), 'results not published');
    Test.stopTest();
  }

  private static CapturingDeployer useCapturingDeployer() {
    CapturingDeployer deployer = new CapturingDeployer();
    TW_ActionManagerController.deployer = deployer;
    return deployer;
  }

  private static TW_Action__mdt record(String developerName, String sObjName, String order) {
    return new TW_Action__mdt(
      DeveloperName = developerName,
      MasterLabel = developerName,
      SObject_Name__c = sObjName,
      Order__c = order,
      Active__c = true
    );
  }

  private static Object valueOf(Metadata.CustomMetadata md, String field) {
    for (Metadata.CustomMetadataValue v : md.values) {
      if (v.field == field) {
        return v.value;
      }
    }
    System.Assert.fail(field + ' not deployed');
    return null;
  }

  private static void assertError(Runnable action, String expectedMessage) {
    try {
      action.run();
      System.Assert.fail('expected exception not thrown');
    } catch (AuraHandledException e) {
      System.Assert.isTrue(e.getMessage().contains(expectedMessage), 'unexpected message: ' + e.getMessage());
    }
  }

  private interface Runnable {
    void run();
  }

  private class SaveOrder implements Runnable {
    private final List<String> names;

    SaveOrder(List<String> names) {
      this.names = names;
    }

    public void run() {
      TW_ActionManagerController.saveOrder('Account', names);
    }
  }

  private class CreateAction implements Runnable {
    private final String className;
    private final String sObjectName;
    private final String description;

    CreateAction(String className, String sObjectName, String description) {
      this.className = className;
      this.sObjectName = sObjectName;
      // null means a valid description, so each case tests one invalid value
      this.description = description == null ? 'Does something' : description;
    }

    public void run() {
      TW_ActionManagerController.createAction(className, sObjectName, true, description);
    }
  }

  private class UpdateAction implements Runnable {
    private final String developerName;
    private final String description;

    UpdateAction(String developerName, String description) {
      this.developerName = developerName;
      this.description = description;
    }

    public void run() {
      TW_ActionManagerController.updateAction(developerName, true, description);
    }
  }

  private class CapturingDeployer extends TW_ActionManagerController.Deployer {
    public Metadata.DeployContainer container;
    public Exception failure;

    public override Id deploy(Metadata.DeployContainer container) {
      if (failure != null) {
        throw failure;
      }
      this.container = container;
      return JOB_ID;
    }

    public List<Metadata.CustomMetadata> deployed() {
      List<Metadata.CustomMetadata> records = new List<Metadata.CustomMetadata>();
      for (Metadata.Metadata md : container.getMetadata()) {
        records.add((Metadata.CustomMetadata) md);
      }
      return records;
    }
  }

  private class MyException extends Exception {
  }
}
