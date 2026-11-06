<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data=$request->validate(['email'=>'required|email','password'=>'required|string']);
        $user=User::where('email',$data['email'])->first();
        if(!$user || !Hash::check($data['password'],$user->password)) return response()->json(['message'=>'بيانات الدخول غير صحيحة'],422);
        return response()->json(['token'=>$user->createToken('makka-android')->plainTextToken,'user'=>$user]);
    }
    public function logout(Request $request) { $request->user()->currentAccessToken()->delete(); return response()->json(['message'=>'تم تسجيل الخروج']); }
    public function me(Request $request) { return response()->json($request->user()); }
}
