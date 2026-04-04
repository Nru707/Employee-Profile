import { LightningElement } from 'lwc';

export default class EmployeeProfile extends LightningElement {
     tabContent = "";

  handleActive(event) {
    const tab = event.target;
    this.tabContent = `Tab ${event.target.value} is now active`;
  }
}