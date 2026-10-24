/**
 * @description Provides test coverage for TW_Context
 */
@IsTest
public with sharing class TW_ContextTest {
  private static final Id ACC_ID = '00100000000000x';

  /**
   * Ensures the constructor throws outside of trigger context
   */
  @IsTest
  static void constructorError() {
    TW_DMLQueue mockQueue = new MyQueue();

    Test.startTest();
    try {
      TW_Context ctx = new TW_Context(mockQueue);
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Context.InvalidContextException.class, 'Unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures getOperation returns correct TriggerOperation
   */
  @IsTest
  static void getTriggerOp() {
    TW_Context ctx = new TW_Context();
    ctx.triggerOp = System.TriggerOperation.AFTER_DELETE;

    Test.startTest();
    System.TriggerOperation actual = ctx.getOperation();
    Test.stopTest();

    System.Assert.areEqual(ctx.triggerOp, actual, 'unexpected TriggerOperation returned');
  }

  /**
   * Ensures getNew returns correct list of SObject records
   */
  @IsTest
  static void getNew() {
    TW_Context ctx = new TW_Context();
    ctx.newRecs = new List<SObject>{ new Account() };

    Test.startTest();
    List<SObject> actual = ctx.getNew();
    Test.stopTest();

    System.Assert.areEqual(ctx.newRecs, actual, 'unexpected records returned');
  }

  /**
   * Ensures getNewMap returns correct map of SObject records
   */
  @IsTest
  static void getNewMap() {
    TW_Context ctx = new TW_Context();
    ctx.newRecsMap = new Map<Id, SObject>{ ACC_ID => new Account() };

    Test.startTest();
    Map<Id, SObject> actual = ctx.getNewMap();
    Test.stopTest();

    System.Assert.areEqual(ctx.newRecsMap, actual, 'unexpected records returned');
  }

  /**
   * Ensures getOld returns correct list of SObject records
   */
  @IsTest
  static void getOld() {
    TW_Context ctx = new TW_Context();
    ctx.oldRecs = new List<SObject>{ new Account() };

    Test.startTest();
    List<SObject> actual = ctx.getOld();
    Test.stopTest();

    System.Assert.areEqual(ctx.oldRecs, actual, 'unexpected records returned');
  }

  /**
   * Ensures getOld with record arg returns correct SObject record
   */
  @IsTest
  static void getOldRecord() {
    TW_Context ctx = new TW_Context();
    Account oldRec = new Account(Id = ACC_ID);
    ctx.oldRecsMap = new Map<Id, SObject>{ ACC_ID => oldRec };

    Account rec = new Account(Id = ACC_ID, Name = 'test');

    Test.startTest();
    SObject actual = ctx.getOld(rec);
    Test.stopTest();

    System.Assert.areEqual(oldRec, actual, 'unexpected record returned');
  }

  /**
   * Ensures getOldMap returns correct map of SObject records
   */
  @IsTest
  static void getOldMap() {
    TW_Context ctx = new TW_Context();
    ctx.oldRecsMap = new Map<Id, SObject>{ ACC_ID => new Account() };

    Test.startTest();
    Map<Id, SObject> actual = ctx.getOldMap();
    Test.stopTest();

    System.Assert.areEqual(ctx.oldRecsMap, actual, 'unexpected records returned');
  }

  /**
   * Ensures getRecords returns old records when new recs is null
   */
  @IsTest
  static void getRecordsOldNull() {
    TW_Context ctx = new TW_Context();
    ctx.oldRecs = new List<SObject>{ new Account(Name = 'old') };

    Test.startTest();
    List<SObject> actual = ctx.getRecords();
    Test.stopTest();

    System.Assert.areEqual(ctx.oldRecs, actual, 'unexpected records returned');
  }

  /**
   * Ensures getRecords returns old records when new recs is empty
   */
  @IsTest
  static void getRecordsOldEmpty() {
    TW_Context ctx = new TW_Context();
    ctx.oldRecs = new List<SObject>{ new Account(Name = 'old') };
    ctx.newRecs = new List<SObject>();

    Test.startTest();
    List<SObject> actual = ctx.getRecords();
    Test.stopTest();

    System.Assert.areEqual(ctx.oldRecs, actual, 'unexpected records returned');
  }

  /**
   * Ensures getRecords returns new records when new recs is set
   */
  @IsTest
  static void getRecordsNew() {
    TW_Context ctx = new TW_Context();
    ctx.oldRecs = new List<SObject>{ new Account(Name = 'old') };
    ctx.newRecs = new List<SObject>{ new Account(Name = 'new') };

    Test.startTest();
    List<SObject> actual = ctx.getRecords();
    Test.stopTest();

    System.Assert.areEqual(ctx.newRecs, actual, 'unexpected records returned');
  }

  /**
   * Ensures getDMLQueue returns the expected queue
   */
  @IsTest
  static void getDMLQueue() {
    TW_Context ctx = new TW_Context();
    ctx.dmlQueue = new MyQueue();

    Test.startTest();
    TW_DMLQueue actual = ctx.getDMLQueue();
    Test.stopTest();

    System.Assert.areEqual(ctx.dmlQueue, actual, 'unexpected queue returned');
  }

  /**
   * Ensures isChanged throws exception outside of update context
   */
  @IsTest
  static void isChangedOutsideUpdate() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = false;

    Test.startTest();
    try {
      ctx.isChanged(Account.Name);
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Context.InvalidContextException.class, 'Unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures isChanged returns as expected
   */
  @IsTest
  static void isChanged() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = true;
    ctx.currentRecord = new Account(Id = ACC_ID, Name = 'old name');
    ctx.oldRecsMap = new Map<Id, SObject>{ ACC_ID => new Account(Id = ACC_ID, Name = 'old name') };

    Test.startTest();
    System.Assert.isFalse(ctx.isChanged(Account.Name), 'expected field to not be changed');
    ctx.currentRecord = new Account(Id = ACC_ID, Name = 'new name');
    System.Assert.isTrue(ctx.isChanged(Account.Name), 'expected field to be changed');
    Test.stopTest();
  }

  /**
   * Ensures anyChanged throws exception outside of update context
   */
  @IsTest
  static void anyChangedOutsideUpdate() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = false;

    Test.startTest();
    try {
      ctx.anyChanged(new List<Schema.SObjectField>{ Account.Name, Account.Phone });
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Context.InvalidContextException.class, 'Unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures anyChanged returns as expected
   */
  @IsTest
  static void anyChanged() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = true;
    ctx.currentRecord = new Account(Id = ACC_ID, Name = 'old name', Phone = '1234567890');
    ctx.oldRecsMap = new Map<Id, SObject>{ ACC_ID => new Account(Id = ACC_ID, Name = 'old name', Phone = '1234567890') };
    List<Schema.SObjectField> changeFields = new List<Schema.SObjectField>{ Account.Name, Account.Phone };

    Test.startTest();
    System.Assert.isFalse(ctx.anyChanged(changeFields), 'expected field to not be changed');
    ((Account) ctx.currentRecord).Name = 'new name';
    System.Assert.isTrue(ctx.anyChanged(changeFields), 'expected field to be changed');
    ((Account) ctx.currentRecord).Name = 'old name';
    ((Account) ctx.currentRecord).Phone = '1234567891';
    System.Assert.isTrue(ctx.anyChanged(changeFields), 'expected field to be changed');
    Test.stopTest();
  }

  /**
   * Ensures allChanged throws exception outside of update context
   */
  @IsTest
  static void allChangedOutsideUpdate() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = false;

    Test.startTest();
    try {
      ctx.allChanged(new List<Schema.SObjectField>{ Account.Name, Account.Phone });
      System.Assert.fail('expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, TW_Context.InvalidContextException.class, 'Unexpected exception thrown');
    }
    Test.stopTest();
  }

  /**
   * Ensures anyChanged returns as expected
   */
  @IsTest
  static void allChanged() {
    TW_Context ctx = new TW_Context();
    ctx.isUpdate = true;
    ctx.currentRecord = new Account(Id = ACC_ID, Name = 'old name', Phone = '1234567890');
    ctx.oldRecsMap = new Map<Id, SObject>{ ACC_ID => new Account(Id = ACC_ID, Name = 'old name', Phone = '1234567890') };
    List<Schema.SObjectField> changeFields = new List<Schema.SObjectField>{ Account.Name, Account.Phone };

    Test.startTest();
    System.Assert.isFalse(ctx.allChanged(changeFields), 'expected to not be changed');
    ((Account) ctx.currentRecord).Name = 'new name';
    System.Assert.isFalse(ctx.allChanged(changeFields), 'expected to not be changed');
    ((Account) ctx.currentRecord).Phone = '1234567891';
    System.Assert.isTrue(ctx.allChanged(changeFields), 'expected to be changed');
    Test.stopTest();
  }

  private class MyQueue implements TW_DMLQueue {
    public void enqueueInsert(SObject record) {
    }
    public void enqueueUpdate(SObject record) {
    }
    public void enqueueDelete(SObject record) {
    }
    public void enqueueUndelete(SObject record) {
    }
    public List<String> flush() {
      return null;
    }
  }
}
