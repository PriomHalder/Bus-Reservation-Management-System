<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide fixed-shift scheduling policy
|--------------------------------------------------------------------------
| This is the single application-level definition of the two supported
| service shifts. Database migration 007 enforces the same mapping for
| writes made outside the University Admin schedule page.
*/

/** @return array<string,array{label:string,departure:string}> */
function uniride_schedule_shifts(): array
{
    return [
        'NOON' => [
            'label' => 'Noon',
            'departure' => '14:00:00',
        ],
        'EVENING' => [
            'label' => 'Evening',
            'departure' => '17:10:00',
        ],
    ];
}

/** @return array{label:string,departure:string}|null */
function uniride_schedule_shift(string $shift): ?array
{
    $shift = strtoupper(trim($shift));
    $shifts = uniride_schedule_shifts();

    return $shifts[$shift] ?? null;
}

function uniride_schedule_is_fixed_shift(?string $shift, ?string $departure): bool
{
    $definition = uniride_schedule_shift((string)$shift);

    return $definition !== null
        && $definition['departure'] === (string)$departure;
}

function uniride_schedule_shift_label(?string $shift, ?string $departure = null): string
{
    $definition = uniride_schedule_shift((string)$shift);

    if ($definition !== null && ($departure === null || $definition['departure'] === $departure)) {
        return $definition['label'];
    }

    return 'Legacy';
}
