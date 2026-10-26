import { createElement } from "lwc";
import TwActionManager from "c/twActionManager";
import ActionModal from "c/twActionModal";
import { subscribe, unsubscribe } from "lightning/empApi";
import { getNavigateCalledWith } from "lightning/navigation";
import { ShowToastEventName } from "lightning/platformShowToastEvent";
import getSObjectOptions from "@salesforce/apex/TW_ActionManagerController.sObjectOptions";
import getActionsBySObject from "@salesforce/apex/TW_ActionManagerController.actionsBySObject";
import saveOrder from "@salesforce/apex/TW_ActionManagerController.saveOrder";

jest.mock("@salesforce/apex/TW_ActionManagerController.sObjectOptions", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/TW_ActionManagerController.actionsBySObject", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/TW_ActionManagerController.saveOrder", () => ({ default: jest.fn() }), { virtual: true });

const CHANNEL = "/event/TW_Action_Deployment__e";
const JOB_ID = "0AfJ0000000JOB1AAA";
const SEARCH_DELAY_MS = 250;
const MATCH_STEP_MS = 150;
const DEPLOYMENT_TIMEOUT_MS = 120000;

function option(apiName, props = {}) {
  return { apiName, label: apiName, hasFrameworkTrigger: true, actionCount: 0, problemCount: 0, ...props };
}

function action(apexClass, sObjectName, description, props = {}) {
  return {
    recordId: `m00${apexClass}`,
    developerName: `${apexClass}_${sObjectName}`,
    label: `${apexClass} (${sObjectName})`,
    apexClass,
    active: true,
    description,
    problems: [],
    ...props
  };
}

function options() {
  return [
    option("Account", { actionCount: 3 }),
    option("Contact", { actionCount: 1, problemCount: 1 }),
    option("Lead", { hasFrameworkTrigger: false })
  ];
}

function actions() {
  return {
    account: [
      action("AccountTWNameChange", "Account", "Copies the name"),
      action("AccountTWRating", "Account", "Sets the rating", { active: false }),
      action("AccountTWOwner", "Account", "Assigns the owner")
    ],
    contact: [action("ContactEmailTWAction", "Contact", "Emails the owner", { problems: ["No order is set."] })],
    lead: []
  };
}

async function flushPromises() {
  // Settles chained promises without a timer, since some tests fake the timers
  for (let i = 0; i < 10; i++) {
    // eslint-disable-next-line no-await-in-loop
    await Promise.resolve();
  }
}

async function createManager() {
  const element = createElement("c-tw-action-manager", { is: TwActionManager });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

const query = (element, selector) => element.shadowRoot.querySelector(selector);
const queryAll = (element, selector) => [...element.shadowRoot.querySelectorAll(selector)];
const toggleButton = (element, apiName) => query(element, `button.tw-toggle[data-name="${apiName}"]`);
const sObjectItem = (element, apiName) => toggleButton(element, apiName).closest("li");
const badges = (element, apiName) => [...sObjectItem(element, apiName).querySelectorAll("lightning-badge")].map((b) => b.label);
const rows = (element, key) => queryAll(element, `ol[data-key="${key}"] li.tw-action`);
const classNames = (element, key) => rows(element, key).map((r) => r.querySelector(".tw-class").textContent);
const row = (element, key, index) => rows(element, key)[index];
const rowButton = (element, key, index, text) =>
  [...row(element, key, index).querySelectorAll("lightning-button-icon")].find((b) => b.alternativeText === text);
const sectionButton = (element, apiName, label) =>
  [...sObjectItem(element, apiName).querySelectorAll("lightning-button")].find((b) => b.label === label);
const errorAlert = (element) => query(element, '[role="alert"]');
const spinner = (element, text) => queryAll(element, "lightning-spinner").find((s) => s.alternativeText === text);
const searchInput = (element) => query(element, ".tw-search-input");
const findBar = (element) => query(element, ".tw-find");
const findButton = (element, text) =>
  [...findBar(element).querySelectorAll("lightning-button-icon")].find((b) => b.alternativeText === text);
const dropArea = (element) => query(element, "article > div");

async function click(target) {
  target.click();
  await flushPromises();
}

async function expand(element, apiName) {
  await click(toggleButton(element, apiName));
}

async function dispatch(target, event) {
  target.dispatchEvent(event);
  await flushPromises();
  return event;
}

function dragEvent(type, props = {}) {
  const event = new CustomEvent(type, { bubbles: true, cancelable: true });
  Object.defineProperty(event, "dataTransfer", { value: { setData: jest.fn() } });
  Object.defineProperty(event, "clientY", { value: props.clientY ?? 0 });
  return event;
}

function keyEvent(key, props = {}) {
  return new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true, ...props });
}

// Lays out the rows of an SObject 20px apart from y = 100, so drag positions can be given in pixels
function layOut(element, key) {
  query(element, `ol[data-key="${key}"]`).getBoundingClientRect = () => ({ top: 100, bottom: 100 + rows(element, key).length * 20 });
  rows(element, key).forEach((r, i) => {
    r.getBoundingClientRect = () => ({ top: 100 + i * 20, bottom: 120 + i * 20, height: 20 });
  });
}

// The name of the first class in names that the row has, or "" if it has none
function markedAs(rowElement, names) {
  const found = Object.keys(names).find((cssClass) => rowElement.classList.contains(cssClass));
  return found ? names[found] : "";
}

function captureToasts(element) {
  const handler = jest.fn();
  element.addEventListener(ShowToastEventName, handler);
  return handler;
}

function lastToast(handler) {
  return handler.mock.lastCall[0].detail;
}

describe("c-tw-action-manager", () => {
  let publishDeployment;

  beforeEach(() => {
    getSObjectOptions.mockImplementation(() => Promise.resolve(options()));
    getActionsBySObject.mockImplementation(() => Promise.resolve(actions()));
    subscribe.mockImplementation((channel, replayId, callback) => {
      publishDeployment = (payload) => callback({ data: { payload } });
      return Promise.resolve({ channel });
    });
    jest.spyOn(ActionModal, "open").mockResolvedValue(undefined);
    Element.prototype.scrollIntoView = jest.fn();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.restoreAllMocks();
    jest.useRealTimers();
  });

  describe("loading", () => {
    it("shows a spinner while the SObjects load", async () => {
      getSObjectOptions.mockReturnValue(new Promise(() => {}));
      const element = await createManager();
      expect(spinner(element, "Loading objects")).toBeDefined();
      expect(query(element, ".tw-sobjects")).toBeNull();
    });

    it("lists each SObject with its counts and warnings", async () => {
      const element = await createManager();
      expect(spinner(element, "Loading objects")).toBeUndefined();
      expect(queryAll(element, ".tw-sobject-label").map((l) => l.textContent)).toEqual(["Account", "Contact", "Lead"]);
      expect(badges(element, "Account")).toEqual(["3 actions"]);
      expect(badges(element, "Contact")).toEqual(["1 action", "1 problem"]);
      expect(badges(element, "Lead")).toEqual(["0 actions", "No framework trigger"]);
    });

    it("counts several problems", async () => {
      getSObjectOptions.mockResolvedValue([option("Account", { problemCount: 2 })]);
      const element = await createManager();
      expect(badges(element, "Account")).toContain("2 problems");
    });

    it("starts with every SObject collapsed", async () => {
      const element = await createManager();
      expect(toggleButton(element, "Account").getAttribute("aria-expanded")).toBe("false");
      expect(query(element, ".tw-section")).toBeNull();
    });

    it("says when no SObject uses the framework", async () => {
      getSObjectOptions.mockResolvedValue([]);
      getActionsBySObject.mockResolvedValue(null);
      const element = await createManager();
      expect(element.shadowRoot.textContent).toContain("No object has a trigger that uses TW_Handler.");
    });

    it("shows the server's error", async () => {
      getActionsBySObject.mockRejectedValue({ body: { message: "Insufficient access" } });
      const element = await createManager();
      expect(errorAlert(element).textContent).toBe("Insufficient access");
      expect(spinner(element, "Loading objects")).toBeUndefined();
    });

    it("falls back to a generic error", async () => {
      getSObjectOptions.mockRejectedValue(undefined);
      const element = await createManager();
      expect(errorAlert(element).textContent).toBe("The actions could not be loaded.");
    });
  });

  describe("deployment events", () => {
    it("subscribes on connect and unsubscribes on disconnect", async () => {
      const element = await createManager();
      expect(subscribe).toHaveBeenCalledWith(CHANNEL, -1, expect.any(Function));
      document.body.removeChild(element);
      expect(unsubscribe).toHaveBeenCalledWith({ channel: CHANNEL });
    });

    it("works without the event when subscribing fails", async () => {
      subscribe.mockRejectedValue(new Error("No streaming"));
      const element = await createManager();
      expect(errorAlert(element)).toBeNull();
      document.body.removeChild(element);
      expect(unsubscribe).not.toHaveBeenCalled();
    });
  });

  describe("expanding", () => {
    it("lists an SObject's actions in execution order", async () => {
      const element = await createManager();
      await expand(element, "Account");
      expect(toggleButton(element, "Account").getAttribute("aria-expanded")).toBe("true");
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
      expect(rows(element, "account").map((r) => r.querySelector(".tw-number").textContent.trim())).toEqual(["1", "2", "3"]);
      expect(row(element, "account", 1).querySelector(".tw-description").textContent).toBe("Sets the rating");
    });

    it("shows whether each action is active", async () => {
      const element = await createManager();
      await expand(element, "Account");
      expect(row(element, "account", 0).classList).toContain("tw-action_active");
      expect(row(element, "account", 0).querySelector(".tw-status").title).toBe("Active");
      expect(row(element, "account", 1).classList).toContain("tw-action_inactive");
      expect(row(element, "account", 1).querySelector(".tw-status").title).toBe("Inactive");
    });

    it("lists an action's problems", async () => {
      const element = await createManager();
      await expand(element, "Contact");
      expect(row(element, "contact", 0).querySelector(".tw-problem").textContent.trim()).toBe("No order is set.");
    });

    it.each([
      ["Account", "Actions run from top to bottom. Drag an action, or use its arrows, to change the order."],
      ["Contact", ""],
      ["Lead", "No actions are configured for Lead."]
    ])("explains the %s section", async (apiName, text) => {
      const element = await createManager();
      await expand(element, apiName);
      expect(sObjectItem(element, apiName).querySelector(".tw-section-bar p").textContent).toBe(text);
    });

    it("treats an SObject the server returns no actions for as empty", async () => {
      getActionsBySObject.mockResolvedValue({});
      const element = await createManager();
      await expand(element, "Account");
      expect(rows(element, "account")).toHaveLength(0);
      expect(sObjectItem(element, "Account").querySelector(".tw-section-bar p").textContent).toBe(
        "No actions are configured for Account."
      );
    });

    it("collapses again", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await expand(element, "Account");
      expect(toggleButton(element, "Account").getAttribute("aria-expanded")).toBe("false");
      expect(rows(element, "account")).toHaveLength(0);
    });

    it("keeps several SObjects expanded", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await expand(element, "Contact");
      expect(rows(element, "account")).toHaveLength(3);
      expect(rows(element, "contact")).toHaveLength(1);
    });

    it("adds a long list's rows in batches", async () => {
      jest.useFakeTimers();
      const many = Array.from({ length: 25 }, (_, i) => action(`AccountTW${i}`, "Account", `Action ${i}`));
      getActionsBySObject.mockResolvedValue({ account: many });
      const element = await createManager();
      await expand(element, "Account");
      expect(rows(element, "account")).toHaveLength(10);
      jest.advanceTimersByTime(20);
      await flushPromises();
      expect(rows(element, "account")).toHaveLength(20);
      jest.advanceTimersByTime(20);
      await flushPromises();
      expect(rows(element, "account")).toHaveLength(25);
    });
  });

  describe("adding an action", () => {
    it("isn't offered for an SObject without a framework trigger", async () => {
      const element = await createManager();
      await expand(element, "Lead");
      const add = sectionButton(element, "Lead", "Add Action");
      expect(add.disabled).toBe(true);
      expect(add.title).toBe("Lead has no trigger that uses TW_Handler, so its actions would never run");
    });

    it("opens the modal for the SObject", async () => {
      const element = await createManager();
      await expand(element, "Account");
      const add = sectionButton(element, "Account", "Add Action");
      expect(add.disabled).toBe(false);
      await click(add);
      expect(ActionModal.open).toHaveBeenCalledWith({
        size: "small",
        label: "New Action",
        options: options(),
        sObjectName: "Account"
      });
    });

    it("does nothing when cancelled", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(sectionButton(element, "Account", "Add Action"));
      expect(spinner(element, "Deploying")).toBeUndefined();
      expect(getSObjectOptions).toHaveBeenCalledTimes(1);
    });

    it("waits for the deployment, then reloads", async () => {
      ActionModal.open.mockResolvedValue({ jobId: JOB_ID, className: "AccountTWNew", sObjectName: "Account" });
      const element = await createManager();
      const toasts = captureToasts(element);
      await expand(element, "Account");
      await click(sectionButton(element, "Account", "Add Action"));
      expect(spinner(element, "Deploying")).toBeDefined();
      expect(sectionButton(element, "Account", "Add Action").disabled).toBe(true);

      getActionsBySObject.mockResolvedValue({
        ...actions(),
        account: [...actions().account, action("AccountTWNew", "Account", "New")]
      });
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeUndefined();
      expect(lastToast(toasts)).toEqual({ variant: "success", title: "Deployed", message: "Created the AccountTWNew action." });
      expect(classNames(element, "account")).toContain("AccountTWNew");
    });

    it("expands the SObject if it was collapsed while the modal was open", async () => {
      let resolveModal;
      ActionModal.open.mockReturnValue(new Promise((resolve) => (resolveModal = resolve)));
      const element = await createManager();
      await expand(element, "Contact");
      await click(sectionButton(element, "Contact", "Add Action"));
      await expand(element, "Contact");
      expect(toggleButton(element, "Contact").getAttribute("aria-expanded")).toBe("false");
      resolveModal({ jobId: JOB_ID, className: "ContactTWNew", sObjectName: "Contact" });
      await flushPromises();
      expect(toggleButton(element, "Contact").getAttribute("aria-expanded")).toBe("true");
    });
  });

  describe("editing an action", () => {
    it("opens the modal with the action", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(rowButton(element, "account", 1, "Edit"));
      expect(ActionModal.open).toHaveBeenCalledWith({
        size: "small",
        label: "Edit Action",
        options: options(),
        sObjectName: "Account",
        action: actions().account[1]
      });
    });

    it("waits for the deployment, then reloads", async () => {
      ActionModal.open.mockResolvedValue({ jobId: JOB_ID, className: "AccountTWRating", sObjectName: "Account" });
      const element = await createManager();
      const toasts = captureToasts(element);
      await expand(element, "Account");
      await click(rowButton(element, "account", 1, "Edit"));
      expect(spinner(element, "Deploying")).toBeDefined();
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(lastToast(toasts).message).toBe("Saved the AccountTWRating action.");
      expect(getSObjectOptions).toHaveBeenCalledTimes(2);
    });

    it("says when nothing changed", async () => {
      ActionModal.open.mockResolvedValue({ unchanged: true });
      const element = await createManager();
      const toasts = captureToasts(element);
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Edit"));
      expect(lastToast(toasts)).toEqual({ variant: "info", title: "No changes", message: "The action is unchanged." });
      expect(spinner(element, "Deploying")).toBeUndefined();
    });

    it("does nothing when cancelled", async () => {
      const element = await createManager();
      const toasts = captureToasts(element);
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Edit"));
      expect(toasts).not.toHaveBeenCalled();
      expect(spinner(element, "Deploying")).toBeUndefined();
    });
  });

  it("opens an action's record in Setup", async () => {
    const element = await createManager();
    await expand(element, "Account");
    await click(rowButton(element, "account", 0, "Open the record in Setup"));
    expect(getNavigateCalledWith().pageReference).toEqual({
      type: "standard__webPage",
      attributes: { url: "/lightning/setup/CustomMetadata/page?address=%2Fm00AccountTWNameChange" }
    });
  });

  describe("reordering with the arrows", () => {
    it("can't move the first action up or the last one down", async () => {
      const element = await createManager();
      await expand(element, "Account");
      expect(rowButton(element, "account", 0, "Move up").disabled).toBe(true);
      expect(rowButton(element, "account", 0, "Move down").disabled).toBe(false);
      expect(rowButton(element, "account", 2, "Move up").disabled).toBe(false);
      expect(rowButton(element, "account", 2, "Move down").disabled).toBe(true);
    });

    it("moves an action down and up", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Move down"));
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWNameChange", "AccountTWOwner"]);
      await click(rowButton(element, "account", 2, "Move up"));
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWOwner", "AccountTWNameChange"]);
    });

    it("marks the moved actions with their saved positions", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Move down"));
      const moved = row(element, "account", 0).querySelector(".tw-moved");
      expect(moved.textContent).toBe("←2");
      expect(moved.title).toBe("Previously in position 2");
      expect(row(element, "account", 2).querySelector(".tw-moved")).toBeNull();
    });

    it("locks the SObject until the order is saved or cancelled", async () => {
      const element = await createManager();
      await expand(element, "Account");
      expect(sectionButton(element, "Account", "Save Order")).toBeUndefined();
      await click(rowButton(element, "account", 0, "Move down"));
      expect(sectionButton(element, "Account", "Save Order")).toBeDefined();
      expect(sObjectItem(element, "Account").textContent).toContain("Save or cancel the new order to edit or add actions here.");
      expect(toggleButton(element, "Account").disabled).toBe(true);
      expect(sectionButton(element, "Account", "Add Action").disabled).toBe(true);
      expect(rowButton(element, "account", 0, "Edit").disabled).toBe(true);
    });

    it("cancels the new order", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Move down"));
      await click(sectionButton(element, "Account", "Cancel"));
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
      expect(sectionButton(element, "Account", "Save Order")).toBeUndefined();
      expect(toggleButton(element, "Account").disabled).toBe(false);
    });
  });

  describe("saving the order", () => {
    async function reorderAccount(element) {
      await expand(element, "Account");
      await click(rowButton(element, "account", 2, "Move up"));
    }

    it("saves the new order and reloads once deployed", async () => {
      saveOrder.mockResolvedValue(JOB_ID);
      const element = await createManager();
      const toasts = captureToasts(element);
      await reorderAccount(element);
      await click(sectionButton(element, "Account", "Save Order"));
      expect(saveOrder).toHaveBeenCalledWith({
        sObjectName: "Account",
        developerNames: ["AccountTWNameChange_Account", "AccountTWOwner_Account", "AccountTWRating_Account"]
      });
      expect(spinner(element, "Deploying")).toBeDefined();
      expect(sectionButton(element, "Account", "Save Order").disabled).toBe(true);
      expect(rowButton(element, "account", 0, "Move down").disabled).toBe(true);
      expect(row(element, "account", 0).querySelector(".tw-number").disabled).toBe(true);

      const saved = actions();
      saved.account = [saved.account[0], saved.account[2], saved.account[1]];
      getActionsBySObject.mockResolvedValue(saved);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(lastToast(toasts)).toEqual({ variant: "success", title: "Deployed", message: "Saved the order of the Account actions." });
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWOwner", "AccountTWRating"]);
      expect(sectionButton(element, "Account", "Save Order")).toBeUndefined();
    });

    it("says when the server found nothing to change", async () => {
      saveOrder.mockResolvedValue(null);
      const element = await createManager();
      const toasts = captureToasts(element);
      await reorderAccount(element);
      await click(sectionButton(element, "Account", "Save Order"));
      expect(lastToast(toasts)).toEqual({ variant: "info", title: "No changes", message: "The order is unchanged." });
      expect(sectionButton(element, "Account", "Save Order")).toBeUndefined();
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWOwner", "AccountTWRating"]);
    });

    it("shows the error and keeps the new order", async () => {
      saveOrder.mockRejectedValue({ body: { message: "Order locked" } });
      const element = await createManager();
      await reorderAccount(element);
      await click(sectionButton(element, "Account", "Save Order"));
      expect(errorAlert(element).textContent).toBe("Order locked");
      expect(sectionButton(element, "Account", "Save Order")).toBeDefined();
    });

    it("falls back to a generic error", async () => {
      saveOrder.mockRejectedValue({});
      const element = await createManager();
      await reorderAccount(element);
      await click(sectionButton(element, "Account", "Save Order"));
      expect(errorAlert(element).textContent).toBe("The order could not be saved.");
    });

    it("keeps another SObject's unsaved order through a reload", async () => {
      ActionModal.open.mockResolvedValue({ jobId: JOB_ID, className: "ContactTWNew", sObjectName: "Contact" });
      const element = await createManager();
      await reorderAccount(element);
      await expand(element, "Contact");
      await click(sectionButton(element, "Contact", "Add Action"));
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(getActionsBySObject).toHaveBeenCalledTimes(2);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWOwner", "AccountTWRating"]);
      expect(sectionButton(element, "Account", "Save Order")).toBeDefined();
    });
  });

  describe("typing a position", () => {
    async function editPosition(element, index) {
      await expand(element, "Account");
      await click(row(element, "account", index).querySelector(".tw-number"));
      return query(element, ".tw-position-input");
    }

    it("replaces the number with a focused input", async () => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      expect(input).not.toBeNull();
      expect(input.max).toBe("3");
      expect(element.shadowRoot.activeElement).toBe(input);
    });

    it("moves the action when Enter is pressed", async () => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      input.value = "3";
      const event = await dispatch(input, keyEvent("Enter"));
      expect(event.defaultPrevented).toBe(true);
      expect(query(element, ".tw-position-input")).toBeNull();
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWOwner", "AccountTWNameChange"]);
    });

    it("moves the action when focus leaves", async () => {
      const element = await createManager();
      const input = await editPosition(element, 2);
      input.value = "1";
      await dispatch(input, new CustomEvent("blur"));
      expect(classNames(element, "account")).toEqual(["AccountTWOwner", "AccountTWNameChange", "AccountTWRating"]);
    });

    it.each([
      ["above the last position", "99", ["AccountTWRating", "AccountTWOwner", "AccountTWNameChange"]],
      ["below the first position", "-4", ["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]]
    ])("keeps a position %s in range", async (_, value, expected) => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      input.value = value;
      await dispatch(input, new CustomEvent("blur"));
      expect(classNames(element, "account")).toEqual(expected);
    });

    it("leaves the action in place for a blank position", async () => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      input.value = "";
      await dispatch(input, new CustomEvent("blur"));
      expect(query(element, ".tw-position-input")).toBeNull();
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("cancels with Escape without the key reaching the page", async () => {
      const element = await createManager();
      const outside = jest.fn();
      element.addEventListener("keydown", outside);
      const input = await editPosition(element, 0);
      input.value = "3";
      const event = await dispatch(input, keyEvent("Escape", { composed: true }));
      expect(event.defaultPrevented).toBe(true);
      expect(outside).not.toHaveBeenCalled();
      expect(query(element, ".tw-position-input")).toBeNull();
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("ignores other keys", async () => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      const event = await dispatch(input, keyEvent("5"));
      expect(event.defaultPrevented).toBe(false);
      expect(query(element, ".tw-position-input")).not.toBeNull();
    });

    it("ignores a blur after editing ended", async () => {
      const element = await createManager();
      const input = await editPosition(element, 0);
      input.value = "3";
      // Enter blurs the input, and removing the focused input can fire blur once more
      input.blur();
      input.dispatchEvent(new CustomEvent("blur"));
      await flushPromises();
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWOwner", "AccountTWNameChange"]);
    });

    it("stops editing when the SObject is collapsed", async () => {
      const element = await createManager();
      await editPosition(element, 0);
      await expand(element, "Account");
      await expand(element, "Account");
      expect(query(element, ".tw-position-input")).toBeNull();
    });
  });

  describe("dragging", () => {
    async function startDrag(element, index) {
      await expand(element, "Account");
      await expand(element, "Contact");
      layOut(element, "account");
      const grip = row(element, "account", index).querySelector(".tw-grip");
      await dispatch(grip, new CustomEvent("mousedown", { bubbles: true }));
      const event = await dispatch(row(element, "account", index), dragEvent("dragstart"));
      return event;
    }

    // Each row is 20px high from y = 100. The top half of a row drops before it, the bottom half after
    async function dragTo(element, clientY, target) {
      layOut(element, "account");
      const over =
        target ||
        rows(element, "account").find((r) => {
          const rect = r.getBoundingClientRect();
          return clientY >= rect.top && clientY < rect.bottom;
        });
      return dispatch(over || dropArea(element), dragEvent("dragover", { clientY }));
    }

    const drop = (element) => dispatch(dropArea(element), dragEvent("drop"));
    const dropBars = (element) =>
      rows(element, "account").map((r) => markedAs(r, { "tw-action_drop-before": "before", "tw-action_drop-after": "after" }));

    it("makes only the row whose grip is pressed draggable", async () => {
      const element = await createManager();
      await expand(element, "Account");
      expect(rows(element, "account").map((r) => r.getAttribute("draggable"))).toEqual(["false", "false", "false"]);
      await dispatch(row(element, "account", 1).querySelector(".tw-grip"), new CustomEvent("mousedown", { bubbles: true }));
      expect(rows(element, "account").map((r) => r.getAttribute("draggable"))).toEqual(["false", "true", "false"]);
    });

    it("starts a move", async () => {
      const element = await createManager();
      const event = await startDrag(element, 0);
      expect(event.dataTransfer.effectAllowed).toBe("move");
      expect(event.dataTransfer.setData).toHaveBeenCalledWith("text/plain", "0");
      expect(row(element, "account", 0).classList).toContain("tw-action_dragging");
    });

    it("drops an action after the row it's over the bottom half of", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      const over = await dragTo(element, 135);
      expect(over.defaultPrevented).toBe(true);
      expect(over.dataTransfer.dropEffect).toBe("move");
      expect(dropBars(element)).toEqual(["", "", "before"]);
      const dropped = await drop(element);
      expect(dropped.defaultPrevented).toBe(true);
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWNameChange", "AccountTWOwner"]);
      expect(rows(element, "account").some((r) => r.classList.contains("tw-action_dragging"))).toBe(false);
    });

    it("drops an action before the row it's over the top half of", async () => {
      const element = await createManager();
      await startDrag(element, 2);
      await dragTo(element, 102);
      expect(dropBars(element)).toEqual(["before", "", ""]);
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWOwner", "AccountTWNameChange", "AccountTWRating"]);
    });

    it("shows the bar after the last row", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await dragTo(element, 155);
      expect(dropBars(element)).toEqual(["", "", "after"]);
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWRating", "AccountTWOwner", "AccountTWNameChange"]);
    });

    it("shows no bar where the action would stay put", async () => {
      const element = await createManager();
      await startDrag(element, 1);
      await dragTo(element, 122);
      expect(dropBars(element)).toEqual(["", "", ""]);
      await dragTo(element, 138);
      expect(dropBars(element)).toEqual(["", "", ""]);
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("drops at the top when above the list and at the bottom when below it", async () => {
      const element = await createManager();
      await startDrag(element, 1);
      await dragTo(element, 50, dropArea(element));
      expect(dropBars(element)).toEqual(["before", "", ""]);
      await dragTo(element, 500, dropArea(element));
      expect(dropBars(element)).toEqual(["", "", "after"]);
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWOwner", "AccountTWRating"]);
    });

    it("keeps the drop point in the gaps between rows", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await dragTo(element, 135);
      await dragTo(element, 130, dropArea(element));
      expect(dropBars(element)).toEqual(["", "", "before"]);
    });

    it("ignores rows of other SObjects", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await dragTo(element, 135);
      const contactRow = row(element, "contact", 0);
      contactRow.getBoundingClientRect = () => ({ top: 0, bottom: 20, height: 20 });
      // Stops the event at the row so the area's handler doesn't move the drop point either
      contactRow.addEventListener("dragover", (e) => e.stopPropagation());
      await dispatch(contactRow, dragEvent("dragover", { clientY: 1 }));
      expect(dropBars(element)).toEqual(["", "", "before"]);
    });

    it("ignores dragging over when nothing is being dragged", async () => {
      const element = await createManager();
      await expand(element, "Account");
      layOut(element, "account");
      const over = await dispatch(row(element, "account", 0), dragEvent("dragover", { clientY: 102 }));
      expect(over.defaultPrevented).toBe(false);
      expect(dropBars(element)).toEqual(["", "", ""]);
    });

    it("ignores a drop when nothing is being dragged", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("ignores a drop before the drop point is known", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("ends the drag without moving when it's cancelled", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await dragTo(element, 155);
      await dispatch(row(element, "account", 0), dragEvent("dragend"));
      expect(dropBars(element)).toEqual(["", "", ""]);
      expect(row(element, "account", 0).getAttribute("draggable")).toBe("false");
      await drop(element);
      expect(classNames(element, "account")).toEqual(["AccountTWNameChange", "AccountTWRating", "AccountTWOwner"]);
    });

    it("stops being draggable when the grip is released without dragging", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await dispatch(row(element, "account", 0).querySelector(".tw-grip"), new CustomEvent("mousedown", { bubbles: true }));
      await dispatch(row(element, "account", 0), new CustomEvent("mouseup"));
      expect(row(element, "account", 0).getAttribute("draggable")).toBe("false");
    });

    it("ends the drag when its SObject is collapsed", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      await expand(element, "Account");
      await expand(element, "Account");
      expect(rows(element, "account").some((r) => r.classList.contains("tw-action_dragging"))).toBe(false);
    });

    it("still accepts the drop when the dragged action's list can't be found", async () => {
      const element = await createManager();
      await startDrag(element, 0);
      query(element, 'ol[data-key="account"]').setAttribute("data-key", "moved");
      const over = await dispatch(dropArea(element), dragEvent("dragover", { clientY: 50 }));
      expect(over.defaultPrevented).toBe(true);
    });
  });

  describe("searching", () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    async function search(element, text) {
      await dispatch(searchInput(element), new CustomEvent("change", { detail: { value: text } }));
      jest.advanceTimersByTime(SEARCH_DELAY_MS);
      await flushPromises();
    }

    async function nextStep() {
      jest.advanceTimersByTime(MATCH_STEP_MS);
      await flushPromises();
    }

    const summary = (element) => query(element, ".tw-find-summary").textContent;
    const matchClasses = (element, key) =>
      rows(element, key).map((r) => markedAs(r, { "tw-action_match": "match", "tw-action_dimmed": "dimmed" }));
    const currentRows = (element) => queryAll(element, ".tw-action_current").map((r) => r.dataset.rowKey);
    const isDimmed = (element, apiName) => sObjectItem(element, apiName).classList.contains("tw-sobject_dimmed");
    const isExpanded = (element, apiName) => toggleButton(element, apiName).getAttribute("aria-expanded") === "true";

    it("waits for typing to pause", async () => {
      const element = await createManager();
      await dispatch(searchInput(element), new CustomEvent("change", { detail: { value: "owner" } }));
      expect(searchInput(element).value).toBe("owner");
      expect(findBar(element)).toBeNull();
      jest.advanceTimersByTime(SEARCH_DELAY_MS - 1);
      await flushPromises();
      expect(findBar(element)).toBeNull();
      jest.advanceTimersByTime(1);
      await flushPromises();
      expect(findBar(element)).not.toBeNull();
    });

    it("highlights the matches across SObjects and dims the rest", async () => {
      const element = await createManager();
      await search(element, "owner");
      expect(summary(element)).toBe("2 matches");
      expect(matchClasses(element, "account")).toEqual(["dimmed", "dimmed", "match"]);
      expect(matchClasses(element, "contact")).toEqual(["match"]);
      expect(badges(element, "Account")).toContain("1 match");
      expect(isDimmed(element, "Account")).toBe(false);
      expect(isDimmed(element, "Lead")).toBe(true);
    });

    it("expands the SObjects with a match and collapses the others", async () => {
      const element = await createManager();
      await expand(element, "Lead");
      await search(element, "owner");
      expect(isExpanded(element, "Account")).toBe(true);
      expect(isExpanded(element, "Contact")).toBe(true);
      expect(isExpanded(element, "Lead")).toBe(false);
    });

    it("needs every word, in any order and across fields", async () => {
      const element = await createManager();
      await search(element, "  OWNER  account ");
      expect(summary(element)).toBe("1 match");
      expect(matchClasses(element, "account")).toEqual(["dimmed", "dimmed", "match"]);
      expect(isDimmed(element, "Contact")).toBe(true);
    });

    it("expands an SObject whose name matches without dimming it", async () => {
      const element = await createManager();
      await search(element, "lead");
      expect(summary(element)).toBe("No matches");
      expect(isExpanded(element, "Lead")).toBe(true);
      expect(isDimmed(element, "Lead")).toBe(false);
      expect(findButton(element, "Next match").disabled).toBe(true);
      expect(findButton(element, "Previous match").disabled).toBe(true);
    });

    it("keeps SObjects with an unsaved order expanded", async () => {
      const element = await createManager();
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Move down"));
      await search(element, "emails");
      expect(isExpanded(element, "Account")).toBe(true);
      expect(isExpanded(element, "Contact")).toBe(true);
    });

    it("moves through the matches, wrapping around", async () => {
      const element = await createManager();
      await search(element, "owner");
      await click(findButton(element, "Next match"));
      expect(summary(element)).toBe("1 of 2 matches");
      expect(currentRows(element)).toEqual(["account.AccountTWOwner_Account"]);
      expect(Element.prototype.scrollIntoView).toHaveBeenCalledWith({ block: "center", behavior: "smooth" });
      await nextStep();
      await click(findButton(element, "Next match"));
      expect(currentRows(element)).toEqual(["contact.ContactEmailTWAction_Contact"]);
      await nextStep();
      await click(findButton(element, "Next match"));
      expect(summary(element)).toBe("1 of 2 matches");
      await nextStep();
      await click(findButton(element, "Previous match"));
      expect(summary(element)).toBe("2 of 2 matches");
    });

    it("starts from the last match when going back first", async () => {
      const element = await createManager();
      await search(element, "owner");
      await click(findButton(element, "Previous match"));
      expect(summary(element)).toBe("2 of 2 matches");
    });

    it("drops steps that come too fast", async () => {
      const element = await createManager();
      await search(element, "owner");
      await click(findButton(element, "Next match"));
      await click(findButton(element, "Next match"));
      expect(summary(element)).toBe("1 of 2 matches");
    });

    it("expands a collapsed SObject to show its match", async () => {
      const element = await createManager();
      await search(element, "owner");
      await expand(element, "Account");
      expect(isExpanded(element, "Account")).toBe(false);
      await click(findButton(element, "Next match"));
      expect(isExpanded(element, "Account")).toBe(true);
      expect(currentRows(element)).toEqual(["account.AccountTWOwner_Account"]);
    });

    it("renders a long list in full to reach a match near the end", async () => {
      const many = Array.from({ length: 25 }, (_, i) => action(`AccountTW${i}`, "Account", i === 24 ? "Target" : `Action ${i}`));
      getActionsBySObject.mockResolvedValue({ account: many });
      const element = await createManager();
      await search(element, "target");
      await click(findButton(element, "Next match"));
      expect(rows(element, "account")).toHaveLength(25);
      expect(currentRows(element)).toEqual(["account.AccountTW24_Account"]);
    });

    it("applies a pending search and moves to the next match on Enter", async () => {
      const element = await createManager();
      await dispatch(searchInput(element), new CustomEvent("change", { detail: { value: "owner" } }));
      const event = await dispatch(searchInput(element), keyEvent("Enter"));
      expect(event.defaultPrevented).toBe(true);
      expect(summary(element)).toBe("1 of 2 matches");
    });

    it("moves to the previous match on Shift+Enter", async () => {
      const element = await createManager();
      await search(element, "owner");
      await dispatch(searchInput(element), keyEvent("Enter", { shiftKey: true }));
      expect(summary(element)).toBe("2 of 2 matches");
    });

    it("drops an Enter that waited while the list redrew", async () => {
      const element = await createManager();
      await search(element, "owner");
      const event = keyEvent("Enter");
      Object.defineProperty(event, "timeStamp", { value: performance.now() - MATCH_STEP_MS - 1 });
      await dispatch(searchInput(element), event);
      expect(event.defaultPrevented).toBe(true);
      expect(summary(element)).toBe("2 matches");
    });

    it("does nothing on Enter without matches", async () => {
      const element = await createManager();
      await search(element, "zzz");
      await dispatch(searchInput(element), keyEvent("Enter"));
      expect(summary(element)).toBe("No matches");
      expect(currentRows(element)).toEqual([]);
    });

    it("ignores other keys", async () => {
      const element = await createManager();
      await search(element, "owner");
      const event = await dispatch(searchInput(element), keyEvent("a"));
      expect(event.defaultPrevented).toBe(false);
      expect(summary(element)).toBe("2 matches");
    });

    it("clears at once when the box is emptied, leaving SObjects expanded", async () => {
      const element = await createManager();
      await search(element, "owner");
      await dispatch(searchInput(element), new CustomEvent("change", { detail: { value: "" } }));
      expect(findBar(element)).toBeNull();
      expect(matchClasses(element, "account")).toEqual(["", "", ""]);
      expect(isDimmed(element, "Lead")).toBe(false);
      expect(isExpanded(element, "Account")).toBe(true);
    });

    it("treats a missing value as empty", async () => {
      const element = await createManager();
      await search(element, "owner");
      await dispatch(searchInput(element), new CustomEvent("change", { detail: {} }));
      expect(findBar(element)).toBeNull();
    });

    it("clears with the clear button", async () => {
      const element = await createManager();
      await search(element, "owner");
      await click(findButton(element, "Clear search"));
      expect(searchInput(element).value).toBe("");
      expect(findBar(element)).toBeNull();
    });

    it("doesn't redo an unchanged search", async () => {
      const element = await createManager();
      await search(element, "owner");
      await click(findButton(element, "Next match"));
      await search(element, "owner");
      expect(summary(element)).toBe("1 of 2 matches");
    });

    it("keeps the current match through a reload", async () => {
      ActionModal.open.mockResolvedValue({ jobId: JOB_ID, className: "AccountTWRating", sObjectName: "Account" });
      const element = await createManager();
      await search(element, "owner");
      await nextStep();
      await click(findButton(element, "Next match"));
      await nextStep();
      await click(findButton(element, "Next match"));
      await click(rowButton(element, "account", 0, "Edit"));
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(summary(element)).toBe("2 of 2 matches");
    });

    it("stops a pending search when removed", async () => {
      const element = await createManager();
      await dispatch(searchInput(element), new CustomEvent("change", { detail: { value: "owner" } }));
      document.body.removeChild(element);
      expect(jest.getTimerCount()).toBe(0);
    });
  });

  describe("deployments", () => {
    async function startDeployment(element) {
      await expand(element, "Account");
      await click(rowButton(element, "account", 0, "Edit"));
    }

    beforeEach(() => {
      ActionModal.open.mockResolvedValue({ jobId: JOB_ID, className: "AccountTWNameChange", sObjectName: "Account" });
    });

    it("disables changes while deploying", async () => {
      const element = await createManager();
      await startDeployment(element);
      expect(rowButton(element, "account", 0, "Edit").disabled).toBe(true);
      expect(rowButton(element, "account", 1, "Move up").disabled).toBe(true);
      expect(row(element, "account", 0).querySelector(".tw-number").disabled).toBe(true);
      expect(element.shadowRoot.textContent).toContain("Deploying the changes. This usually takes a few seconds.");
    });

    it("matches a result whose job ID has 15 characters", async () => {
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID.substring(0, 15), Success__c: true });
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeUndefined();
      expect(lastToast(toasts).variant).toBe("success");
    });

    it("ignores other deployments' results", async () => {
      const element = await createManager();
      await startDeployment(element);
      publishDeployment({ Job_Id__c: "0AfJ0000000OTHERAAA", Success__c: true });
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeDefined();
    });

    it("ignores results while nothing is deploying", async () => {
      const element = await createManager();
      const toasts = captureToasts(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      expect(toasts).not.toHaveBeenCalled();
      expect(getSObjectOptions).toHaveBeenCalledTimes(1);
    });

    it("uses a result that arrived before the job ID", async () => {
      let resolveModal;
      ActionModal.open.mockReturnValue(new Promise((resolve) => (resolveModal = resolve)));
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      resolveModal({ jobId: JOB_ID, className: "AccountTWNameChange", sObjectName: "Account" });
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeUndefined();
      expect(lastToast(toasts).message).toBe("Saved the AccountTWNameChange action.");
      expect(getSObjectOptions).toHaveBeenCalledTimes(2);
    });

    it("shows a failed deployment's message and reloads", async () => {
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: false, Message__c: "Class not found" });
      await flushPromises();
      expect(errorAlert(element).textContent).toBe("The deployment failed: Class not found");
      expect(toasts).not.toHaveBeenCalled();
      expect(getSObjectOptions).toHaveBeenCalledTimes(2);
    });

    it("says when a failed deployment has no message", async () => {
      const element = await createManager();
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: false });
      await flushPromises();
      expect(errorAlert(element).textContent).toBe("The deployment failed: no details were returned.");
    });

    it("clears an earlier error when a deployment starts", async () => {
      const element = await createManager();
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: false });
      await flushPromises();
      ActionModal.open.mockResolvedValue({ jobId: "0AfJ0000000JOB2AAA", className: "AccountTWNameChange" });
      await click(rowButton(element, "account", 0, "Edit"));
      expect(errorAlert(element)).toBeNull();
    });

    it("gives up waiting after two minutes and reloads", async () => {
      jest.useFakeTimers();
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      jest.advanceTimersByTime(DEPLOYMENT_TIMEOUT_MS - 1);
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeDefined();
      jest.advanceTimersByTime(1);
      await flushPromises();
      expect(spinner(element, "Deploying")).toBeUndefined();
      expect(lastToast(toasts)).toEqual({
        variant: "warning",
        title: "Still deploying",
        message: "The deployment is taking longer than expected. Check Setup > Deployment Status, then reload the list."
      });
      expect(getSObjectOptions).toHaveBeenCalledTimes(2);
    });

    it("stops the timeout once the result arrives", async () => {
      jest.useFakeTimers();
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      publishDeployment({ Job_Id__c: JOB_ID, Success__c: true });
      await flushPromises();
      jest.advanceTimersByTime(DEPLOYMENT_TIMEOUT_MS);
      await flushPromises();
      expect(toasts).toHaveBeenCalledTimes(1);
    });

    it("stops the timeout when removed", async () => {
      jest.useFakeTimers();
      const element = await createManager();
      const toasts = captureToasts(element);
      await startDeployment(element);
      document.body.removeChild(element);
      jest.advanceTimersByTime(DEPLOYMENT_TIMEOUT_MS);
      await flushPromises();
      expect(toasts).not.toHaveBeenCalled();
      expect(getSObjectOptions).toHaveBeenCalledTimes(1);
    });
  });

  it("is accessible", async () => {
    const element = await createManager();
    await expand(element, "Account");
    await expand(element, "Contact");
    await expect(element).toBeAccessible();
  });
});
