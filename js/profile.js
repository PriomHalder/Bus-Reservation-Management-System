(() => {
    'use strict';

    const tabs = [...document.querySelectorAll('[data-profile-tab]')];
    const panels = [...document.querySelectorAll('[data-profile-panel]')];

    function activateTab(key, updateHash = true) {
        if (!panels.some((panel) => panel.dataset.profilePanel === key)) key = 'overview';
        tabs.forEach((tab) => {
            const active = tab.dataset.profileTab === key;
            tab.classList.toggle('is-active', active);
            tab.setAttribute('aria-selected', active ? 'true' : 'false');
            tab.tabIndex = active ? 0 : -1;
        });
        panels.forEach((panel) => {
            const active = panel.dataset.profilePanel === key;
            panel.classList.toggle('is-active', active);
            panel.hidden = !active;
        });
        if (updateHash && history.replaceState) history.replaceState(null, '', `#${key}`);
    }

    tabs.forEach((tab, index) => {
        tab.addEventListener('click', () => activateTab(tab.dataset.profileTab));
        tab.addEventListener('keydown', (event) => {
            if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
            event.preventDefault();
            let next = index;
            if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
            if (event.key === 'ArrowLeft') next = (index - 1 + tabs.length) % tabs.length;
            if (event.key === 'Home') next = 0;
            if (event.key === 'End') next = tabs.length - 1;
            tabs[next].focus();
            activateTab(tabs[next].dataset.profileTab);
        });
    });
    document.querySelectorAll('[data-open-profile-tab]').forEach((button) => {
        button.addEventListener('click', () => activateTab(button.dataset.openProfileTab));
    });
    activateTab(location.hash.slice(1) || 'overview', false);

    document.querySelectorAll('[data-profile-personal-form]').forEach((personalForm) => {
        const fields = [...personalForm.elements].filter((field) => {
            if (!(field instanceof HTMLInputElement || field instanceof HTMLSelectElement || field instanceof HTMLTextAreaElement)) return false;
            if (field.disabled || field.readOnly) return false;
            return !['hidden', 'submit', 'button', 'reset'].includes(field.type);
        });
        const persistedValues = fields.map((field) => ({
            field,
            checked: field instanceof HTMLInputElement && ['checkbox', 'radio'].includes(field.type)
                ? field.checked
                : undefined,
            value: field.value,
        }));

        personalForm.querySelector('[data-profile-reset]')?.addEventListener('click', (event) => {
            event.preventDefault();
            persistedValues.forEach(({field, checked, value}) => {
                field.setCustomValidity('');
                if (typeof checked === 'boolean') field.checked = checked;
                else field.value = value;
                field.classList.remove('is-invalid', 'is-valid');
                field.removeAttribute('aria-invalid');
                field.dispatchEvent(new Event('input', {bubbles: true}));
                field.dispatchEvent(new Event('change', {bubbles: true}));
            });
        });
    });

    document.querySelectorAll('[data-password-toggle]').forEach((button) => {
        button.addEventListener('click', () => {
            const input = button.parentElement?.querySelector('input');
            if (!input) return;
            const show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            button.textContent = show ? 'Hide' : 'Show';
            button.setAttribute('aria-label', `${show ? 'Hide' : 'Show'} password`);
        });
    });

    const newPassword = document.querySelector('[data-new-password]');
    const meter = document.querySelector('[data-password-meter]');
    const strength = document.querySelector('[data-password-strength]');
    newPassword?.addEventListener('input', () => {
        const value = newPassword.value;
        const score = [value.length >= 8, /[a-z]/.test(value), /[A-Z]/.test(value), /\d/.test(value), /[^A-Za-z0-9]/.test(value)].filter(Boolean).length;
        const labels = ['not entered', 'very weak', 'weak', 'fair', 'good', 'strong'];
        const colors = ['#a5241a', '#a5241a', '#b45416', '#9a7200', '#39734c', '#176536'];
        if (meter) {
            meter.style.width = `${score * 20}%`;
            meter.style.background = colors[score];
        }
        if (strength) strength.textContent = `Strength: ${value ? labels[score] : labels[0]}`;
    });

    const master = document.querySelector('[data-notification-master]');
    const options = [...document.querySelectorAll('[data-notification-option]:not(:disabled)')];
    function applyMaster() {
        if (!master) return;
        options.forEach((option) => {
            option.disabled = !master.checked;
            if (!master.checked) option.checked = false;
        });
    }
    master?.addEventListener('change', applyMaster);
    applyMaster();

    const form = document.querySelector('[data-profile-picture-form]');
    const input = form?.querySelector('[data-picture-input]');
    const preview = form?.querySelector('[data-picture-preview]');
    const controls = form?.querySelector('[data-crop-controls]');
    const zoom = form?.querySelector('[data-crop-zoom]');
    const positionX = form?.querySelector('[data-crop-x]');
    const positionY = form?.querySelector('[data-crop-y]');
    const canvas = form?.querySelector('[data-crop-canvas]');
    const maximumPictureBytes = Number(form?.dataset.maxBytes || 2 * 1024 * 1024);
    let sourceImage = null;

    function updatePreview() {
        const image = preview?.querySelector('img');
        if (!image || !zoom || !positionX || !positionY) return;
        image.style.objectPosition = `${positionX.value}% ${positionY.value}%`;
        image.style.transform = `scale(${zoom.value})`;
    }

    input?.addEventListener('change', () => {
        const file = input.files?.[0];
        input.setCustomValidity('');
        if (!file) return;
        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > maximumPictureBytes) {
            input.setCustomValidity('Choose a supported image within the displayed size limit.');
            input.reportValidity();
            return;
        }
        const url = URL.createObjectURL(file);
        const image = new Image();
        image.onload = () => {
            sourceImage = image;
            if (preview) preview.innerHTML = `<span class="profile-avatar profile-avatar-preview"><img src="${url}" alt="Selected profile picture preview"></span>`;
            if (controls) controls.hidden = false;
            updatePreview();
        };
        image.src = url;
    });
    [zoom, positionX, positionY].forEach((control) => control?.addEventListener('input', updatePreview));

    form?.addEventListener('submit', (event) => {
        if (form.dataset.cropped === 'true' || !sourceImage || !canvas || typeof DataTransfer === 'undefined') return;
        event.preventDefault();
        const context = canvas.getContext('2d');
        if (!context) return form.submit();
        const z = Number(zoom?.value || 1);
        const scale = Math.max(canvas.width / sourceImage.naturalWidth, canvas.height / sourceImage.naturalHeight) * z;
        const width = sourceImage.naturalWidth * scale;
        const height = sourceImage.naturalHeight * scale;
        const x = (canvas.width - width) * (Number(positionX?.value || 50) / 100);
        const y = (canvas.height - height) * (Number(positionY?.value || 50) / 100);
        context.clearRect(0, 0, canvas.width, canvas.height);
        context.drawImage(sourceImage, x, y, width, height);
        canvas.toBlob((blob) => {
            if (!blob || !input) return form.submit();
            const transfer = new DataTransfer();
            transfer.items.add(new File([blob], 'profile.jpg', {type: 'image/jpeg'}));
            input.files = transfer.files;
            form.dataset.cropped = 'true';
            form.requestSubmit();
        }, 'image/jpeg', .9);
    });
})();
