(() => {
    'use strict';

    document.querySelectorAll('[data-delete-administrator]').forEach((form) => {
        form.addEventListener('submit', (event) => {
            event.preventDefault();
            const name = form.dataset.administratorName || 'this administrator';
            const email = form.dataset.administratorEmail || '';
            const typed = window.prompt(
                `Permanent deletion cannot be undone. Type ${email} to delete ${name}.`
            );
            if (typed === null) return;

            if (typed.trim().toLowerCase() !== email.trim().toLowerCase()) {
                window.alert('The confirmation did not match the administrator email address.');
                return;
            }
            if (!window.confirm(`Permanently delete the University Administrator account for ${name}?`)) return;

            const confirmation = form.querySelector('input[name="delete_confirmation"]');
            if (confirmation) confirmation.value = typed.trim();
            form.submit();
        });
    });
})();
