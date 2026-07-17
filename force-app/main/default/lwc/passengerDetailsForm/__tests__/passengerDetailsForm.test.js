import { createElement } from '@lwc/engine-dom';
import PassengerDetailsForm from 'c/passengerDetailsForm';

function findAllByName(element, tag, name) {
    const candidates = Array.from(element.shadowRoot.querySelectorAll(tag));
    return candidates.filter((el) => el.name === name);
}

describe('c-passenger-details-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders one passenger card per passengerCount', () => {
        const element = createElement('c-passenger-details-form', {
            is: PassengerDetailsForm
        });
        element.passengerCount = 3;
        document.body.appendChild(element);

        const cards = element.shadowRoot.querySelectorAll('.pdf-passenger-card');
        expect(cards).toHaveLength(3);
    });

    it('updates the matching passenger when a first name field changes', () => {
        const element = createElement('c-passenger-details-form', {
            is: PassengerDetailsForm
        });
        element.passengerCount = 2;
        document.body.appendChild(element);

        const firstNameInputs = findAllByName(element, 'lightning-input', 'firstName');
        expect(firstNameInputs).toHaveLength(2);

        const secondPassengerFirstName = firstNameInputs[1];
        secondPassengerFirstName.value = 'Priya';
        secondPassengerFirstName.dispatchEvent(
            new CustomEvent('change', { detail: { value: 'Priya' } })
        );

        expect(secondPassengerFirstName.value).toBe('Priya');
        // The first passenger's field should be unaffected.
        expect(firstNameInputs[0].value).toBe('');
    });
});
