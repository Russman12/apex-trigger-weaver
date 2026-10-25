import { LightningElement, api } from "lwc";

const MAX_RESULTS = 50;

/**
 * Searchable lookup that only accepts one of its options. Each option is
 * { value, label, sublabel, badge }; sublabel and badge are optional. Searching matches the label,
 * value and sublabel. Fires a change event with the selected value in detail.value.
 */
export default class TwLookup extends LightningElement {
  @api label;
  @api required = false;
  @api disabled = false;
  @api placeholder = "Search...";
  @api fieldLevelHelp;
  /**
   * Shown when there are no options at all.
   */
  @api emptyText = "Nothing to select.";

  searchText = "";
  isOpen = false;
  highlightIndex = 0;
  _options = [];
  _value;

  /**
   * The options to choose from.
   */
  @api
  get options() {
    return this._options;
  }
  set options(value) {
    this._options = value || [];
    this.showSelectedLabel();
  }

  /**
   * The selected option's value.
   */
  @api
  get value() {
    return this._value;
  }
  set value(value) {
    this._value = value;
    this.showSelectedLabel();
  }

  get selectedOption() {
    return this._options.find((o) => o.value === this._value);
  }

  get matchingOptions() {
    const term = this.isOpen ? this.searchText.trim().toLowerCase() : "";
    if (!term) {
      return this._options;
    }
    return this._options.filter((o) => [o.label, o.value, o.sublabel].some((text) => text && text.toLowerCase().includes(term)));
  }

  get results() {
    return this.matchingOptions.slice(0, MAX_RESULTS).map((o, i) => ({
      ...o,
      isSelected: o.value === this._value,
      cssClass: "tw-option slds-p-around_x-small" + (i === this.highlightIndex ? " tw-option_highlighted" : "")
    }));
  }

  get hasResults() {
    return this.results.length > 0;
  }

  get moreResultsText() {
    const remaining = this.matchingOptions.length - MAX_RESULTS;
    return remaining > 0 ? `${remaining} more. Type to narrow the list.` : null;
  }

  get noResultsText() {
    return this._options.length === 0 ? this.emptyText : "No matches.";
  }

  showSelectedLabel() {
    if (!this.isOpen) {
      const selected = this.selectedOption;
      if (!selected) {
        this.searchText = this._value || "";
      } else {
        this.searchText = selected.sublabel ? `${selected.label} (${selected.sublabel})` : selected.label;
      }
    }
  }

  // The box shows the selected option until focused, then holds the search text
  handleFocus() {
    this.isOpen = true;
    this.searchText = "";
    this.highlightIndex = 0;
  }

  handleBlur() {
    this.isOpen = false;
    this.showSelectedLabel();
  }

  handleInput(event) {
    this.searchText = event.detail.value;
    this.isOpen = true;
    this.highlightIndex = 0;
  }

  handleKeyDown(event) {
    const count = this.results.length;
    if (event.key === "ArrowDown" && count) {
      event.preventDefault();
      this.isOpen = true;
      this.highlightIndex = (this.highlightIndex + 1) % count;
    } else if (event.key === "ArrowUp" && count) {
      event.preventDefault();
      this.highlightIndex = (this.highlightIndex - 1 + count) % count;
    } else if (event.key === "Enter" && this.isOpen && count) {
      event.preventDefault();
      this.select(this.results[this.highlightIndex].value);
    } else if (event.key === "Escape" && this.isOpen) {
      event.preventDefault();
      this.handleBlur();
    }
  }

  // Keeps focus in the input so the click below selects before blur closes the list
  handleOptionMouseDown(event) {
    event.preventDefault();
  }

  handleOptionClick(event) {
    this.select(event.currentTarget.dataset.value);
  }

  select(value) {
    this._value = value;
    this.isOpen = false;
    this.showSelectedLabel();
    this.dispatchEvent(new CustomEvent("change", { detail: { value } }));
  }
}
