<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\OrderItem;
use App\Events\OrderUpdated;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $data=$request->validate(['address'=>'required|string|min:8','notes'=>'nullable|string','items'=>'required|array|min:1','items.*.product_id'=>'required|integer|exists:products,id','items.*.quantity'=>'required|integer|min:1|max:100']);
        $order=DB::transaction(function() use($data,$request) {
            $subtotal=0; $lines=[];
            foreach($data['items'] as $item) {
                $p=Product::whereKey($item['product_id'])->lockForUpdate()->first();
                if(!$p || !$p->is_active) throw ValidationException::withMessages(['items'=>'منتج غير متاح حالياً']);
                if($p->stock < $item['quantity']) throw ValidationException::withMessages(['items'=>"الكمية غير متاحة للمنتج: {$p->name}"]);
                $line=$p->price*$item['quantity']; $subtotal+=$line;
                $lines[]=[$p,$item['quantity'],$line];
            }
            $delivery=25.00; // قيمة تجريبية: تُستبدل بتسعير مناطق العجمي
            $order=Order::create(['customer_id'=>$request->user()->id,'status'=>'new','subtotal'=>$subtotal,'delivery_fee'=>$delivery,'total'=>$subtotal+$delivery,'address'=>$data['address'],'notes'=>$data['notes']??null,'payment_method'=>'cash','payment_status'=>'unpaid']);
            foreach($lines as [$p,$qty,$line]) {
                $p->decrement('stock',$qty);
                OrderItem::create(['order_id'=>$order->id,'product_id'=>$p->id,'product_name'=>$p->name,'unit'=>$p->unit,'unit_price'=>$p->price,'quantity'=>$qty,'line_total'=>$line]);
            }
            return $order->load('items','customer');
        });
        broadcast(new OrderUpdated($order))->toOthers();
        return response()->json($order,201);
    }
    public function myOrders(Request $request) { return Order::with('items','courier:id,name,phone')->where('customer_id',$request->user()->id)->latest()->paginate(20); }
}
