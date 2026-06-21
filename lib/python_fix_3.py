import os

def fix_activity(c):
    c = c.replace('Widget _buildTimeline(Activity activity)', 'Widget _buildTimeline(BuildContext context, Activity activity)')
    c = c.replace('_buildTimeline(activity)', '_buildTimeline(context, activity)')
    c = c.replace('Widget _buildActionSection(Activity activity)', 'Widget _buildActionSection(BuildContext context, Activity activity)')
    c = c.replace('_buildActionSection(activity)', '_buildActionSection(context, activity)')
    c = c.replace('Widget _buildActionButton(String title,', 'Widget _buildActionButton(BuildContext context, String title,')
    c = c.replace('Widget _buildActionButton(\n      String title,', 'Widget _buildActionButton(BuildContext context,\n      String title,')
    c = c.replace('_buildActionButton(\'Ouvrir', '_buildActionButton(context, \'Ouvrir')
    c = c.replace('_buildActionButton(\n                        \'Fermer', '_buildActionButton(context,\n                        \'Fermer')
    return c

def fix_ticket(c):
    c = c.replace('Widget _buildTypeBadge(WorkTicket ticket)', 'Widget _buildTypeBadge(BuildContext context, WorkTicket ticket)')
    c = c.replace('_buildTypeBadge(ticket)', '_buildTypeBadge(context, ticket)')
    c = c.replace('Widget _buildStatusBadge(WorkTicket ticket)', 'Widget _buildStatusBadge(BuildContext context, WorkTicket ticket)')
    c = c.replace('_buildStatusBadge(ticket)', '_buildStatusBadge(context, ticket)')
    c = c.replace('Widget _buildTimeline(WorkTicket ticket)', 'Widget _buildTimeline(BuildContext context, WorkTicket ticket)')
    c = c.replace('_buildTimeline(ticket)', '_buildTimeline(context, ticket)')
    c = c.replace('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({required BuildContext context, ')
    c = c.replace('_buildTimelineItem(\n            title:', '_buildTimelineItem(\ncontext: context,\ntitle:')
    c = c.replace('context: context, context: context,', 'context: context,')
    return c

def fix_onboarding(c):
    return c.replace('final List<Map<String, dynamic>> _pages = [', 'List<Map<String, dynamic>> get _pages => [')

def fix_timeline(c):
    c = c.replace('AppColors.', 'Theme.of(context).extension<AppSemanticColors>()!.')
    c = c.replace('const TextStyle', 'TextStyle')
    c = c.replace('const Icon', 'Icon')
    return c

def fix_file(p, f):
    if os.path.exists(p):
        with open(p, 'r', encoding='utf-8') as file:
            c = file.read()
        new_c = f(c)
        if c != new_c:
            with open(p, 'w', encoding='utf-8') as file:
                file.write(new_c)

base = r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib'
fix_file(os.path.join(base, 'screens', 'activity_detail_screen.dart'), fix_activity)
fix_file(os.path.join(base, 'screens', 'ticket_detail_screen.dart'), fix_ticket)
fix_file(os.path.join(base, 'screens', 'onboarding_screen.dart'), fix_onboarding)
fix_file(os.path.join(base, 'widgets', 'timeline_item.dart'), fix_timeline)
