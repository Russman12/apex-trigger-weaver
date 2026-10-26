/**
 * @description Server side of the Trigger Weaver tab components. Lists SObjects and their
 * TW_Action__mdt records, and deploys record changes through the Apex Metadata API. Deployments are
 * asynchronous; when one finishes, a TW_Action_Deployment__e event reports the result.
 */
public with sharing class TW_ActionManagerController {
  private static final Integer MAX_NAME_LENGTH = 40;
  private static final Integer MAX_DESCRIPTION_LENGTH = 255;
  private static final Integer HASHED_NAME_PREFIX_LENGTH = 31;
  private static final Integer NAME_HASH_LENGTH = 8;

  @TestVisible
  private static List<TW_Action__mdt> actionRecords;
  @TestVisible
  private static Deployer deployer = new Deployer();

  /**
   * @description Returns the SObjects that have an active trigger using TW_Handler, or that have
   * actions configured, with their action counts.
   * @return The SObjects, ordered by label.
   */
  @AuraEnabled
  public static List<SObjectOption> sObjectOptions() {
    List<SObjectOption> options = new List<SObjectOption>();
    Map<String, SObjectOption> optionsByName = new Map<String, SObjectOption>();
    Map<String, SObjectOption> optionsByDurableId = new Map<String, SObjectOption>();
    // Assigned to a list first because EntityDefinition does not support the batching a SOQL for loop uses
    List<EntityDefinition> entities = [
      SELECT QualifiedApiName, Label, DurableId
      FROM EntityDefinition
      WHERE IsTriggerable = TRUE
      ORDER BY Label
    ];
    for (EntityDefinition e : entities) {
      SObjectOption option = new SObjectOption(e.QualifiedApiName, e.Label);
      options.add(option);
      optionsByName.put(e.QualifiedApiName.toLowerCase(), option);
      optionsByDurableId.put(e.DurableId, option);
    }

    // TableEnumOrId is the API name for standard objects and the object ID for custom objects
    for (ApexTrigger t : [SELECT TableEnumOrId, Body FROM ApexTrigger WHERE Status = 'Active']) {
      if (t.Body == null || !t.Body.containsIgnoreCase('TW_Handler')) {
        continue;
      }
      SObjectOption option = optionsByName.get(t.TableEnumOrId.toLowerCase());
      if (option == null) {
        option = optionsByDurableId.get(t.TableEnumOrId);
      }
      if (option != null) {
        option.hasFrameworkTrigger = true;
      }
    }

    Map<SObjectOption, List<TW_Action__mdt>> recordsByOption = new Map<SObjectOption, List<TW_Action__mdt>>();
    for (TW_Action__mdt r : records()) {
      SObjectOption option = String.isBlank(r.SObject_Name__c) ? null : optionsByName.get(r.SObject_Name__c.toLowerCase());
      if (option != null) {
        option.actionCount++;
        if (!recordsByOption.containsKey(option)) {
          recordsByOption.put(option, new List<TW_Action__mdt>());
        }
        recordsByOption.get(option).add(r);
      }
    }
    // Counted with the same checks actions uses, so the count matches the problems listed
    for (SObjectOption option : recordsByOption.keySet()) {
      for (ActionRow row : rows(recordsByOption.get(option))) {
        option.problemCount += row.problems.size();
      }
    }

    List<SObjectOption> frameworkOptions = new List<SObjectOption>();
    for (SObjectOption option : options) {
      if (option.hasFrameworkTrigger || option.actionCount > 0) {
        frameworkOptions.add(option);
      }
    }
    return frameworkOptions;
  }

  /**
   * @description Returns the org's Apex classes that extend TW_Action. A class can be used by actions
   * on several SObjects, so classes that already have actions are included.
   * @return The class names, in alphabetical order.
   */
  @AuraEnabled
  public static List<String> actionClassOptions() {
    // TW_Action is a class rather than an interface, so ApexTypeImplementor cannot list its
    // subclasses. Resolving each class name also finds classes that extend another action class.
    List<String> names = new List<String>();
    for (ApexClass c : [SELECT Name FROM ApexClass WHERE NamespacePrefix = NULL AND Status = 'Active' ORDER BY Name]) {
      if (isActionClass(c.Name)) {
        names.add(c.Name);
      }
    }
    return names;
  }

  /**
   * @description Returns every action, active or not, grouped by SObject. Each SObject's actions are
   * in execution order, with actions that have no order last.
   * @return The actions with any configuration problems found, by lowercase SObject API name.
   */
  @AuraEnabled
  public static Map<String, List<ActionRow>> actionsBySObject() {
    Map<String, List<TW_Action__mdt>> recordsBySObject = new Map<String, List<TW_Action__mdt>>();
    for (TW_Action__mdt r : records()) {
      String sObjectName = r.SObject_Name__c == null ? '' : r.SObject_Name__c.toLowerCase();
      if (!recordsBySObject.containsKey(sObjectName)) {
        recordsBySObject.put(sObjectName, new List<TW_Action__mdt>());
      }
      recordsBySObject.get(sObjectName).add(r);
    }

    Map<String, List<ActionRow>> rowsBySObject = new Map<String, List<ActionRow>>();
    for (String sObjectName : recordsBySObject.keySet()) {
      List<TW_Action__mdt> sObjectRecords = recordsBySObject.get(sObjectName);
      sObjectRecords.sort(new ExecutionOrder());
      rowsBySObject.put(sObjectName, rows(sObjectRecords));
    }
    return rowsBySObject;
  }

  // One SObject's records as rows, in the given order, with their configuration problems
  private static List<ActionRow> rows(List<TW_Action__mdt> records) {
    Map<String, List<String>> namesByOrder = new Map<String, List<String>>();
    for (TW_Action__mdt r : records) {
      if (String.isNotBlank(r.Order__c)) {
        if (!namesByOrder.containsKey(r.Order__c)) {
          namesByOrder.put(r.Order__c, new List<String>());
        }
        namesByOrder.get(r.Order__c).add(r.DeveloperName);
      }
    }

    List<ActionRow> rows = new List<ActionRow>();
    for (TW_Action__mdt r : records) {
      ActionRow row = new ActionRow(r);
      if (String.isBlank(r.Order__c)) {
        row.problems.add('No order is set.');
      } else if (namesByOrder.get(r.Order__c).size() > 1) {
        List<String> others = namesByOrder.get(r.Order__c).clone();
        others.remove(others.indexOf(r.DeveloperName));
        row.problems.add('Shares its order with ' + String.join(others, ', ') + '.');
      }
      if (!isActionClass(row.apexClass)) {
        row.problems.add('No Apex class named ' + row.apexClass + ' extends TW_Action.');
      }
      rows.add(row);
    }
    return rows;
  }

  /**
   * @description Deploys new Order__c values so the SObject's actions run in the given order. Keeps
   * the current order of as many actions as possible, so usually only moved actions are deployed.
   * @param sObjectName The SObject API name.
   * @param developerNames The DeveloperName of every action for the SObject, in the new order.
   * @return The deployment job ID, or null if no action needed a new order.
   */
  @AuraEnabled
  public static String saveOrder(String sObjectName, List<String> developerNames) {
    Metadata.DeployContainer container = new Metadata.DeployContainer();
    addOrderChanges(container, orderedRecords(sObjectName, developerNames), null);
    return container.getMetadata().isEmpty() ? null : deploy(container);
  }

  // The SObject's records in the given order. Throws if the names don't match its actions exactly
  private static List<TW_Action__mdt> orderedRecords(String sObjectName, List<String> developerNames) {
    List<TW_Action__mdt> records = recordsFor(sObjectName);
    Map<String, TW_Action__mdt> recordsByName = new Map<String, TW_Action__mdt>();
    for (TW_Action__mdt r : records) {
      recordsByName.put(r.DeveloperName, r);
    }
    if (
      developerNames == null ||
      developerNames.size() != records.size() ||
      !recordsByName.keySet().equals(new Set<String>(developerNames))
    ) {
      throw error('The actions for ' + sObjectName + ' changed since the list loaded. Reload the list and try again.');
    }

    List<TW_Action__mdt> ordered = new List<TW_Action__mdt>();
    for (String name : developerNames) {
      ordered.add(recordsByName.get(name));
    }
    return ordered;
  }

  /**
   * @description Returns the record name a new action for the class and SObject would get. See
   * createAction.
   * @param className The action's Apex class.
   * @param sObjectName The SObject API name.
   * @return The record name, or null if the class or SObject is not valid.
   */
  @AuraEnabled
  public static String actionName(String className, String sObjectName) {
    String canonicalClassName = actionClassName(className);
    String canonicalSObjectName = sObjectName(sObjectName);
    return canonicalClassName == null || canonicalSObjectName == null ? null : generatedName(canonicalSObjectName, canonicalClassName);
  }

  /**
   * @description Deploys a new action, ordered after the SObject's existing actions. The record name
   * and label are generated from the SObject and class, so the same pair gets the same name in every
   * org: the name is SObject_Class with special characters replaced by underscores, shortened with a
   * hash when over 40 characters, and the label is the class's last name part followed by the SObject.
   * @param className The Apex class that implements the action. It must extend TW_Action and can be
   * used by actions on other SObjects, but only once per SObject.
   * @param sObjectName The SObject API name.
   * @param active Whether the action runs.
   * @param description What the action does.
   * @return The deployment job ID.
   */
  @AuraEnabled
  public static String createAction(String className, String sObjectName, Boolean active, String description) {
    String canonicalClassName = actionClassName(className);
    if (canonicalClassName == null) {
      throw error(
        String.isBlank(className) ? 'Select an Apex class.' : 'No Apex class named ' + className.trim() + ' extends TW_Action.'
      );
    }
    String canonicalSObjectName = sObjectName(sObjectName);
    if (canonicalSObjectName == null) {
      throw error((String.isBlank(sObjectName) ? 'Select an SObject.' : sObjectName + ' is not an SObject.'));
    }
    description = description == null ? '' : description.trim();
    validateDescription(description);

    List<TW_Action__mdt> ordered = recordsFor(canonicalSObjectName);
    for (TW_Action__mdt r : ordered) {
      if (TW_ActionRegistry.className(r).equalsIgnoreCase(canonicalClassName)) {
        throw error(canonicalClassName + ' already runs for ' + canonicalSObjectName + ' as ' + r.DeveloperName + '.');
      }
    }
    String developerName = generatedName(canonicalSObjectName, canonicalClassName);
    for (TW_Action__mdt r : records()) {
      if (r.DeveloperName.equalsIgnoreCase(developerName)) {
        throw error('An action named ' + developerName + ' already exists.');
      }
    }

    TW_Action__mdt newRecord = new TW_Action__mdt(
      DeveloperName = developerName,
      MasterLabel = generatedLabel(canonicalSObjectName, canonicalClassName),
      Apex_Class__c = canonicalClassName,
      SObject_Name__c = canonicalSObjectName,
      Active__c = active == true,
      Description__c = description
    );
    ordered.add(newRecord);
    Metadata.DeployContainer container = new Metadata.DeployContainer();
    addOrderChanges(container, ordered, newRecord);
    return deploy(container);
  }

  /**
   * @description Deploys a new active setting and description for an existing action. Its name,
   * label, class, SObject and order are kept.
   * @param developerName The name of the action to update.
   * @param active Whether the action runs.
   * @param description What the action does.
   * @return The deployment job ID, or null if nothing changed.
   */
  @AuraEnabled
  public static String updateAction(String developerName, Boolean active, String description) {
    description = description == null ? '' : description.trim();
    validateDescription(description);

    TW_Action__mdt existing;
    for (TW_Action__mdt r : records()) {
      if (r.DeveloperName == developerName) {
        existing = r;
      }
    }
    if (existing == null) {
      throw error('The action ' + developerName + ' no longer exists. Reload the list and try again.');
    }
    if (existing.Active__c == (active == true) && description.equals(existing.Description__c)) {
      return null;
    }

    TW_Action__mdt updated = new TW_Action__mdt(
      DeveloperName = existing.DeveloperName,
      MasterLabel = existing.MasterLabel,
      Apex_Class__c = existing.Apex_Class__c,
      SObject_Name__c = existing.SObject_Name__c,
      Active__c = active == true,
      Description__c = description
    );
    Metadata.DeployContainer container = new Metadata.DeployContainer();
    container.addMetadata(toMetadata(updated, existing.Order__c));
    return deploy(container);
  }

  // SObject_Class with special characters replaced by single underscores. A name over 40 characters
  // is cut to 31 and given a hash of the full pair, so long names that start the same stay unique.
  // The hash is of the lowercased pair because record names ignore case.
  @TestVisible
  private static String generatedName(String sObjectName, String className) {
    String name = (sObjectName + '_' + className).replaceAll('[^A-Za-z0-9]+', '_').replaceAll('^_+|_+$', '');
    if (name.length() <= MAX_NAME_LENGTH) {
      return name;
    }
    Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf((sObjectName + ':' + className).toLowerCase()));
    return name.left(HASHED_NAME_PREFIX_LENGTH).replaceAll('_+$', '') + '_' + EncodingUtil.convertToHex(digest).left(NAME_HASH_LENGTH);
  }

  // The class's last name part followed by the SObject. A label over 40 characters shortens the
  // class part so the SObject always shows
  @TestVisible
  private static String generatedLabel(String sObjectName, String className) {
    String shortName = className.substringAfterLast('.');
    if (String.isBlank(shortName)) {
      shortName = className;
    }
    String suffix = ' (' + sObjectName + ')';
    if (shortName.length() + suffix.length() <= MAX_NAME_LENGTH) {
      return shortName + suffix;
    }
    Integer room = MAX_NAME_LENGTH - suffix.length() - 1;
    return room > 0 ? shortName.left(room) + '…' + suffix : (shortName + suffix).left(MAX_NAME_LENGTH - 1) + '…';
  }

  private static void validateDescription(String description) {
    if (String.isBlank(description)) {
      throw error('Enter a description.');
    }
    if (description.length() > MAX_DESCRIPTION_LENGTH) {
      throw error('The description must be ' + MAX_DESCRIPTION_LENGTH + ' characters or fewer.');
    }
  }

  // Adds every record whose order changes, plus alwaysInclude, to the container
  private static void addOrderChanges(Metadata.DeployContainer container, List<TW_Action__mdt> ordered, TW_Action__mdt alwaysInclude) {
    List<String> keys = newKeys(ordered);
    for (Integer i = 0; i < ordered.size(); i++) {
      TW_Action__mdt r = ordered[i];
      // equals is case-sensitive, matching how actions are sorted
      if (r === alwaysInclude || r.Order__c == null || !keys[i].equals(r.Order__c)) {
        container.addMetadata(toMetadata(r, keys[i]));
      }
    }
  }

  private static List<String> newKeys(List<TW_Action__mdt> ordered) {
    List<String> currentKeys = new List<String>();
    for (TW_Action__mdt r : ordered) {
      currentKeys.add(r.Order__c);
    }
    return TW_OrderKeys.reorder(currentKeys);
  }

  // Every field is set because a deployed record replaces the existing one. The order is passed in
  // because records from getAll() are read-only
  private static Metadata.CustomMetadata toMetadata(TW_Action__mdt r, String orderKey) {
    Metadata.CustomMetadata md = new Metadata.CustomMetadata();
    md.fullName = 'TW_Action.' + r.DeveloperName;
    md.label = r.MasterLabel;
    md.values.add(value('Apex_Class__c', r.Apex_Class__c));
    md.values.add(value('SObject_Name__c', r.SObject_Name__c));
    md.values.add(value('Order__c', orderKey));
    md.values.add(value('Active__c', r.Active__c));
    md.values.add(value('Description__c', r.Description__c));
    return md;
  }

  private static Metadata.CustomMetadataValue value(String field, Object value) {
    Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
    v.field = field;
    v.value = value;
    return v;
  }

  private static String deploy(Metadata.DeployContainer container) {
    try {
      return deployer.deploy(container);
    } catch (Exception e) {
      throw error('The deployment could not start: ' + e.getMessage());
    }
  }

  private static List<TW_Action__mdt> records() {
    return actionRecords != null ? actionRecords : TW_Action__mdt.getAll().values();
  }

  // The SObject's records in execution order, then those without an order, by DeveloperName
  private static List<TW_Action__mdt> recordsFor(String sObjectName) {
    List<TW_Action__mdt> records = new List<TW_Action__mdt>();
    for (TW_Action__mdt r : records()) {
      if (sObjectName != null && sObjectName.equalsIgnoreCase(r.SObject_Name__c)) {
        records.add(r);
      }
    }
    records.sort(new ExecutionOrder());
    return records;
  }

  private static Boolean isActionClass(String className) {
    return actionClassName(className) != null;
  }

  // The class's name as Apex spells it, or null if it does not extend TW_Action
  private static String actionClassName(String className) {
    System.Type t = String.isBlank(className) ? null : System.Type.forName(className.trim());
    return t != null && TW_Action.class.isAssignableFrom(t) && t != TW_Action.class ? t.getName() : null;
  }

  // Matches TW_ActionRegistry: any name Type.forName resolves to an SObject type
  private static String sObjectName(String name) {
    System.Type t = String.isBlank(name) ? null : System.Type.forName(name.trim());
    return t != null && SObject.class.isAssignableFrom(t) ? t.getName() : null;
  }

  private static AuraHandledException error(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }

  private class ExecutionOrder implements System.Comparator<TW_Action__mdt> {
    public Integer compare(TW_Action__mdt a, TW_Action__mdt b) {
      Boolean aBlank = String.isBlank(a.Order__c);
      Boolean bBlank = String.isBlank(b.Order__c);
      if (aBlank != bBlank) {
        return aBlank ? 1 : -1;
      }
      Integer result = aBlank ? 0 : a.Order__c.compareTo(b.Order__c);
      return result != 0 ? result : a.DeveloperName.compareTo(b.DeveloperName);
    }
  }

  /**
   * @description An SObject that can have a trigger.
   */
  public class SObjectOption {
    @AuraEnabled
    public String apiName;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean hasFrameworkTrigger = false;
    @AuraEnabled
    public Integer actionCount = 0;
    @AuraEnabled
    public Integer problemCount = 0;

    private SObjectOption(String apiName, String label) {
      this.apiName = apiName;
      this.label = label;
    }
  }

  /**
   * @description A TW_Action__mdt record and any problems with its configuration.
   */
  public class ActionRow {
    @AuraEnabled
    public Id recordId;
    @AuraEnabled
    public String developerName;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String apexClass;
    @AuraEnabled
    public String orderKey;
    @AuraEnabled
    public Boolean active;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public List<String> problems = new List<String>();

    private ActionRow(TW_Action__mdt r) {
      recordId = r.Id;
      developerName = r.DeveloperName;
      label = r.MasterLabel;
      apexClass = TW_ActionRegistry.className(r);
      orderKey = r.Order__c;
      active = r.Active__c;
      description = r.Description__c;
    }
  }

  /**
   * @description Starts metadata deployments. Replaced in tests, which cannot deploy metadata.
   */
  public virtual class Deployer {
    /**
     * @description Starts the deployment.
     * @param container The metadata to deploy.
     * @return The deployment job ID.
     */
    public virtual Id deploy(Metadata.DeployContainer container) {
      return Metadata.Operations.enqueueDeployment(container, new DeployCallback());
    }
  }

  /**
   * @description Publishes a TW_Action_Deployment__e event when a deployment finishes.
   */
  public class DeployCallback implements Metadata.DeployCallback {
    /**
     * @description Called by the platform when the deployment finishes.
     * @param result The deployment result.
     * @param context The callback context.
     */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
      Boolean success = result.status == Metadata.DeployStatus.SUCCEEDED;
      List<String> messages = new List<String>();
      if (String.isNotBlank(result.errorMessage)) {
        messages.add(result.errorMessage);
      }
      if (result.details != null && result.details.componentFailures != null) {
        for (Metadata.DeployMessage m : result.details.componentFailures) {
          messages.add(m.fullName + ': ' + m.problem);
        }
      }
      EventBus.publish(
        new TW_Action_Deployment__e(
          Job_Id__c = result.id,
          Success__c = success,
          Message__c = success ? null : String.join(messages, ' ').left(MAX_DESCRIPTION_LENGTH)
        )
      );
    }
  }
}
