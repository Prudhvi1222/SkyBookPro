import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import AgentDashboard from 'c/agentDashboard';
import getMyBookings from '@salesforce/apex/BookingService.getMyBookings';

const getMyBookingsAdapter = registerApexTestWireAdapter(getMyBookings);

const MOCK_BOOKINGS = [
    {
        Id: 'a01000000000001',
        Name: 'BK-0001',
        Booking_Status__c: 'Confirmed',
        Total_Amount__c: 450.0,
        Booking_Date__c: '2026-07-17',
        Flight__r: {
            Origin_Airport__c: 'HYD',
            Destination_Airport__c: 'DEL',
            Airline_Name__c: 'IndiGo',
            Departure_DateTime__c: '2026-07-20T09:00:00.000Z'
        }
    },
    {
        Id: 'a01000000000002',
        Name: 'BK-0002',
        Booking_Status__c: 'Cancelled',
        Total_Amount__c: 220.0,
        Booking_Date__c: '2026-07-10',
        Flight__r: {
            Origin_Airport__c: 'BLR',
            Destination_Airport__c: 'BOM',
            Airline_Name__c: 'Air India',
            Departure_DateTime__c: '2026-07-25T09:00:00.000Z'
        }
    }
];

describe('c-agent-dashboard', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the empty state and zeroed stat tiles when there are no bookings', async () => {
        const element = createElement('c-agent-dashboard', {
            is: AgentDashboard
        });
        document.body.appendChild(element);

        getMyBookingsAdapter.emit([]);
        await Promise.resolve();

        const statValues = element.shadowRoot.querySelectorAll('.ad-stat-value');
        expect(statValues).toHaveLength(4);
        statValues.forEach((statValue) => {
            expect(['0', '0.00']).toContain(statValue.textContent);
        });

        const emptyState = element.shadowRoot.querySelector('.ad-empty-state');
        expect(emptyState).not.toBeNull();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();
    });

    it('renders confirmed/cancelled counts and the recent bookings table when data is returned', async () => {
        const element = createElement('c-agent-dashboard', {
            is: AgentDashboard
        });
        document.body.appendChild(element);

        getMyBookingsAdapter.emit(MOCK_BOOKINGS);
        await Promise.resolve();

        const confirmedTile = element.shadowRoot.querySelector('.ad-stat-purple .ad-stat-value');
        const cancelledTile = element.shadowRoot.querySelector('.ad-stat-amber .ad-stat-value');
        expect(confirmedTile.textContent).toBe('1');
        expect(cancelledTile.textContent).toBe('1');

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(2);

        const emptyState = element.shadowRoot.querySelector('.ad-empty-state');
        expect(emptyState).toBeNull();
    });
});