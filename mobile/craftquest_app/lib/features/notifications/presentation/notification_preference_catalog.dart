/// Notification types that support an email channel when the user enables it.
const emailEligibleNotificationTypes = <String>{
  'quiz_shared',
  'class_joined',
  'assignment_created',
  'assignment_due_soon',
  'ai_job_completed',
  'ai_job_failed',
  'membership_expiring',
  'membership_expired',
};

class NotificationPreferenceSection {
  const NotificationPreferenceSection({
    required this.titleKey,
    required this.types,
  });

  final String titleKey;
  final List<String> types;
}

const notificationPreferenceSections = <NotificationPreferenceSection>[
  NotificationPreferenceSection(
    titleKey: 'sharing',
    types: ['quiz_shared', 'class_joined'],
  ),
  NotificationPreferenceSection(
    titleKey: 'assignments',
    types: ['assignment_created', 'assignment_due_soon'],
  ),
  NotificationPreferenceSection(
    titleKey: 'membership',
    types: ['membership_expiring', 'membership_expired'],
  ),
  NotificationPreferenceSection(
    titleKey: 'ai',
    types: ['ai_job_completed', 'ai_job_failed'],
  ),
];
