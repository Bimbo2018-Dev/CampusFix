<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\FormatsCampusFixResponses;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    use FormatsCampusFixResponses;

    public function index(Request $request)
    {
        abort_unless($request->user()->role === 'Admin', 403, 'Only admins can view users.');

        return response()->json([
            'users' => User::orderBy('role')
                ->orderBy('name')
                ->get()
                ->map(fn (User $user) => $this->userPayload($user))
                ->values(),
        ]);
    }

    public function update(Request $request, User $user)
    {
        $admin = $request->user();
        abort_unless($admin->role === 'Admin', 403, 'Only admins can update users.');

        $validated = $request->validate([
            'role' => ['sometimes', 'required', Rule::in(['Student', 'Teacher', 'Admin'])],
            'department' => ['sometimes', 'required', 'string', 'max:255'],
            'isActive' => ['sometimes', 'required', 'boolean'],
        ]);

        if ((int) $admin->id === (int) $user->id && ($validated['isActive'] ?? true) === false) {
            abort(422, 'Admins cannot deactivate their own account.');
        }

        $updates = [];
        if (array_key_exists('role', $validated)) {
            $updates['role'] = $validated['role'];
        }
        if (array_key_exists('department', $validated)) {
            $updates['department'] = $validated['department'];
        }
        if (array_key_exists('isActive', $validated)) {
            $updates['is_active'] = $validated['isActive'];
        }

        $user->update($updates);

        return response()->json(['user' => $this->userPayload($user->fresh())]);
    }
}
