/**
 * seed_games.js
 *
 * One-time script to seed the Firestore `games` catalogue and `game_content`
 * collections with initial data that matches the app's offline fallback.
 *
 * Usage (from the family-workbook/ directory):
 *   node functions/scripts/seed_games.js
 *
 * Prerequisites:
 *   1. Install the admin SDK locally:
 *      npm install firebase-admin --prefix functions/scripts
 *   2. Download your Firebase service account key:
 *      Firebase Console → Project Settings → Service accounts → Generate new private key
 *      Save it as: functions/scripts/serviceAccountKey.json
 *   3. Run:
 *      node functions/scripts/seed_games.js
 *
 * Re-running this script is safe — it uses `set({ merge: true })` so it only
 * updates fields without wiping any data you may have added manually.
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();

// ── Game Catalogue (`games` collection) ────────────────────────────────────
const games = [
  {
    id: 'trivia',
    data: {
      title: 'Family Wisdom Quiz',
      description: 'Multiple choice trivia about communication and values.',
      icon: 'quiz',
      color: '#00897B',
      type: 'trivia',
      isActive: true,
      order: 1,
    },
  },
  {
    id: 'matching',
    data: {
      title: 'Values Matching Game',
      description: 'A fun memory card matchup focusing on core values.',
      icon: 'grid_view',
      color: '#9C27B0',
      type: 'matching',
      isActive: true,
      order: 2,
    },
  },
  {
    id: 'conversations',
    data: {
      title: 'Conversation Starters',
      description: 'A deck of meaningful, fun prompts for the dinner table.',
      icon: 'forum',
      color: '#E91E8C',
      type: 'conversations',
      isActive: true,
      order: 3,
    },
  },
];

// ── Game Content (`game_content` collection) ───────────────────────────────
const gameContent = [
  {
    id: 'trivia',
    data: {
      questions: [
        {
          question: 'Which of these is a core key to building family trust?',
          options: [
            'Active listening & honesty',
            'Buying expensive gifts',
            'Avoiding conversation',
            'Ignoring household rules',
          ],
          answerIndex: 0,
        },
        {
          question: 'What is the primary purpose of a Family Charter?',
          options: [
            'To track daily chores only',
            'To define shared values and structure',
            'To assign homework punishments',
            'To list family recipes',
          ],
          answerIndex: 1,
        },
        {
          question:
            'How should conflicts be addressed in a healthy family structure?',
          options: [
            'Silent treatment',
            'Shouting at each other',
            'Respectful dialogue and seeking common ground',
            'Pretending nothing happened',
          ],
          answerIndex: 2,
        },
        {
          question:
            'Which of the following is NOT one of the 8 weekly modules?',
          options: [
            'Boundaries & Safety',
            'Roles of Children',
            'Family Identity & Structure',
            'Advanced Cooking Skills',
          ],
          answerIndex: 3,
        },
        {
          question: 'How often should a family hold family governance meetings?',
          options: [
            'Once a year',
            'Regularly (e.g. weekly or monthly)',
            'Only during crises',
            'Never',
          ],
          answerIndex: 1,
        },
      ],
    },
  },
  {
    id: 'matching',
    data: {
      values: [
        'Love 💖',
        'Trust 🤝',
        'Safety 🛡️',
        'Respect 🙌',
        'Fun 🎉',
        'Unity 🧩',
      ],
    },
  },
  {
    id: 'conversations',
    data: {
      cards: [
        'What is your absolute favorite memory of our family doing something together?',
        'If our family had a theme song or motto, what would you want it to be?',
        'What is one thing you appreciate most about the person sitting next to you?',
        'If you could travel anywhere in the world with the family tomorrow, where would you go?',
        'What is a family tradition you want to make sure we keep doing forever?',
        'What is one value you think is most important for our household?',
        'If you could trade places with any other family member for one day, who would it be and why?',
        'What was the most challenging part of your week, and how did you overcome it?',
      ],
    },
  },
];

// ── Seed ───────────────────────────────────────────────────────────────────
async function seed() {
  console.log('🌱 Seeding Firestore games data...\n');

  // Seed game catalogue
  for (const game of games) {
    await db.collection('games').doc(game.id).set(game.data, { merge: true });
    console.log(`  ✅ games/${game.id}`);
  }

  // Seed game content
  for (const content of gameContent) {
    await db
      .collection('game_content')
      .doc(content.id)
      .set(content.data, { merge: true });
    console.log(`  ✅ game_content/${content.id}`);
  }

  console.log('\n✨ Seeding complete!');
  console.log('\n📋 How to add a new game:');
  console.log('  1. Add a document to `games` with: title, description,');
  console.log('     icon, color (hex), type, isActive, order');
  console.log('  2. Add a document to `game_content` with the same id and');
  console.log('     its content fields (questions / values / cards)');
  console.log(
    '  3. If the type is new, add a case to _buildSubPage() in home_screen.dart'
  );
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
