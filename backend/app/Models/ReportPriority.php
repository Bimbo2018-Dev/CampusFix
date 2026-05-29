<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReportPriority extends Model
{
    protected $fillable = ['name', 'weight'];

    public function reports()
    {
        return $this->hasMany(Report::class, 'priority_id');
    }
}
