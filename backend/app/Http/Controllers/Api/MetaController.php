<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReportCategory;
use App\Models\ReportPriority;
use App\Models\ReportStatus;

class MetaController extends Controller
{
    public function index()
    {
        return response()->json([
            'categories' => ReportCategory::orderBy('name')->pluck('name')->values(),
            'priorities' => ReportPriority::orderBy('weight')->pluck('name')->values(),
            'statuses' => ReportStatus::orderBy('sort_order')->pluck('name')->values(),
        ]);
    }
}
