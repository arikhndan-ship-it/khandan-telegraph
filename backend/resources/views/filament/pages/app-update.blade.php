<div class="p-6">
    <div class="max-w-2xl mx-auto">
        <div class="mb-6">
            <h2 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-3">
                <svg class="w-7 h-7 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                </svg>
                App Version Control
            </h2>
            <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
                Manage the minimum required app version. When you set a new minimum version, 
                all app installations with an older version will see a force-update screen 
                and must update before using the app.
            </p>
        </div>

        {{ $this->form }}

        <div class="mt-6">
            <x-filament::button
                wire:click="save"
                color="danger"
                size="lg"
                class="w-full sm:w-auto"
            >
                Save Update Settings
            </x-filament::button>
        </div>

        <div class="mt-8 p-4 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800/30 rounded-lg">
            <div class="flex items-start gap-3">
                <svg class="w-5 h-5 text-amber-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"/>
                </svg>
                <div>
                    <h4 class="font-semibold text-amber-800 dark:text-amber-300 text-sm">How it works</h4>
                    <ul class="mt-2 text-sm text-amber-700 dark:text-amber-400 space-y-1 list-disc list-inside">
                        <li>Set the <strong>Minimum Required Version</strong> (e.g., 0.0.5)</li>
                        <li>Provide the <strong>Update Download URL</strong> where users can get the latest APK</li>
                        <li>When users open an old app version, they'll see a screen forcing them to update</li>
                        <li>After saving, publish the new APK/AAB with the matching version</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>
