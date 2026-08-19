(() => {
    const menuButton = document.querySelector('[data-menu-button]');
    const nav = document.querySelector('.main-nav');

    if (menuButton && nav) {
        menuButton.addEventListener('click', () => {
            nav.classList.toggle('open');
        });
    }

    const search = document.querySelector('#routeSearch');
    const cards = [...document.querySelectorAll('[data-route-card]')];
    const filters = [...document.querySelectorAll('[data-filter]')];
    let activeFilter = 'all';

    function updateRoutes() {
        const query = (search?.value || '').toLowerCase().trim();

        cards.forEach((card) => {
            const text = (card.dataset.search || '').toLowerCase();
            const university = (card.dataset.university || '').toLowerCase();

            const textMatches = !query || text.includes(query);
            const filterMatches =
                activeFilter === 'all' || university === activeFilter;

            card.hidden = !(textMatches && filterMatches);
        });
    }

    search?.addEventListener('input', updateRoutes);

    filters.forEach((button) => {
        button.addEventListener('click', () => {
            activeFilter = button.dataset.filter || 'all';

            filters.forEach((item) => {
                item.classList.toggle('active', item === button);
            });

            updateRoutes();
        });
    });

    const authTabs = [...document.querySelectorAll('[data-auth-tab]')];
    const accountType = document.querySelector('#accountType');
    const emailLabel = document.querySelector('#emailLabel');
    const forgotLink = document.querySelector('#forgotLink');

    authTabs.forEach((tab) => {
        tab.addEventListener('click', () => {
            const type = tab.dataset.authTab;

            authTabs.forEach((item) => {
                item.classList.toggle('active', item === tab);
            });

            if (accountType) accountType.value = type;

            if (emailLabel) {
                emailLabel.textContent =
                    type === 'PASSENGER'
                        ? 'Academic email address'
                        : 'Email address';
            }

            if (forgotLink) {
                forgotLink.href =
                    'forgot-password.php?type=' +
                    encodeURIComponent(type);
            }
        });
    });

    document.querySelectorAll('[data-password-toggle]').forEach((button) => {
        button.addEventListener('click', () => {
            const input = document.querySelector('#passwordInput');

            if (!input) return;

            const show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            button.textContent = show ? 'Hide' : 'Show';
        });
    });
})();
