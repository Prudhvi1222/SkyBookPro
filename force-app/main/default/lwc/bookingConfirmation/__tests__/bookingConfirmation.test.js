import { createElement } from '@lwc/engine-dom';
import BookingConfirmation from 'c/bookingConfirmation';

const SELECTED_OFFER = {
    flightId: 'a03000000000001',
    offerId: 'off_1',
    airline: 'IndiGo',
    flightNumber: '6E-202',
    origin: 'HYD',
    destination: 'DEL',
    cabinClass: 'Economy',
    price: 5000,
    currency_x: 'INR',
    tripType: 'oneway'
};

describe('c-booking-confirmation', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('computes the total amount from price and passenger count', () => {
        const element = createElement('c-booking-confirmation', {
            is: BookingConfirmation
        });
        element.selectedOffer = SELECTED_OFFER;
        element.passengerCount = 2;
        element.passengers = [];
        element.contactId = '003000000000001';
        document.body.appendChild(element);

        const totalValue = element.shadowRoot.querySelector('.bc-total-value');
        expect(totalValue.textContent).toContain('10000');
    });

    it('keeps the confirm button disabled until the terms checkbox is accepted', async () => {
        const element = createElement('c-booking-confirmation', {
            is: BookingConfirmation
        });
        element.selectedOffer = SELECTED_OFFER;
        element.passengerCount = 1;
        element.passengers = [];
        element.contactId = '003000000000001';
        document.body.appendChild(element);

        const confirmButton = element.shadowRoot.querySelector('.bc-btn-confirm');
        expect(confirmButton.disabled).toBe(true);

        const termsCheckbox = element.shadowRoot.querySelector(
            '.bc-terms-box lightning-input'
        );
        termsCheckbox.checked = true;
        termsCheckbox.dispatchEvent(new CustomEvent('change'));

        await Promise.resolve();

        expect(confirmButton.disabled).toBe(false);
    });
});
