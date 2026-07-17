/*import { LightningElement, api } from 'lwc';
import cancelBooking from '@salesforce/apex/CancellationService.cancelBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CancellationModal extends LightningElement {
    @api booking;

    reason = '';
    isProcessing = false;

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleConfirmCancellation() {
        if (!this.reason || !this.reason.trim()) {
            this.showToast(
                'Reason Required',
                'Please enter a cancellation reason.',
                'error'
            );
            return;
        }

        this.isProcessing = true;

        try {
            await cancelBooking({
                bookingId: this.booking.Id,
                reason: this.reason
            });

            this.dispatchEvent(new CustomEvent('cancelled'));
        } catch (error) {
            this.showToast(
                'Cancellation Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isProcessing = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
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
}*/
import { LightningElement, api, wire } from 'lwc';
import cancelBooking from '@salesforce/apex/CancellationService.cancelBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import {
    publish,
    MessageContext
} from 'lightning/messageService';

import SKYBOOK_CHANNEL from '@salesforce/messageChannel/skyBook_Channel__c';

export default class CancellationModal extends LightningElement {
    @api booking;

    reason = '';
    isProcessing = false;

    @wire(MessageContext)
    messageContext;

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleConfirmCancellation() {
        if (!this.reason || !this.reason.trim()) {
            this.showToast(
                'Reason Required',
                'Please enter a cancellation reason.',
                'error'
            );
            return;
        }

        this.isProcessing = true;

        try {
            await cancelBooking({
                bookingId: this.booking.Id,
                reason: this.reason
            });

            publish(this.messageContext, SKYBOOK_CHANNEL, {
                bookingId: this.booking.Id,
                eventType: 'BOOKING_CANCELLED',
                message: 'Booking cancelled successfully.'
            });

            this.dispatchEvent(new CustomEvent('cancelled'));
        } catch (error) {
            this.showToast(
                'Cancellation Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isProcessing = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
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