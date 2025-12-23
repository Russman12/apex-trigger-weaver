/**
 * @description Handles trigger context execution
 * @internal
 */
public interface TW_Executor {
  /**
   * @description Returns trigger records which meet the filter criteria difined
   * on the given action.
   * @param action The action for which the filter should be taken.
   * @return List of SObject records that meet the actions filter criteria.
   */
  List<SObject> filteredRecords(TW_Action action);

  /**
   * @description Executes setup function for the given action.
   * @param action The action for which the setup should be executed.
   */
  void setup(TW_Action action);

  /**
   * @description Executes the action's primary function for the given record.
   * @param action The action which should be executed.
   * @param record The record which the action will be executed on.
   */
  void execute(TW_Action action, SObject record);
}
