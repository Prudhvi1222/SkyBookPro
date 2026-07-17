import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// API name of the "My Bookings Dashboard" tab.
// Verify this matches the Tab's Developer Name under Setup -> Tabs
// if the "Go to Dashboard" button doesn't navigate correctly.
const MY_BOOKINGS_TAB_API_NAME = 'My_Bookings_Dashboard';

export default class BookingSuccess extends NavigationMixin(LightningElement) {
    @api booking;
    @api selectedOffer;

    // A unique 6-character PNR is generated server-side at booking
    // creation (Booking__c.PNR__c). Fall back to the booking's
    // auto-number Name if it's ever missing (e.g. older records).
    get pnr() {
        return this.booking?.PNR__c || this.booking?.Name || '-';
    }

    get hasBooking() {
        return !!this.booking?.Id;
    }

    get hasNoBooking() {
        return !this.hasBooking;
    }

    get isRoundTrip() {
        return this.selectedOffer?.tripType === 'roundtrip';
    }

    handleSearchAgain() {
        this.dispatchEvent(new CustomEvent('searchagain'));
    }

    handleViewBooking() {
        if (!this.hasBooking) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.booking.Id,
                objectApiName: 'Booking__c',
                actionName: 'view'
            }
        });
    }

    handleGoToDashboard() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: MY_BOOKINGS_TAB_API_NAME
            }
        });
    }
}