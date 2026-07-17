import { createElement } from '@lwc/engine-dom';
import FlightSearchForm from 'c/flightSearchForm';

function findByName(element, tag, name) {
    const candidates = Array.from(element.shadowRoot.querySelectorAll(tag));
    return candidates.find((el) => el.name === name);
}

describe('c-flight-search-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('does not show a Return Date field by default (one-way trip)', () => {
        const element = createElement('c-flight-search-form', {
            is: FlightSearchForm
        });
        document.body.appendChild(element);

        const returnDateInput = findByName(element, 'lightning-input', 'returnDate');
        expect(returnDateInput).toBeUndefined();
    });

    it('reveals the Return Date field when trip type is switched to round-trip', async () => {
        const element = createElement('c-flight-search-form', {
            is: FlightSearchForm
        });
        document.body.appendChild(element);

        const tripTypeRadioGroup = element.shadowRoot.querySelector('.fsf-trip-type');
        tripTypeRadioGroup.value = 'roundtrip';
        tripTypeRadioGroup.dispatchEvent(new CustomEvent('change'));

        await Promise.resolve();

        const returnDateInput = findByName(element, 'lightning-input', 'returnDate');
        expect(returnDateInput).not.toBeUndefined();
    });
});
