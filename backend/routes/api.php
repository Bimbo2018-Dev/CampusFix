<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MetaController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => [
    'status' => 'ok',
    'app' => 'CampusFix',
    'backend' => 'Laravel API',
    'endpoints' => [
        'health' => '/api/health',
        'meta' => '/api/meta',
        'login' => '/api/auth/login',
        'register' => '/api/auth/register',
        'reports' => '/api/reports',
        'users' => '/api/users',
    ],
]);
Route::get('/health', fn () => ['status' => 'ok', 'app' => 'CampusFix']);
Route::get('/meta', [MetaController::class, 'index']);

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::get('/users', [UserController::class, 'index']);
    Route::patch('/users/{user}', [UserController::class, 'update']);

    Route::apiResource('reports', ReportController::class);
    Route::post('/reports/{report}/notes', [ReportController::class, 'addNote']);
    Route::post('/reports/{report}/validate', [ReportController::class, 'validateByTeacher']);
});
