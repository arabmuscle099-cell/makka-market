<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        return Product::where('is_active',true)
            ->when($request->filled('category'),fn($q)=>$q->where('category',$request->category))
            ->when($request->filled('search'),fn($q)=>$q->where('name','ilike','%'.$request->search.'%'))
            ->orderBy('name')->paginate(30);
    }
    public function store(Request $request)
    {
        $data=$request->validate(['sku'=>'required|string|unique:products,sku','name'=>'required|string|max:255','category'=>'required|string','unit'=>'required|string','price'=>'required|numeric|min:0','stock'=>'required|integer|min:0','description'=>'nullable|string','image_url'=>'nullable|url']);
        return response()->json(Product::create($data),201);
    }
    public function update(Request $request, Product $product)
    {
        $data=$request->validate(['sku'=>'sometimes|required|string|unique:products,sku,'.$product->id,'name'=>'sometimes|required|string|max:255','category'=>'sometimes|required|string','unit'=>'sometimes|required|string','price'=>'sometimes|required|numeric|min:0','stock'=>'sometimes|required|integer|min:0','is_active'=>'sometimes|boolean','description'=>'nullable|string','image_url'=>'nullable|url']);
        $product->update($data); return response()->json($product);
    }
}
