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
- [Plugins](#plugins)
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

- An org on Salesforce API version 65.0 or later
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

Create a `TW_Action__mdt` record. The record's **DeveloperName must match the Apex class name**.

| Field             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `SObject_Name__c` | API name of the SObject whose trigger runs the action. |
| `Active__c`       | When checked, the action runs. Defaults to checked.    |
| `Description__c`  | Optional description of the action's purpose.          |

```xml
<!-- customMetadata/TW_Action.AccountTWNameChange.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8" ?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>AccountTWNameChange</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>SObject_Name__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
</CustomMetadata>
```

## How It Works

When `TW_Handler.execute()` runs:

1. **Resolve actions.** The handler loads active `TW_Action__mdt` records for the SObject and caches them for the transaction. It removes any bypassed actions and creates a new instance of each remaining action. If no actions remain, the handler exits without invoking any plugins. Action order is not guaranteed.
2. **Filter.** For each action, the handler calls the filter for the current operation on every trigger record and keeps the records that pass.
3. **Execute.** For each action, the handler calls the handler method for the current operation once per filtered record.
4. **Plugins.** The handler invokes plugin hooks around each stage. See [Plugins](#plugins).

Every filter runs before any handler method runs. Because one action instance handles all records in an execution, actions can cache bulk query results in instance variables. Query once for all `newRecords()` on first use, then read from the cache for each record.

### Action API

| Method                                      | Purpose                                                                         |
| ------------------------------------------- | ------------------------------------------------------------------------------- |
| `<operation>Filter(...)`                    | Return `true` to process the record. One per trigger operation.                 |
| `<operation>(...)`                          | The action's logic for one record. One per trigger operation.                   |
| `newRecords()` / `oldRecords()`             | All records in the trigger (`Trigger.new` / `Trigger.old`).                     |
| `isChanged(field)`                          | Whether the field changed on the current record. Throws outside update context. |
| `anyChanged(fields)` / `allChanged(fields)` | Whether any or every field changed. Throws outside update context.              |
| `getPlugin(pluginType)`                     | Returns a plugin registered on the handler. Throws if the handler has none.     |

Operations: `beforeInsert`, `afterInsert`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`, `afterUndelete`. Insert and undelete methods receive `newRecord`. Delete methods receive `oldRecord`. Update methods receive both.

### Bypassing Actions

Bypasses are static and last for the rest of the transaction, or until removed:

```apex
TW_Handler.addBypass(AccountTWNameChange.class);
update accounts; // AccountTWNameChange does not run
TW_Handler.removeBypass(AccountTWNameChange.class);
```

`TW_Handler.clearBypasses()` removes all bypasses.

## Plugins

A plugin extends `TW_Plugin` and overrides any of these lifecycle hooks:

| Hook                                  | When it runs                                                   |
| ------------------------------------- | -------------------------------------------------------------- |
| `onStart(ctx, actions)`               | Once, after the handler resolves actions and applies bypasses. |
| `onActionSetup(ctx, action, records)` | Once per action that has at least one record after filtering.  |
| `beforeExecute(ctx)`                  | Once, after all filters and before any action logic.           |
| `afterExecute(ctx)`                   | Once, after all action logic completes.                        |
| `onError(ctx, e)`                     | When an exception occurs. The handler rethrows the exception.  |
| `onFinish(ctx)`                       | Once at the end, even if an exception occurred.                |

Register plugins on the handler. They run in registration order, and the handler creates a new instance for each trigger execution:

```apex
new TW_Handler(Account.getSObjectType()).addPlugin(TW_Plugin_DML.class).execute();
```

Actions can call public methods on a plugin, so a plugin can provide shared services:

```apex
TW_Plugin_DML dml = (TW_Plugin_DML) getPlugin(TW_Plugin_DML.class);
dml.enqueueUpdate(new Account(Id = accountId, Name = 'New Name'));
```

To pass constructor arguments, register an instance with `addPlugin(pluginType, instance)`. To apply default plugins to every trigger, extend `TW_Handler` and override `newPlugins()`.

`force-app/example` includes two sample plugins:

- **`TW_Plugin_DML`** collects DML from all actions and performs one bulk statement per operation in `afterExecute`.
- **`TW_Plugin_Logging`** logs the operation, the number of actions that ran, and the SOQL and DML used.

## Project Structure

```
force-app/
├── src/        Framework package: TW_Handler, TW_Action, TW_Plugin, TW_Context,
│               executors, and the TW_Action__mdt custom metadata type
├── example/    Sample triggers, actions, plugins, and metadata records
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

| Script                  | Description                                                         |
| ----------------------- | ------------------------------------------------------------------- |
| `npm test`              | Run all local Apex tests in the default org.                        |
| `npm run test:coverage` | Run tests with detailed code coverage.                              |
| `npm run lint`          | Run PMD rules from `apex-ruleset.xml` and lint the README.          |
| `npm run prettier`      | Format the project.                                                 |
| `npm run scratch:new`   | Create a scratch org, install dependencies, and deploy the project. |
| `npm run docs:dev`      | Generate the API reference and start the docs site locally.         |
| `npm run docs:build`    | Generate the API reference and build the docs site.                 |

Tests use [Apex Mockery](https://github.com/salesforce/apex-mockery), which `scratch:install` installs.

### Documentation

Run `npm run docs:dev` to view the documentation site. [ApexDocs](https://github.com/cesarParra/apexdocs) generates the API reference from the doc comments in `force-app/src`. Don't edit the generated pages by hand.

## Contributing

1. Create a branch from `main`.
2. Make your changes and add tests under `force-app/test`.
3. Commit using [Conventional Commits](https://www.conventionalcommits.org/). The project includes a commitlint config for the format. A Husky pre-commit hook runs Prettier and the linters.
4. Open a pull request against `main`.
