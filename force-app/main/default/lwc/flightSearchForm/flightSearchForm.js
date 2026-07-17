import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAirports from '@salesforce/apex/AirportSearchService.searchAirports';

const DEBOUNCE_MS = 300;

export default class FlightSearchForm extends LightningElement {
    @api initialOrigin;
    @api initialDestination;

    origin = '';
    destination = '';
    departureDate;
    returnDate;
    cabinClass = 'economy';
    adults = 1;
    tripType = 'oneway';

    @track originQuery = '';
    @track destinationQuery = '';
    @track originSuggestions = [];
    @track destinationSuggestions = [];
    showOriginSuggestions = false;
    showDestinationSuggestions = false;
    originSearchLoading = false;
    destinationSearchLoading = false;

    originDebounceHandle;
    destinationDebounceHandle;

    connectedCallback() {
        if (this.initialOrigin) {
            this.origin = this.initialOrigin;
            this.originQuery = this.initialOrigin;
        }

        if (this.initialDestination) {
            this.destination = this.initialDestination;
            this.destinationQuery = this.initialDestination;
        }
    }

    get isRoundTrip() {
        return this.tripType === 'roundtrip';
    }

    get cabinOptions() {
        return [
            { label: 'Economy', value: 'economy' },
            { label: 'Business', value: 'business' },
            { label: 'First', value: 'first' }
        ];
    }

    get tripTypeOptions() {
        return [
            { label: 'One-Way', value: 'oneway' },
            { label: 'Round-Trip', value: 'roundtrip' }
        ];
    }

    handleInputChange(event) {
        const { name, value } = event.target;

        if (name === 'adults') {
            this.adults = Number(value);
        } else {
            this[name] = value;
        }
    }

    // ---- Origin/destination airport autocomplete ----
    // Live lookup against Duffel's Places API (via AirportSearchService)
    // instead of a bundled ~100-airport static list, so typing any city,
    // airport name, or IATA code world-wide returns real matches instead
    // of only the handful of airports that happened to be hardcoded.
    // Debounced so we don't fire a server call on every keystroke.
    handleOriginInput(event) {
        this.originQuery = event.target.value;
        this.origin = this.originQuery ? this.originQuery.toUpperCase() : '';

        window.clearTimeout(this.originDebounceHandle);
        this.originDebounceHandle = window.setTimeout(() => {
            this.runAirportSearch(this.originQuery, 'origin');
        }, DEBOUNCE_MS);
    }

    handleDestinationInput(event) {
        this.destinationQuery = event.target.value;
        this.destination = this.destinationQuery ? this.destinationQuery.toUpperCase() : '';

        window.clearTimeout(this.destinationDebounceHandle);
        this.destinationDebounceHandle = window.setTimeout(() => {
            this.runAirportSearch(this.destinationQuery, 'destination');
        }, DEBOUNCE_MS);
    }

    async runAirportSearch(query, field) {
        const normalized = (query || '').trim();

        if (normalized.length < 2) {
            if (field === 'origin') {
                this.originSuggestions = [];
                this.showOriginSuggestions = false;
            } else {
                this.destinationSuggestions = [];
                this.showDestinationSuggestions = false;
            }
            return;
        }

        if (field === 'origin') {
            this.originSearchLoading = true;
        } else {
            this.destinationSearchLoading = true;
        }

        try {
            const results = await searchAirports({ query: normalized });

            // Guard against the field's text changing again while this
            // request was in flight (e.g. user kept typing) - only apply
            // results if the query is still what triggered this call.
            const currentQuery =
                field === 'origin' ? this.originQuery : this.destinationQuery;

            if ((currentQuery || '').trim() !== normalized) {
                return;
            }

            if (field === 'origin') {
                this.originSuggestions = results || [];
                this.showOriginSuggestions = this.originSuggestions.length > 0;
            } else {
                this.destinationSuggestions = results || [];
                this.showDestinationSuggestions = this.destinationSuggestions.length > 0;
            }
        } catch (error) {
            if (field === 'origin') {
                this.originSuggestions = [];
                this.showOriginSuggestions = false;
            } else {
                this.destinationSuggestions = [];
                this.showDestinationSuggestions = false;
            }
        } finally {
            if (field === 'origin') {
                this.originSearchLoading = false;
            } else {
                this.destinationSearchLoading = false;
            }
        }
    }

    handleSelectOrigin(event) {
        const code = event.currentTarget.dataset.code;
        const airport = this.originSuggestions.find((a) => a.code === code);

        this.origin = code;
        this.originQuery = airport ? `${airport.code} — ${airport.city}` : code;
        this.showOriginSuggestions = false;
    }

    handleSelectDestination(event) {
        const code = event.currentTarget.dataset.code;
        const airport = this.destinationSuggestions.find((a) => a.code === code);

        this.destination = code;
        this.destinationQuery = airport ? `${airport.code} — ${airport.city}` : code;
        this.showDestinationSuggestions = false;
    }

    // Delay hiding on blur so a click on a suggestion registers first.
    handleOriginBlur() {
        setTimeout(() => {
            this.showOriginSuggestions = false;
        }, 150);
    }

    handleDestinationBlur() {
        setTimeout(() => {
            this.showDestinationSuggestions = false;
        }, 150);
    }

    handleSearch() {
        if (!this.validateForm()) {
            return;
        }

        this.dispatchEvent(
            new CustomEvent('flightsearch', {
                detail: {
                    origin: this.origin,
                    destination: this.destination,
                    departureDate: this.departureDate,
                    returnDate: this.returnDate,
                    cabinClass: this.cabinClass,
                    adults: this.adults,
                    tripType: this.tripType
                }
            })
        );
    }

    validateForm() {
        if (!this.origin || this.origin.length !== 3) {
            this.showToast(
                'Invalid Origin',
                'Please select a valid origin airport from the suggestions.',
                'error'
            );
            return false;
        }

        if (!this.destination || this.destination.length !== 3) {
            this.showToast(
                'Invalid Destination',
                'Please select a valid destination airport from the suggestions.',
                'error'
            );
            return false;
        }

        const allInputs = [
            ...this.template.querySelectorAll(
                'lightning-input, lightning-combobox, lightning-radio-group'
            )
        ];

        const allValid = allInputs.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.showToast(
                'Validation Error',
                'Please complete all required fields.',
                'error'
            );
            return false;
        }

        if (this.origin === this.destination) {
            this.showToast(
                'Invalid Route',
                'Origin and destination cannot be the same.',
                'error'
            );
            return false;
        }

        if (!this.isFutureDate(this.departureDate)) {
            this.showToast(
                'Invalid Date',
                'Departure date must be a future date.',
                'error'
            );
            return false;
        }

        if (this.isRoundTrip && this.returnDate && this.returnDate < this.departureDate) {
            this.showToast(
                'Invalid Return Date',
                'Return date cannot be before departure date.',
                'error'
            );
            return false;
        }

        if (!this.adults || this.adults < 1) {
            this.showToast(
                'Invalid Passenger Count',
                'At least one adult passenger is required.',
                'error'
            );
            return false;
        }

        return true;
    }

    isFutureDate(dateValue) {
        if (!dateValue) {
            return false;
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const selectedDate = new Date(dateValue);
        selectedDate.setHours(0, 0, 0, 0);

        return selectedDate > today;
    }

    handleReset() {
        this.origin = '';
        this.destination = '';
        this.originQuery = '';
        this.destinationQuery = '';
        this.originSuggestions = [];
        this.destinationSuggestions = [];
        this.showOriginSuggestions = false;
        this.showDestinationSuggestions = false;
        this.departureDate = null;
        this.returnDate = null;
        this.cabinClass = 'economy';
        this.adults = 1;
        this.tripType = 'oneway';
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