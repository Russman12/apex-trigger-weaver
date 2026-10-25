import { api } from "lwc";
import LightningModal from "lightning/modal";
import createAction from "@salesforce/apex/TW_ActionManagerController.createAction";
import updateAction from "@salesforce/apex/TW_ActionManagerController.updateAction";
import getActionName from "@salesforce/apex/TW_ActionManagerController.actionName";
import getActionClassOptions from "@salesforce/apex/TW_ActionManagerController.actionClassOptions";

function errorMessage(error, fallback) {
  return error?.body?.message || error?.message || fallback;
}

/**
 * Creates a TW_Action__mdt record for sObjectName, or edits one when action is set. The SObject is
 * fixed in both cases. The record name and label are generated from the SObject and class when the
 * action is created. When editing, only the active setting and description can change.
 *
 * Closes once the deployment starts with { jobId, className, sObjectName }, with { unchanged: true }
 * if an edit changed nothing, or with no result when cancelled.
 */
export default class TwActionModal extends LightningModal {
  /**
   * SObject options from TW_ActionManagerController.sObjectOptions, used to show the SObject's label.
   */
  @api options = [];
  /**
   * The SObject the action runs for.
   */
  @api sObjectName;
  /**
   * The action row to edit, from TW_ActionManagerController.actions. Leave unset to create.
   */
  @api action;

  previewName;
  active = true;
  description = "";
  className = "";
  selectedSObject;
  classOptions = [];
  isLoadingClasses = false;
  isSaving = false;
  error;
  previewRequest = 0;

  connectedCallback() {
    this.selectedSObject = this.sObjectName;
    if (this.isEdit) {
      this.active = this.action.active;
      this.description = this.action.description || "";
      this.className = this.action.apexClass;
      return;
    }
    this.loadClassOptions();
  }

  get isEdit() {
    return !!this.action;
  }

  get heading() {
    return `${this.isEdit ? "Edit" : "New"} ${this.sObjectLabel} Action`;
  }

  get saveLabel() {
    return this.isEdit ? "Save" : "Create";
  }

  get developerName() {
    return this.isEdit ? this.action.developerName : this.previewName;
  }

  get activeMessage() {
    return `Runs in the ${this.sObjectLabel} trigger`;
  }

  get sObjectLabel() {
    const option = (this.options || []).find((o) => o.apiName === this.selectedSObject);
    return option ? option.label : this.selectedSObject;
  }

  get classPlaceholder() {
    return this.isLoadingClasses ? "Loading classes..." : "Search classes...";
  }

  async loadClassOptions() {
    this.isLoadingClasses = true;
    try {
      const names = await getActionClassOptions();
      this.classOptions = names.map((name) => ({ value: name, label: name }));
    } catch (e) {
      this.error = errorMessage(e, "The action classes could not be loaded.");
    } finally {
      this.isLoadingClasses = false;
    }
  }

  // The server generates the name, so the preview comes from the same code that creates the record
  async updatePreviewName() {
    const request = ++this.previewRequest;
    if (!this.className || !this.selectedSObject) {
      this.previewName = undefined;
      return;
    }
    try {
      const name = await getActionName({ className: this.className, sObjectName: this.selectedSObject });
      // Ignore a response for a selection that has since changed
      if (request === this.previewRequest) {
        this.previewName = name;
      }
    } catch (e) {
      this.previewName = undefined;
    }
  }

  handleActiveChange(event) {
    this.active = event.target.checked;
  }

  handleClassNameChange(event) {
    this.className = event.detail.value;
    this.updatePreviewName();
  }

  handleDescriptionChange(event) {
    this.description = event.detail.value;
  }

  handleCancel() {
    this.close();
  }

  async handleSave() {
    const inputs = [...this.template.querySelectorAll("lightning-textarea")];
    const valid = inputs.reduce((allValid, input) => input.reportValidity() && allValid, true);
    if (!valid) {
      return;
    }

    this.error = undefined;
    this.isSaving = true;
    this.disableClose = true;
    try {
      const result = this.isEdit ? await this.update() : await this.create();
      if (result) {
        this.disableClose = false;
        this.close(result);
      }
    } catch (e) {
      this.error = errorMessage(e, "The action could not be saved.");
    } finally {
      this.isSaving = false;
      this.disableClose = false;
    }
  }

  async create() {
    // The lookup's input is inside its own component, so it is checked here
    if (!this.className) {
      this.error = "Select an Apex class.";
      return null;
    }
    const jobId = await createAction({
      className: this.className,
      sObjectName: this.selectedSObject,
      active: this.active,
      description: this.description
    });
    return { jobId, className: this.className, sObjectName: this.selectedSObject };
  }

  async update() {
    const jobId = await updateAction({
      developerName: this.action.developerName,
      active: this.active,
      description: this.description
    });
    return jobId ? { jobId, className: this.className, sObjectName: this.selectedSObject } : { unchanged: true };
  }
}
