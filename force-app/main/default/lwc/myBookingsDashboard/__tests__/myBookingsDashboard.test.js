import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import MyBookingsDashboard from 'c/myBookingsDashboard';
import getMyBookings from '@salesforce/apex/BookingService.getMyBookings';

const getMyBookingsAdapter = registerApexTestWireAdapter(getMyBookings);

const MOCK_BOOKINGS = [
    {
        Id: 'a01000000000001',
        Name: 'BK-0001',
        Booking_Status__c: 'Confirmed',
        Total_Amount__c: 4500,
        Flight__r: {
            Origin_Airport__c: 'HYD',
            Destination_Airport__c: 'DEL',
            Airline_Name__c: 'IndiGo',
            Departure_DateTime__c: '2099-01-01T09:00:00.000Z'
        }
    },
    {
        Id: 'a01000000000002',
        Name: 'BK-0002',
        Booking_Status__c: 'Cancelled',
        Total_Amount__c: 2200,
        Flight__r: {
            Origin_Airport__c: 'BLR',
            Destination_Airport__c: 'BOM',
            Airline_Name__c: 'Air India',
            Departure_DateTime__c: '2099-02-01T09:00:00.000Z'
        }
    }
];

describe('c-my-bookings-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the total/cancelled stat chips from the wired bookings', async () => {
        const element = createElement('c-my-bookings-dashboard', {
            is: MyBookingsDashboard
        });
        document.body.appendChild(element);

        getMyBookingsAdapter.emit(MOCK_BOOKINGS);
        await Promise.resolve();

        const statChips = element.shadowRoot.querySelectorAll('.mbd-stat-value');
        expect(statChips[0].textContent).toBe('2'); // Total
        expect(statChips[2].textContent).toBe('1'); // Cancelled
    });

    it('filters the datatable down to cancelled bookings when the Cancelled tab is clicked', async () => {
        const element = createElement('c-my-bookings-dashboard', {
            is: MyBookingsDashboard
        });
        document.body.appendChild(element);

        getMyBookingsAdapter.emit(MOCK_BOOKINGS);
        await Promise.resolve();

        const cancelledTab = element.shadowRoot.querySelector('[data-tab="Cancelled"]');
        cancelledTab.click();
        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].Name).toBe('BK-0002');
    });
});
