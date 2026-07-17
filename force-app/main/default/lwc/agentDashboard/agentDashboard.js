import { LightningElement, wire, track } from 'lwc';
import getMyBookings from '@salesforce/apex/BookingService.getMyBookings';
import { refreshApex } from '@salesforce/apex';

import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';

import SKYBOOK_CHANNEL from '@salesforce/messageChannel/skyBook_Channel__c';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
        label: 'Booking Ref',
        fieldName: 'Name',
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
        label: 'Status',
        fieldName: 'Booking_Status__c',
        type: 'text'
    },
    {
        label: 'Amount',
        fieldName: 'Total_Amount__c',
        type: 'currency'
    },
    {
        label: 'Departure',
        fieldName: 'departureDisplay',
        type: 'text'
    }
];

export default class AgentDashboard extends LightningElement {
    columns = COLUMNS;

    @track bookings = [];
    @track recentBookings = [];

    wiredBookingsResult;
    subscription = null;
    isLoading = true;
    lastMessage;

    @wire(MessageContext)
    messageContext;

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
                    rawDeparture: departure
                };
            });

            this.recentBookings = this.bookings.slice(0, 10);
        } else if (result.error) {
            this.showToast(
                'Dashboard Load Failed',
                this.reduceError(result.error),
                'error'
            );
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannel();
    }

    subscribeToMessageChannel() {
        if (this.subscription) {
            return;
        }

        this.subscription = subscribe(
            this.messageContext,
            SKYBOOK_CHANNEL,
            (message) => this.handleSkyBookMessage(message),
            {
                scope: APPLICATION_SCOPE
            }
        );
    }

    unsubscribeFromMessageChannel() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    async handleSkyBookMessage(message) {
        if (!message) {
            return;
        }

        if (message.eventType === 'BOOKING_CANCELLED') {
            this.lastMessage =
                `Cancellation event received for Booking Id: ${message.bookingId}`;

            await refreshApex(this.wiredBookingsResult);

            this.showToast(
                'Dashboard Refreshed',
                'Booking cancellation received. Agent dashboard refreshed.',
                'success'
            );
        }
    }

    get hasRecentBookings() {
        return this.recentBookings && this.recentBookings.length > 0;
    }

    get todaysBookingsCount() {
        return this.bookings.filter((booking) => {
            return this.isToday(booking.Booking_Date__c);
        }).length;
    }

    get todaysRevenue() {
        const total = this.bookings.reduce((sum, booking) => {
            if (this.isToday(booking.Booking_Date__c)) {
                return sum + Number(booking.Total_Amount__c || 0);
            }

            return sum;
        }, 0);

        return total.toFixed(2);
    }

    get confirmedCount() {
        return this.bookings.filter(
            (booking) => booking.Booking_Status__c === 'Confirmed'
        ).length;
    }

    get cancelledCount() {
        return this.bookings.filter(
            (booking) => booking.Booking_Status__c === 'Cancelled'
        ).length;
    }

    async handleManualRefresh() {
        this.isLoading = true;

        try {
            await refreshApex(this.wiredBookingsResult);
            this.showToast(
                'Refreshed',
                'Agent dashboard refreshed successfully.',
                'success'
            );
        } catch (error) {
            this.showToast(
                'Refresh Failed',
                this.reduceError(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleSearchNewFlight() {
        this.showToast(
            'Search New Flight',
            'Open the SkyBook Pro App component to search and create a booking.',
            'info'
        );
    }

    isToday(dateValue) {
        if (!dateValue) {
            return false;
        }

        const inputDate = new Date(dateValue);
        const today = new Date();

        return (
            inputDate.getFullYear() === today.getFullYear() &&
            inputDate.getMonth() === today.getMonth() &&
            inputDate.getDate() === today.getDate()
        );
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