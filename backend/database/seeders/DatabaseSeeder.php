<?php

namespace Database\Seeders;

use App\Models\Report;
use App\Models\ReportCategory;
use App\Models\ReportPriority;
use App\Models\ReportStatus;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $categories = [
            'Facility' => 'Buildings, rooms, chairs, and school fixtures.',
            'IT Concern' => 'Network, accounts, projectors, and devices.',
            'Classroom' => 'Teaching spaces and classroom equipment.',
            'Comfort Room' => 'Restroom fixtures and sanitation concerns.',
            'Lost and Found' => 'Lost IDs, bags, and recovered items.',
            'Clinic' => 'Clinic supplies and health support.',
            'Maintenance' => 'Repairs, cleaning, electrical, and utility work.',
            'Other' => 'Reports outside the standard categories.',
        ];

        foreach ($categories as $name => $description) {
            ReportCategory::updateOrCreate(
                ['name' => $name],
                ['description' => $description],
            );
        }

        foreach (['Low' => 1, 'Medium' => 2, 'High' => 3, 'Urgent' => 4] as $name => $weight) {
            ReportPriority::updateOrCreate(['name' => $name], ['weight' => $weight]);
        }

        foreach (['Pending' => 1, 'Reviewed' => 2, 'In Progress' => 3, 'Resolved' => 4, 'Rejected' => 5] as $name => $sortOrder) {
            ReportStatus::updateOrCreate(['name' => $name], ['sort_order' => $sortOrder]);
        }

        $student = User::updateOrCreate(
            ['email' => 'student@campusfix.app'],
            [
                'name' => 'Juan Dela Cruz',
                'password' => 'student123',
                'role' => 'Student',
                'department' => 'Computer Studies',
                'avatar_text' => 'JD',
                'is_active' => true,
            ],
        );

        $teacher = User::updateOrCreate(
            ['email' => 'teacher@campusfix.app'],
            [
                'name' => 'Maria Santos',
                'password' => 'teacher123',
                'role' => 'Teacher',
                'department' => 'General Education',
                'avatar_text' => 'MS',
                'is_active' => true,
            ],
        );

        $admin = User::updateOrCreate(
            ['email' => 'admin@campusfix.app'],
            [
                'name' => 'Admin User',
                'password' => 'admin123',
                'role' => 'Admin',
                'department' => 'Campus Administration',
                'avatar_text' => 'AU',
                'is_active' => true,
            ],
        );

        $samples = [
            [
                'external_id' => 'CF-1001',
                'user' => $student,
                'category' => 'Classroom',
                'priority' => 'Medium',
                'status' => 'Pending',
                'title' => 'Broken classroom chair',
                'description' => 'One chair in Room 204 has a loose backrest and may injure students.',
                'location' => 'Room 204, Main Building',
                'validated' => false,
            ],
            [
                'external_id' => 'CF-1002',
                'user' => $teacher,
                'category' => 'IT Concern',
                'priority' => 'High',
                'status' => 'In Progress',
                'title' => 'Projector not working',
                'description' => 'The projector in the AVR powers on but does not display laptop input.',
                'location' => 'AVR 1',
                'validated' => true,
                'assigned_to' => 'IT Support Team',
            ],
            [
                'external_id' => 'CF-1003',
                'user' => $student,
                'category' => 'Comfort Room',
                'priority' => 'Urgent',
                'status' => 'Reviewed',
                'title' => 'Comfort room faucet leaking',
                'description' => 'The faucet has been leaking continuously since morning.',
                'location' => 'Ground Floor Comfort Room',
                'validated' => true,
            ],
            [
                'external_id' => 'CF-1004',
                'user' => $student,
                'category' => 'Lost and Found',
                'priority' => 'Low',
                'status' => 'Resolved',
                'title' => 'Lost ID card',
                'description' => 'Student ID was lost near the cafeteria and reported to the guard.',
                'location' => 'Cafeteria Entrance',
                'validated' => true,
            ],
            [
                'external_id' => 'CF-1005',
                'user' => $teacher,
                'category' => 'Clinic',
                'priority' => 'Medium',
                'status' => 'Pending',
                'title' => 'Clinic medicine request',
                'description' => 'Clinic needs replenishment of basic headache and fever medicine.',
                'location' => 'School Clinic',
                'validated' => true,
            ],
            [
                'external_id' => 'CF-1006',
                'user' => $student,
                'category' => 'IT Concern',
                'priority' => 'High',
                'status' => 'In Progress',
                'title' => 'WiFi connection issue',
                'description' => 'Students cannot connect to campus WiFi from the computer lab.',
                'location' => 'Computer Lab 2',
                'validated' => true,
                'assigned_to' => 'Network Administrator',
            ],
            [
                'external_id' => 'CF-1007',
                'user' => $teacher,
                'category' => 'Maintenance',
                'priority' => 'High',
                'status' => 'Reviewed',
                'title' => 'Ceiling fan not working',
                'description' => 'The ceiling fan makes noise and stopped spinning during class.',
                'location' => 'Room 301',
                'validated' => true,
            ],
            [
                'external_id' => 'CF-1008',
                'user' => $student,
                'category' => 'Facility',
                'priority' => 'Urgent',
                'status' => 'Pending',
                'title' => 'Trash bin overflow',
                'description' => 'Trash bins outside the library are full and need immediate cleanup.',
                'location' => 'Library Walkway',
                'validated' => false,
            ],
        ];

        foreach ($samples as $sample) {
            $report = Report::updateOrCreate(
                ['external_id' => $sample['external_id']],
                [
                    'user_id' => $sample['user']->id,
                    'category_id' => ReportCategory::where('name', $sample['category'])->value('id'),
                    'priority_id' => ReportPriority::where('name', $sample['priority'])->value('id'),
                    'status_id' => ReportStatus::where('name', $sample['status'])->value('id'),
                    'title' => $sample['title'],
                    'description' => $sample['description'],
                    'location' => $sample['location'],
                    'is_validated_by_teacher' => $sample['validated'],
                    'assigned_to' => $sample['assigned_to'] ?? null,
                ],
            );

            if ($report->notes()->doesntExist()) {
                $report->notes()->create([
                    'user_id' => $admin->id,
                    'message' => 'Seeded prototype report for demo tracking.',
                ]);
            }
        }
    }
}
