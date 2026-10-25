/**
 * @description Runs an action's filter and handler methods for a single trigger operation.
 * TW_ExecutorFactory returns the implementation for the current operation.
 * @internal
 */
public interface TW_Executor {
  /**
   * @description Returns the trigger records that pass the given action's filter for this operation.
   * Sets the context's currentRecord to each record before its filter is called.
   * @param action The action whose filter is applied.
   * @return The records that passed the action's filter.
   */
  List<SObject> filteredRecords(TW_Action action);

  /**
   * @description Calls the action's handler method for this operation on the given record.
   * @param action The action which should be executed.
   * @param record The record which the action will be executed on.
   */
  void execute(TW_Action action, SObject record);
}
