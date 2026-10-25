import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, unsubscribe } from "lightning/empApi";
import getSObjectOptions from "@salesforce/apex/TW_ActionManagerController.sObjectOptions";
import getActions from "@salesforce/apex/TW_ActionManagerController.actions";
import saveOrder from "@salesforce/apex/TW_ActionManagerController.saveOrder";
import ActionModal from "c/twActionModal";

const DEPLOYMENT_CHANNEL = "/event/TW_Action_Deployment__e";
const DEPLOYMENT_TIMEOUT_MS = 120000;

function errorMessage(error, fallback) {
  return error?.body?.message || error?.message || fallback;
}

// Deployment IDs can arrive as 15 or 18 characters
function sameId(a, b) {
  return !!a && !!b && a.substring(0, 15) === b.substring(0, 15);
}

/**
 * Lists the SObjects that use Trigger Weaver with their action counts. One SObject at a time
 * expands to show its actions in execution order, where they can be reordered by dragging or with
 * the arrow buttons, and edited. Saving, editing and creating actions start metadata deployments;
 * this component waits for the TW_Action_Deployment__e event that reports each result, then reloads.
 */
export default class TwActionManager extends NavigationMixin(LightningElement) {
  sObjectOptions = [];
  isLoadingSObjects = true;
  expandedName;
  savedActions = [];
  actions = [];
  isLoadingActions = false;
  error;
  pendingJobId;
  pendingSuccessMessage;
  dragIndex;
  // The row whose grip is pressed. Only that row is draggable, so rows move only from the grip
  gripIndex;
  // The row whose position number is being typed over
  editingIndex;
  focusPositionInput = false;
  // Insertion point while dragging: 0 is before the first action, actions.length after the last
  dropPosition;

  subscription;
  deploymentResults = new Map();
  timeoutId;

  connectedCallback() {
    this.loadSObjectOptions();
    this.subscribeToDeployments();
  }

  renderedCallback() {
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
    if (this.subscription) {
      unsubscribe(this.subscription);
    }
    clearTimeout(this.timeoutId);
  }

  get isDeploying() {
    return !!this.pendingJobId;
  }

  get isDirty() {
    return this.actions.map((a) => a.developerName).join() !== this.savedActions.map((a) => a.developerName).join();
  }

  // Deploying, or reloading after another change, would discard an unsaved order
  get isLocked() {
    return this.isDeploying || this.isDirty;
  }

  get hasSObjects() {
    return this.sObjectOptions.length > 0;
  }

  get showNoSObjects() {
    return !this.isLoadingSObjects && !this.hasSObjects;
  }

  get sObjects() {
    return this.sObjectOptions.map((o) => {
      const isExpanded = o.apiName === this.expandedName;
      return {
        ...o,
        isExpanded,
        sectionId: `tw-section-${o.apiName}`,
        chevron: isExpanded ? "utility:chevrondown" : "utility:chevronright",
        countLabel: o.actionCount === 1 ? "1 action" : `${o.actionCount} actions`,
        missingTrigger: !o.hasFrameworkTrigger,
        toggleDisabled: this.isDirty && !isExpanded,
        // An action on an SObject without a framework trigger would never run
        addDisabled: !o.hasFrameworkTrigger || this.isLocked,
        addTitle: o.hasFrameworkTrigger ? null : `${o.label} has no trigger that uses TW_Handler, so its actions would never run`,
        actions: isExpanded ? this.actionRows : [],
        showLoading: isExpanded && this.isLoadingActions,
        // The hint and Add Action share one line so the section gets no taller
        showSectionBar: isExpanded && !this.isLoadingActions,
        sectionText: this.sectionText(o),
        showOrderButtons: isExpanded && this.isDirty
      };
    });
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

  sectionText(option) {
    if (this.actions.length === 0) {
      return `No actions are configured for ${option.label}.`;
    }
    return this.actions.length > 1 ? "Actions run from top to bottom. Drag an action, or use its arrows, to change the order." : "";
  }

  get actionRows() {
    const savedPositions = new Map(this.savedActions.map((a, i) => [a.developerName, i]));
    const last = this.actions.length - 1;
    return this.actions.map((a, i) => {
      const classes = ["tw-action", a.active ? "tw-action_active" : "tw-action_inactive"];
      if (i === this.dragIndex) {
        classes.push("tw-action_dragging");
      }
      if (this.showsDropBar) {
        if (this.dropPosition === i) {
          classes.push("tw-action_drop-before");
        } else if (this.dropPosition === i + 1 && i === last) {
          classes.push("tw-action_drop-after");
        }
      }
      return {
        ...a,
        index: i,
        position: i + 1,
        cssClass: classes.join(" "),
        draggable: !this.isDeploying && i === this.gripIndex ? "true" : "false",
        statusLabel: a.active ? "Active" : "Inactive",
        statusClass: a.active ? "tw-status tw-status_active" : "tw-status tw-status_inactive",
        isEditingPosition: i === this.editingIndex,
        positionMax: this.actions.length,
        positionDisabled: this.isDeploying,
        moved: savedPositions.get(a.developerName) !== i,
        movedLabel: `←${savedPositions.get(a.developerName) + 1}`,
        movedTitle: `Previously in position ${savedPositions.get(a.developerName) + 1}`,
        upDisabled: i === 0 || this.isDeploying,
        downDisabled: i === last || this.isDeploying,
        editDisabled: this.isLocked
      };
    });
  }

  async loadSObjectOptions() {
    try {
      this.sObjectOptions = await getSObjectOptions();
    } catch (e) {
      this.error = errorMessage(e, "The objects could not be loaded.");
    } finally {
      this.isLoadingSObjects = false;
    }
  }

  async loadExpandedActions() {
    const sObjectName = this.expandedName;
    if (!sObjectName) {
      return;
    }
    this.isLoadingActions = true;
    try {
      const actions = await getActions({ sObjectName });
      // Ignore a response for an SObject that is no longer expanded
      if (sObjectName === this.expandedName) {
        this.savedActions = actions;
        this.actions = [...actions];
      }
    } catch (e) {
      this.error = errorMessage(e, "The actions could not be loaded.");
    } finally {
      this.isLoadingActions = false;
    }
  }

  handleToggle(event) {
    const apiName = event.currentTarget.dataset.name;
    this.savedActions = [];
    this.actions = [];
    this.handleDragEnd();
    if (apiName === this.expandedName) {
      this.expandedName = undefined;
      return;
    }
    this.expandedName = apiName;
    this.loadExpandedActions();
  }

  handleDragStart(event) {
    this.dragIndex = Number(event.currentTarget.dataset.index);
    event.dataTransfer.effectAllowed = "move";
    // Some browsers only start a drag when data is set
    event.dataTransfer.setData("text/plain", String(this.dragIndex));
  }

  // Over the top half of an action the insertion point is before it, over the bottom half after it
  handleDragOver(event) {
    if (this.dragIndex === undefined) {
      return;
    }
    const index = Number(event.currentTarget.dataset.index);
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropPosition = event.clientY < rect.top + rect.height / 2 ? index : index + 1;
  }

  // Accepts the drop anywhere in the component, so it lands where the bar shows. Above the list the
  // insertion point is the first position and below it the last; over the rows, and in the gaps
  // between them, the point set by handleDragOver is kept
  handleAreaDragOver(event) {
    if (this.dragIndex === undefined) {
      return;
    }
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
    const list = this.template.querySelector(".tw-actions");
    if (!list) {
      return;
    }
    const rect = list.getBoundingClientRect();
    if (event.clientY < rect.top) {
      this.dropPosition = 0;
    } else if (event.clientY > rect.bottom) {
      this.dropPosition = this.actions.length;
    }
  }

  handleDrop(event) {
    event.preventDefault();
    if (this.dragIndex !== undefined && this.dropPosition !== undefined) {
      // Removing the dragged action first shifts later insertion points up by one
      this.move(this.dragIndex, this.dropPosition > this.dragIndex ? this.dropPosition - 1 : this.dropPosition);
    }
    this.handleDragEnd();
  }

  handlePositionClick(event) {
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
      this.editingIndex = undefined;
    }
  }

  // Enter and clicking away both end up here. A blank or invalid value leaves the action in place
  handlePositionBlur(event) {
    if (this.editingIndex === undefined) {
      return;
    }
    const from = this.editingIndex;
    const target = Number.parseInt(event.currentTarget.value, 10);
    this.editingIndex = undefined;
    if (Number.isNaN(target)) {
      return;
    }
    this.move(from, Math.min(Math.max(target, 1), this.actions.length) - 1);
  }

  handleGripDown(event) {
    this.gripIndex = Number(event.currentTarget.dataset.index);
  }

  handleDragEnd() {
    this.gripIndex = undefined;
    this.dragIndex = undefined;
    this.dropPosition = undefined;
  }

  handleMoveUp(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.move(index, index - 1);
  }

  handleMoveDown(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.move(index, index + 1);
  }

  move(from, to) {
    if (from === undefined || from === to || to < 0 || to >= this.actions.length) {
      return;
    }
    const actions = [...this.actions];
    const [moved] = actions.splice(from, 1);
    actions.splice(to, 0, moved);
    this.actions = actions;
  }

  handleCancelOrder() {
    this.actions = [...this.savedActions];
  }

  async handleSaveOrder() {
    this.error = undefined;
    try {
      const jobId = await saveOrder({ sObjectName: this.expandedName, developerNames: this.actions.map((a) => a.developerName) });
      if (jobId) {
        const option = this.sObjectOptions.find((o) => o.apiName === this.expandedName);
        this.waitForDeployment(jobId, `Saved the order of the ${option ? option.label : this.expandedName} actions.`);
      } else {
        this.savedActions = [...this.actions];
        this.toast("info", "No changes", "The order is unchanged.");
      }
    } catch (e) {
      this.error = errorMessage(e, "The order could not be saved.");
    }
  }

  async handleEdit(event) {
    const action = this.actions.find((a) => a.developerName === event.currentTarget.dataset.name);
    const result = await ActionModal.open({
      size: "small",
      label: "Edit Action",
      options: this.sObjectOptions,
      sObjectName: this.expandedName,
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
      if (this.expandedName !== sObjectName) {
        this.expandedName = sObjectName;
        this.savedActions = [];
        this.actions = [];
      }
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
    this.loadSObjectOptions();
    this.loadExpandedActions();
  }

  toast(variant, title, message) {
    this.dispatchEvent(new ShowToastEvent({ variant, title, message }));
  }
}
