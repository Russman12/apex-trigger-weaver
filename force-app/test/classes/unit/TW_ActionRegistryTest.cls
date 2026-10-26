/**
 * @description Provides unit test coverage for TW_ActionRegistry
 */
@IsTest
public class TW_ActionRegistryTest {
  /**
   * Ensures activeActions loads the org's TW_Action__mdt records. The org can have records beyond
   * those in source, such as ones added in the Trigger Weaver Manager, so the expected actions come
   * from the org's records. activeActionsSorted covers the order
   */
  @IsTest
  static void activeActions() {
    Set<System.Type> expected = new Set<System.Type>();
    for (TW_Action__mdt r : TW_Action__mdt.getAll().values()) {
      if (r.Active__c && r.SObject_Name__c?.equalsIgnoreCase('Account') == true) {
        expected.add(System.Type.forName(TW_ActionRegistry.className(r)));
      }
    }
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.isTrue(expected.contains(AccountDescriptionTWAction.class), 'source record not deployed to the org');
    System.Assert.areEqual(expected, new Set<System.Type>(types), 'active actions not returned as expected');
  }

  /**
   * Ensures activeActions sorts by Order__c, comparing characters by Unicode value
   */
  @IsTest
  static void activeActionsSorted() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{
      record('ContactSetAccDescTWAction', 'Account', 'b'),
      record('ContactEmailTWAction', 'Account', 'B'),
      record('AccountTWNameChange', 'Account', '9'),
      record('AccountDescriptionTWAction', 'Account', '10')
    };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(
      new List<System.Type>{
        AccountDescriptionTWAction.class,
        AccountTWNameChange.class,
        ContactEmailTWAction.class,
        ContactSetAccDescTWAction.class
      },
      types,
      'actions not sorted by order'
    );
  }

  /**
   * Ensures activeActions skips inactive actions, including any that share an order
   */
  @IsTest
  static void activeActionsInactive() {
    TW_Action__mdt inactive = record('AccountTWNameChange', 'Account', '1');
    inactive.Active__c = false;
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ inactive, record('AccountDescriptionTWAction', 'Account', '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ AccountDescriptionTWAction.class }, types, 'inactive action returned');
  }

  /**
   * Ensures activeActions matches the SObject name regardless of case
   */
  @IsTest
  static void activeActionsSObjectNameCase() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'account', '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ AccountTWNameChange.class }, types, 'action not matched to SObject');
  }

  /**
   * Ensures activeActions returns null when no actions are configured for the SObject
   */
  @IsTest
  static void activeActionsNone() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'Account', '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Contact.getSObjectType());
    Test.stopTest();

    System.Assert.isNull(types, 'unexpected actions returned');
  }

  /**
   * Ensures activeActions runs the class named by Apex_Class__c, so one class can run for several SObjects
   */
  @IsTest
  static void activeActionsApexClass() {
    TW_Action__mdt forAccount = record('Name_Change_Account', 'Account', '1');
    forAccount.Apex_Class__c = 'AccountTWNameChange';
    TW_Action__mdt forContact = record('Name_Change_Contact', 'Contact', '1');
    forContact.Apex_Class__c = ' AccountTWNameChange ';
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ forAccount, forContact };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> accountTypes = registry.activeActions(Account.getSObjectType());
    List<System.Type> contactTypes = registry.activeActions(Contact.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ AccountTWNameChange.class }, accountTypes, 'class not resolved for Account');
    System.Assert.areEqual(new List<System.Type>{ AccountTWNameChange.class }, contactTypes, 'class not resolved for Contact');
  }

  /**
   * Ensures activeActions throws when Apex_Class__c names a class that does not exist
   */
  @IsTest
  static void activeActionsMissingApexClass() {
    TW_Action__mdt r = record('AccountTWNameChange', 'Account', '1');
    r.Apex_Class__c = 'TW_DoesNotExist';
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ r };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    try {
      registry.activeActions(Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
      System.Assert.isTrue(e.getMessage().contains('TW_DoesNotExist'), 'class name not reported: ' + e.getMessage());
    }
    Test.stopTest();
  }

  /**
   * Ensures activeActions throws when two active actions for an SObject share an order
   */
  @IsTest
  static void activeActionsDuplicateOrder() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('AccountDescriptionTWAction', 'Account', '1')
    };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    try {
      registry.activeActions(Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures a duplicate order on one SObject does not affect another SObject
   */
  @IsTest
  static void activeActionsDuplicateOrderOtherSObject() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{
      record('ContactEmailTWAction', 'Contact', '1'),
      record('ContactSetAccDescTWAction', 'Contact', '1'),
      record('AccountTWNameChange', 'Account', '1')
    };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ AccountTWNameChange.class }, types, 'unexpected actions returned');
  }

  /**
   * Ensures activeActions throws when an active action has no order
   */
  @IsTest
  static void activeActionsBlankOrder() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', 'Account', ' ') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    try {
      registry.activeActions(Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures activeActions throws when an active action has no matching Apex class
   */
  @IsTest
  static void activeActionsMissingClass() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ record('TW_DoesNotExist', 'Account', '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    try {
      registry.activeActions(Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures activeActions throws for any SObject when an active action's SObject name is not an
   * SObject, and keeps throwing on later calls
   */
  @IsTest
  static void activeActionsInvalidSObject() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{
      record('AccountTWNameChange', 'Account', '1'),
      record('ContactEmailTWAction', 'Acount', '1'),
      record('ContactSetAccDescTWAction', 'TW_Handler', '1')
    };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    for (Integer i = 0; i < 2; i++) {
      try {
        registry.activeActions(Account.getSObjectType());
        System.Assert.fail('expected exception not thrown');
      } catch (Exception e) {
        System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
      }
    }
    Test.stopTest();
  }

  /**
   * Ensures activeActions throws when an active action has no SObject name
   */
  @IsTest
  static void activeActionsBlankSObject() {
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ record('AccountTWNameChange', null, '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    try {
      registry.activeActions(Account.getSObjectType());
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_ActionRegistry.InvalidActionConfigException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures an inactive action with an invalid SObject name is ignored
   */
  @IsTest
  static void activeActionsInvalidSObjectInactive() {
    TW_Action__mdt inactive = record('ContactEmailTWAction', 'Acount', '1');
    inactive.Active__c = false;
    TW_ActionRegistry.actionRecords = new List<TW_Action__mdt>{ inactive, record('AccountTWNameChange', 'Account', '1') };
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ AccountTWNameChange.class }, types, 'unexpected actions returned');
  }

  /**
   * Ensures register registers actions as expected
   */
  @IsTest
  static void register() {
    TW_ActionRegistry.register(Account.getSObjectType(), TW_ActionRegistryTest.class);
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(new List<System.Type>{ TW_ActionRegistryTest.class }, types, 'active actions not returned as expected');
  }

  /**
   * Ensures clear prevents actions from being returned
   */
  @IsTest
  static void clear() {
    TW_ActionRegistry.clear();
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(null, types, 'active actions not returned as expected');
  }

  private static TW_Action__mdt record(String developerName, String sObjName, String order) {
    return new TW_Action__mdt(DeveloperName = developerName, SObject_Name__c = sObjName, Order__c = order, Active__c = true);
  }
}
