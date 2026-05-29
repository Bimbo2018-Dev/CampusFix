<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    protected $fillable = [
        'external_id',
        'user_id',
        'category_id',
        'priority_id',
        'status_id',
        'title',
        'description',
        'location',
        'image_path',
        'resolved_image_path',
        'is_validated_by_teacher',
        'assigned_to',
    ];

    protected function casts(): array
    {
        return [
            'is_validated_by_teacher' => 'boolean',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'external_id';
    }

    public function reporter()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function category()
    {
        return $this->belongsTo(ReportCategory::class, 'category_id');
    }

    public function priority()
    {
        return $this->belongsTo(ReportPriority::class, 'priority_id');
    }

    public function status()
    {
        return $this->belongsTo(ReportStatus::class, 'status_id');
    }

    public function notes()
    {
        return $this->hasMany(ReportNote::class);
    }
}
