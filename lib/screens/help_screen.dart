import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final faqs = [
      _FAQ(
        question: 'Mes données sont-elles synchronisées avec Odoo ?',
        answer:
            'Oui. Les tickets et réservations créés depuis la tablette sont envoyés directement au serveur Odoo du club. En cas d\'erreur réseau ponctuelle, la donnée reste visible localement et sera renvoyée lors de la prochaine modification.',
      ),
      _FAQ(
        question: 'Comment scanner un équipement ?',
        answer:
            'Appuyez sur l\'icône de scanner photo (en haut à droite de la plupart des écrans). Cadrez le code QR de la machine ou de la pièce. Si votre appareil photo présente un dysfonctionnement, utilisez le bouton "Saisir le code manuellement" pour insérer le code d\'identification de l\'équipement.',
      ),
      _FAQ(
        question: 'Que faire en cas d\'incident critique ?',
        answer:
            'Pour tout incident critique (danger immédiat, blessure grave, défaillance technique majeure), créez immédiatement un ticket via le bouton "Créer un ticket" de l\'onglet Tickets. Marquez la priorité comme "Critique". Cela affichera une alerte clignotante rouge sur le tableau de bord de tous les managers.',
      ),
      _FAQ(
        question: 'Comment suivre l\'état d\'une activité ?',
        answer:
            'Allez dans l\'onglet "Activités" et choisissez l\'activité concernée. Vous y trouvez l\'occupation en temps réel, les sessions réservées du jour, l\'inventaire, les équipements et les interventions ouvertes. Chaque module (piscine, écurie, stand de tir…) propose en plus ses indicateurs spécifiques.',
      ),
      _FAQ(
        question: 'Où trouver les rapports de statistiques ?',
        answer:
            'Les rapports détaillés de maintenance et d\'incidents sont réservés aux superviseurs et directeurs. Ils se trouvent dans l\'onglet "Plus" -> "Rapports". Si vous n\'avez pas les droits requis, cette option n\'apparaît pas dans votre menu.',
      ),
    ];

    return AppPage(
      title: 'Aide & FAQ',
      subtitle: 'Guide d\'utilisation et support',
      maxWidth: 800,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Support card
          AppPanel(
            padding: const EdgeInsets.all(20),
            color: colors.accentPrimary.withValues(alpha: 0.07),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      color: colors.accentPrimary, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'Besoin d\'une assistance directe ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notre équipe de support technique est disponible pour résoudre vos problèmes opérationnels de 8h à 20h.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          foregroundColor: colors.textOnAccent,
                          minimumSize: const Size(0, 52),
                        ),
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('Appeler',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: () {
                          // Action simulation
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                          minimumSize: const Size(0, 52),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('E-mail',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: () {
                          // Action simulation
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. FAQ
          const SectionTitle(
            title: 'Foire aux questions',
            icon: Icons.quiz_outlined,
          ),
          for (final faq in faqs) ...[
            AppPanel(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  iconColor: colors.accentPrimary,
                  collapsedIconColor: colors.textSecondary,
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerLeft,
                  children: [
                    Text(
                      faq.answer,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;

  _FAQ({required this.question, required this.answer});
}
