import { LightningElement, wire, track } from 'lwc';
import getMyBookings from '@salesforce/apex/BookingService.getMyBookings';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ROW_ACTIONS = [
    /*{ label: 'View Record', name: 'view' },*/
    { label: 'View Details', name: 'details' },
    { label: 'Cancel Booking', name: 'cancel' },
    { label: 'Track Refund', name: 'refund' }
];

const COLUMNS = [
    {
        label: 'Booking Ref',
        fieldName: 'Name',
        type: 'text'
    },
    {
        label: 'PNR',
        fieldName: 'PNR__c',
        type: 'text'
    },
    {
        label: 'Route',
        fieldName: 'route',
        type: 'text'
    },
    {
        label: 'Airline',
        fieldName: 'airline',
        type: 'text'
    },
    {
        label: 'Departure',
        fieldName: 'departureDisplay',
        type: 'text'
    },
    {
        label: 'Status',
        fieldName: 'Booking_Status__c',
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'statusClass' }
        }
    },
    {
        label: 'Seat Class',
        fieldName: 'Seat_Class__c',
        type: 'text'
    },
    {
        label: 'Total Amount',
        fieldName: 'Total_Amount__c',
        type: 'currency'
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: ROW_ACTIONS
        }
    }
];

export default class MyBookingsDashboard extends NavigationMixin(LightningElement) {
    columns = COLUMNS;

    @track bookings = [];
    @track filteredBookings = [];

    wiredBookingsResult;
    isLoading = true;
    activeTab = 'All';

    showCancellationModal = false;
    showRefundTracker = false;
    selectedBooking;
    selectedBookingId;
    showBookingDetail = false;

    @wire(getMyBookings)
    wiredBookings(result) {
        this.wiredBookingsResult = result;
        this.isLoading = false;

        if (result.data) {
            this.bookings = result.data.map((booking) => {
                const origin = booking.Flight__r?.Origin_Airport__c || '';
                const destination = booking.Flight__r?.Destination_Airport__c || '';
                const departure = booking.Flight__r?.Departure_DateTime__c;

                return {
                    ...booking,
                    route: `${origin} → ${destination}`,
                    airline: booking.Flight__r?.Airline_Name__c || '',
                    departureDisplay: this.formatDateTime(departure),
                    rawDeparture: departure,
                    statusClass: this.getStatusClass(booking.Booking_Status__c)
                };
            });

            this.applyFilter();
        } else if (result.error) {
            this.showToast(
                'Error Loading Bookings',
                this.reduceError(result.error),
                'error'
            );
        }
    }

    get hasBookings() {
        return this.bookings && this.bookings.length > 0;
    }

    get totalCount() {
        return this.bookings ? this.bookings.length : 0;
    }

    get upcomingCount() {
        if (!this.bookings) {
            return 0;
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        return this.bookings.filter((booking) => {
            if (!booking.rawDeparture) {
                return false;
            }
            const departureDate = new Date(booking.rawDeparture);
            return departureDate >= today && booking.Booking_Status__c !== 'Cancelled';
        }).length;
    }

    get cancelledCount() {
        if (!this.bookings) {
            return 0;
        }
        return this.bookings.filter(
            (booking) => booking.Booking_Status__c === 'Cancelled'
        ).length;
    }

    get allTabClass() {
        return this.activeTab === 'All' ? 'mbd-pill-tab mbd-pill-tab-active' : 'mbd-pill-tab';
    }

    get upcomingTabClass() {
        return this.activeTab === 'Upcoming' ? 'mbd-pill-tab mbd-pill-tab-active' : 'mbd-pill-tab';
    }

    get pastTabClass() {
        return this.activeTab === 'Past' ? 'mbd-pill-tab mbd-pill-tab-active' : 'mbd-pill-tab';
    }

    get cancelledTabClass() {
        return this.activeTab === 'Cancelled' ? 'mbd-pill-tab mbd-pill-tab-active' : 'mbd-pill-tab';
    }

    handleTabChange(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        this.applyFilter();
    }

    applyFilter() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        if (this.activeTab === 'All') {
            this.filteredBookings = [...this.bookings];
            return;
        }

        if (this.activeTab === 'Cancelled') {
            this.filteredBookings = this.bookings.filter(
                (booking) => booking.Booking_Status__c === 'Cancelled'
            );
            return;
        }

        if (this.activeTab === 'Upcoming') {
            this.filteredBookings = this.bookings.filter((booking) => {
                if (!booking.rawDeparture) {
                    return false;
                }

                const departureDate = new Date(booking.rawDeparture);
                return (
                    departureDate >= today &&
                    booking.Booking_Status__c !== 'Cancelled'
                );
            });
            return;
        }

        if (this.activeTab === 'Past') {
            this.filteredBookings = this.bookings.filter((booking) => {
                if (!booking.rawDeparture) {
                    return false;
                }

                const departureDate = new Date(booking.rawDeparture);
                return departureDate < today;
            });
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        /*if (actionName === 'view') {
            this.navigateToRecord(row.Id);
        }*/
        
        if (actionName === 'details') {
            this.selectedBookingId = row.Id;
            this.showBookingDetail = true;
        }


        if (actionName === 'cancel') {
            if (row.Booking_Status__c === 'Cancelled') {
                this.showToast(
                    'Already Cancelled',
                    'This booking is already cancelled.',
                    'warning'
                );
                return;
            }

            this.selectedBooking = row;
            this.showCancellationModal = true;
        }

        if (actionName === 'refund') {
            this.selectedBookingId = row.Id;
            this.showRefundTracker = true;
        }
    }

    handleCloseBookingDetail() {
        this.showBookingDetail = false;
        this.selectedBookingId = null;
    }

    /*navigateToRecord(recordId) {
        this{
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Booking__c',
                actionName: 'view'
            }
        };
    }*/

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Booking__c',
                actionName: 'view'
            }
        });
    }

    handleCloseCancellationModal() {
        this.showCancellationModal = false;
        this.selectedBooking = null;
    }

    async handleBookingCancelled() {
        this.showCancellationModal = false;
        this.selectedBooking = null;

        this.showToast(
            'Booking Cancelled',
            'Booking cancelled successfully. Refund has been initiated.',
            'success'
        );

        await refreshApex(this.wiredBookingsResult);
    }

    handleCloseRefundTracker() {
        this.showRefundTracker = false;
        this.selectedBookingId = null;
    }

    getStatusClass(status) {
        const normalized = (status || '').toLowerCase();

        if (normalized === 'confirmed') {
            return 'slds-text-color_success slds-text-title_bold';
        }

        if (normalized === 'cancelled') {
            return 'slds-text-color_error slds-text-title_bold';
        }

        if (normalized === 'draft') {
            return 'slds-text-color_warning slds-text-title_bold';
        }

        return 'slds-text-title_bold';
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