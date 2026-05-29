<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->string('external_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('report_categories');
            $table->foreignId('priority_id')->constrained('report_priorities');
            $table->foreignId('status_id')->constrained('report_statuses');
            $table->string('title');
            $table->text('description');
            $table->string('location');
            $table->longText('image_path')->nullable();
            $table->boolean('is_validated_by_teacher')->default(false);
            $table->string('assigned_to')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
