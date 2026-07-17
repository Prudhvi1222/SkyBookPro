import { createElement } from '@lwc/engine-dom';
import SkyBookApp from 'c/skyBookApp';
import searchFlights from '@salesforce/apex/DuffelFlightSearchService.searchFlights';

jest.mock(
    '@salesforce/apex/DuffelFlightSearchService.searchFlights',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_OFFERS = [
    {
        offerId: 'off_1',
        flightId: 'a03000000000001',
        airline: 'IndiGo',
        origin: 'HYD',
        destination: 'DEL',
        price: 5000,
        currency_x: 'INR',
        tripType: 'oneway'
    }
];

describe('c-sky-book-app', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the search form on initial render (search step)', () => {
        const element = createElement('c-sky-book-app', {
            is: SkyBookApp
        });
        document.body.appendChild(element);

        const searchForm = element.shadowRoot.querySelector('c-flight-search-form');
        expect(searchForm).not.toBeNull();
    });

    it('renders flight results after a successful search, and moves to the selected-flight step on a valid offer', async () => {
        searchFlights.mockResolvedValue(MOCK_OFFERS);

        const element = createElement('c-sky-book-app', {
            is: SkyBookApp
        });
        document.body.appendChild(element);

        const searchForm = element.shadowRoot.querySelector('c-flight-search-form');
        searchForm.dispatchEvent(
            new CustomEvent('flightsearch', {
                detail: {
                    origin: 'HYD',
                    destination: 'DEL',
                    departureDate: '2099-01-01',
                    tripType: 'oneway',
                    cabinClass: 'economy',
                    adults: 1
                }
            })
        );

        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        const resultsList = element.shadowRoot.querySelector('c-flight-results-list');
        expect(resultsList).not.toBeNull();
        expect(resultsList.flightOffers).toHaveLength(1);

        resultsList.dispatchEvent(
            new CustomEvent('offerselected', {
                detail: MOCK_OFFERS[0]
            })
        );
        await Promise.resolve();

        const searchFormAfterSelection = element.shadowRoot.querySelector(
            'c-flight-search-form'
        );
        expect(searchFormAfterSelection).toBeNull();

        const priceText = element.shadowRoot.querySelector('.skybook-price');
        expect(priceText.textContent).toContain('5000');
    });
});
