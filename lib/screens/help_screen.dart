import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FAQ(
        question: 'Comment fonctionne le mode hors-ligne ?',
        answer:
            'L\'application stocke localement toutes vos modifications (tickets créés, relevés de piscine, checklist cochées). Dès que votre appareil détecte du réseau, les données sont synchronisées automatiquement. Vous pouvez suivre l\'état des fichiers en attente ou forcer une synchronisation dans le menu "Plus" -> "Mode hors-ligne".',
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
        question: 'Comment valider le contrôle quotidien d\'une activité ?',
        answer:
            'Allez dans l\'onglet "Activités", choisissez l\'activité concernée, et appuyez sur le bouton "Lancer le contrôle". Répondez aux points requis en swipant les cartes (Droite pour Validé, Gauche pour Problème). Validez à la fin pour enregistrer le rapport.',
      ),
      _FAQ(
        question: 'Où trouver les rapports de statistiques ?',
        answer:
            'Les rapports détaillés de maintenance et d\'incidents sont réservés aux superviseurs et directeurs. Ils se trouvent dans l\'onglet "Plus" -> "Rapports". Si vous n\'avez pas les droits requis, cette option n\'apparaît pas dans votre menu.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Aide & FAQ'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Support Banner Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colors.accentPrimary.withValues(alpha: 0.15),
                        context.colors.accentSecondary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: context.colors.accentPrimary.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.help_center_outlined,
                          color: context.colors.accentPrimary, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Besoin d\'une assistance directe ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Notre équipe de support technique est disponible pour résoudre vos problèmes opérationnels de 8h à 20h.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Support actions (glove-friendly size)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.accentPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.phone),
                                label: Text('Appeler',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  // Action simulation
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side:
                                      BorderSide(color: context.colors.border),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.mail_outline,
                                    color: context.colors.textPrimary),
                                label: Text('Email',
                                    style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  // Action simulation
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28),

                // 2. FAQ Section Header
                Text(
                  'Foire Aux Questions (FAQ)',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),

                // 3. Expandable FAQ Accordion Cards
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: ExpansionTile(
                          iconColor: context.colors.accentPrimary,
                          collapsedIconColor: context.colors.textSecondary,
                          title: Text(
                            faq.question,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                faq.answer,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;

  _FAQ({required this.question, required this.answer});
}
