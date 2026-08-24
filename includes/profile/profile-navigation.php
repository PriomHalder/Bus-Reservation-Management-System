<?php
declare(strict_types=1);

function profile_render_navigation(): void
{
    $tabs = [
        'overview' => 'Overview',
        'personal' => 'Personal information',
        'picture' => 'Profile picture',
        'notifications' => 'Notifications',
        'security' => 'Password & security',
        'sessions' => 'Active sessions',
        'activity' => 'Login activity',
    ];
    echo '<nav class="profile-tabs" aria-label="Profile sections" role="tablist">';
    foreach ($tabs as $key => $label) {
        echo '<button type="button" class="profile-tab' . ($key === 'overview' ? ' is-active' : '')
            . '" data-profile-tab="' . profile_h($key) . '" role="tab" aria-controls="profile-panel-'
            . profile_h($key) . '" aria-selected="' . ($key === 'overview' ? 'true' : 'false') . '">'
            . profile_h($label) . '</button>';
    }
    echo '</nav>';
}
