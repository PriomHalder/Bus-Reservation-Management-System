(() => {
    'use strict';

    const MOBILE_BREAKPOINT = 920;

    function initializeSidebar(sidebar) {
        const sidebarId = sidebar.id;
        if (!sidebarId) return;

        const toggle = [...document.querySelectorAll('[data-sidebar-toggle]')]
            .find((button) => button.getAttribute('aria-controls') === sidebarId);
        const shell = sidebar.parentElement;
        const scrim = shell?.querySelector('[data-sidebar-scrim]');

        if (!toggle || !scrim) return;

        let restoreFocus = null;

        function isMobile() {
            return window.innerWidth <= MOBILE_BREAKPOINT;
        }

        function setSidebar(open, options = {}) {
            const shouldOpen = Boolean(open && isMobile());

            sidebar.classList.toggle('is-open', shouldOpen);
            scrim.classList.toggle('is-visible', shouldOpen);
            toggle.classList.toggle('is-active', shouldOpen);
            toggle.setAttribute('aria-expanded', shouldOpen ? 'true' : 'false');
            scrim.setAttribute('aria-hidden', shouldOpen ? 'false' : 'true');
            document.body.classList.toggle('sidebar-open', shouldOpen);

            if (isMobile()) {
                sidebar.setAttribute('aria-hidden', shouldOpen ? 'false' : 'true');
                sidebar.inert = !shouldOpen;
            } else {
                sidebar.removeAttribute('aria-hidden');
                sidebar.inert = false;
            }

            if (shouldOpen) {
                restoreFocus = document.activeElement;
                sidebar.querySelector('a[aria-current="page"], a')?.focus({preventScroll: true});
            } else if (options.restoreFocus && restoreFocus instanceof HTMLElement) {
                restoreFocus.focus({preventScroll: true});
            }
        }

        toggle.addEventListener('click', () => {
            setSidebar(!sidebar.classList.contains('is-open'), {restoreFocus: true});
        });

        scrim.addEventListener('click', () => {
            setSidebar(false, {restoreFocus: true});
        });

        sidebar.addEventListener('click', (event) => {
            if (event.target.closest('a') && isMobile()) {
                setSidebar(false);
            }
        });

        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape' && sidebar.classList.contains('is-open')) {
                setSidebar(false, {restoreFocus: true});
            }
        });

        window.addEventListener('resize', () => setSidebar(false), {passive: true});

        setSidebar(false);
    }

    document.querySelectorAll('[data-dashboard-sidebar]').forEach(initializeSidebar);

    const customDateToggle = document.querySelector('[data-custom-date-toggle]');
    const customDateForm = document.querySelector('[data-custom-date-form]');

    customDateToggle?.addEventListener('click', () => {
        const visible = customDateForm?.classList.toggle('is-visible') ?? false;
        customDateToggle.setAttribute('aria-expanded', visible ? 'true' : 'false');
        if (visible) customDateForm?.querySelector('input[type="date"]')?.focus();
    });
})();
