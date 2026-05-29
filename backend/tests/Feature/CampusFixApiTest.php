<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CampusFixApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_login_and_view_seeded_reports(): void
    {
        $this->seed();

        $login = $this->postJson('/api/auth/login', [
            'email' => 'admin@campusfix.app',
            'password' => 'admin123',
            'role' => 'Admin',
        ]);

        $login->assertOk()
            ->assertJsonPath('user.email', 'admin@campusfix.app')
            ->assertJsonPath('user.role', 'Admin')
            ->assertJsonStructure(['token']);

        $this->withToken($login->json('token'))
            ->getJson('/api/reports')
            ->assertOk()
            ->assertJsonCount(8, 'reports');
    }

    public function test_student_can_create_report_through_api(): void
    {
        $this->seed();

        $login = $this->postJson('/api/auth/login', [
            'email' => 'student@campusfix.app',
            'password' => 'student123',
            'role' => 'Student',
        ]);

        $this->withToken($login->json('token'))
            ->postJson('/api/reports', [
                'title' => 'Loose whiteboard mount',
                'description' => 'The whiteboard bracket is loose after class.',
                'category' => 'Classroom',
                'location' => 'Room 105',
                'priority' => 'Medium',
            ])
            ->assertCreated()
            ->assertJsonPath('report.title', 'Loose whiteboard mount')
            ->assertJsonPath('report.status', 'Pending');
    }

    public function test_duplicate_active_report_returns_existing_report(): void
    {
        $this->seed();

        $login = $this->postJson('/api/auth/login', [
            'email' => 'student@campusfix.app',
            'password' => 'student123',
            'role' => 'Student',
        ]);

        $payload = [
            'title' => 'Duplicate projector issue',
            'description' => 'The projector still shows no display.',
            'category' => 'Classroom',
            'location' => 'Room 204',
            'priority' => 'Urgent',
        ];

        $first = $this->withToken($login->json('token'))
            ->postJson('/api/reports', $payload)
            ->assertCreated()
            ->json('report.id');

        $this->withToken($login->json('token'))
            ->postJson('/api/reports', $payload)
            ->assertOk()
            ->assertJsonPath('duplicate', true)
            ->assertJsonPath('report.id', $first);

        $this->assertDatabaseCount('reports', 9);
    }

    public function test_teacher_can_validate_student_report(): void
    {
        $this->seed();

        $login = $this->postJson('/api/auth/login', [
            'email' => 'teacher@campusfix.app',
            'password' => 'teacher123',
            'role' => 'Teacher',
        ]);

        $this->withToken($login->json('token'))
            ->postJson('/api/reports/CF-1001/validate')
            ->assertOk()
            ->assertJsonPath('report.isValidatedByTeacher', true);
    }

    public function test_admin_can_see_new_registered_accounts_and_their_reports(): void
    {
        $this->seed();

        $registration = $this->postJson('/api/auth/register', [
            'name' => 'Bimbo Reyes',
            'email' => 'bimbo.reyes@campusfix.app',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'role' => 'Student',
            'department' => 'Computer Studies',
        ]);

        $registration->assertCreated()
            ->assertJsonPath('user.email', 'bimbo.reyes@campusfix.app')
            ->assertJsonPath('user.role', 'Student');

        $this->withToken($registration->json('token'))
            ->postJson('/api/reports', [
                'title' => 'New account submitted report',
                'description' => 'This report confirms that new registered users can submit reports.',
                'category' => 'Facility',
                'location' => 'Testing Room',
                'priority' => 'Low',
                'imagePath' => 'data:image/jpeg;base64,'.base64_encode('campusfix-test-image'),
            ])
            ->assertCreated()
            ->assertJsonPath('report.reporterName', 'Bimbo Reyes')
            ->assertJsonPath('report.imagePath', 'data:image/jpeg;base64,'.base64_encode('campusfix-test-image'));

        $this->flushHeaders();

        Sanctum::actingAs(User::where('email', 'admin@campusfix.app')->first());

        $this->getJson('/api/users')
            ->assertOk()
            ->assertJsonFragment(['email' => 'bimbo.reyes@campusfix.app']);

        $this->getJson('/api/reports')
            ->assertOk()
            ->assertJsonFragment(['title' => 'New account submitted report']);
    }

    public function test_admin_can_assign_resolve_with_photo_and_deactivate_user(): void
    {
        $this->seed();

        Sanctum::actingAs(User::where('email', 'admin@campusfix.app')->first());

        $resolutionPhoto = 'data:image/jpeg;base64,'.base64_encode('fixed-photo');

        $this->patchJson('/api/reports/CF-1001', [
            'assignedTo' => 'Maintenance Team',
            'status' => 'Resolved',
            'resolvedImagePath' => $resolutionPhoto,
        ])
            ->assertOk()
            ->assertJsonPath('report.assignedTo', 'Maintenance Team')
            ->assertJsonPath('report.status', 'Resolved')
            ->assertJsonPath('report.resolvedImagePath', $resolutionPhoto);

        $student = User::where('email', 'student@campusfix.app')->first();

        $this->patchJson('/api/users/'.$student->id, [
            'isActive' => false,
        ])
            ->assertOk()
            ->assertJsonPath('user.isActive', false);

        $this->postJson('/api/auth/login', [
            'email' => 'student@campusfix.app',
            'password' => 'student123',
            'role' => 'Student',
        ])->assertUnprocessable();
    }

    public function test_cloudinary_driver_uploads_report_photos_and_returns_url(): void
    {
        $this->seed();

        config([
            'services.campusfix.image_driver' => 'cloudinary',
            'services.cloudinary.cloud_name' => 'campusfix-demo',
            'services.cloudinary.api_key' => 'demo-key',
            'services.cloudinary.api_secret' => 'demo-secret',
        ]);

        Http::fake([
            'api.cloudinary.com/*' => Http::response([
                'secure_url' => 'https://res.cloudinary.com/campusfix-demo/image/upload/v1/campusfix/problem-photos/sample.jpg',
            ]),
        ]);

        Sanctum::actingAs(User::where('email', 'student@campusfix.app')->first());

        $this->postJson('/api/reports', [
            'title' => 'Cloudinary photo test',
            'description' => 'This verifies cloud image storage for deployment.',
            'category' => 'Facility',
            'location' => 'Room 101',
            'priority' => 'Low',
            'imagePath' => 'data:image/jpeg;base64,'.base64_encode('photo-bytes'),
        ])
            ->assertCreated()
            ->assertJsonPath(
                'report.imagePath',
                'https://res.cloudinary.com/campusfix-demo/image/upload/v1/campusfix/problem-photos/sample.jpg',
            );

        Http::assertSent(fn ($request) => str_contains($request->url(), 'api.cloudinary.com/v1_1/campusfix-demo/image/upload'));
    }
}
