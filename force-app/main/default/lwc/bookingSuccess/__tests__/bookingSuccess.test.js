import { createElement } from '@lwc/engine-dom';
import BookingSuccess from 'c/bookingSuccess';

const mockNavigate = jest.fn();

jest.mock('lightning/navigation', () => {
    const Navigate = Symbol('Navigate');
    const NavigationMixin = (Base) =>
        class extends Base {
            [Navigate](pageReference) {
                mockNavigate(pageReference);
            }
        };
    NavigationMixin.Navigate = Navigate;
    return { NavigationMixin };
});

describe('c-booking-success', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('falls back to the booking Name when PNR__c is missing, and disables the view button without a booking', () => {
        const element = createElement('c-booking-success', {
            is: BookingSuccess
        });
        element.booking = { Name: 'BK-0007' };
        element.selectedOffer = { origin: 'HYD', destination: 'DEL', tripType: 'oneway' };
        document.body.appendChild(element);

        const pnrValue = element.shadowRoot.querySelector('.bs-pnr-value');
        expect(pnrValue.textContent).toBe('BK-0007');

        const viewButton = element.shadowRoot.querySelector('.bs-btn-view');
        expect(viewButton.disabled).toBe(true);
    });

    it('navigates to the My Bookings Dashboard tab when "Go to Dashboard" is clicked', () => {
        const element = createElement('c-booking-success', {
            is: BookingSuccess
        });
        element.booking = { Id: 'a01000000000001', Name: 'BK-0007', PNR__c: 'XYZ987' };
        element.selectedOffer = { origin: 'HYD', destination: 'DEL', tripType: 'oneway' };
        document.body.appendChild(element);

        const dashboardButton = element.shadowRoot.querySelector('.bs-btn-dashboard');
        dashboardButton.click();

        expect(mockNavigate).toHaveBeenCalledTimes(1);
        const pageReference = mockNavigate.mock.calls[0][0];
        expect(pageReference.type).toBe('standard__navItemPage');
        expect(pageReference.attributes.apiName).toBe('My_Bookings_Dashboard');
    });
});
