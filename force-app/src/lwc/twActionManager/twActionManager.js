import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, unsubscribe } from "lightning/empApi";
import getSObjectOptions from "@salesforce/apex/TW_ActionManagerController.sObjectOptions";
import getActionsBySObject from "@salesforce/apex/TW_ActionManagerController.actionsBySObject";
import saveOrder from "@salesforce/apex/TW_ActionManagerController.saveOrder";
import ActionModal from "c/twActionModal";

const DEPLOYMENT_CHANNEL = "/event/TW_Action_Deployment__e";
const DEPLOYMENT_TIMEOUT_MS = 120000;
// A newly expanded SObject shows this many actions at once, then adds the rest in batches on later
// animation frames, so a long list appears without a pause
const FIRST_ROWS = 10;
const ROW_BATCH = 10;
// The search applies once typing pauses this long, so each keystroke doesn't rework the list
const SEARCH_DELAY_MS = 250;
// Moving between matches happens at most this often. Faster steps, such as a held Enter key's
// repeats, are dropped rather than queued, so moving stops as soon as the key is released
const MATCH_STEP_MS = 150;

function errorMessage(error, fallback) {
  return error?.body?.message || error?.message || fallback;
}

// Deployment IDs can arrive as 15 or 18 characters
function sameId(a, b) {
  return !!a && !!b && a.substring(0, 15) === b.substring(0, 15);
}

// Actions are stored by lowercase SObject API name, as TW_ActionManagerController returns them
function keyOf(sObjectName) {
  return (sObjectName || "").toLowerCase();
}

// The search's words, lowercased. Spaces separate words
function searchWords(term) {
  return term
    .toLowerCase()
    .split(/\s+/)
    .filter((word) => word);
}

// True if every word appears somewhere in the texts, in any order and not necessarily in the same text
function containsAll(words, texts) {
  const text = texts
    .filter((t) => t)
    .join(" ")
    .toLowerCase();
  return words.length > 0 && words.every((word) => text.includes(word));
}

function names(actions) {
  return (actions || []).map((a) => a.developerName).join();
}

/**
 * Lists the SObjects that use Trigger Weaver with their action counts. Any number of SObjects can be
 * expanded to show their actions in execution order, where they can be reordered by dragging, with
 * the arrow buttons or by typing a position, and edited. Each SObject keeps its own unsaved order.
 * Saving, editing and creating actions start metadata deployments; this component waits for the
 * TW_Action_Deployment__e event that reports each result, then reloads.
 *
 * Searching highlights the actions whose class, description or SObject matches, across every
 * SObject, and dims the rest. It expands the SObjects with a match and collapses the others;
 * clearing the search leaves them as they are. Nothing is hidden within an SObject, so positions
 * and reordering are unaffected.
 */
export default class TwActionManager extends NavigationMixin(LightningElement) {
  sObjectOptions = [];
  isLoading = true;
  error;
  pendingJobId;
  pendingSuccessMessage;

  // Each SObject's actions as last loaded, and in their current, possibly unsaved, order
  savedBySObject = {};
  actionsBySObject = {};
  // The expanded SObjects, by key
  expanded = {};
  // How many of each expanded SObject's actions are rendered while a long list is still being added
  renderLimit = {};

  // Dragging works within one SObject at a time
  dragKey;
  dragIndex;
  // The row whose grip is pressed. Only that row is draggable, so rows move only from the grip
  gripKey;
  gripIndex;
  // Insertion point while dragging: 0 is before the first action, the action count after the last
  dropPosition;
  // The row whose position number is being typed over
  editingKey;
  editingIndex;
  focusPositionInput = false;

  // The search box's text, and the search applied from it once typing pauses
  searchInput = "";
  searchTerm = "";
  searchTimer;
  lastMatchStep = 0;
  // The matching actions as { sObjectName, developerName }, in list order
  matches = [];
  // Index into matches of the match last moved to, or -1 before any
  currentMatch = -1;
  // An action to scroll to once it has rendered, as "key.developerName"
  scrollToKey;

  // Each SObject's built rows and what they were built from, so unchanged SObjects aren't rebuilt
  // on every render, such as each keystroke in the search box
  rowCache = new Map();

  subscription;
  deploymentResults = new Map();
  timeoutId;

  connectedCallback() {
    this.load();
    this.subscribeToDeployments();
  }

  renderedCallback() {
    if (this.scrollToKey) {
      const row = this.template.querySelector(`li[data-row-key="${this.scrollToKey}"]`);
      if (row) {
        this.scrollToKey = undefined;
        row.scrollIntoView({ block: "center", behavior: "smooth" });
      }
    }
    if (this.focusPositionInput) {
      const input = this.template.querySelector(".tw-position-input");
      if (input) {
        this.focusPositionInput = false;
        input.focus();
        input.select();
      }
    }
  }

  disconnectedCallback() {
    clearTimeout(this.searchTimer);
    if (this.subscription) {
      unsubscribe(this.subscription);
    }
    clearTimeout(this.timeoutId);
  }

  get isDeploying() {
    return !!this.pendingJobId;
  }

  get hasSObjects() {
    return this.sObjectOptions.length > 0;
  }

  get showNoSObjects() {
    return !this.isLoading && !this.hasSObjects;
  }

  isDirty(key) {
    return names(this.actionsBySObject[key]) !== names(this.savedBySObject[key]);
  }

  get dirtyKeys() {
    return Object.keys(this.actionsBySObject).filter((key) => this.isDirty(key));
  }

  get isSearching() {
    return this.searchTerm.trim().length > 0;
  }

  get hasNoMatches() {
    return this.matches.length === 0;
  }

  get searchSummary() {
    const count = this.matches.length;
    if (count === 0) {
      return "No matches";
    }
    const total = count === 1 ? "1 match" : `${count} matches`;
    return this.currentMatch < 0 ? total : `${this.currentMatch + 1} of ${total}`;
  }

  get currentMatchKey() {
    const match = this.matches[this.currentMatch];
    return match ? `${keyOf(match.sObjectName)}.${match.developerName}` : null;
  }

  get sObjects() {
    const matchesByKey = new Map();
    for (const m of this.matches) {
      const key = keyOf(m.sObjectName);
      if (!matchesByKey.has(key)) {
        matchesByKey.set(key, new Set());
      }
      matchesByKey.get(key).add(m.developerName);
    }
    return this.sObjectOptions.map((o) => {
      const key = keyOf(o.apiName);
      const isExpanded = !!this.expanded[key];
      const isDirty = this.isDirty(key);
      const matchNames = matchesByKey.get(key) || new Set();
      const actions = this.actionsBySObject[key] || [];
      return {
        ...o,
        key,
        isExpanded,
        cssClass: "tw-sobject" + (this.isSearching && matchNames.size === 0 && !this.sObjectMatches(o) ? " tw-sobject_dimmed" : ""),
        sectionId: `tw-section-${o.apiName}`,
        chevron: isExpanded ? "utility:chevrondown" : "utility:chevronright",
        countLabel: o.actionCount === 1 ? "1 action" : `${o.actionCount} actions`,
        showMatchCount: this.isSearching && matchNames.size > 0,
        matchLabel: matchNames.size === 1 ? "1 match" : `${matchNames.size} matches`,
        hasProblems: o.problemCount > 0,
        problemLabel: o.problemCount === 1 ? "1 problem" : `${o.problemCount} problems`,
        missingTrigger: !o.hasFrameworkTrigger,
        // An SObject with an unsaved order stays expanded so its changes are never hidden
        toggleDisabled: isExpanded && isDirty,
        // An action on an SObject without a framework trigger would never run. Deploying would also
        // reload, and so discard, this SObject's unsaved order
        addDisabled: !o.hasFrameworkTrigger || this.isDeploying || isDirty,
        addTitle: o.hasFrameworkTrigger ? null : `${o.label} has no trigger that uses TW_Handler, so its actions would never run`,
        actions: isExpanded ? this.actionRows(key, matchNames) : [],
        showLoading: isExpanded && this.isLoading,
        // The hint and Add Action share one line so the section gets no taller
        showSectionBar: isExpanded && !this.isLoading,
        sectionText: this.sectionText(o, actions),
        showOrderButtons: isExpanded && isDirty
      };
    });
  }

  sObjectMatches(option) {
    return containsAll(searchWords(this.searchTerm), [option.apiName, option.label]);
  }

  sectionText(option, actions) {
    if (actions.length === 0) {
      return `No actions are configured for ${option.label}.`;
    }
    return actions.length > 1 ? "Actions run from top to bottom. Drag an action, or use its arrows, to change the order." : "";
  }

  // No bar where dropping would leave the action where it is
  get showsDropBar() {
    return (
      this.dragIndex !== undefined &&
      this.dropPosition !== undefined &&
      this.dropPosition !== this.dragIndex &&
      this.dropPosition !== this.dragIndex + 1
    );
  }

  // Rebuilds an SObject's rows only when something they depend on has changed
  actionRows(key, matchNames) {
    const inputs = [
      this.actionsBySObject[key],
      this.savedBySObject[key],
      this.isSearching,
      [...matchNames].join(),
      this.currentMatchKey,
      key === this.dragKey ? `${this.dragIndex}:${this.dropPosition}` : null,
      key === this.gripKey ? this.gripIndex : null,
      key === this.editingKey ? this.editingIndex : null,
      this.isDeploying,
      this.renderLimit[key]
    ];
    const cached = this.rowCache.get(key);
    if (cached && cached.inputs.every((value, i) => value === inputs[i])) {
      return cached.rows;
    }
    const rows = this.buildActionRows(key, matchNames);
    this.rowCache.set(key, { inputs, rows });
    return rows;
  }

  buildActionRows(key, matchNames) {
    const actions = this.actionsBySObject[key] || [];
    const savedPositions = new Map((this.savedBySObject[key] || []).map((a, i) => [a.developerName, i]));
    const last = actions.length - 1;
    const isDirty = this.isDirty(key);
    const currentKey = this.currentMatchKey;
    const isDragSObject = key === this.dragKey;
    const limit = this.renderLimit[key] ?? actions.length;
    return actions.slice(0, limit).map((a, i) => {
      const rowKey = `${key}.${a.developerName}`;
      const classes = ["tw-action", a.active ? "tw-action_active" : "tw-action_inactive"];
      if (this.isSearching) {
        classes.push(matchNames.has(a.developerName) ? "tw-action_match" : "tw-action_dimmed");
        if (currentKey === rowKey) {
          classes.push("tw-action_current");
        }
      }
      if (isDragSObject && i === this.dragIndex) {
        classes.push("tw-action_dragging");
      }
      if (isDragSObject && this.showsDropBar) {
        if (this.dropPosition === i) {
          classes.push("tw-action_drop-before");
        } else if (this.dropPosition === i + 1 && i === last) {
          classes.push("tw-action_drop-after");
        }
      }
      return {
        ...a,
        key,
        rowKey,
        index: i,
        position: i + 1,
        cssClass: classes.join(" "),
        draggable: !this.isDeploying && key === this.gripKey && i === this.gripIndex ? "true" : "false",
        statusLabel: a.active ? "Active" : "Inactive",
        statusClass: a.active ? "tw-status tw-status_active" : "tw-status tw-status_inactive",
        isEditingPosition: key === this.editingKey && i === this.editingIndex,
        positionMax: actions.length,
        positionDisabled: this.isDeploying,
        moved: savedPositions.get(a.developerName) !== i,
        movedLabel: `←${savedPositions.get(a.developerName) + 1}`,
        movedTitle: `Previously in position ${savedPositions.get(a.developerName) + 1}`,
        upDisabled: i === 0 || this.isDeploying,
        downDisabled: i === last || this.isDeploying,
        // Deploying would reload, and so discard, this SObject's unsaved order
        editDisabled: this.isDeploying || isDirty
      };
    });
  }

  async load() {
    try {
      const [options, actionsBySObject] = await Promise.all([getSObjectOptions(), getActionsBySObject()]);
      const dirty = new Set(this.dirtyKeys);
      const saved = {};
      const working = {};
      for (const [key, actions] of Object.entries(actionsBySObject || {})) {
        saved[key] = actions;
        // An unsaved order in another SObject survives the reload
        working[key] = dirty.has(key) ? this.actionsBySObject[key] : [...actions];
      }
      this.sObjectOptions = options;
      this.savedBySObject = saved;
      this.actionsBySObject = working;
      this.updateMatches();
    } catch (e) {
      this.error = errorMessage(e, "The actions could not be loaded.");
    } finally {
      this.isLoading = false;
    }
  }

  // Finds the actions where every word of the search appears in the class, description, SObject API
  // name or SObject label, ignoring case. They are listed in the order the list shows them, so moving
  // between matches goes down the page
  updateMatches() {
    const words = searchWords(this.searchTerm);
    const previous = this.currentMatchKey;
    if (!words.length) {
      this.matches = [];
      this.currentMatch = -1;
      return;
    }
    const matches = [];
    for (const o of this.sObjectOptions) {
      for (const a of this.actionsBySObject[keyOf(o.apiName)] || []) {
        if (containsAll(words, [a.apexClass, a.description, o.apiName, o.label])) {
          matches.push({ sObjectName: o.apiName, developerName: a.developerName });
        }
      }
    }
    this.matches = matches;
    // Keeps the place in the matches when they're recalculated, such as after a deployment
    this.currentMatch = matches.findIndex((m) => `${keyOf(m.sObjectName)}.${m.developerName}` === previous);
  }

  // Sets the expanded SObjects, rendering any newly expanded ones in stages
  setExpanded(expanded) {
    const renderLimit = { ...this.renderLimit };
    const added = [];
    for (const key of Object.keys(expanded)) {
      if (!this.expanded[key]) {
        renderLimit[key] = FIRST_ROWS;
        added.push(key);
      }
    }
    for (const key of Object.keys(renderLimit)) {
      if (!expanded[key]) {
        delete renderLimit[key];
      }
    }
    this.expanded = expanded;
    this.renderLimit = renderLimit;
    if (added.length) {
      this.renderMoreRows();
    }
  }

  // Adds a batch of rows to every SObject still being rendered, then waits for the next frame
  renderMoreRows() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    requestAnimationFrame(() => {
      const renderLimit = { ...this.renderLimit };
      let pending = false;
      for (const key of Object.keys(renderLimit)) {
        const total = (this.actionsBySObject[key] || []).length;
        if (renderLimit[key] < total) {
          renderLimit[key] += ROW_BATCH;
          pending = pending || renderLimit[key] < total;
        }
      }
      this.renderLimit = renderLimit;
      if (pending) {
        this.renderMoreRows();
      }
    });
  }

  // Renders all of an SObject's actions now, such as before scrolling to one of them
  renderAllRows(key) {
    this.renderLimit = { ...this.renderLimit, [key]: Infinity };
  }

  // Expands the SObjects with a match, or that match themselves, and collapses the rest. SObjects
  // with an unsaved order stay expanded
  expandToMatches() {
    const expanded = {};
    for (const o of this.sObjectOptions) {
      if (this.sObjectMatches(o)) {
        expanded[keyOf(o.apiName)] = true;
      }
    }
    for (const m of this.matches) {
      expanded[keyOf(m.sObjectName)] = true;
    }
    for (const key of this.dirtyKeys) {
      expanded[key] = true;
    }
    this.setExpanded(expanded);
  }

  // Applies the search once typing pauses. An emptied box clears the search at once
  handleSearchChange(event) {
    this.searchInput = event.detail.value || "";
    clearTimeout(this.searchTimer);
    if (!this.searchInput.trim()) {
      this.applySearch();
      return;
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.searchTimer = setTimeout(() => this.applySearch(), SEARCH_DELAY_MS);
  }

  handleClearSearch() {
    clearTimeout(this.searchTimer);
    this.searchInput = "";
    this.applySearch();
  }

  applySearch() {
    if (this.searchInput !== this.searchTerm) {
      this.setSearchTerm(this.searchInput);
    }
  }

  // Clearing the search leaves the SObjects that are expanded open
  setSearchTerm(term) {
    this.searchTerm = term;
    this.currentMatch = -1;
    this.updateMatches();
    if (this.isSearching) {
      this.expandToMatches();
    }
  }

  // Enter moves to the next match, Shift+Enter to the previous one
  // A search still waiting for typing to pause is applied first. A key press that waited in the
  // browser's queue while the list was redrawing, such as a held Enter key's repeats, is dropped
  handleSearchKeyDown(event) {
    if (event.key !== "Enter") {
      return;
    }
    event.preventDefault();
    if (performance.now() - event.timeStamp > MATCH_STEP_MS) {
      return;
    }
    clearTimeout(this.searchTimer);
    this.applySearch();
    this.stepMatch(event.shiftKey ? -1 : 1);
  }

  handleNextMatch() {
    this.stepMatch(1);
  }

  handlePreviousMatch() {
    this.stepMatch(-1);
  }

  // Moves between matches no faster than MATCH_STEP_MS, dropping steps that come sooner
  stepMatch(step) {
    const now = Date.now();
    if (now - this.lastMatchStep < MATCH_STEP_MS) {
      return;
    }
    this.lastMatchStep = now;
    this.goToMatch(step);
  }

  // Expands the match's SObject if it was collapsed by hand, and scrolls to the match
  goToMatch(step) {
    const count = this.matches.length;
    if (!count) {
      return;
    }
    const start = this.currentMatch < 0 && step < 0 ? 0 : this.currentMatch;
    const index = (start + step + count) % count;
    const match = this.matches[index];
    const key = keyOf(match.sObjectName);
    if (!this.expanded[key]) {
      this.setExpanded({ ...this.expanded, [key]: true });
    }
    this.renderAllRows(key);
    this.currentMatch = index;
    this.scrollToKey = `${key}.${match.developerName}`;
  }

  handleToggle(event) {
    const key = keyOf(event.currentTarget.dataset.name);
    const expanded = { ...this.expanded };
    if (expanded[key]) {
      delete expanded[key];
      if (key === this.dragKey || key === this.editingKey) {
        this.handleDragEnd();
        this.editingKey = undefined;
      }
    } else {
      expanded[key] = true;
    }
    this.setExpanded(expanded);
  }

  handleDragStart(event) {
    this.dragKey = event.currentTarget.dataset.key;
    this.dragIndex = Number(event.currentTarget.dataset.index);
    event.dataTransfer.effectAllowed = "move";
    // Some browsers only start a drag when data is set
    event.dataTransfer.setData("text/plain", String(this.dragIndex));
  }

  // Over the top half of an action the insertion point is before it, over the bottom half after it.
  // Rows of other SObjects are ignored, since actions only move within their SObject
  handleDragOver(event) {
    if (this.dragIndex === undefined || event.currentTarget.dataset.key !== this.dragKey) {
      return;
    }
    const index = Number(event.currentTarget.dataset.index);
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropPosition = event.clientY < rect.top + rect.height / 2 ? index : index + 1;
  }

  // Accepts the drop anywhere in the component, so it lands where the bar shows. Above the dragged
  // action's list the insertion point is the first position and below it the last; over the rows,
  // and in the gaps between them, the point set by handleDragOver is kept
  handleAreaDragOver(event) {
    if (this.dragIndex === undefined) {
      return;
    }
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
    const list = this.template.querySelector(`ol[data-key="${this.dragKey}"]`);
    if (!list) {
      return;
    }
    const rect = list.getBoundingClientRect();
    if (event.clientY < rect.top) {
      this.dropPosition = 0;
    } else if (event.clientY > rect.bottom) {
      this.dropPosition = (this.actionsBySObject[this.dragKey] || []).length;
    }
  }

  handleDrop(event) {
    event.preventDefault();
    if (this.dragIndex !== undefined && this.dropPosition !== undefined) {
      // Removing the dragged action first shifts later insertion points up by one
      this.move(this.dragKey, this.dragIndex, this.dropPosition > this.dragIndex ? this.dropPosition - 1 : this.dropPosition);
    }
    this.handleDragEnd();
  }

  handleGripDown(event) {
    this.gripKey = event.currentTarget.dataset.key;
    this.gripIndex = Number(event.currentTarget.dataset.index);
  }

  handleDragEnd() {
    this.gripKey = undefined;
    this.gripIndex = undefined;
    this.dragKey = undefined;
    this.dragIndex = undefined;
    this.dropPosition = undefined;
  }

  handlePositionClick(event) {
    this.editingKey = event.currentTarget.dataset.key;
    this.editingIndex = Number(event.currentTarget.dataset.index);
    this.focusPositionInput = true;
  }

  handlePositionKeyDown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      event.currentTarget.blur();
    } else if (event.key === "Escape") {
      event.preventDefault();
      // Stops the Esc from also closing anything around the component
      event.stopPropagation();
      this.editingKey = undefined;
      this.editingIndex = undefined;
    }
  }

  // Enter and clicking away both end up here. A blank or invalid value leaves the action in place
  handlePositionBlur(event) {
    if (this.editingKey === undefined) {
      return;
    }
    const key = this.editingKey;
    const from = this.editingIndex;
    const target = Number.parseInt(event.currentTarget.value, 10);
    this.editingKey = undefined;
    this.editingIndex = undefined;
    if (Number.isNaN(target)) {
      return;
    }
    const count = (this.actionsBySObject[key] || []).length;
    this.move(key, from, Math.min(Math.max(target, 1), count) - 1);
  }

  handleMoveUp(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.move(event.currentTarget.dataset.key, index, index - 1);
  }

  handleMoveDown(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.move(event.currentTarget.dataset.key, index, index + 1);
  }

  move(key, from, to) {
    const actions = [...(this.actionsBySObject[key] || [])];
    if (from === undefined || from === to || to < 0 || to >= actions.length) {
      return;
    }
    const [moved] = actions.splice(from, 1);
    actions.splice(to, 0, moved);
    this.actionsBySObject = { ...this.actionsBySObject, [key]: actions };
  }

  handleCancelOrder(event) {
    const key = event.currentTarget.dataset.key;
    this.actionsBySObject = { ...this.actionsBySObject, [key]: [...(this.savedBySObject[key] || [])] };
  }

  async handleSaveOrder(event) {
    const key = event.currentTarget.dataset.key;
    const option = this.optionFor(key);
    this.error = undefined;
    try {
      const jobId = await saveOrder({
        sObjectName: option.apiName,
        developerNames: (this.actionsBySObject[key] || []).map((a) => a.developerName)
      });
      if (jobId) {
        this.waitForDeployment(jobId, `Saved the order of the ${option.label} actions.`);
      } else {
        this.savedBySObject = { ...this.savedBySObject, [key]: [...this.actionsBySObject[key]] };
        this.toast("info", "No changes", "The order is unchanged.");
      }
    } catch (e) {
      this.error = errorMessage(e, "The order could not be saved.");
    }
  }

  optionFor(key) {
    return this.sObjectOptions.find((o) => keyOf(o.apiName) === key);
  }

  async handleEdit(event) {
    const key = event.currentTarget.dataset.key;
    const action = (this.actionsBySObject[key] || []).find((a) => a.developerName === event.currentTarget.dataset.name);
    const result = await ActionModal.open({
      size: "small",
      label: "Edit Action",
      options: this.sObjectOptions,
      sObjectName: this.optionFor(key).apiName,
      action
    });
    if (result?.jobId) {
      this.waitForDeployment(result.jobId, `Saved the ${result.className} action.`);
    } else if (result?.unchanged) {
      this.toast("info", "No changes", "The action is unchanged.");
    }
  }

  // The record's page in Setup, which has the Delete button the tab doesn't offer. Lightning Web
  // Security blocks window.open for Setup pages, so this uses the navigation service
  handleOpenRecord(event) {
    const address = encodeURIComponent(`/${event.currentTarget.dataset.id}`);
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: { url: `/lightning/setup/CustomMetadata/page?address=${address}` }
    });
  }

  async handleAddAction(event) {
    const sObjectName = event.currentTarget.dataset.name;
    const result = await ActionModal.open({
      size: "small",
      label: "New Action",
      options: this.sObjectOptions,
      sObjectName
    });
    if (result?.jobId) {
      // Show the SObject's actions, including the new one once the deployment finishes
      this.setExpanded({ ...this.expanded, [keyOf(sObjectName)]: true });
      this.waitForDeployment(result.jobId, `Created the ${result.className} action.`);
    }
  }

  async subscribeToDeployments() {
    try {
      this.subscription = await subscribe(DEPLOYMENT_CHANNEL, -1, (message) => this.handleDeploymentResult(message.data.payload));
    } catch (e) {
      // Without the event the timeout below still ends the wait and reloads the list
      this.subscription = undefined;
    }
  }

  waitForDeployment(jobId, successMessage) {
    this.error = undefined;
    this.pendingJobId = jobId;
    this.pendingSuccessMessage = successMessage;
    // The result can arrive before the job ID is returned
    const result = [...this.deploymentResults.values()].find((r) => sameId(r.Job_Id__c, jobId));
    if (result) {
      this.finishDeployment(result);
      return;
    }
    clearTimeout(this.timeoutId);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.timeoutId = setTimeout(() => this.handleDeploymentTimeout(), DEPLOYMENT_TIMEOUT_MS);
  }

  handleDeploymentResult(payload) {
    this.deploymentResults.set(payload.Job_Id__c, payload);
    if (sameId(payload.Job_Id__c, this.pendingJobId)) {
      this.finishDeployment(payload);
    }
  }

  // The saved SObject's order is no longer unsaved, so it's replaced on reload; other SObjects'
  // unsaved orders are kept
  finishDeployment(payload) {
    clearTimeout(this.timeoutId);
    this.pendingJobId = undefined;
    if (payload.Success__c) {
      this.toast("success", "Deployed", this.pendingSuccessMessage);
    } else {
      this.error = `The deployment failed: ${payload.Message__c || "no details were returned."}`;
    }
    this.refresh();
  }

  handleDeploymentTimeout() {
    this.pendingJobId = undefined;
    this.toast(
      "warning",
      "Still deploying",
      "The deployment is taking longer than expected. Check Setup > Deployment Status, then reload the list."
    );
    this.refresh();
  }

  refresh() {
    this.load();
  }

  toast(variant, title, message) {
    this.dispatchEvent(new ShowToastEvent({ variant, title, message }));
  }
}
