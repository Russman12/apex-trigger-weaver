/**
 * The lightning/modalHeader stub that comes with @salesforce/sfdx-lwc-jest drops slotted content.
 * This one renders it, as the real component does, so tests can check what a modal shows there.
 */
import { LightningElement, api } from "lwc";

export default class ModalHeader extends LightningElement {
  @api label;
}
