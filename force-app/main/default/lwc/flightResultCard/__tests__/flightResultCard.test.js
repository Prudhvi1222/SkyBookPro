import { createElement } from '@lwc/engine-dom';
import FlightResultCard from 'c/flightResultCard';

const ONE_WAY_OFFER = {
    offerId: 'off_1',
    flightId: 'a03000000000001',
    airline: 'IndiGo',
    flightNumber: '6E-202',
    origin: 'HYD',
    destination: 'DEL',
    cabinClass: 'Economy',
    price: 5000,
    currency_x: 'INR',
    tripType: 'oneway',
    numberOfStops: 0,
    seatsAvailable: 4
};

describe('c-flight-result-card', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders one-way offer details without a return leg', () => {
        const element = createElement('c-flight-result-card', {
            is: FlightResultCard
        });
        element.offer = ONE_WAY_OFFER;
        document.body.appendChild(element);

        const route = element.shadowRoot.querySelector('.frc-route');
        expect(route.textContent).toContain('HYD');
        expect(route.textContent).toContain('DEL');

        const legLabels = element.shadowRoot.querySelectorAll('.frc-leg-label');
        expect(legLabels).toHaveLength(0);
    });

    it('dispatches a selectoffer event with the offer detail when Select is clicked', () => {
        const element = createElement('c-flight-result-card', {
            is: FlightResultCard
        });
        element.offer = ONE_WAY_OFFER;
        document.body.appendChild(element);

        const selectHandler = jest.fn();
        element.addEventListener('selectoffer', selectHandler);

        const selectButton = element.shadowRoot.querySelector('.frc-select-btn');
        selectButton.click();

        expect(selectHandler).toHaveBeenCalledTimes(1);
        expect(selectHandler.mock.calls[0][0].detail).toEqual(ONE_WAY_OFFER);
    });
});
