import { LightningElement, api } from 'lwc';
import uploadProfilePhoto from '@salesforce/apex/ProfilePhotoController.uploadProfilePhoto';
import getProfileImage from '@salesforce/apex/ProfilePhotoController.getProfileImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import defaultImage from '@salesforce/resourceUrl/defaultProfile';

export default class ProfilePhoto extends LightningElement {

    @api recordId;
    imageUrl;
    fileData;
    isEditMode = false;

    get showEditButton() {
        return !this.isEditMode;
    }

    get showUploadSection() {
        return this.isEditMode;
    }

    connectedCallback() {
        this.loadImage();
    }

    loadImage() {
        getProfileImage({ recordId: this.recordId })
            .then(result => this.imageUrl = result || defaultImage);
    }

    handleEdit() {
        this.isEditMode = true;
    }

    handleFileChange(event) {
        const file = event.target.files[0];


        if (file.size > 5 * 1024 * 1024) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Alert',
                    message: 'File size should be less than 5MB.',
                    variant: 'alert'
                })
            );
            return;
        }

        const reader = new FileReader();

        reader.onload = () => {
            this.fileData = {
                fileName: file.name,
                base64: reader.result.split(',')[1]
            };
            this.imageUrl = reader.result;
        };

        reader.readAsDataURL(file);
    }

    uploadPhoto() {

        if (!this.fileData) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Alert',
                    message: 'Please select a file to upload.',
                    variant: 'alert'
                })
            );
            return;
        }


        uploadProfilePhoto({
            recordId: this.recordId,
            fileName: this.fileData.fileName,
            base64Data: this.fileData.base64
        })
            .then(() => {

                // success toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Photo uploaded successfully!',
                        variant: 'success'
                    })
                );

                this.fileData = null;
                this.isEditMode = false;
                this.loadImage();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
    handleCancel() {
        this.fileData = null;
        this.isEditMode = false;
        this.loadImage();
    }
}