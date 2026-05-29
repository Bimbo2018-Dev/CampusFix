<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class ReportImageStorage
{
    public function store(?string $value, string $folder): ?string
    {
        if ($value === null || trim($value) === '') {
            return null;
        }

        if (! $this->usesCloudinary() || ! str_starts_with($value, 'data:image/')) {
            return $value;
        }

        $cloudName = (string) config('services.cloudinary.cloud_name');
        $apiKey = (string) config('services.cloudinary.api_key');
        $apiSecret = (string) config('services.cloudinary.api_secret');

        if ($cloudName === '' || $apiKey === '' || $apiSecret === '') {
            throw ValidationException::withMessages([
                'imagePath' => ['Cloudinary is enabled but credentials are incomplete.'],
            ]);
        }

        $timestamp = (string) time();
        $normalizedFolder = trim($folder, '/');
        $signature = $this->signature([
            'folder' => $normalizedFolder,
            'timestamp' => $timestamp,
        ], $apiSecret);

        $response = Http::asMultipart()
            ->timeout(20)
            ->post("https://api.cloudinary.com/v1_1/{$cloudName}/image/upload", [
                'file' => $value,
                'api_key' => $apiKey,
                'timestamp' => $timestamp,
                'folder' => $normalizedFolder,
                'signature' => $signature,
            ]);

        if (! $response->successful()) {
            throw ValidationException::withMessages([
                'imagePath' => ['Could not upload that image to Cloudinary.'],
            ]);
        }

        $url = $response->json('secure_url') ?: $response->json('url');
        if (! is_string($url) || $url === '') {
            throw ValidationException::withMessages([
                'imagePath' => ['Cloudinary did not return an image URL.'],
            ]);
        }

        return $url;
    }

    private function usesCloudinary(): bool
    {
        return config('services.campusfix.image_driver', 'local') === 'cloudinary';
    }

    private function signature(array $params, string $apiSecret): string
    {
        ksort($params);

        $payload = collect($params)
            ->map(fn ($value, $key) => "{$key}={$value}")
            ->implode('&');

        return sha1($payload.$apiSecret);
    }
}
