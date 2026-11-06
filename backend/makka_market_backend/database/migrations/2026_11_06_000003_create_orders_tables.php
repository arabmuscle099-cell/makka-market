<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('orders', function (Blueprint $table) {
            $table->id(); $table->foreignId('customer_id')->constrained('users');
            $table->foreignId('courier_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status',30)->default('new')->index();
            $table->decimal('subtotal',10,2); $table->decimal('delivery_fee',10,2)->default(0);
            $table->decimal('total',10,2); $table->text('address'); $table->text('notes')->nullable();
            $table->string('payment_method',30)->default('cash');
            $table->string('payment_status',30)->default('unpaid'); $table->timestamps();
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->id(); $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->string('product_name'); $table->string('unit',80);
            $table->decimal('unit_price',10,2); $table->unsignedInteger('quantity');
            $table->decimal('line_total',10,2); $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('order_items'); Schema::dropIfExists('orders'); }
};
