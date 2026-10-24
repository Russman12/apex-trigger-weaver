/**
 * @description Provides unit test coverage for TW_ActionRegistry
 */
@IsTest
public class TW_ActionRegistryTest {
  /**
   * Ensures activeActions returns active actions for given SObject based on TW_Action__mdt
   */
  @IsTest
  static void activeActions() {
    TW_ActionRegistry registry = new TW_ActionRegistry();

    Test.startTest();
    List<System.Type> types = registry.activeActions(Account.getSObjectType());
    Test.stopTest();

    System.Assert.areEqual(
      new List<System.Type>{ AccountDescriptionTWAction.class, AccountTWNameChange.class },
      types,
      'active actions not returned as expected'
    );
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
   * Ensures register registers actions as expected
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
}
