
import 'package:flutter/material.dart';

void main() => runApp(const MakkaApp());

const green = Color(0xFF123D2D);
const orange = Color(0xFFF47A20);
const cream = Color(0xFFF7F6F0);

class Product {
  final int id;
  final String name, category, unit, emoji;
  double price;
  int stock;
  Product(this.id,this.name,this.category,this.unit,this.price,this.emoji,{this.stock=30});
}
final List<Product> inventory = [
  Product(1,'طماطم طازجة','خضار وفاكهة','1 كجم',24.90,'🍅'),
  Product(2,'بطاطس','خضار وفاكهة','1 كجم',19.50,'🥔'),
  Product(3,'موز','خضار وفاكهة','1 كجم',32,'🍌'),
  Product(4,'لبن كامل الدسم','ألبان','1 لتر',32.50,'🥛'),
  Product(5,'جبنة بيضاء','ألبان','500 جم',48,'🧀'),
  Product(6,'بيض','ألبان','طبق 30 بيضة',145,'🥚'),
  Product(7,'فراخ كاملة','لحوم ودواجن','1 كجم',115,'🍗'),
  Product(8,'لحم بلدي','لحوم ودواجن','1 كجم',390,'🥩'),
  Product(9,'أرز','بقالة','1 كجم',34,'🍚'),
  Product(10,'زيت عباد الشمس','بقالة','1 لتر',68,'🫙'),
  Product(11,'عصير برتقال','مشروبات','1 لتر',29,'🧃'),
  Product(12,'منظف أرضيات','منظفات','1 لتر',55,'🧴'),
];
class Order {
  final int id;
  final String customer, address;
  final Map<int,int> items;
  final double total;
  String status;
  Order(this.id,this.customer,this.address,this.items,this.total,{this.status='طلب جديد'});
}
final List<Order> orders = [];

class MakkaApp extends StatelessWidget {
  const MakkaApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'مكّة ماركت',
    theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:cream,colorScheme:ColorScheme.fromSeed(seedColor:green,primary:green,secondary:orange),fontFamily:'Arial'),
    home:const RoleChooser());
}
class RoleChooser extends StatelessWidget {
  const RoleChooser({super.key});
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:green,
    body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(Icons.shopping_basket_rounded,color:orange,size:76),
      const SizedBox(height:12),const Text('مكّة ماركت',style:TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.bold)),
      const Text('كل احتياجات بيتك في مكان واحد',style:TextStyle(color:Colors.white70)),
      const SizedBox(height:38),
      _roleButton(context,'تطبيق العميل','تسوق المنتجات واطلب احتياجاتك',Icons.shopping_bag,()=>const CustomerHome()),
      _roleButton(context,'لوحة الإدارة','المنتجات والمخزون والطلبات',Icons.dashboard,()=>const AdminHome()),
      _roleButton(context,'واجهة المندوب','استلام الطلبات وتحديث التوصيل',Icons.delivery_dining,()=>const CourierHome()),
      const SizedBox(height:18),const Text('نسخة تجريبية للواجهات — البيانات محلية',style:TextStyle(color:Colors.white54,fontSize:11))
    ])))))
  );
  Widget _roleButton(BuildContext c,String title,String sub,IconData icon,Widget Function() page)=>Padding(
    padding:const EdgeInsets.only(bottom:12),child(Material(color:Colors.white,borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page())),child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Icon(icon,color:green,size:30),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),Text(sub,style:const TextStyle(color:Colors.black54,fontSize:12))])),const Icon(Icons.chevron_left,color:orange)])))))
  );
}

class CustomerHome extends StatefulWidget { const CustomerHome({super.key}); @override State<CustomerHome> createState()=>_CustomerHomeState(); }
class _CustomerHomeState extends State<CustomerHome>{
  final Map<int,int> cart={}; String q=''; String cat='الكل';
  final cats=['الكل','خضار وفاكهة','لحوم ودواجن','ألبان','بقالة','مشروبات','منظفات'];
  double get total=>cart.entries.fold(0,(s,e)=>s+inventory.firstWhere((p)=>p.id==e.key).price*e.value);
  List<Product> get visible=>inventory.where((p)=>(cat=='الكل'||p.category==cat)&&(q.isEmpty||p.name.contains(q))).toList();
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(backgroundColor:green,foregroundColor:Colors.white,title:const Text('مكّة ماركت'),actions:[TextButton.icon(onPressed:()=>_cart(),icon:const Icon(Icons.shopping_cart,color:Colors.white),label:Text('${cart.values.fold(0,(a,b)=>a+b)}',style:const TextStyle(color:Colors.white)))]),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(18)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('أهلاً بيك في مكّة ماركت 🛒',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold)),SizedBox(height:5),Text('كل احتياجات بيتك في مكان واحد',style:TextStyle(color:Colors.white70)),SizedBox(height:8),Text('📍 التوصيل إلى العجمي — الإسكندرية',style:TextStyle(color:Colors.white))])),
      const SizedBox(height:12),TextField(onChanged:(v)=>setState(()=>q=v),decoration:InputDecoration(hintText:'ابحث عن منتج...',prefixIcon:const Icon(Icons.search),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))),
      const SizedBox(height:16),const Text('تسوق حسب القسم',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:green)),
      Wrap(spacing:7,children:cats.map((c)=>ChoiceChip(label:Text(c),selected:cat==c,onSelected:(_)=>setState(()=>cat=c),selectedColor:orange)).toList()),
      const SizedBox(height:12),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:visible.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.82,crossAxisSpacing:10,mainAxisSpacing:10),itemBuilder:(c,i){final p=visible[i];return Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:Text(p.emoji,style:const TextStyle(fontSize:48)))),Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)),Text(p.unit,style:const TextStyle(color:Colors.grey,fontSize:11)),Row(children:[Expanded(child:Text('${p.price.toStringAsFixed(2)} ج.م',style:const TextStyle(color:green,fontWeight:FontWeight.bold))),IconButton(onPressed:()=>setState(()=>cart[p.id]=(cart[p.id]??0)+1),icon:const Icon(Icons.add_circle,color:orange))])])));}),
    ]),
  ));
  void _cart()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CartPage(cart:cart,total:total,onChanged:()=>setState(()=>{}))));
}

class CartPage extends StatefulWidget {
 final Map<int,int> cart; final double total; final VoidCallback onChanged;
 const CartPage({super.key,required this.cart,required this.total,required this.onChanged});
 @override State<CartPage> createState()=>_CartPageState();
}
class _CartPageState extends State<CartPage>{
 double get total=>widget.cart.entries.fold(0,(s,e)=>s+inventory.firstWhere((p)=>p.id==e.key).price*e.value);
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('سلة المشتريات')),body:widget.cart.isEmpty?const Center(child:Text('السلة فارغة')):Column(children:[
 Expanded(child:ListView(children:widget.cart.entries.map((e){final p=inventory.firstWhere((x)=>x.id==e.key);return ListTile(leading:Text(p.emoji,style:const TextStyle(fontSize:28)),title:Text(p.name),subtitle:Text('${p.price} ج.م'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>setState(()=>e.value<=1?widget.cart.remove(e.key):widget.cart[e.key]=e.value-1),icon:const Icon(Icons.remove_circle_outline)),Text('${widget.cart[e.key]}'),IconButton(onPressed:()=>setState(()=>widget.cart[e.key]=e.value+1),icon:const Icon(Icons.add_circle_outline))]));}).toList())),
 Padding(padding:const EdgeInsets.all(16),child:Column(children:[Text('الإجمالي: ${total.toStringAsFixed(2)} جنيه',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),FilledButton(onPressed:_checkout,child:const Text('إتمام الطلب'))]))
 ])));
 void _checkout(){
 final n=TextEditingController(),ph=TextEditingController(),a=TextEditingController();
 showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('بيانات التوصيل'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:ph,decoration:const InputDecoration(labelText:'رقم الهاتف'),keyboardType:TextInputType.phone),TextField(controller:a,decoration:const InputDecoration(labelText:'العنوان بالتفصيل'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:(){if(n.text.isEmpty||ph.text.isEmpty||a.text.isEmpty)return;orders.add(Order(orders.length+1001,n.text,a.text,Map.of(widget.cart),total));widget.cart.clear();Navigator.pop(ctx);Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل الطلب التجريبي')));},child:const Text('تأكيد الطلب'))]));
 }
}

class AdminHome extends StatefulWidget{const AdminHome({super.key});@override State<AdminHome> createState()=>_AdminHomeState();}
class _AdminHomeState extends State<AdminHome>{
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('لوحة إدارة مكّة ماركت'),backgroundColor:green,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('نظرة عامة',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:green)),
 GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.6,children:[_stat('المنتجات','${inventory.length}',Icons.inventory),_stat('الطلبات','${orders.length}',Icons.receipt_long),_stat('طلبات جديدة','${orders.where((o)=>o.status=='طلب جديد').length}',Icons.notifications_active),_stat('المخزون','تجريبي',Icons.warehouse)]),
 const SizedBox(height:14),const Text('إدارة المنتجات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...inventory.map((p)=>Card(color:Colors.white,child:ListTile(leading:Text(p.emoji,style:const TextStyle(fontSize:25)),title:Text(p.name),subtitle:Text('${p.price} جنيه • المخزون ${p.stock}'),trailing:IconButton(icon:const Icon(Icons.edit,color:orange),onPressed:()=>_edit(p))))),
 const SizedBox(height:14),const Text('الطلبات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...orders.map((o)=>Card(color:Colors.white,child:ListTile(title:Text('طلب #${o.id} — ${o.customer}'),subtitle:Text('${o.total.toStringAsFixed(2)} جنيه • ${o.address}'),trailing:Text(o.status))))
 ])));
 Widget _stat(String title,String value,IconData icon)=>Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:orange),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(title)])));
 void _edit(Product p){final c=TextEditingController(text:p.price.toString());showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('تعديل ${p.name}'),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر بالجنيه')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:(){final v=double.tryParse(c.text);if(v!=null)p.price=v;Navigator.pop(ctx);setState((){});},child:const Text('حفظ'))]));}
}

class CourierHome extends StatefulWidget{const CourierHome({super.key});@override State<CourierHome> createState()=>_CourierHomeState();}
class _CourierHomeState extends State<CourierHome>{
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('واجهة المندوب'),backgroundColor:green,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(14),children:[
 Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.delivery_dining,color:orange,size:40),SizedBox(width:12),Expanded(child:Text('أهلاً بيك يا مندوب مكّة ماركت',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)))])),
 const SizedBox(height:16),const Text('الطلبات المسندة إليك',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
 if(orders.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('لا توجد طلبات مسندة حالياً'))),
 ...orders.map((o)=>Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('طلب #${o.id}',style:const TextStyle(fontWeight:FontWeight.bold)),Text(o.customer),Text(o.address),Text('${o.total.toStringAsFixed(2)} جنيه'),DropdownButton<String>(value:o.status,items:['طلب جديد','تم التجهيز','خرج للتوصيل','تم التسليم'].map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),onChanged:(v)=>setState(()=>o.status=v??o.status))]))))
 ])));
}
