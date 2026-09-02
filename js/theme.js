(() => {
    'use strict';

    const STORAGE_KEY = 'uniride-color-theme';
    const root = document.documentElement;
    const systemPreference = window.matchMedia
        ? window.matchMedia('(prefers-color-scheme: dark)')
        : null;

    function cookieTheme() {
        const match = document.cookie.match(new RegExp(`(?:^|; )${STORAGE_KEY}=(light|dark)(?:;|$)`));
        return match ? match[1] : null;
    }

    function storedTheme() {
        try {
            const value = window.localStorage.getItem(STORAGE_KEY);
            if (value === 'light' || value === 'dark') return value;
        } catch (error) {
            // Fall through to the non-database cookie fallback.
        }
        return cookieTheme();
    }

    function preferredTheme() {
        return storedTheme() || (systemPreference?.matches ? 'dark' : 'light');
    }

    function persistTheme(theme) {
        try {
            window.localStorage.setItem(STORAGE_KEY, theme);
        } catch (error) {
            // Keep persistence working when localStorage is blocked.
        }
        document.cookie = `${STORAGE_KEY}=${theme}; Max-Age=31536000; Path=/; SameSite=Lax`;
    }

    function updateToggle(button, theme) {
        if (!button) return;
        const dark = theme === 'dark';
        const action = dark ? 'Switch to light mode' : 'Switch to dark mode';
        button.setAttribute('aria-pressed', dark ? 'true' : 'false');
        button.setAttribute('aria-label', action);
        button.title = action;
        const label = button.querySelector('[data-theme-toggle-label]');
        if (label) label.textContent = dark ? 'Light mode' : 'Dark mode';
    }

    function applyTheme(theme, persist = false) {
        const resolved = theme === 'dark' ? 'dark' : 'light';
        root.setAttribute('data-theme', resolved);
        root.style.colorScheme = resolved;
        if (persist) persistTheme(resolved);
        document.querySelectorAll('[data-theme-toggle]').forEach((button) => {
            updateToggle(button, resolved);
        });
        window.dispatchEvent(new CustomEvent('uniride:themechange', {detail: {theme: resolved}}));
    }

    function createToggle() {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'theme-toggle';
        button.setAttribute('data-theme-toggle', '');
        button.innerHTML = `
            <span class="theme-toggle-icon theme-toggle-moon" aria-hidden="true">
                <svg viewBox="0 0 24 24" focusable="false"><path d="M20.2 15.4A8.5 8.5 0 0 1 8.6 3.8a8.7 8.7 0 1 0 11.6 11.6Z"/></svg>
            </span>
            <span class="theme-toggle-icon theme-toggle-sun" aria-hidden="true">
                <svg viewBox="0 0 24 24" focusable="false"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
            </span>
            <span class="theme-toggle-label" data-theme-toggle-label></span>`;
        button.addEventListener('click', () => {
            applyTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark', true);
        });
        updateToggle(button, root.getAttribute('data-theme') || preferredTheme());
        return button;
    }

    function mountToggle() {
        if (document.querySelector('[data-theme-toggle]')) return;
        const target = document.querySelector([
            '[data-theme-toggle-slot]',
            '.topbar .nav-actions',
            '.uni-account',
            '.system-account',
            '.passenger-account',
            '.pp-account',
            '.shell-user'
        ].join(','));
        const button = createToggle();
        if (!target) {
            button.classList.add('theme-toggle-floating');
            document.body.append(button);
            return;
        }
        const signOut = target.querySelector('a[href*="logout"]');
        target.insertBefore(button, signOut || target.firstChild);
    }

    applyTheme(root.getAttribute('data-theme') || preferredTheme());
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', mountToggle, {once: true});
    } else {
        mountToggle();
    }

    window.addEventListener('storage', (event) => {
        if (event.key === STORAGE_KEY && (event.newValue === 'light' || event.newValue === 'dark')) {
            applyTheme(event.newValue);
        } else if (event.key === STORAGE_KEY && event.newValue === null) {
            applyTheme(preferredTheme());
        }
    });
    systemPreference?.addEventListener?.('change', (event) => {
        if (!storedTheme()) applyTheme(event.matches ? 'dark' : 'light');
    });
})();
