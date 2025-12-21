---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "Apex Trigger Weaver"
  text: "Take control of your triggers"
  tagline: My great project tagline
  actions:
    - theme: brand
      text: Getting Started
      link: /getting-started
    - theme: alt
      text: API Reference Guide
      link: /api-reference-guide
---

Trigger Weaver is a complete trigger framework designed to simplify the way you write triggers in Salesforce.
It includes the following features:

- Context bypass
- Declarive activation
- Automatic registration
- Isolated action source
- Elegant syntax
- abstracted bulkification
- Easy implementation
- Complete documentation
- Much more

## Core Principals

The design of the package was done with much consideration and intent. The following are the core guiding principals

### Ease of use

This framework was designed to be very easy to use. So easy in fact, that you don't even have to
implement bulkification logic. Just describe how your functionaltiy applies to a single record, and
the framework will handle the rest.

### Optimization

Effeciency is crucial in a trigger context because so your org has many things that fire in this context. This framework is desigend to be effecient
as possible. It consolidates queries, and DML operations for you. It also includes checks that minimize iterations.

### Resiliancy

This framework must be compatible with any reasonable functionality that needs to be triggered. Tests should be complete and ensure
the functionality has not broken. Any time a breaking change is made, there must be a proper deprecation period, allowing consumers
to make the necessary changes for they are broken.
