import { createElement } from '@lwc/engine-dom';
import CustomDatatable from 'c/customDatatable';

describe('c-custom-datatable', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('registers a statusBadge custom type with the expected type attributes', () => {
        expect(CustomDatatable.customTypes).toBeDefined();
        expect(CustomDatatable.customTypes.statusBadge).toBeDefined();
        expect(CustomDatatable.customTypes.statusBadge.typeAttributes).toEqual([
            'status',
            'badgeClass'
        ]);
        expect(CustomDatatable.customTypes.statusBadge.standardCellLayout).toBe(true);
    });

    it('can be created and appended without throwing', () => {
        const element = createElement('c-custom-datatable', {
            is: CustomDatatable
        });

        expect(() => document.body.appendChild(element)).not.toThrow();
        expect(element).toBeTruthy();
    });
});
