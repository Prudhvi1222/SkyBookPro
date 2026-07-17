import { createElement } from '@lwc/engine-dom';
import FlightResultsList from 'c/flightResultsList';

const OFFERS = [
    { offerId: 'off_1', airline: 'IndiGo', price: 6000, durationMinutes: 120 },
    { offerId: 'off_2', airline: 'Air India', price: 4000, durationMinutes: 150 },
    { offerId: 'off_3', airline: 'Vistara', price: 5000, durationMinutes: 90 }
];

describe('c-flight-results-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the empty state when no flight offers are provided', () => {
        const element = createElement('c-flight-results-list', {
            is: FlightResultsList
        });
        element.flightOffers = [];
        document.body.appendChild(element);

        const emptyState = element.shadowRoot.querySelector('.frl-empty-state');
        expect(emptyState).not.toBeNull();

        const cards = element.shadowRoot.querySelectorAll('c-flight-result-card');
        expect(cards).toHaveLength(0);
    });

    it('sorts offers by price ascending by default and renders one card per offer', () => {
        const element = createElement('c-flight-results-list', {
            is: FlightResultsList
        });
        element.flightOffers = OFFERS;
        document.body.appendChild(element);

        const cards = element.shadowRoot.querySelectorAll('c-flight-result-card');
        expect(cards).toHaveLength(3);
        expect(cards[0].offer.offerId).toBe('off_2'); // 4000
        expect(cards[1].offer.offerId).toBe('off_3'); // 5000
        expect(cards[2].offer.offerId).toBe('off_1'); // 6000
    });
});
