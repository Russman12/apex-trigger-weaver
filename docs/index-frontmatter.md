---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "Apex Trigger Weaver"
  text: "Take control of your triggers"
  tagline: A metadata-driven Apex trigger framework for Salesforce
  actions:
    - theme: brand
      text: Getting Started
      link: /getting-started
    - theme: alt
      text: API Reference Guide
      link: "#reference-guide"
---

Trigger Weaver is an Apex trigger framework for Salesforce. Each SObject gets a single one-line trigger. Business logic lives in small action classes that you activate with custom metadata.

It includes the following features:

- **One trigger per object:** every trigger has the same one-line body.
- **Declarative activation:** register and activate actions with `TW_Action__mdt` records.
- **Per-record logic:** actions handle one record at a time, and the framework iterates over the trigger records.
- **Filters:** each action selects the records it processes before any action logic runs.
- **Bypasses:** turn off individual actions for the rest of a transaction.
- **Field change checks:** `isChanged`, `anyChanged`, and `allChanged` for update logic.
- **Plugins:** lifecycle hooks for shared behaviour such as bulk DML or logging.

## Core Principles

### Ease of use

Describe how your functionality applies to a single record, and the framework handles iterating over the trigger records and routing each trigger operation to the right method.

### Efficiency

Filters run before any action logic, and the framework skips actions that have no matching records. Each action instance handles every record in a trigger execution, so actions can query once for all records and reuse the results.

### Resiliency

Tests must cover the framework's behaviour so changes don't break consumers. Breaking changes require a deprecation period so consumers have time to update.
