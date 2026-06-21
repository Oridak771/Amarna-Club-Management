import os
import re

def fix_file(filepath, fix_func):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = fix_func(content)
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

def fix_main_nav(content):
    return content.replace('const PlusMenuScreen()', 'PlusMenuScreen()')

def fix_onboarding(content):
    return content.replace('final List<Map<String, dynamic>> _pages = [', 'List<Map<String, dynamic>> get _pages => [')

def fix_ticket_detail(content):
    # Fix the method signature properly
    content = re.sub(r'Widget _buildTimelineItem\(\{\s*(?:required\s+BuildContext\s+context,\s*)+', 'Widget _buildTimelineItem({required BuildContext context, ', content)
    content = content.replace('Widget _buildTimelineItem({required String title,', 'Widget _buildTimelineItem({required BuildContext context, required String title,')
    
    # Fix missing context in calls
    content = re.sub(r'_buildTimelineItem\(\s*title:', '_buildTimelineItem(\ncontext: context,\ntitle:', content)
    content = re.sub(r'context: context,\s*context: context,', 'context: context,', content)
    
    return content

def fix_activity_detail(content):
    # Add context to method definitions
    content = content.replace('Widget _buildTimeline(Activity activity)', 'Widget _buildTimeline(BuildContext context, Activity activity)')
    content = content.replace('Widget _buildActionSection(Activity activity)', 'Widget _buildActionSection(BuildContext context, Activity activity)')
    content = content.replace('Widget _buildActionButton(String title,', 'Widget _buildActionButton(BuildContext context, String title,')
    content = content.replace('Widget _buildActionButton(\n      String title,', 'Widget _buildActionButton(BuildContext context,\n      String title,')
    content = content.replace('Widget _buildTimelineItem({', 'Widget _buildTimelineItem({required BuildContext context, ')
    
    # Add context to method calls
    content = content.replace('_buildTimeline(activity)', '_buildTimeline(context, activity)')
    content = content.replace('_buildActionSection(activity)', '_buildActionSection(context, activity)')
    content = content.replace("_buildActionButton('Ouvrir", "_buildActionButton(context, 'Ouvrir")
    content = content.replace("_buildActionButton(\n                        'Fermer", "_buildActionButton(context,\n                        'Fermer")
    
    content = re.sub(r'_buildTimelineItem\(\s*title:', '_buildTimelineItem(\ncontext: context,\ntitle:', content)
    content = re.sub(r'context: context,\s*context: context,', 'context: context,', content)
    return content

def fix_gauge_card(content):
    content = content.replace('Widget _buildStatusIndicator(String label,', 'Widget _buildStatusIndicator(BuildContext context, String label,')
    content = content.replace("_buildStatusIndicator('PH',", "_buildStatusIndicator(context, 'PH',")
    content = content.replace("_buildStatusIndicator('Chlore',", "_buildStatusIndicator(context, 'Chlore',")
    content = content.replace("_buildStatusIndicator('Temp.',", "_buildStatusIndicator(context, 'Temp.',")
    return content

def main():
    base = r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib'
    fix_file(os.path.join(base, 'screens', 'main_navigation_shell.dart'), fix_main_nav)
    fix_file(os.path.join(base, 'screens', 'onboarding_screen.dart'), fix_onboarding)
    fix_file(os.path.join(base, 'screens', 'ticket_detail_screen.dart'), fix_ticket_detail)
    fix_file(os.path.join(base, 'screens', 'activity_detail_screen.dart'), fix_activity_detail)
    fix_file(os.path.join(base, 'widgets', 'gauge_card.dart'), fix_gauge_card)

if __name__ == '__main__':
    main()
