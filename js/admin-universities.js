(() => {
    'use strict';

    const codeInput = document.querySelector('[data-university-code]');
    const domainInput = document.querySelector('[data-academic-domain]');
    let lastSuggestion = '';

    function expectedDomain() {
        const label = (codeInput?.value || '').trim().toLowerCase().replace(/_/g, '-');
        return label ? `${label}.ac.bd` : '';
    }

    function validateDomain() {
        if (!domainInput) return;
        const expected = expectedDomain();
        const value = domainInput.value.trim().toLowerCase();
        domainInput.setCustomValidity(
            expected && value !== expected
                ? `Academic domain must be ${expected}.`
                : ''
        );
    }

    codeInput?.addEventListener('input', () => {
        if (!domainInput) return;
        const suggestion = expectedDomain();
        if (!domainInput.value.trim() || domainInput.value.trim().toLowerCase() === lastSuggestion) {
            domainInput.value = suggestion;
        }
        lastSuggestion = suggestion;
        validateDomain();
    });

    domainInput?.addEventListener('input', () => {
        domainInput.value = domainInput.value.toLowerCase();
        validateDomain();
    });

    lastSuggestion = expectedDomain();
    if (domainInput && !domainInput.value.trim() && lastSuggestion) domainInput.value = lastSuggestion;
    validateDomain();

    document.querySelectorAll('[data-delete-university]').forEach((form) => {
        form.addEventListener('submit', (event) => {
            event.preventDefault();
            const code = form.dataset.universityCode || '';
            const name = form.dataset.universityName || '';
            const typed = window.prompt(
                `Permanent deletion cannot be undone. Type ${code} or the full university name to continue.`
            );
            if (typed === null) return;

            const normalized = typed.trim().toLowerCase();
            if (normalized !== code.trim().toLowerCase() && normalized !== name.trim().toLowerCase()) {
                window.alert('The confirmation did not match the university code or full name.');
                return;
            }
            if (!window.confirm(`Permanently delete ${name} and all of its university-owned data?`)) return;

            const confirmation = form.querySelector('input[name="delete_confirmation"]');
            if (confirmation) confirmation.value = typed.trim();
            form.submit();
        });
    });
})();
