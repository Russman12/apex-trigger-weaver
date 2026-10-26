# Apex Trigger Weaver

Trigger Weaver is a metadata-driven Apex trigger framework for Salesforce. Each SObject gets a single one-line trigger. Business logic lives in small, focused action classes that you turn on and off with custom metadata. The framework handles trigger operation routing, per-record filtering and iteration, and bypasses. A plugin system lets you add cross-cutting behaviour such as bulk DML or logging.

## Contents

- [Why Trigger Weaver](#why-trigger-weaver)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [1. Create the trigger](#1-create-the-trigger)
  - [2. Write an action](#2-write-an-action)
  - [3. Register the action](#3-register-the-action)
- [How It Works](#how-it-works)
  - [Action API](#action-api)
  - [Bypassing Actions](#bypassing-actions)
  - [Bypassing Without Code](#bypassing-without-code)
- [Plugins](#plugins)
- [Action Manager](#action-manager)
- [Project Structure](#project-structure)
- [Development](#development)
  - [Scripts](#scripts)
  - [Documentation](#documentation)
- [Contributing](#contributing)

## Why Trigger Weaver

- **One trigger per object.** Every trigger has the same body, so trigger files never need to change.
- **Focused actions.** Each action is one class with one job. Override the trigger operations you need and ignore the rest.
- **Per-record API.** Actions receive one record at a time. The framework loops over the bulk trigger records for you.
- **Filter first.** Each action decides which records it cares about before any logic runs. The framework skips actions with no matching records.
- **Configuration, not code.** Register, activate, and deactivate actions with `TW_Action__mdt` records, without changing Apex code.
- **Plugins.** Hook into every stage of the trigger lifecycle to share state and services across actions.

## Requirements

- An org on Salesforce API version 68.0 or later
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`)
- Node.js and npm, for formatting, linting, and docs

## Installation

Clone the repository and deploy the framework package directory to your org:

```sh
git clone https://github.com/Russman12/apex-trigger-weaver.git
cd apex-trigger-weaver
sf project deploy start --source-dir force-app/src --target-org <your-org>
```

`force-app/src` holds the whole framework. Do not deploy `force-app/example` or `force-app/test` to a production org.

## Quick Start

### 1. Create the trigger

Create one trigger per SObject that subscribes to every operation and hands control to `TW_Handler`:

```apex
trigger Account on Account(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new TW_Handler(Account.getSObjectType()).execute();
}
```

### 2. Write an action

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

### 3. Register the action

Create a `TW_Action__mdt` record and set `Apex_Class__c` to the action's class. Name the record `<SObject>_<Class>`, the convention the [Action Manager](#action-manager) tab uses, such as `Account_AccountTWNameChange`. To run one class, such as a logger, for more than one SObject, create a record for each SObject. If `Apex_Class__c` is blank, the handler uses the record's DeveloperName as the class name.

| Field             | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `Apex_Class__c`   | Apex class that runs. Leave blank to use the record's DeveloperName.        |
| `SObject_Name__c` | API name of the SObject whose trigger runs the action.                      |
| `Order__c`        | Position in the SObject's execution order. Unique among its active actions. |
| `Active__c`       | When checked, the action runs. Defaults to checked.                         |
| `Description__c`  | Required description of the action's purpose.                               |

```xml
<!-- customMetadata/TW_Action.Account_AccountTWNameChange.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8" ?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>AccountTWNameChange (Account)</label>
    <protected>false</protected>
    <values>
        <field>Apex_Class__c</field>
        <value xsi:type="xsd:string">AccountTWNameChange</value>
    </values>
    <values>
        <field>SObject_Name__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:string">1</value>
    </values>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">Records the previous name in the description when an account's name changes.</value>
    </values>
</CustomMetadata>
```

## How It Works

The trigger's `new TW_Handler(...)` creates the plugins, before the handler loads any actions. When `TW_Handler.execute()` runs:

1. **Initialize.** The handler invokes each plugin's `OnInit` hook, in every execution.
2. **Resolve actions.** The handler loads active `TW_Action__mdt` records for the SObject, sorts them by `Order__c`, and caches them for the transaction. It removes any bypassed actions, including bypasses added in `OnInit`, and creates a new instance of each remaining action. If no actions remain, the handler exits without invoking any other plugin hooks.
3. **Filter.** For each action, the handler calls the filter for the current operation on every trigger record and keeps the records that pass.
4. **Execute.** For each action, the handler calls the handler method for the current operation once per filtered record.
5. **Plugins.** The handler invokes plugin hooks around each stage. See [Plugins](#plugins).

Actions run in ascending `Order__c`. The handler compares values one character at a time by Unicode value, so `10` sorts before `9` and uppercase letters sort before lowercase. Each active action for an SObject needs its own order. If two share an order, the SObject's trigger throws `TW_ActionRegistry.InvalidActionConfigException`. It does the same for a record that names an Apex class that doesn't exist, and these errors affect no other SObject. An active record whose `SObject_Name__c` is not a valid SObject throws the same exception in every trigger that uses the framework, because the handler can't match it to one SObject.

Every filter runs before any handler method runs. Because one action instance handles all records in an execution, actions can cache bulk query results in instance variables. Query once for all `newRecords()` on first use, then read from the cache for each record.

### Action API

| Method                                      | Purpose                                                                         |
| ------------------------------------------- | ------------------------------------------------------------------------------- |
| `<operation>Filter(...)`                    | Return `true` to process the record. One per trigger operation.                 |
| `<operation>(...)`                          | The action's logic for one record. One per trigger operation.                   |
| `newRecords()` / `oldRecords()`             | All records in the trigger (`Trigger.new` / `Trigger.old`).                     |
| `isChanged(field)`                          | Whether the field changed on the current record. Throws outside update context. |
| `anyChanged(fields)` / `allChanged(fields)` | Whether any or every field changed. Throws outside update context.              |
| `getPlugin(pluginType)`                     | Returns a plugin listed in the plugin registry. Throws if not listed.           |

Operations: `beforeInsert`, `afterInsert`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`, `afterUndelete`. Insert and undelete methods receive `newRecord`. Delete methods receive `oldRecord`. Update methods receive both.

### Bypassing Actions

Bypasses are static and last for the rest of the transaction, or until removed:

```apex
TW_Handler.addBypass(AccountTWNameChange.class);
update accounts; // AccountTWNameChange does not run
TW_Handler.removeBypass(AccountTWNameChange.class);
```

`TW_Handler.isBypassed(type)` reports whether a bypass applies to an action, and `TW_Handler.clearBypasses()` removes all bypasses.

### Bypassing Without Code

`addBypass` is an Apex method, so it can't help when no Apex runs before record changes. Data Loader, the Bulk API, and external integrations write records through the standard APIs. Other trigger frameworks handle this problem by providing a switch that admins set without code. The common solutions are a custom permission that skips actions for the users who hold it or a hierarchy custom setting.

While these solutions function, they introduce issues:

- **Different users get different results.** With a per-user bypass, two users who save the same record can get different results, and nothing on the record shows why. That makes problems hard to troubleshoot and code execution unpredictable.
- **Configuration would spread out.** Actions live in `TW_Action__mdt`. A bypass would add permission sets or a custom setting as more places to check when an action doesn't run.
- **Bypassed records skip business logic.** Records loaded with a bypass can leave data in an incorrect state and make related records and integrations out of sync.
- **A bypass acts like a privilege.** When actions enforce rules, the right to skip them must stay with the users who need it, but permission set assignments tend to spread.

Personally, I think this is a bad idea to have such a bypass. An org that accepts the trade-offs above can build the switch itself. A plugin's `OnInit` hook runs before the handler resolves the actions, so it can call `TW_Handler.addBypass` for the actions to skip in that execution. The org then owns the bypass and its configuration. `force-app/example` includes `TW_Plugin_Bypass`, which bypasses actions for users with a custom permission, as set in the example `Trigger_Bypass__mdt` records. See [Plugins](#plugins).

## Plugins

A plugin implements one or more of the hook interfaces nested in `TW_Plugin`. The handler calls each hook a plugin declares and skips the rest:

| Interface                 | Method                                | When it runs                                                                |
| ------------------------- | ------------------------------------- | --------------------------------------------------------------------------- |
| `TW_Plugin.OnInit`        | `onInit(ctx)`                         | Once, at the start of every execution, before the handler resolves actions. |
| `TW_Plugin.OnStart`       | `onStart(ctx, actions)`               | Once, after the handler resolves actions and applies bypasses.              |
| `TW_Plugin.OnActionSetup` | `onActionSetup(ctx, action, records)` | Once per action that has at least one record after filtering.               |
| `TW_Plugin.BeforeExecute` | `beforeExecute(ctx)`                  | Once, after all filters and before any action logic.                        |
| `TW_Plugin.AfterExecute`  | `afterExecute(ctx)`                   | Once, after all action logic completes.                                     |
| `TW_Plugin.OnError`       | `onError(ctx, e)`                     | When an exception occurs. The handler rethrows the exception.               |
| `TW_Plugin.OnFinish`      | `onFinish(ctx)`                       | Once at the end, even if an exception occurred.                             |

`OnInit` runs even when the SObject has no actions, and anything it changes, such as bypasses, applies to the actions resolved for the same execution. `ctx.getSObjectType()` and `ctx.getOperation()` describe the execution. An exception in `OnInit` reaches the trigger without invoking `OnError` or `OnFinish`, because the execution hasn't started. The other hooks run when at least one action remains.

Every hook interface extends `TW_Plugin.Plugin`. A plugin that provides services to actions without using any hooks implements `TW_Plugin.Plugin` directly. Plugins use interfaces rather than inheritance, so a plugin class is free to extend another class.

```apex
public class MyPlugin implements TW_Plugin.BeforeExecute, TW_Plugin.AfterExecute {
  public void beforeExecute(TW_Context ctx) {
  }
  public void afterExecute(TW_Context ctx) {
  }
}
```

### Registering Plugins

The framework runs plugins for every SObject that uses it. To register plugins, create a class named `TW_PluginRegistry` that implements `TW_Plugin.Registry`. The handler runs the plugins it returns, in order:

```apex
public class TW_PluginRegistry implements TW_Plugin.Registry {
  public List<System.Type> plugins() {
    return new List<System.Type>{ TW_Plugin_DML.class, TW_Plugin_Logging.class };
  }
}
```

The handler creates the registry once per transaction and calls `plugins()` each time a trigger creates a handler. Each plugin type needs a public no-arg constructor. The handler creates a new instance of each plugin for each trigger execution, including nested executions caused by DML. To share data across the transaction, such as reference records queried once, hold it in a static variable on the plugin class.

The handler throws `TW_Handler.InvalidPluginException` in these cases:

- `TW_PluginRegistry` is not a `TW_Plugin.Registry`.
- The registry lists a type that is not a `TW_Plugin.Plugin`.
- The registry lists a type twice.

Without a `TW_PluginRegistry` class, no plugins run.

Actions can call public methods on a plugin, so a plugin can provide shared services:

```apex
TW_Plugin_DML dml = (TW_Plugin_DML) getPlugin(TW_Plugin_DML.class);
dml.enqueueUpdate(new Account(Id = accountId, Name = 'New Name'));
```

`force-app/example` includes three sample plugins, listed in its `TW_PluginRegistry`:

- **`TW_Plugin_Bypass`** bypasses actions for users with a custom permission. Each `Trigger_Bypass__mdt` record names a custom permission, an action class and, optionally, an SObject. A blank SObject matches every SObject. In `OnInit`, the plugin calls `TW_Handler.addBypass` for the matching actions, and removes the bypasses it added for an earlier SObject. The example record skips `AccountTWNameChange` on Account for users with the **Bypass Account Name Change** permission set.
- **`TW_Plugin_DML`** collects DML from all actions and performs one bulk statement per operation in `afterExecute`.
- **`TW_Plugin_Logging`** logs the operation, the number of actions that ran, and the SOQL and DML used.

## Action Manager

The **Trigger Weaver** tab lists every SObject whose trigger calls `TW_Handler`, with its number of actions, so you can reorder and create actions without editing `TW_Action__mdt` records by hand.

To use it, assign the **Trigger Weaver Action Manager** permission set. Saving deploys metadata, so the user also needs the Customize Application permission.

- **Search actions.** Type in the search box to highlight every action that contains each word you type, in any order, in its Apex class, description, or SObject name or label, and dim the rest. For example, `set description` finds "Sets the account description". Matching ignores case. Each SObject shows its number of matching actions. Searching expands every SObject that has a matching action, or whose own name or label matches, and collapses the rest. Clearing the search leaves the expanded SObjects open. Select the arrow buttons, or press Enter or Shift+Enter, to move between matches. Searching never hides actions, so their positions and reordering stay the same.
- **View actions.** Expand an SObject to list its actions in execution order, with each action's Apex class, description, and a filled (active) or hollow (inactive) status dot. You can expand any number of SObjects. The list flags actions with a duplicate or missing order and actions whose Apex class does not extend `TW_Action`. An SObject that has actions but no framework trigger shows a warning.
- **Reorder actions.** In the expanded SObject, drag an action by its grip, use its arrow buttons, or select its position number and type a new position. Then select **Save Order**. The tab keeps each action's `Order__c` value where it still fits the new order and generates values between neighbours for the rest. Moving one action updates one record, unless no value fits between its neighbours, such as between `1` and `10`. The tab then renumbers that object's actions. Each SObject keeps its own unsaved order. Until you save or cancel it, that SObject stays expanded and you can't edit or add its actions.
- **Create an action.** Expand an SObject and select **Add Action**, choose whether the action is active and an Apex class that extends `TW_Action`, then enter a description. The SObject comes from the expanded row. One class can run for any number of SObjects, once for each. The tab orders the new action after the object's existing actions. An SObject without a framework trigger can't get new actions.
- **Edit an action.** Select the edit button next to an action to change its active setting or description. To delete an action, select the button beside edit to open the record in Setup, then delete it there.

The tab generates each new record's name and label from the SObject and class, so the same action gets the same name in every org. The name is `<SObject>_<Class>` with special characters replaced by underscores, such as `Account_AccountTWNameChange`. The tab cuts a name longer than 40 characters to 31 and adds a hash of the full SObject and class, such as `Account_MySuper_SuperLongClassN_66dce1e2`. The label is the last part of the class name followed by the SObject, such as `AccountTWNameChange (Account)`.

Changes deploy in the background. The tab reports the result when the deployment finishes. If it hears nothing within two minutes, it tells you to check Setup > Deployment Status.

The tab changes records in the org, not in your project. Retrieve the `TW_Action__mdt` records before your next deployment from source control, or that deployment overwrites the changes.

## Project Structure

```
force-app/
├── src/        Framework package: TW_Handler, TW_Action, TW_Plugin, TW_Context,
│               executors, the TW_Action__mdt custom metadata type, and the
│               Action Manager tab
├── example/    Sample triggers, actions, plugins, plugin registry, and metadata records
└── test/       Unit and integration tests (requires Apex Mockery)
docs/           VitePress documentation site
config/         Scratch org definition
```

## Development

Install dependencies:

```sh
npm install
```

Create a scratch org with the dependencies and all package directories deployed:

```sh
npm run scratch:new
```

### Scripts

| Script                       | Description                                                                 |
| ---------------------------- | --------------------------------------------------------------------------- |
| `npm run test:apex`          | Run all local Apex tests in the default org.                                |
| `npm run test:apex:coverage` | Run the Apex tests with detailed code coverage.                             |
| `npm run test:unit`          | Run the Lightning web component Jest tests.                                 |
| `npm run test:unit:watch`    | Run the Jest tests again whenever a file changes.                           |
| `npm run test:unit:debug`    | Run the Jest tests in debug mode.                                           |
| `npm run test:unit:coverage` | Run the Jest tests with code coverage.                                      |
| `npm run lint`               | Run all linters: `lint:apex`, `lint:lwc` and `lint:doc`.                    |
| `npm run lint:apex`          | Run the PMD rules from `apex-ruleset.xml` on the Apex classes.              |
| `npm run lint:lwc`           | Run ESLint on the Lightning web components, their tests and the Jest mocks. |
| `npm run lint:doc`           | Lint the README.                                                            |
| `npm run prettier`           | Format the project.                                                         |
| `npm run prettier:verify`    | Check the project's formatting without changing files.                      |
| `npm run scratch:new`        | Create a scratch org, install dependencies, and deploy the project.         |
| `npm run docs:dev`           | Generate the API reference and start the docs site locally.                 |
| `npm run docs:build`         | Generate the API reference and build the docs site.                         |
| `npm run docs:preview`       | Preview the built docs site.                                                |

Tests use [Apex Mockery](https://github.com/salesforce/apex-mockery), which `scratch:install` installs. Lightning web component tests run in Jest with [sfdx-lwc-jest](https://github.com/salesforce/sfdx-lwc-jest) and don't need an org. They sit in a `__tests__` folder beside each component. The mocks for `lightning/*` modules are in `force-app/test/jest-mocks`, and `jest.config.js` maps each module to its mock.

### Documentation

Run `npm run docs:dev` to view the documentation site. [ApexDocs](https://github.com/cesarParra/apexdocs) generates the API reference from the doc comments in `force-app/src`. Don't edit the generated pages by hand. The Handlebars templates in `apexdocs/templates` control the layout of class and interface pages. Add a `@usage` tag to a class or interface doc comment to fill its Usage section.

## Contributing

1. Create a branch from `main`.
2. Make your changes and add tests: Apex tests under `force-app/test`, and Jest tests in the component's `__tests__` folder.
3. Commit using [Conventional Commits](https://www.conventionalcommits.org/). The project includes a commitlint config for the format. A Husky pre-commit hook runs Prettier and the linters.
4. Open a pull request against `main`.
