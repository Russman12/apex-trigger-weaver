/**
 * @description Resolves which action classes run for an SObject, based on active TW_Action__mdt
 * records. Each record's DeveloperName is used as the action class name, and actions run in
 * ascending Order__c. Records are loaded once per transaction, and each SObject's actions are
 * sorted and validated the first time they are requested, so a duplicate order or missing class
 * only affects its own SObject. An active record with an invalid SObject_Name__c cannot be matched
 * to an SObject, so it fails the load for every SObject.
 */
public class TW_ActionRegistry {
  @TestVisible
  private static List<TW_Action__mdt> actionRecords;
  private static Map<String, List<TW_Action__mdt>> activeRecordsBySObj;
  private static Map<Schema.SObjectType, List<System.Type>> activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
  private static Boolean manuallyRegistered = false;

  /**
   * @description Returns the active action types configured for the given SObject type, in
   * ascending Order__c. Throws InvalidActionConfigException if any active action has an invalid
   * SObject_Name__c, or if an active action for the SObject has no order, shares its order with
   * another active action, or has no matching Apex class.
   * @param sObjType The SObject type to get active actions for.
   * @return The active action types in execution order, or null if none are configured.
   */
  public List<System.Type> activeActions(Schema.SObjectType sObjType) {
    if (!manuallyRegistered && !activeActionsBySObj.containsKey(sObjType)) {
      activeActionsBySObj.put(sObjType, resolveActions(sObjType));
    }
    return activeActionsBySObj.get(sObjType);
  }

  private static List<System.Type> resolveActions(Schema.SObjectType sObjType) {
    List<TW_Action__mdt> records = activeRecordsBySObj().get(String.valueOf(sObjType).toLowerCase());
    if (records == null) {
      return null;
    }

    for (TW_Action__mdt r : records) {
      if (String.isBlank(r.Order__c)) {
        throw new InvalidActionConfigException('TW_Action__mdt ' + r.DeveloperName + ' has no Order__c');
      }
    }

    List<TW_Action__mdt> sorted = records.clone();
    sorted.sort(new OrderComparator());

    List<System.Type> types = new List<System.Type>();
    for (Integer i = 0; i < sorted.size(); i++) {
      TW_Action__mdt r = sorted[i];
      // equals is case-sensitive, matching the sort; == ignores case for strings
      if (i > 0 && sorted[i - 1].Order__c.equals(r.Order__c)) {
        throw new InvalidActionConfigException(
          'TW_Action__mdt ' +
            sorted[i - 1].DeveloperName +
            ' and ' +
            r.DeveloperName +
            ' share Order__c ' +
            r.Order__c +
            ' for ' +
            sObjType
        );
      }

      System.Type t = System.Type.forName(r.DeveloperName);
      if (t == null) {
        throw new InvalidActionConfigException('No Apex class named ' + r.DeveloperName + ' for TW_Action__mdt ' + r.DeveloperName);
      }
      types.add(t);
    }
    return types;
  }

  // Built in a local map and cached only once every record is valid, so an invalid record keeps
  // throwing in later trigger executions instead of leaving a partially loaded cache
  private static Map<String, List<TW_Action__mdt>> activeRecordsBySObj() {
    if (activeRecordsBySObj == null) {
      Map<String, List<TW_Action__mdt>> recordsBySObj = new Map<String, List<TW_Action__mdt>>();
      List<TW_Action__mdt> records = actionRecords != null ? actionRecords : TW_Action__mdt.getAll().values();
      for (TW_Action__mdt r : records) {
        if (!r.Active__c) {
          continue;
        }
        System.Type sObjType = String.isBlank(r.SObject_Name__c) ? null : System.Type.forName(r.SObject_Name__c);
        if (sObjType == null || !SObject.class.isAssignableFrom(sObjType)) {
          throw new InvalidActionConfigException(
            'TW_Action__mdt ' + r.DeveloperName + ' has an invalid SObject_Name__c: ' + r.SObject_Name__c
          );
        }
        String sObjName = sObjType.getName().toLowerCase();
        if (!recordsBySObj.containsKey(sObjName)) {
          recordsBySObj.put(sObjName, new List<TW_Action__mdt>());
        }
        recordsBySObj.get(sObjName).add(r);
      }
      activeRecordsBySObj = recordsBySObj;
    }
    return activeRecordsBySObj;
  }

  /**
   * @description Manually registers an action. Once called, TW_Action__mdt records are not loaded
   * for the rest of the transaction. Actions run in the order they are registered. This should only
   * be used in a test context.
   * @param sObjType The SObject type to register the action for.
   * @param actionType The action type to register.
   */
  @TestVisible
  private static void register(Schema.SObjectType sObjType, System.Type actionType) {
    if (!manuallyRegistered) {
      manuallyRegistered = true;
      activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
    }
    if (!activeActionsBySObj.containsKey(sObjType)) {
      activeActionsBySObj.put(sObjType, new List<System.Type>());
    }
    if (!activeActionsBySObj.get(sObjType).contains(actionType)) {
      activeActionsBySObj.get(sObjType).add(actionType);
    }
  }

  /**
   * @description Clears the action registry and prevents future calls from executing actions.
   * This should only be used in a test context.
   */
  @TestVisible
  private static void clear() {
    manuallyRegistered = true;
    activeActionsBySObj = new Map<Schema.SObjectType, List<System.Type>>();
  }

  private class OrderComparator implements System.Comparator<TW_Action__mdt> {
    public Integer compare(TW_Action__mdt a, TW_Action__mdt b) {
      return a.Order__c.compareTo(b.Order__c);
    }
  }

  /**
   * @description Thrown when the active TW_Action__mdt records for an SObject are misconfigured.
   */
  public class InvalidActionConfigException extends Exception {
  }
}
