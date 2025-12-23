/**
 * @descript Describes how to run functionality for a given context
 */

public interface TW_Executor {
  /**
   * Executes functionality
   */
  List<SObject> filteredRecords(TW_Action action);
  void setup(TW_Action action);
  void execute(TW_Action action, SObject record);
}
