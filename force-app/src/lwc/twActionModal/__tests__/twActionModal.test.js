import { createElement } from "lwc";
import { mockClose as close } from "lightning/modal";
import TwActionModal from "c/twActionModal";
import createAction from "@salesforce/apex/TW_ActionManagerController.createAction";
import updateAction from "@salesforce/apex/TW_ActionManagerController.updateAction";
import getActionName from "@salesforce/apex/TW_ActionManagerController.actionName";
import getActionClassOptions from "@salesforce/apex/TW_ActionManagerController.actionClassOptions";

jest.mock("@salesforce/apex/TW_ActionManagerController.createAction", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/TW_ActionManagerController.updateAction", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/TW_ActionManagerController.actionName", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/TW_ActionManagerController.actionClassOptions", () => ({ default: jest.fn() }), { virtual: true });

const OPTIONS = [
  { apiName: "Account", label: "Account" },
  { apiName: "Custom__c", label: "Custom Thing" }
];

const ACTION = {
  developerName: "AccountTWNameChange_Account",
  apexClass: "AccountTWNameChange",
  active: false,
  description: "Copies the name"
};

async function flushPromises() {
  // Settles chained promises without a timer, since some tests fake the timers
  for (let i = 0; i < 10; i++) {
    // eslint-disable-next-line no-await-in-loop
    await Promise.resolve();
  }
}

async function createModal(props = {}) {
  const element = createElement("c-tw-action-modal", { is: TwActionModal });
  Object.assign(element, { options: OPTIONS, sObjectName: "Custom__c" }, props);
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

const query = (element, selector) => element.shadowRoot.querySelector(selector);
const header = (element) => query(element, "lightning-modal-header");
const headerText = (element) => query(element, "lightning-modal-header p").textContent;
const lookup = (element) => query(element, "c-tw-lookup");
const description = (element) => query(element, "lightning-textarea");
const inputs = (element) => [...element.shadowRoot.querySelectorAll("lightning-input")];
const toggle = (element) => inputs(element).find((i) => i.type === "toggle");
const buttons = (element) => [...element.shadowRoot.querySelectorAll("lightning-modal-footer lightning-button")];
const cancelButton = (element) => buttons(element)[0];
const saveButton = (element) => buttons(element)[1];
const errorAlert = (element) => query(element, '[role="alert"]');

function setValidity(element, valid) {
  description(element).reportValidity = jest.fn(() => valid);
}

async function selectClass(element, value) {
  lookup(element).dispatchEvent(new CustomEvent("change", { detail: { value } }));
  await flushPromises();
}

async function enterDescription(element, value) {
  description(element).dispatchEvent(new CustomEvent("change", { detail: { value } }));
  await flushPromises();
}

async function setActive(element, checked) {
  const input = toggle(element);
  input.checked = checked;
  input.dispatchEvent(new CustomEvent("change"));
  await flushPromises();
}

async function save(element) {
  saveButton(element).click();
  await flushPromises();
}

describe("c-tw-action-modal", () => {
  beforeEach(() => {
    getActionClassOptions.mockResolvedValue(["AccountTWNameChange", "ContactEmailTWAction"]);
    getActionName.mockResolvedValue("ContactEmailTWAction_Custom");
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  describe("creating", () => {
    it("shows the SObject's label in the heading and active message", async () => {
      const element = await createModal();
      expect(header(element).label).toBe("New Custom Thing Action");
      expect(toggle(element).messageToggleActive).toBe("Runs in the Custom Thing trigger");
      expect(saveButton(element).label).toBe("Create");
    });

    it("falls back to the API name when the SObject has no option", async () => {
      const element = await createModal({ options: undefined, sObjectName: "Lead" });
      expect(header(element).label).toBe("New Lead Action");
    });

    it("starts active with an empty description", async () => {
      const element = await createModal();
      expect(toggle(element).checked).toBe(true);
      expect(description(element).value).toBe("");
    });

    it("lists the action classes in the lookup", async () => {
      const element = await createModal();
      expect(getActionClassOptions).toHaveBeenCalledTimes(1);
      expect(lookup(element).options).toEqual([
        { value: "AccountTWNameChange", label: "AccountTWNameChange" },
        { value: "ContactEmailTWAction", label: "ContactEmailTWAction" }
      ]);
      expect(lookup(element).disabled).toBe(false);
      expect(lookup(element).placeholder).toBe("Search classes...");
    });

    it("disables the lookup while the classes load", async () => {
      getActionClassOptions.mockReturnValue(new Promise(() => {}));
      const element = await createModal();
      expect(lookup(element).disabled).toBe(true);
      expect(lookup(element).placeholder).toBe("Loading classes...");
    });

    it("shows an error when the classes can't be loaded", async () => {
      getActionClassOptions.mockRejectedValue({ body: { message: "No access" } });
      const element = await createModal();
      expect(errorAlert(element).textContent).toBe("No access");
      expect(lookup(element).disabled).toBe(false);
    });

    it("explains the name before a class is chosen", async () => {
      const element = await createModal();
      expect(headerText(element)).toBe("The name is generated from the Apex class.");
    });

    it("previews the generated name for the chosen class", async () => {
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      expect(getActionName).toHaveBeenCalledWith({ className: "ContactEmailTWAction", sObjectName: "Custom__c" });
      expect(lookup(element).value).toBe("ContactEmailTWAction");
      expect(headerText(element)).toBe("ContactEmailTWAction_Custom");
    });

    it("clears the preview when the class is cleared", async () => {
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      await selectClass(element, "");
      expect(getActionName).toHaveBeenCalledTimes(1);
      expect(headerText(element)).toBe("The name is generated from the Apex class.");
    });

    it("clears the preview when it can't be generated", async () => {
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      getActionName.mockRejectedValue(new Error("Invalid class"));
      await selectClass(element, "AccountTWNameChange");
      expect(headerText(element)).toBe("The name is generated from the Apex class.");
    });

    it("ignores a preview for a class that has since changed", async () => {
      let resolveFirst;
      getActionName.mockReturnValueOnce(new Promise((resolve) => (resolveFirst = resolve)));
      getActionName.mockResolvedValueOnce("AccountTWNameChange_Custom");
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      await selectClass(element, "AccountTWNameChange");
      resolveFirst("ContactEmailTWAction_Custom");
      await flushPromises();
      expect(headerText(element)).toBe("AccountTWNameChange_Custom");
    });

    it("creates the action and closes with the job", async () => {
      createAction.mockResolvedValue("0AfJOB");
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      await enterDescription(element, "Emails the contact");
      await setActive(element, false);
      setValidity(element, true);
      await save(element);
      expect(createAction).toHaveBeenCalledWith({
        className: "ContactEmailTWAction",
        sObjectName: "Custom__c",
        active: false,
        description: "Emails the contact"
      });
      expect(close).toHaveBeenCalledWith({ jobId: "0AfJOB", className: "ContactEmailTWAction", sObjectName: "Custom__c" });
    });

    it("requires a class", async () => {
      const element = await createModal();
      setValidity(element, true);
      await save(element);
      expect(createAction).not.toHaveBeenCalled();
      expect(close).not.toHaveBeenCalled();
      expect(errorAlert(element).textContent).toBe("Select an Apex class.");
    });

    it("doesn't save an invalid description", async () => {
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      setValidity(element, false);
      await save(element);
      expect(description(element).reportValidity).toHaveBeenCalled();
      expect(createAction).not.toHaveBeenCalled();
      expect(close).not.toHaveBeenCalled();
    });

    it("shows the server's error and stays open", async () => {
      createAction.mockRejectedValue({ body: { message: "Duplicate action" } });
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      setValidity(element, true);
      await save(element);
      expect(errorAlert(element).textContent).toBe("Duplicate action");
      expect(close).not.toHaveBeenCalled();
      expect(saveButton(element).disabled).toBe(false);
    });

    it("falls back to a generic error", async () => {
      createAction.mockRejectedValue({});
      const element = await createModal();
      await selectClass(element, "ContactEmailTWAction");
      setValidity(element, true);
      await save(element);
      expect(errorAlert(element).textContent).toBe("The action could not be saved.");
    });

    it("clears the previous error and disables the buttons while saving", async () => {
      let resolveSave;
      createAction.mockReturnValue(new Promise((resolve) => (resolveSave = resolve)));
      const element = await createModal();
      setValidity(element, true);
      await save(element);
      expect(errorAlert(element)).not.toBeNull();
      await selectClass(element, "ContactEmailTWAction");
      await save(element);
      expect(errorAlert(element)).toBeNull();
      expect(saveButton(element).disabled).toBe(true);
      expect(cancelButton(element).disabled).toBe(true);
      expect(element.disableClose).toBe(true);
      resolveSave("0AfJOB");
      await flushPromises();
      expect(element.disableClose).toBe(false);
      expect(close).toHaveBeenCalled();
    });

    it("describes where the new action runs", async () => {
      const element = await createModal();
      expect(query(element, "lightning-modal-body").textContent).toContain("The action runs after the object's existing actions.");
    });
  });

  describe("editing", () => {
    it("shows the action's settings and record name", async () => {
      const element = await createModal({ sObjectName: "Account", action: ACTION });
      expect(header(element).label).toBe("Edit Account Action");
      expect(headerText(element)).toBe("AccountTWNameChange_Account");
      expect(saveButton(element).label).toBe("Save");
      expect(toggle(element).checked).toBe(false);
      expect(description(element).value).toBe("Copies the name");
      expect(inputs(element).find((i) => i.label === "Apex Class").value).toBe("AccountTWNameChange");
      expect(lookup(element)).toBeNull();
      expect(getActionClassOptions).not.toHaveBeenCalled();
      expect(query(element, "lightning-modal-body").textContent).toContain("Only the active setting and description can change.");
    });

    it("shows an empty description when the action has none", async () => {
      const element = await createModal({ sObjectName: "Account", action: { ...ACTION, description: null } });
      expect(description(element).value).toBe("");
    });

    it("saves the active setting and description and closes with the job", async () => {
      updateAction.mockResolvedValue("0AfJOB");
      const element = await createModal({ sObjectName: "Account", action: ACTION });
      await setActive(element, true);
      await enterDescription(element, "New description");
      setValidity(element, true);
      await save(element);
      expect(updateAction).toHaveBeenCalledWith({
        developerName: "AccountTWNameChange_Account",
        active: true,
        description: "New description"
      });
      expect(close).toHaveBeenCalledWith({ jobId: "0AfJOB", className: "AccountTWNameChange", sObjectName: "Account" });
    });

    it("closes as unchanged when nothing was deployed", async () => {
      updateAction.mockResolvedValue(null);
      const element = await createModal({ sObjectName: "Account", action: ACTION });
      setValidity(element, true);
      await save(element);
      expect(close).toHaveBeenCalledWith({ unchanged: true });
    });

    it("shows the error's message", async () => {
      updateAction.mockRejectedValue(new Error("Deploy failed"));
      const element = await createModal({ sObjectName: "Account", action: ACTION });
      setValidity(element, true);
      await save(element);
      expect(errorAlert(element).textContent).toBe("Deploy failed");
      expect(close).not.toHaveBeenCalled();
    });
  });

  it("closes with no result when cancelled", async () => {
    const element = await createModal();
    cancelButton(element).click();
    await flushPromises();
    expect(close).toHaveBeenCalledWith();
  });

  it("is accessible", async () => {
    const element = await createModal({ sObjectName: "Account", action: ACTION });
    await expect(element).toBeAccessible();
  });
});
