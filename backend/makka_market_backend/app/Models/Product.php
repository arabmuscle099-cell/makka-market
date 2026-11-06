<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = ['sku','name','category','description','image_url','unit','price','stock','is_active'];
    protected $casts = ['price' => 'decimal:2', 'stock' => 'integer', 'is_active' => 'boolean'];
    public function orderItems() { return $this->hasMany(OrderItem::class); }
}
