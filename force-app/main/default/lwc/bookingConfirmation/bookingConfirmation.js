import { LightningElement, api } from 'lwc';
import createBooking from '@salesforce/apex/BookingService.createBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BookingConfirmation extends LightningElement {
    @api selectedOffer;
    @api passengers = [];
    @api passengerCount = 1;
    @api contactId;

    termsAccepted = false;
    isSubmitting = false;

    get totalAmount() {
        const price = Number(this.selectedOffer?.price || 0);
        const count = Number(this.passengerCount || 1);
        return price * count;
    }

    get isRoundTrip() {
        return this.selectedOffer?.tripType === 'roundtrip';
    }

    get outboundSummaryTitle() {
        return this.isRoundTrip ? 'Outbound flight summary' : 'Flight summary';
    }

    get disableConfirmButton() {
        return !this.termsAccepted || this.isSubmitting;
    }

    handleTermsChange(event) {
        this.termsAccepted = event.target.checked;
    }

    async handleConfirmBooking() {
        if (!this.contactId) {
            this.showToast(
                'Contact Required',
                'Passenger contact details are missing. Please go back and complete the passenger form.',
                'error'
            );
            return;
        }

        if (!this.selectedOffer?.flightId) {
            this.showToast(
                'Flight Missing',
                'Selected flight does not have a valid Flight Id.',
                'error'
            );
            return;
        }

        this.isSubmitting = true;

        try {
            const booking = await createBooking({
                contactId: this.contactId,
                flightId: this.selectedOffer.flightId,
                offerId: this.selectedOffer.offerId,
                seats: Number(this.passengerCount),
                seatClass: this.selectedOffer.cabinClass || 'Economy',
                price: Number(this.selectedOffer.price),
                passengersJson: JSON.stringify(this.passengers),
                returnFlightId: this.isRoundTrip
                    ? this.selectedOffer.returnFlightId
                    : null
            });

            this.showToast(
                'Booking Created',
                `Booking ${booking.Name} created successfully.`,
                'success'
            );

            this.dispatchEvent(
                new CustomEvent('bookingcreated', {
                    detail: {
                        booking
                    }
                })
            );
        } catch (error) {
            this.showToast(
                'Booking Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isSubmitting = false;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
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