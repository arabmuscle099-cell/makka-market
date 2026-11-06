<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Events\OrderUpdated;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class CourierOrderController extends Controller
{
    public function index(Request $request) { return Order::with('items','customer:id,name,phone')->where('courier_id',$request->user()->id)->latest()->paginate(30); }

    public function updateStatus(Request $request, Order $order)
    {
        abort_unless($order->courier_id===$request->user()->id,403,'هذا الطلب غير مسند إليك');
        $data=$request->validate(['status'=>'required|in:preparing,out_for_delivery,delivered']);
        $allowed=['assigned'=>['preparing'],'preparing'=>['out_for_delivery'],'out_for_delivery'=>['delivered']];
        if(!in_array($data['status'],$allowed[$order->status]??[],true)) throw ValidationException::withMessages(['status'=>'انتقال حالة الطلب غير مسموح']);
        $order->update(['status'=>$data['status']]);
        $order->load('items','customer','courier');
        broadcast(new OrderUpdated($order));
        return response()->json($order);
    }
}
