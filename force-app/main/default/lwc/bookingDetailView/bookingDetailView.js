import { LightningElement, api, wire } from 'lwc';
import getBookingDetails from '@salesforce/apex/BookingService.getBookingDetails';
import getBookingSegments from '@salesforce/apex/BookingService.getBookingSegments';

export default class BookingDetailView extends LightningElement {
    @api bookingId;

    booking;
    segments;
    errorMessage;
    isLoading = true;

    @wire(getBookingDetails, { bookingId: '$bookingId' })
    wiredBooking({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.booking = data;
            this.errorMessage = undefined;
        } else if (error) {
            this.booking = undefined;
            this.errorMessage = this.reduceError(error);
        }
    }

    @wire(getBookingSegments, { bookingId: '$bookingId' })
    wiredSegments({ data, error }) {
        if (data) {
            // Segment_Order__c 1 = outbound, 2 = return (round-trip only).
            this.segments = data.map((segment) => ({
                ...segment,
                isReturn: segment.Segment_Order__c === 2,
                departureDisplay: this.formatDateTime(segment.Departure_DateTime__c),
                arrivalDisplay: this.formatDateTime(segment.Arrival_DateTime__c)
            }));
        } else if (error) {
            this.segments = undefined;
        }
    }

    get isRoundTrip() {
        return (this.segments || []).length > 1;
    }

    get outboundSegment() {
        return (this.segments || []).find((segment) => !segment.isReturn);
    }

    get returnSegment() {
        return (this.segments || []).find((segment) => segment.isReturn);
    }

    get flightSectionTitle() {
        return this.isRoundTrip ? 'Outbound Flight' : 'Flight Information';
    }

    get departureDisplay() {
        return this.formatDateTime(this.booking?.Flight__r?.Departure_DateTime__c);
    }

    get arrivalDisplay() {
        return this.formatDateTime(this.booking?.Flight__r?.Arrival_DateTime__c);
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    formatDateTime(value) {
        if (!value) {
            return '';
        }

        try {
            return new Intl.DateTimeFormat('en-IN', {
                dateStyle: 'medium',
                timeStyle: 'short'
            }).format(new Date(value));
        } catch (error) {
            return value;
        }
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