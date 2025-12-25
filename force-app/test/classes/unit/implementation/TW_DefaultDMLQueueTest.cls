/**
 * @description provides unit test coverage for TW_DefaultDMLQueue
 */
@IsTest
private class TW_DefaultDMLQueueTest {
  static {
    TW_ActionRegistry.clear();
  }

  /**
   * Ensures inserts are enqueued and executed as expected when flushed
   */
  @IsTest
  static void enqueueInsertAndFlush() {
    // Arrange
    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();
    Account a1 = new Account(Name = 'A1');
    Account a2 = new Account(Name = 'A2');

    // Act
    q.enqueueInsert(a1);
    q.enqueueInsert(a2);

    Test.startTest();
    List<String> result = q.flush();
    Test.stopTest();

    // Assert
    System.assertEquals(null, result, 'flush should return null per implementation');
    // Verify records inserted
    List<Account> accs = [
      SELECT Id, Name
      FROM Account
      WHERE Name IN ('A1', 'A2')
      ORDER BY Name
    ];
    System.assertEquals(2, accs.size(), 'Two accounts should have been inserted');
    System.assertEquals('A1', accs[0].Name);
    System.assertEquals('A2', accs[1].Name);
  }

  /**
   * Ensures updates are enqueued and executed as expected when flushed
   */
  @IsTest
  static void enqueueUpdateAndFlush() {
    // Arrange - create existing records
    List<Account> base = new List<Account>{ new Account(Name = 'U1'), new Account(Name = 'U2') };
    insert base;

    // Modify for update
    base[0].Name = 'U1-Updated';
    base[1].Name = 'U2-Updated';

    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();
    q.enqueueUpdate(base[0]);
    q.enqueueUpdate(base[1]);

    // Act
    Test.startTest();
    List<String> result = q.flush();
    Test.stopTest();

    // Assert
    System.assertEquals(null, result, 'flush should return null per implementation');

    Map<Id, Account> refreshed = new Map<Id, Account>(
      [SELECT Id, Name FROM Account WHERE Id IN :new List<Id>{ base[0].Id, base[1].Id }]
    );
    System.assertEquals('U1-Updated', refreshed.get(base[0].Id).Name);
    System.assertEquals('U2-Updated', refreshed.get(base[1].Id).Name);
  }

  /**
   * Ensures deletes are enqueued and executed as expected when flushed
   */
  @IsTest
  static void enqueueDeleteAndFlush() {
    // Arrange - create records to delete
    List<Account> toDel = new List<Account>{ new Account(Name = 'D1'), new Account(Name = 'D2') };
    insert toDel;

    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();
    q.enqueueDelete(toDel[0]);
    q.enqueueDelete(toDel[1]);

    // Act
    Test.startTest();
    List<String> result = q.flush();
    Test.stopTest();

    // Assert
    System.assertEquals(null, result, 'flush should return null per implementation');

    // Should be deleted (0 rows)
    System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :new List<Id>{ toDel[0].Id, toDel[1].Id }]);
  }

  /**
   * Ensures undeletes are enqueued and executed as expected when flushed
   */
  @IsTest
  static void enqueueUndeleteAndFlush() {
    // Arrange - create and delete records, then undelete through queue
    List<Account> accs = new List<Account>{ new Account(Name = 'R1'), new Account(Name = 'R2') };
    insert accs;
    delete accs;

    // Verify they are deleted
    System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :accs]);

    // Enqueue undelete on stub records with Ids
    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();
    q.enqueueUndelete(new Account(Id = accs[0].Id));
    q.enqueueUndelete(new Account(Id = accs[1].Id));

    // Act
    Test.startTest();
    List<String> result = q.flush();
    Test.stopTest();

    // Assert
    System.assertEquals(null, result, 'flush should return null per implementation');

    // They should now exist again
    System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Id IN :accs]);
  }

  /**
   * Ensures queue is cleared after flush and that subsequent flush does nothing but still returns null
   */
  @IsTest
  static void queueClearedAfterFlush() {
    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();
    q.enqueueInsert(new Account(Name = 'Once'));

    Test.startTest();
    List<String> first = q.flush();
    List<String> second = q.flush();
    Test.stopTest();

    System.assertEquals(null, first, 'flush returns null');
    System.assertEquals(null, second, 'flush returns null even when no operations are pending');

    // Verify the insert actually happened
    System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Name = 'Once']);
  }

  /**
   * Ensures DML exceptions are handled as expected
   */
  @IsTest
  static void flushInsertFailureThrows() {
    TW_DMLQueue q = (TW_DMLQueue) new TW_DefaultDMLQueue();

    // Valid record
    q.enqueueInsert(new Account());

    Test.startTest();
    try {
      q.flush();
      System.Assert.fail('Expected exception not thrown');
    } catch (Exception e) {
      System.Assert.isInstanceOfType(e, DmlException.class, 'unexpected exception thrown');
    }
    Test.stopTest();
  }
}
