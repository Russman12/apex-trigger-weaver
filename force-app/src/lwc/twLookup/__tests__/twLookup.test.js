import { createElement } from "lwc";
import TwLookup from "c/twLookup";

const OPTIONS = [
  { value: "AccountTWNameChange", label: "Account Name Change" },
  { value: "ContactEmailTWAction", label: "Contact Email", sublabel: "Contact", badge: "In use" },
  { value: "LeadTWConvert", label: "Lead Convert" }
];

async function flushPromises() {
  // Settles chained promises without a timer, since some tests fake the timers
  for (let i = 0; i < 5; i++) {
    // eslint-disable-next-line no-await-in-loop
    await Promise.resolve();
  }
}

function createLookup(props = {}) {
  const element = createElement("c-tw-lookup", { is: TwLookup });
  Object.assign(element, { label: "Apex Class", options: OPTIONS }, props);
  document.body.appendChild(element);
  return element;
}

const input = (element) => element.shadowRoot.querySelector("lightning-input");
const lookupBox = (element) => element.shadowRoot.querySelector(".tw-lookup");
const optionElements = (element) => [...element.shadowRoot.querySelectorAll('[role="option"]')];
const optionValues = (element) => optionElements(element).map((o) => o.dataset.value);
const highlighted = (element) => element.shadowRoot.querySelector(".tw-option_highlighted");
const message = (element) => element.shadowRoot.querySelector(".tw-results p");

async function focus(element) {
  input(element).dispatchEvent(new CustomEvent("focus"));
  await flushPromises();
}

async function type(element, value) {
  input(element).dispatchEvent(new CustomEvent("change", { detail: { value } }));
  await flushPromises();
}

async function press(element, key) {
  const event = new KeyboardEvent("keydown", { key, cancelable: true });
  lookupBox(element).dispatchEvent(event);
  await flushPromises();
  return event;
}

describe("c-tw-lookup", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  describe("showing the selection", () => {
    it("shows the selected option's label", () => {
      const element = createLookup({ value: "AccountTWNameChange" });
      expect(input(element).value).toBe("Account Name Change");
    });

    it("adds the sublabel in brackets", () => {
      const element = createLookup({ value: "ContactEmailTWAction" });
      expect(input(element).value).toBe("Contact Email (Contact)");
    });

    it("shows a value that matches no option as it is", () => {
      const element = createLookup({ value: "UnknownClass" });
      expect(input(element).value).toBe("UnknownClass");
    });

    it("shows the label once options arrive after the value", async () => {
      const element = createLookup({ options: [], value: "LeadTWConvert" });
      element.options = OPTIONS;
      await flushPromises();
      expect(input(element).value).toBe("Lead Convert");
    });

    it("treats null options as none", async () => {
      const element = createLookup({ options: null });
      expect(element.options).toEqual([]);
      await focus(element);
      expect(message(element).textContent).toBe("Nothing to select.");
    });

    it("passes its settings to the input", () => {
      const element = createLookup({ required: true, disabled: true, placeholder: "Find", fieldLevelHelp: "Help" });
      const box = input(element);
      expect(box.label).toBe("Apex Class");
      expect(box.required).toBe(true);
      expect(box.disabled).toBe(true);
      expect(box.placeholder).toBe("Find");
      expect(box.fieldLevelHelp).toBe("Help");
    });
  });

  describe("searching", () => {
    it("lists every option on focus, with the search box emptied", async () => {
      const element = createLookup({ value: "LeadTWConvert" });
      await focus(element);
      expect(input(element).value).toBe("");
      expect(optionValues(element)).toEqual(OPTIONS.map((o) => o.value));
    });

    it("marks the selected option", async () => {
      const element = createLookup({ value: "LeadTWConvert" });
      await focus(element);
      const selected = optionElements(element).filter((o) => o.getAttribute("aria-selected") === "true");
      expect(selected.map((o) => o.dataset.value)).toEqual(["LeadTWConvert"]);
    });

    it("shows the sublabel and badge", async () => {
      const element = createLookup();
      await focus(element);
      const contact = optionElements(element)[1];
      expect(contact.textContent).toContain("Contact");
      expect(contact.querySelector("lightning-badge").label).toBe("In use");
      expect(optionElements(element)[0].querySelector("lightning-badge")).toBeNull();
    });

    it.each([
      ["label", "name change", ["AccountTWNameChange"]],
      ["value", "twconvert", ["LeadTWConvert"]],
      ["sublabel", "contact", ["ContactEmailTWAction"]],
      ["surrounding spaces", "  LEAD  ", ["LeadTWConvert"]]
    ])("matches by %s, ignoring case", async (_, term, expected) => {
      const element = createLookup();
      await focus(element);
      await type(element, term);
      expect(optionValues(element)).toEqual(expected);
    });

    it("says when nothing matches", async () => {
      const element = createLookup();
      await focus(element);
      await type(element, "zzz");
      expect(optionElements(element)).toHaveLength(0);
      expect(message(element).textContent).toBe("No matches.");
    });

    it("shows the empty text when there are no options", async () => {
      const element = createLookup({ options: [], emptyText: "No Apex class extends TW_Action." });
      await focus(element);
      expect(message(element).textContent).toBe("No Apex class extends TW_Action.");
    });

    it("lists the first 50 matches and counts the rest", async () => {
      const many = Array.from({ length: 53 }, (_, i) => ({ value: `Class${i}`, label: `Class ${i}` }));
      const element = createLookup({ options: many });
      await focus(element);
      expect(optionElements(element)).toHaveLength(50);
      expect(message(element).textContent).toBe("3 more. Type to narrow the list.");
    });

    it("opens the list when typing without focus", async () => {
      const element = createLookup();
      await type(element, "lead");
      expect(optionValues(element)).toEqual(["LeadTWConvert"]);
    });

    it("closes and shows the selection again on blur", async () => {
      const element = createLookup({ value: "LeadTWConvert" });
      await focus(element);
      await type(element, "acc");
      input(element).dispatchEvent(new CustomEvent("blur"));
      await flushPromises();
      expect(element.shadowRoot.querySelector('[role="listbox"]')).toBeNull();
      expect(input(element).value).toBe("Lead Convert");
    });

    it("ignores a new value for the box while open", async () => {
      const element = createLookup();
      await focus(element);
      await type(element, "acc");
      element.value = "LeadTWConvert";
      await flushPromises();
      expect(input(element).value).toBe("acc");
    });
  });

  describe("selecting", () => {
    it("selects a clicked option and fires change", async () => {
      const element = createLookup();
      const handler = jest.fn();
      element.addEventListener("change", handler);
      await focus(element);
      optionElements(element)[2].click();
      await flushPromises();
      expect(handler).toHaveBeenCalledTimes(1);
      expect(handler.mock.calls[0][0].detail).toEqual({ value: "LeadTWConvert" });
      expect(element.value).toBe("LeadTWConvert");
      expect(input(element).value).toBe("Lead Convert");
      expect(element.shadowRoot.querySelector('[role="listbox"]')).toBeNull();
    });

    it("keeps focus in the input when an option is pressed", async () => {
      const element = createLookup();
      await focus(element);
      const event = new MouseEvent("mousedown", { cancelable: true });
      optionElements(element)[0].dispatchEvent(event);
      expect(event.defaultPrevented).toBe(true);
    });
  });

  describe("keyboard", () => {
    it("highlights the first option on focus", async () => {
      const element = createLookup();
      await focus(element);
      expect(highlighted(element).dataset.value).toBe("AccountTWNameChange");
    });

    it("moves the highlight down and wraps to the top", async () => {
      const element = createLookup();
      await focus(element);
      const event = await press(element, "ArrowDown");
      expect(event.defaultPrevented).toBe(true);
      expect(highlighted(element).dataset.value).toBe("ContactEmailTWAction");
      await press(element, "ArrowDown");
      await press(element, "ArrowDown");
      expect(highlighted(element).dataset.value).toBe("AccountTWNameChange");
    });

    it("moves the highlight up and wraps to the bottom", async () => {
      const element = createLookup();
      await focus(element);
      const event = await press(element, "ArrowUp");
      expect(event.defaultPrevented).toBe(true);
      expect(highlighted(element).dataset.value).toBe("LeadTWConvert");
    });

    it("opens the list with ArrowDown after a selection closed it", async () => {
      const element = createLookup();
      await focus(element);
      await press(element, "Enter");
      expect(element.shadowRoot.querySelector('[role="listbox"]')).toBeNull();
      await press(element, "ArrowDown");
      expect(element.shadowRoot.querySelector('[role="listbox"]')).not.toBeNull();
    });

    it("selects the highlighted option with Enter", async () => {
      const element = createLookup();
      const handler = jest.fn();
      element.addEventListener("change", handler);
      await focus(element);
      await press(element, "ArrowDown");
      const event = await press(element, "Enter");
      expect(event.defaultPrevented).toBe(true);
      expect(handler.mock.calls[0][0].detail.value).toBe("ContactEmailTWAction");
    });

    it("restarts the highlight at the top after typing", async () => {
      const element = createLookup();
      await focus(element);
      await press(element, "ArrowDown");
      await type(element, "t");
      expect(highlighted(element).dataset.value).toBe("AccountTWNameChange");
    });

    it("closes with Escape and keeps the selection", async () => {
      const element = createLookup({ value: "LeadTWConvert" });
      const handler = jest.fn();
      element.addEventListener("change", handler);
      await focus(element);
      const event = await press(element, "Escape");
      expect(event.defaultPrevented).toBe(true);
      expect(element.shadowRoot.querySelector('[role="listbox"]')).toBeNull();
      expect(input(element).value).toBe("Lead Convert");
      expect(handler).not.toHaveBeenCalled();
    });

    it("leaves keys alone when closed or without matches", async () => {
      const element = createLookup();
      expect((await press(element, "Enter")).defaultPrevented).toBe(false);
      expect((await press(element, "Escape")).defaultPrevented).toBe(false);
      await focus(element);
      await type(element, "zzz");
      expect((await press(element, "ArrowDown")).defaultPrevented).toBe(false);
      expect((await press(element, "ArrowUp")).defaultPrevented).toBe(false);
      expect((await press(element, "Enter")).defaultPrevented).toBe(false);
      expect((await press(element, "Tab")).defaultPrevented).toBe(false);
    });
  });

  it("is accessible", async () => {
    const element = createLookup({ value: "LeadTWConvert" });
    await focus(element);
    await expect(element).toBeAccessible();
  });
});
