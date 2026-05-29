<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReportNote extends Model
{
    protected $fillable = ['report_id', 'user_id', 'message'];

    public function report()
    {
        return $this->belongsTo(Report::class);
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
