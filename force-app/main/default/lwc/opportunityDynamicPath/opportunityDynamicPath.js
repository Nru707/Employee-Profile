import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

export default class OpportunityDynamicPath extends LightningElement {

    @api recordId;

    stages = [];
    currentStage;
    selectedStage;
    recordTypeId;

    /* Get current Opportunity stage */

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD] })
    opportunityHandler({ data, error }) {

        if (data) {
            this.currentStage = data.fields.StageName.value;
            this.selectedStage = this.currentStage;
        } 
        else if (error) {
            console.error('Error fetching Opportunity:', error);
        }

    }

    /* Get Opportunity metadata */

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfoHandler({ data, error }) {

        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } 
        else if (error) {
            console.error('Error fetching object info:', error);
        }

    }

    /* Get Stage picklist values */

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: STAGE_FIELD
    })
    stageValuesHandler({ data, error }) {

        if (data) {
            this.stages = data.values.map(stage => stage.value);
        } 
        else if (error) {
            console.error('Error fetching stage values:', error);
        }

    }

    /* When user selects a stage */

    handleStageSelect(event) {
        this.selectedStage = event.target.value;
    }

    /* Mark Stage as Complete */

    handleMarkComplete() {

        let stageToUpdate = this.selectedStage;

        // if user hasn't changed the stage, get the next stage
        if (this.selectedStage === this.currentStage) {

            const currentIndex = this.stages.indexOf(this.currentStage);
            stageToUpdate = this.stages[currentIndex + 1];

        }

        if (!stageToUpdate) {
            return;
        }

        const fields = {
            Id: this.recordId,
            [STAGE_FIELD.fieldApiName]: stageToUpdate
        };

        updateRecord({ fields })
            .then(() => {

                this.currentStage = stageToUpdate;
                this.selectedStage = stageToUpdate;

            })
            .catch(error => {
                console.error('Error updating stage:', error);
            });

    }

}