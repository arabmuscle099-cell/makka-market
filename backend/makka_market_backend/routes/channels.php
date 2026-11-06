<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Order;

Broadcast::channel('admin.orders', fn($user) => $user->role === 'admin');
Broadcast::channel('orders.{orderId}', function ($user, $orderId) {
    $order=Order::find($orderId);
    return $order && ($order->customer_id===$user->id || $order->courier_id===$user->id || $user->role==='admin');
});
Broadcast::channel('courier.{courierId}', fn($user,$courierId) => $user->role==='admin' || ($user->role==='courier' && (int)$user->id===(int)$courierId));
