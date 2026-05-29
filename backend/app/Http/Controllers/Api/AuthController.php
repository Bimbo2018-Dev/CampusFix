<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\FormatsCampusFixResponses;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use FormatsCampusFixResponses;

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'min:3', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
            'role' => ['required', Rule::in(['Student', 'Teacher', 'Admin'])],
            'department' => ['required', 'string', 'max:255'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => mb_strtolower($validated['email']),
            'password' => $validated['password'],
            'role' => $validated['role'],
            'department' => $validated['department'],
            'avatar_text' => $this->initials($validated['name']),
        ]);

        return response()->json($this->authPayload($user), 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'role' => ['required', Rule::in(['Student', 'Teacher', 'Admin'])],
        ]);

        $user = User::where('email', mb_strtolower($validated['email']))->first();
        if (! $user || ! Hash::check($validated['password'], $user->password) || $user->role !== $validated['role']) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials for the selected role.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'email' => ['This account is deactivated. Contact the campus admin.'],
            ]);
        }

        return response()->json($this->authPayload($user));
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request)
    {
        return response()->json(['user' => $this->userPayload($request->user())]);
    }

    private function authPayload(User $user): array
    {
        $token = $user->createToken('campusfix-'.$user->role)->plainTextToken;

        return [
            'token' => $token,
            'user' => $this->userPayload($user),
        ];
    }
}
