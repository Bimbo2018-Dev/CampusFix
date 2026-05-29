<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Report;
use App\Models\ReportNote;
use App\Models\User;

trait FormatsCampusFixResponses
{
    protected function userPayload(User $user): array
    {
        return [
            'id' => (string) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'department' => $user->department ?? '',
            'avatarText' => $user->avatar_text ?? $this->initials($user->name),
            'isActive' => (bool) ($user->is_active ?? true),
        ];
    }

    protected function reportPayload(Report $report): array
    {
        $report->loadMissing([
            'reporter',
            'category',
            'priority',
            'status',
            'notes.author',
        ]);

        return [
            'id' => $report->external_id,
            'reporterId' => (string) $report->user_id,
            'reporterName' => $report->reporter?->name ?? 'Unknown User',
            'reporterRole' => $report->reporter?->role ?? 'Student',
            'title' => $report->title,
            'description' => $report->description,
            'category' => $report->category?->name ?? 'Other',
            'location' => $report->location,
            'priority' => $report->priority?->name ?? 'Medium',
            'status' => $report->status?->name ?? 'Pending',
            'createdAt' => $report->created_at?->toISOString(),
            'updatedAt' => $report->updated_at?->toISOString(),
            'imagePath' => $report->image_path,
            'resolvedImagePath' => $report->resolved_image_path,
            'isValidatedByTeacher' => (bool) $report->is_validated_by_teacher,
            'assignedTo' => $report->assigned_to,
            'notes' => $report->notes
                ->sortBy('created_at')
                ->map(fn (ReportNote $note) => $this->notePayload($note))
                ->values()
                ->all(),
        ];
    }

    protected function notePayload(ReportNote $note): array
    {
        $note->loadMissing('author');

        return [
            'id' => (string) $note->id,
            'authorName' => $note->author?->name ?? 'CampusFix User',
            'authorRole' => $note->author?->role ?? 'Staff',
            'message' => $note->message,
            'createdAt' => $note->created_at?->toISOString(),
        ];
    }

    protected function initials(string $name): string
    {
        $parts = preg_split('/\s+/', trim($name)) ?: [];
        $letters = array_map(fn (string $part) => mb_substr($part, 0, 1), $parts);

        return mb_strtoupper(mb_substr(implode('', $letters), 0, 2));
    }
}
