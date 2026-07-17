import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import BookingDetailView from 'c/bookingDetailView';
import getBookingDetails from '@salesforce/apex/BookingService.getBookingDetails';
import getBookingSegments from '@salesforce/apex/BookingService.getBookingSegments';

const getBookingDetailsAdapter = registerApexTestWireAdapter(getBookingDetails);
const getBookingSegmentsAdapter = registerApexTestWireAdapter(getBookingSegments);

const MOCK_BOOKING = {
    Id: 'a01000000000001',
    Name: 'BK-0001',
    PNR__c: 'ABC123',
    Booking_Status__c: 'Confirmed',
    Seat_Class__c: 'Economy',
    Number_Of_Seats__c: 1,
    Booking_Date__c: '2026-07-17',
    Base_Fare__c: 4000,
    Taxes_Fees__c: 500,
    Total_Amount__c: 4500,
    Passenger__r: { FirstName: 'Asha', LastName: 'Rao', Email: 'asha@example.com' },
    Flight__r: {
        Name: '6E-202',
        Airline_Name__c: 'IndiGo',
        Origin_Airport__c: 'HYD',
        Destination_Airport__c: 'DEL',
        Departure_DateTime__c: '2026-07-20T09:00:00.000Z',
        Arrival_DateTime__c: '2026-07-20T11:00:00.000Z',
        Amadeus_Offer_ID__c: 'off_1'
    }
};

const MOCK_SEGMENTS = [
    {
        Segment_Order__c: 1,
        Flight_Number__c: '6E-202',
        Carrier_Code__c: '6E',
        Origin__c: 'HYD',
        Destination__c: 'DEL',
        Departure_DateTime__c: '2026-07-20T09:00:00.000Z',
        Arrival_DateTime__c: '2026-07-20T11:00:00.000Z'
    },
    {
        Segment_Order__c: 2,
        Flight_Number__c: '6E-303',
        Carrier_Code__c: '6E',
        Origin__c: 'DEL',
        Destination__c: 'HYD',
        Departure_DateTime__c: '2026-07-25T09:00:00.000Z',
        Arrival_DateTime__c: '2026-07-25T11:00:00.000Z'
    }
];

describe('c-booking-detail-view', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the PNR and booking summary once booking details are returned', async () => {
        const element = createElement('c-booking-detail-view', {
            is: BookingDetailView
        });
        element.bookingId = 'a01000000000001';
        document.body.appendChild(element);

        getBookingDetailsAdapter.emit(MOCK_BOOKING);
        await Promise.resolve();

        const summaryValues = element.shadowRoot.querySelectorAll(
            '.bdv-section-summary .bdv-value'
        );
        // Order in the template: Booking Reference, PNR, Status, Seat Class, ...
        expect(summaryValues[0].textContent).toBe('BK-0001');
        expect(summaryValues[1].textContent).toBe('ABC123');
    });

    it('shows a Return Flight section when two segments (round trip) are returned', async () => {
        const element = createElement('c-booking-detail-view', {
            is: BookingDetailView
        });
        element.bookingId = 'a01000000000001';
        document.body.appendChild(element);

        getBookingDetailsAdapter.emit(MOCK_BOOKING);
        getBookingSegmentsAdapter.emit(MOCK_SEGMENTS);
        await Promise.resolve();

        const flightSections = element.shadowRoot.querySelectorAll(
            '.bdv-section-flight'
        );
        expect(flightSections).toHaveLength(2);

        const sectionTitles = element.shadowRoot.querySelectorAll(
            '.bdv-section-title-light'
        );
        const titleTexts = Array.from(sectionTitles).map((el) =>
            el.textContent.trim()
        );
        expect(titleTexts).toContain('Return Flight');
    });
});
