<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Product;

class MakkaDemoSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(['email'=>'admin@makka.test'],['name'=>'مدير مكّة ماركت','phone'=>'01000000001','password'=>'password','role'=>'admin']);
        User::updateOrCreate(['email'=>'courier@makka.test'],['name'=>'مندوب تجريبي','phone'=>'01000000002','password'=>'password','role'=>'courier']);
        User::updateOrCreate(['email'=>'customer@makka.test'],['name'=>'عميل تجريبي','phone'=>'01000000003','password'=>'password','role'=>'customer']);
        $items=[
            ['sku'=>'MK-001','name'=>'طماطم طازجة','category'=>'خضار وفاكهة','unit'=>'1 كجم','price'=>24.90,'stock'=>100],
            ['sku'=>'MK-002','name'=>'بطاطس','category'=>'خضار وفاكهة','unit'=>'1 كجم','price'=>19.50,'stock'=>100],
            ['sku'=>'MK-003','name'=>'لبن كامل الدسم','category'=>'ألبان','unit'=>'1 لتر','price'=>32.50,'stock'=>50],
            ['sku'=>'MK-004','name'=>'أرز','category'=>'بقالة','unit'=>'1 كجم','price'=>34,'stock'=>80],
        ];
        foreach($items as $item) Product::updateOrCreate(['sku'=>$item['sku']],$item+['is_active'=>true]);
    }
}
