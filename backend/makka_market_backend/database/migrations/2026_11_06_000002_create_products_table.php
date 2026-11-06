<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('products', function (Blueprint $table) {
            $table->id(); $table->string('sku')->unique(); $table->string('name');
            $table->string('category')->index(); $table->text('description')->nullable();
            $table->text('image_url')->nullable(); $table->string('unit',80);
            $table->decimal('price',10,2); $table->unsignedInteger('stock')->default(0);
            $table->boolean('is_active')->default(true)->index(); $table->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('products'); }
};
