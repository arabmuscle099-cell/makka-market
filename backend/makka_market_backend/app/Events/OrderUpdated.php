<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderUpdated implements ShouldBroadcast
{
    use Dispatchable, SerializesModels;

    public function __construct(public Order $order) {}

    public function broadcastOn(): array
    {
        $channels = [new PrivateChannel('admin.orders'), new PrivateChannel('orders.'.$this->order->id)];
        if ($this->order->courier_id) $channels[] = new PrivateChannel('courier.'.$this->order->courier_id);
        return $channels;
    }

    public function broadcastAs(): string { return 'order.updated'; }

    public function broadcastWith(): array
    {
        return ['order_id'=>$this->order->id,'status'=>$this->order->status,'courier_id'=>$this->order->courier_id,'total'=>$this->order->total];
    }
}
