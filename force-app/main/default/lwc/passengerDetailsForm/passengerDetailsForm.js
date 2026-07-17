import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PassengerDetailsForm extends LightningElement {
    @api passengerCount = 1;
    @track passengers = [];

    connectedCallback() {
        this.initializePassengers();
    }

    initializePassengers() {
        const count = Number(this.passengerCount || 1);

        this.passengers = Array.from({ length: count }, (_, index) => {
            return {
                key: `passenger-${index}`,
                displayNumber: index + 1,
                isPrimary: index === 0,
                firstName: '',
                lastName: '',
                dateOfBirth: '',
                passengerType: 'Adult',
                passportNumber: '',
                mealPreference: '',
                email: '',
                phone: ''
            };
        });
    }

    get passengerTypeOptions() {
        return [
            { label: 'Adult', value: 'Adult' },
            { label: 'Child', value: 'Child' },
            { label: 'Infant', value: 'Infant' }
        ];
    }

    get mealOptions() {
        return [
            { label: 'Vegetarian', value: 'Vegetarian' },
            { label: 'Non-Veg', value: 'Non-Veg' },
            { label: 'Vegan', value: 'Vegan' },
            { label: 'Jain', value: 'Jain' }
        ];
    }

    /*handleInputChange(event) {
        const index = Number(event.target.dataset.index);
        const fieldName = event.target.name;
        const value = event.detail.value || event.target.value;

        this.passengers = this.passengers.map((passenger, passengerIndex) => {
            if (passengerIndex === index) {
                return {
                    ...passenger,
                    value
                };
            }

            return passenger;
        });
    }*/
    handleInputChange(event) {
        const index = Number(event.target.dataset.index);
        const fieldName = event.target.name;
        const fieldValue = event.detail.value || event.target.value;

        this.passengers = this.passengers.map((passenger, passengerIndex) => {
            if (passengerIndex === index) {
                const updatedPassenger = { ...passenger };
                updatedPassenger[fieldName] = fieldValue;
                return updatedPassenger;
            }

            return passenger;
        });

        console.log('Updated passengers:', JSON.stringify(this.passengers));
    }

    handleContinue() {
        if (!this.validateAllPassengers()) {
            return;
        }

        this.dispatchEvent(
            new CustomEvent('passengersready', {
                detail: {
                    passengers: this.passengers.map((p) => {
                        return {
                            firstName: p.firstName,
                            lastName: p.lastName,
                            dateOfBirth: p.dateOfBirth,
                            passengerType: p.passengerType,
                            passportNumber: p.passportNumber,
                            mealPreference: p.mealPreference,
                            email: p.email,
                            phone: p.phone
                        };
                    })
                }
            })
        );
    }

    validateAllPassengers() {
        const inputs = [
            ...this.template.querySelectorAll(
                'lightning-input, lightning-combobox'
            )
        ];

        const allValid = inputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.showToast(
                'Validation Error',
                'Please complete all required passenger fields.',
                'error'
            );
            return false;
        }

        return true;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}