<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\FormatsCampusFixResponses;
use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\ReportCategory;
use App\Models\ReportPriority;
use App\Models\ReportStatus;
use App\Services\ReportImageStorage;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    use FormatsCampusFixResponses;

    public function __construct(private readonly ReportImageStorage $imageStorage) {}

    public function index(Request $request)
    {
        $user = $request->user();
        $query = Report::query()
            ->with(['reporter', 'category', 'priority', 'status', 'notes.author'])
            ->latest('updated_at');

        $this->applyVisibility($query, $user);

        if ($search = trim((string) $request->query('search', ''))) {
            $query->where(function ($inner) use ($search) {
                $inner->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%")
                    ->orWhereHas('reporter', fn ($q) => $q->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('category', fn ($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        foreach (['status' => 'status', 'priority' => 'priority', 'category' => 'category'] as $param => $relation) {
            if ($value = $request->query($param)) {
                $query->whereHas($relation, fn ($q) => $q->where('name', $value));
            }
        }

        return response()->json([
            'reports' => $query->get()->map(fn (Report $report) => $this->reportPayload($report))->values(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate($this->reportRules());
        $user = $request->user();

        $report = Report::create([
            'external_id' => $this->nextExternalId(),
            'user_id' => $user->id,
            'category_id' => $this->categoryId($validated['category']),
            'priority_id' => $this->priorityId($validated['priority']),
            'status_id' => $this->statusId('Pending'),
            'title' => $validated['title'],
            'description' => $validated['description'],
            'location' => $validated['location'],
            'image_path' => $this->imageStorage->store(
                $validated['imagePath'] ?? null,
                'campusfix/problem-photos',
            ),
            'resolved_image_path' => $this->imageStorage->store(
                $validated['resolvedImagePath'] ?? null,
                'campusfix/resolution-photos',
            ),
            'is_validated_by_teacher' => $user->role === 'Teacher',
        ]);

        return response()->json(['report' => $this->reportPayload($report)], 201);
    }

    public function show(Request $request, Report $report)
    {
        abort_unless($this->canView($request->user(), $report), 403);

        return response()->json(['report' => $this->reportPayload($report)]);
    }

    public function update(Request $request, Report $report)
    {
        $user = $request->user();
        abort_unless($this->canView($user, $report), 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'required', 'string'],
            'category' => ['sometimes', 'required', Rule::exists('report_categories', 'name')],
            'location' => ['sometimes', 'required', 'string', 'max:255'],
            'priority' => ['sometimes', 'required', Rule::exists('report_priorities', 'name')],
            'status' => ['sometimes', 'required', Rule::exists('report_statuses', 'name')],
            'assignedTo' => ['sometimes', 'nullable', 'string', 'max:255'],
            'imagePath' => ['sometimes', 'nullable', 'string'],
            'resolvedImagePath' => ['sometimes', 'nullable', 'string'],
        ]);

        if (
            array_key_exists('status', $validated) ||
            array_key_exists('assignedTo', $validated) ||
            array_key_exists('resolvedImagePath', $validated)
        ) {
            abort_unless($user->role === 'Admin', 403, 'Only admins can update assignment and status.');
        }

        $updates = [];
        foreach (['title', 'description', 'location'] as $field) {
            if (array_key_exists($field, $validated)) {
                $updates[$field] = $validated[$field];
            }
        }
        if (array_key_exists('category', $validated)) {
            $updates['category_id'] = $this->categoryId($validated['category']);
        }
        if (array_key_exists('priority', $validated)) {
            $updates['priority_id'] = $this->priorityId($validated['priority']);
        }
        if (array_key_exists('status', $validated)) {
            $updates['status_id'] = $this->statusId($validated['status']);
            $report->notes()->create([
                'user_id' => $user->id,
                'message' => 'Status changed to '.$validated['status'].'.',
            ]);
        }
        if (array_key_exists('assignedTo', $validated)) {
            $updates['assigned_to'] = $validated['assignedTo'];
            if ($validated['assignedTo']) {
                $report->notes()->create([
                    'user_id' => $user->id,
                    'message' => 'Assigned to '.$validated['assignedTo'].'.',
                ]);
            }
        }
        if (array_key_exists('imagePath', $validated)) {
            $updates['image_path'] = $this->imageStorage->store(
                $validated['imagePath'],
                'campusfix/problem-photos',
            );
        }
        if (array_key_exists('resolvedImagePath', $validated)) {
            $updates['resolved_image_path'] = $this->imageStorage->store(
                $validated['resolvedImagePath'],
                'campusfix/resolution-photos',
            );
            if ($validated['resolvedImagePath']) {
                $report->notes()->create([
                    'user_id' => $user->id,
                    'message' => 'Resolution photo uploaded.',
                ]);
            }
        }

        $report->update($updates);

        return response()->json(['report' => $this->reportPayload($report->fresh())]);
    }

    public function destroy(Request $request, Report $report)
    {
        abort_unless($request->user()->role === 'Admin', 403, 'Only admins can delete reports.');
        $report->delete();

        return response()->json(['message' => 'Report deleted.']);
    }

    public function addNote(Request $request, Report $report)
    {
        $user = $request->user();
        abort_unless($this->canView($user, $report), 403);

        $validated = $request->validate([
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $note = $report->notes()->create([
            'user_id' => $user->id,
            'message' => $validated['message'],
        ]);

        return response()->json([
            'note' => $this->notePayload($note),
            'report' => $this->reportPayload($report->fresh()),
        ], 201);
    }

    public function validateByTeacher(Request $request, Report $report)
    {
        $user = $request->user();
        abort_unless(in_array($user->role, ['Teacher', 'Admin'], true), 403);
        abort_unless($this->canView($user, $report), 403);

        $report->update(['is_validated_by_teacher' => true]);
        $report->notes()->create([
            'user_id' => $user->id,
            'message' => 'Report validated by teacher.',
        ]);

        return response()->json(['report' => $this->reportPayload($report->fresh())]);
    }

    private function applyVisibility($query, $user): void
    {
        match ($user->role) {
            'Student' => $query->where('user_id', $user->id),
            'Teacher' => $query->where(fn ($q) => $q
                ->whereHas('reporter', fn ($userQuery) => $userQuery->where('role', 'Student'))
                ->orWhere('user_id', $user->id)),
            default => null,
        };
    }

    private function canView($user, Report $report): bool
    {
        if ($user->role === 'Admin') {
            return true;
        }
        if ($user->role === 'Teacher') {
            return $report->user_id === $user->id || $report->reporter?->role === 'Student';
        }

        return $report->user_id === $user->id;
    }

    private function reportRules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'category' => ['required', Rule::exists('report_categories', 'name')],
            'location' => ['required', 'string', 'max:255'],
            'priority' => ['required', Rule::exists('report_priorities', 'name')],
            'imagePath' => ['nullable', 'string'],
            'resolvedImagePath' => ['nullable', 'string'],
        ];
    }

    private function nextExternalId(): string
    {
        $next = (Report::max('id') ?? 0) + 1001;

        return 'CF-'.$next;
    }

    private function categoryId(string $name): int
    {
        return ReportCategory::where('name', $name)->value('id');
    }

    private function priorityId(string $name): int
    {
        return ReportPriority::where('name', $name)->value('id');
    }

    private function statusId(string $name): int
    {
        return ReportStatus::where('name', $name)->value('id');
    }
}
