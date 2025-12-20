/**
 * Represents functionality that can queue DML operations
 */
public interface TW_DMLQueueable {
  void enqueueInsert(SObject record);
  void enqueueUpdate(SObject record);
  void enqueueDelete(SObject record);
  void enqueueUndelete(SObject record);

  List<String> flush();
}
