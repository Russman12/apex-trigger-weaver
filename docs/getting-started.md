# Getting Started

## Installation

Deploy the framework package directory to your org. It requires Salesforce API version 65.0 or later.

```sh
sf project deploy start --source-dir force-app/src --target-org <your-org>
```

## 1. Create the trigger

Create one trigger per SObject that subscribes to every operation and hands control to `TW_Handler`:

```apex
trigger Account on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new TW_Handler(Account.getSObjectType()).execute();
}
```

## 2. Write an action

Extend `TW_Action` and override the filter and handler methods for the operations you need. Methods you don't override do nothing, and filters return `true` by default.

```apex
public with sharing class AccountTWNameChange extends TW_Action {
  public override Boolean beforeUpdateFilter(SObject oldRecord, SObject newRecord) {
    return isChanged(Account.Name);
  }

  public override void beforeUpdate(SObject oldRecord, SObject newRecord) {
    Account acc = (Account) newRecord;
    acc.Description = 'Renamed from ' + ((Account) oldRecord).Name;
  }
}
```

For each trigger operation, the handler first calls every action's filter on each record. It then calls each action's handler method once per record that passed that action's filter.

## 3. Register the action

Create a `TW_Action__mdt` record and set `Apex_Class__c` to the action's class. Name the record `<SObject>_<Class>`, such as `Account_AccountTWNameChange`, the convention the Trigger Weaver tab uses. To run one class for several SObjects, create a record for each SObject:

| Field             | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `Apex_Class__c`   | Apex class that runs. Leave blank to use the record's DeveloperName.        |
| `SObject_Name__c` | API name of the SObject whose trigger runs the action.                      |
| `Order__c`        | Position in the SObject's execution order. Unique among its active actions. |
| `Active__c`       | When checked, the action runs. Defaults to checked.                         |
| `Description__c`  | Required description of the action's purpose.                               |

## Next steps

- Reorder and create actions from the **Trigger Weaver** tab. Assign the **Trigger Weaver Action Manager** permission set to see it.
- Hook into the trigger lifecycle with plugins, which run for every SObject once listed in a `TW_PluginRegistry` class. See [TW_Plugin](/framework/TW_Plugin).
- Turn off an action for the rest of a transaction with `TW_Handler.addBypass`. See [TW_Handler](/framework/TW_Handler).
- See the [API Reference Guide](/#reference-guide) for every public method.
