<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Events\OrderUpdated;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AdminOrderController extends Controller
{
    public function index(Request $request) { return Order::with('customer:id,name,phone','courier:id,name,phone','items')->latest()->paginate(30); }

    public function couriers()
    {
        return User::query()->where('role', 'courier')->orderBy('name')->get(['id', 'name', 'phone']);
    }

    public function assign(Request $request, Order $order)
    {
        $data=$request->validate(['courier_id'=>'required|integer|exists:users,id']);
        $courier=User::findOrFail($data['courier_id']);
        if($courier->role!=='courier') throw ValidationException::withMessages(['courier_id'=>'المستخدم المحدد ليس مندوباً']);
        $order->update(['courier_id'=>$courier->id,'status'=>'assigned']);
        $order->load('items','customer','courier');
        broadcast(new OrderUpdated($order));
        return response()->json($order);
    }
}
