<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = ['customer_id','courier_id','status','subtotal','delivery_fee','total','address','notes','payment_method','payment_status'];
    protected $casts = ['subtotal'=>'decimal:2','delivery_fee'=>'decimal:2','total'=>'decimal:2'];
    public function customer() { return $this->belongsTo(User::class, 'customer_id'); }
    public function courier() { return $this->belongsTo(User::class, 'courier_id'); }
    public function items() { return $this->hasMany(OrderItem::class); }
}
