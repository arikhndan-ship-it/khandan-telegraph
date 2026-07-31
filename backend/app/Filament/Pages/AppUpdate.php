<?php

namespace App\Filament\Pages;

use App\Helpers\CacheHelper;
use App\Models\Setting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class AppUpdate extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-arrow-up-circle';

    protected static ?string $navigationLabel = 'App Update';

    protected static ?string $navigationGroup = 'System';

    protected static ?string $slug = 'app-update';

    protected static string $view = 'filament.pages.app-update';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'minimum_app_version' => Setting::where('key', 'minimum_app_version')->value('value') ?? '0.0.3',
            'update_url' => Setting::where('key', 'update_url')->value('value') ?? '',
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('App Version Control')
                    ->description('Set the minimum required version. Apps older than this will be forced to update.')
                    ->schema([
                        Forms\Components\TextInput::make('minimum_app_version')
                            ->label('Minimum Required Version')
                            ->helperText('e.g., 0.0.5 — any app with a lower version will show a force-update screen')
                            ->required()
                            ->maxLength(20)
                            ->placeholder('0.0.5'),
                        Forms\Components\TextInput::make('update_url')
                            ->label('Update Download URL')
                            ->helperText('URL where users can download the latest APK/AAB')
                            ->required()
                            ->maxLength(500)
                            ->url()
                            ->placeholder('https://khandantelegraph.news/downloads/khandan.apk'),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        Setting::updateOrCreate(
            ['key' => 'minimum_app_version'],
            ['value' => $data['minimum_app_version'], 'type' => 'text']
        );

        Setting::updateOrCreate(
            ['key' => 'update_url'],
            ['value' => $data['update_url'], 'type' => 'text']
        );

        CacheHelper::clearSettingsCaches();

        Notification::make()
            ->title('App update settings saved successfully!')
            ->success()
            ->send();
    }

    public static function canView(): bool
    {
        return in_array(auth()->user()?->role, ['author', 'admin']);
    }
}
