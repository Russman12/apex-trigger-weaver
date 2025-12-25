/**
 * Provides unit test coverage for TW_DefaultQuerySelector
 */
@IsTest
public class TW_DefaultQuerySelectorTest {
  /**
   * Ensures fields isSet is false by default
   */
  @IsTest
  static void isSetFalse() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    Test.startTest();
    Boolean isSet = selector.isSet();
    Test.stopTest();

    System.Assert.isFalse(isSet, 'selector not set as expected');
  }

  /**
   * Ensures addField sets query as expected
   */
  @IsTest
  static void addField() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    selector.addField(Account.Name);

    Test.startTest();
    Boolean isSet = selector.isSet();
    String clauseStr = selector.toClauseString();
    Test.stopTest();

    System.Assert.isTrue(isSet, 'selector not set as expected');
    System.Assert.areEqual('SELECT Name', clauseStr, 'clause string not set as expected');
  }

  /**
   * Ensures addFields sets query as expected
   */
  @IsTest
  static void addFields() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    selector.addFields(new List<SObjectField>{ Account.Name, Account.Description });

    Test.startTest();
    Boolean isSet = selector.isSet();
    String clauseStr = selector.toClauseString();
    Test.stopTest();

    System.Assert.isTrue(isSet, 'selector not set as expected');
    System.Assert.areEqual('SELECT Name, Description', clauseStr, 'clause string not set as expected');
  }

  /**
   * Ensures addParentField sets query as expected
   */
  @IsTest
  static void addParentField() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    selector.addParentField(new List<SObjectField>{ Account.ParentId, Account.Name });

    Test.startTest();
    Boolean isSet = selector.isSet();
    String clauseStr = selector.toClauseString();
    Test.stopTest();

    System.Assert.isTrue(isSet, 'selector not set as expected');
    System.Assert.areEqual('SELECT Parent.Name', clauseStr, 'clause string not set as expected');
  }

  /**
   * Ensures addChildField sets query as expected
   */
  @IsTest
  static void addChildField() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    selector.addChildField(Account.ParentId, Account.Name);

    Test.startTest();
    Boolean isSet = selector.isSet();
    String clauseStr = selector.toClauseString();
    Test.stopTest();

    System.Assert.isTrue(isSet, 'selector not set as expected');
    System.Assert.areEqual('SELECT (SELECT Name FROM ChildAccounts)', clauseStr, 'clause string not set as expected');
  }

  /**
   * Ensures addChildField sets query as expected
   */
  @IsTest
  static void addChildParentField() {
    TW_DefaultQuerySelector selector = new TW_DefaultQuerySelector();

    selector.addChildParentField(Account.ParentId, new List<Schema.SObjectField>{ Account.ParentId, Account.Name });

    Test.startTest();
    Boolean isSet = selector.isSet();
    String clauseStr = selector.toClauseString();
    Test.stopTest();

    System.Assert.isTrue(isSet, 'selector not set as expected');
    System.Assert.areEqual('SELECT (SELECT Parent.Name FROM ChildAccounts)', clauseStr, 'clause string not set as expected');
  }
}
