<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\AdminOrderController;
use App\Http\Controllers\Api\CourierOrderController;

Route::post('/login', [AuthController::class, 'login']);
Route::get('/products', [ProductController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::middleware('role:admin')->group(function () {
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{product}', [ProductController::class, 'update']);
        Route::get('/admin/orders', [AdminOrderController::class, 'index']);
        Route::get('/admin/couriers', [AdminOrderController::class, 'couriers']);
        Route::post('/admin/orders/{order}/assign', [AdminOrderController::class, 'assign']);
    });

    Route::middleware('role:customer')->group(function () {
        Route::post('/orders', [OrderController::class, 'store']);
        Route::get('/orders/my', [OrderController::class, 'myOrders']);
    });

    Route::middleware('role:courier')->group(function () {
        Route::get('/courier/orders', [CourierOrderController::class, 'index']);
        Route::patch('/courier/orders/{order}/status', [CourierOrderController::class, 'updateStatus']);
    });
});
