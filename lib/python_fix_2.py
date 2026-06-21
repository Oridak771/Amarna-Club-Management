import os
import re

def fix_activity_detail(content):
    content = content.replace('activity.iconData', 'resolveActivityIcon(activity.iconKey)')
    content = content.replace('asset.statusColor', 'asset.status.resolveColor(context)')
    content = content.replace('ticket.statusColor', 'ticket.status.resolveColor(context)')
    content = content.replace('ticket.typeColor', 'ticket.type.resolveColor(context)')
    content = content.replace('AppColors.', 'context.colors.')
    return content

def fix_ticket_detail(content):
    content = content.replace('ticket.statusColor', 'ticket.status.resolveColor(context)')
    content = content.replace('ticket.typeColor', 'ticket.type.resolveColor(context)')
    return content

def main():
    base = r'c:\Users\H0017549\Desktop\Repos\Amarna-Club\lib\screens'
    
    act_path = os.path.join(base, 'activity_detail_screen.dart')
    if os.path.exists(act_path):
        with open(act_path, 'r', encoding='utf-8') as f:
            c = f.read()
        c = fix_activity_detail(c)
        with open(act_path, 'w', encoding='utf-8') as f:
            f.write(c)
            
    tic_path = os.path.join(base, 'ticket_detail_screen.dart')
    if os.path.exists(tic_path):
        with open(tic_path, 'r', encoding='utf-8') as f:
            c = f.read()
        c = fix_ticket_detail(c)
        with open(tic_path, 'w', encoding='utf-8') as f:
            f.write(c)
            
if __name__ == '__main__':
    main()
