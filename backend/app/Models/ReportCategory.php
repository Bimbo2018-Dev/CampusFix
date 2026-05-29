<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReportCategory extends Model
{
    protected $fillable = ['name', 'description'];

    public function reports()
    {
        return $this->hasMany(Report::class, 'category_id');
    }
}
