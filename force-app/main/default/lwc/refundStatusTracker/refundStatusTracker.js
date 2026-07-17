import { LightningElement, api, wire } from 'lwc';
import getRefundStatus from '@salesforce/apex/CancellationService.getRefundStatus';

export default class RefundStatusTracker extends LightningElement {
    @api bookingId;

    refund;
    errorMessage;

    @wire(getRefundStatus, { bookingId: '$bookingId' })
    wiredRefund({ data, error }) {
        if (data) {
            this.refund = data;
            this.errorMessage = undefined;
        } else if (error) {
            this.refund = undefined;
            this.errorMessage = this.reduceError(error);
        }
    }

    get currentStep() {
        return this.refund?.Refund_Status__c || 'Initiated';
    }

    get noRefundFound() {
        return !this.refund && !this.errorMessage;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        if (typeof error?.message === 'string') {
            return error.message;
        }

        return 'Unknown error occurred.';
    }
}