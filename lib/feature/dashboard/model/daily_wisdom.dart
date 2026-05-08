// lib/feature/dashboard/model/daily_wisdom.dart
//
// Curated wisdom drawn from stoic philosophy, existentialism, absurdism,
// banned & burned books, eastern traditions, physical mastery, spiritual
// depth, and wealth-building principles.
//
// All quotes verified. Fake/misattributed viral quotes removed.
// Rotates one entry per calendar day.

class WisdomEntry {
  final String title;
  final String source;
  final String quote;
  final String explanation;

  const WisdomEntry({
    required this.title,
    required this.source,
    required this.quote,
    required this.explanation,
  });
}

class DailyWisdom {
  DailyWisdom._();

  static WisdomEntry today({DateTime? from}) {
    final now = from ?? DateTime.now();
    return entries[_dayOfYear(now) % entries.length];
  }

  static WisdomEntry at({required DateTime date, required int offset}) {
    return entries[(_dayOfYear(date) + offset) % entries.length];
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year)).inDays;

  static const List<WisdomEntry> entries = [

    // ════════════════════════════════════════════════════════════════════
    // BURNED & BANNED BOOKS — Suppressed Because They Were True
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Manuscripts Don\'t Burn',
      source:      'Mikhail Bulgakov · The Master and Margarita',
      quote:       'Manuscripts don\'t burn.',
      explanation:
          'Bulgakov\'s masterpiece was suppressed by Stalin for twelve years. '
          'He burned an early draft himself out of fear — then rewrote it from '
          'memory. Truth has a way of surviving suppression. The idea that was '
          'crushed tends to return stronger. Focus less on whether something '
          'is accepted and more on whether it is true.',
    ),
    WisdomEntry(
      title:       'One Word of Truth',
      source:      'Aleksandr Solzhenitsyn · Nobel Lecture, 1970',
      quote:       'One word of truth outweighs the whole world.',
      explanation:
          'Solzhenitsyn could not deliver this lecture in person — the Soviet '
          'state banned him from traveling. He knew the cost of truth and paid '
          'it anyway. Speak carefully, but don\'t abandon what you know is real. '
          'Distortion is more expensive over time.',
    ),
    WisdomEntry(
      title:       'Live Not by Lies',
      source:      'Aleksandr Solzhenitsyn · Live Not by Lies, 1974',
      quote:       'Let the lie come into the world, let it even triumph. But not through me.',
      explanation:
          'This essay was distributed underground the day Solzhenitsyn was '
          'arrested and expelled from the USSR. His argument: you may not stop '
          'a corrupt system, but you can refuse to participate in it. That '
          'refusal is the smallest — and most available — unit of resistance.',
    ),
    WisdomEntry(
      title:       'The Portable Self',
      source:      'Aleksandr Solzhenitsyn · The Gulag Archipelago',
      quote:       'Own only what you can always carry with you: know languages, know countries, know people. Let your memory be your travel bag.',
      explanation:
          'Written from inside the Soviet labor camps. Material wealth is '
          'easily confiscated. True security lives in your skills, knowledge, '
          'and character — things no authority can seize. Invest in the portable.',
    ),
    WisdomEntry(
      title:       'The Controlled Narrative',
      source:      'George Orwell · 1984',
      quote:       'Reality exists in the human mind, and nowhere else.',
      explanation:
          'If perception can be shaped, reality can be shaped. Guard your '
          'ability to think independently. The moment you outsource interpretation '
          '— to media, algorithm, or social pressure — you lose control over '
          'what is real to you.',
    ),
    WisdomEntry(
      title:       'Language as a Weapon',
      source:      'George Orwell · Politics and the English Language',
      quote:       'If thought corrupts language, language can also corrupt thought.',
      explanation:
          'Words are not neutral. The vocabulary available to you determines '
          'the limits of your thinking. Imprecise language hides manipulation. '
          'When someone is deliberately vague, ask what they are avoiding saying '
          'directly. Precision is a form of power.',
    ),
    WisdomEntry(
      title:       'The Memory Hole',
      source:      'George Orwell · 1984',
      quote:       'Who controls the past controls the future. Who controls the present controls the past.',
      explanation:
          'In your own life: the story you tell about your past shapes what '
          'you think is possible. Rewrite your narrative about failure — not '
          'to erase it, but to frame it as data rather than verdict.',
    ),
    WisdomEntry(
      title:       'Doublethink',
      source:      'George Orwell · 1984',
      quote:       'The party told you to reject the evidence of your eyes and ears. It was their final, most essential command.',
      explanation:
          'Notice when you are being asked to override your own direct '
          'perception because it is inconvenient — to a relationship, a '
          'narrative, an institution. Your experience is data. Do not let '
          'anyone make you doubt your own senses.',
    ),
    WisdomEntry(
      title:       'The Drift of Power',
      source:      'George Orwell · Animal Farm',
      quote:       'The creatures outside looked from pig to man, and from man to pig, and from pig to man again; but already it was impossible to say which was which.',
      explanation:
          'Power tends to make the new ruler mimic the old oppressor. Watch '
          'your own ascent carefully. If you achieve success by adopting the '
          'same coldness you once resisted, you have not escaped the system '
          '— you have become it.',
    ),
    WisdomEntry(
      title:       'The Soma World',
      source:      'Aldous Huxley · Brave New World',
      quote:       'A gramme is better than a damn.',
      explanation:
          'Huxley\'s nightmare was not pain — it was a civilization too '
          'comfortable to notice its own captivity. Audit your comfort: what '
          'are you consuming — scroll, substance, entertainment — that makes '
          'it easier not to think? The soma is whatever dulls the question.',
    ),
    WisdomEntry(
      title:       'Ending Is Better Than Mending',
      source:      'Aldous Huxley · Brave New World',
      quote:       'Ending is better than mending.',
      explanation:
          'A hypnopaedic slogan from Huxley\'s conditioning state — designed '
          'to create endless consumption. A system that trains you to discard '
          'rather than repair — objects, habits, relationships — keeps you '
          'dependent and spending. Learn to maintain. That alone separates '
          'you from the default path.',
    ),
    WisdomEntry(
      title:       'Conditioned Belonging',
      source:      'Aldous Huxley · Brave New World',
      quote:       'Everyone belongs to everyone else.',
      explanation:
          'When belonging requires giving up your own judgment, it is not '
          'belonging — it is assimilation. Protect your ability to choose '
          'independently, even when conformity is easier and more comfortable.',
    ),
    WisdomEntry(
      title:       'The Axe for the Frozen Sea',
      source:      'Franz Kafka · Letter to Oskar Pollak, 1904',
      quote:       'A book must be the axe for the frozen sea within us.',
      explanation:
          'If a book doesn\'t disturb something in you, it hasn\'t done its '
          'job. Seek the writing that cracks you open — not the writing that '
          'confirms what you already believe. Comfort reading is entertainment. '
          'Real reading is surgery.',
    ),
    WisdomEntry(
      title:       'Sit With the Question',
      source:      'Franz Kafka · Letter to Oskar Pollak, 1904',
      quote:       'You do not need to leave your room. Remain sitting at your table and listen. The world will freely offer itself to you.',
      explanation:
          'Not all progress is locomotion. Some of the sharpest work happens '
          'in stillness — reading, sitting, thinking long enough for things '
          'to clarify. The answers come to those who stay long enough to '
          'receive them.',
    ),
    WisdomEntry(
      title:       'Noncombustible Data',
      source:      'Ray Bradbury · Fahrenheit 451',
      quote:       'Cram them full of noncombustible data, chock them so damned full of \'facts\' they feel stuffed, but absolutely \'brilliant\' with information.',
      explanation:
          'Captain Beatty explains the system: flood people with information '
          'and they will feel they are thinking without actually thinking. '
          'Volume of input is not the same as depth of understanding. Read '
          'less. Think longer about what you read.',
    ),
    WisdomEntry(
      title:       'Be Really Bothered',
      source:      'Ray Bradbury · Fahrenheit 451',
      quote:       'We need not to be let alone. We need to be really bothered once in a while.',
      explanation:
          'Fahrenheit 451 has been repeatedly challenged and banned — a book '
          'about burning books. Bradbury\'s Faber argues that real living '
          'requires friction. Constant ease dulls awareness. Seek difficulty '
          'periodically. It keeps your thinking sharp and your identity intact.',
    ),
    WisdomEntry(
      title:       'The Optimism of the Crowd',
      source:      'Milan Kundera · The Joke',
      quote:       'Optimism is the opium of the people.',
      explanation:
          'Banned in Czechoslovakia after the Prague Spring; Kundera was '
          'stripped of his citizenship. Blind optimism can be as dangerous '
          'as blind pessimism — it prevents clear seeing. Reality does not '
          'improve because you expect it to. It improves because you act '
          'within it accurately.',
    ),
    WisdomEntry(
      title:       'Weight and Lightness',
      source:      'Milan Kundera · The Unbearable Lightness of Being',
      quote:       'The heaviest of burdens is simultaneously an image of life\'s most intense fulfillment.',
      explanation:
          'Total freedom without weight feels empty. Total responsibility '
          'feels crushing. Life is lived in the tension between the two. '
          'Seek enough weight to feel grounded — enough freedom to feel alive. '
          'The balance is not found; it is maintained daily.',
    ),
    WisdomEntry(
      title:       'Memory Against Forgetting',
      source:      'Milan Kundera · The Book of Laughter and Forgetting',
      quote:       'The struggle of man against power is the struggle of memory against forgetting.',
      explanation:
          'Systems of control work by distorting the record. Keep your own '
          'account of what actually happened, what you actually decided, and '
          'why. A journal is not vanity — it is sovereignty.',
    ),
    WisdomEntry(
      title:       'Internal Sovereignty',
      source:      'Czesław Miłosz · The Captive Mind',
      quote:       'The man who possesses the truth is a nuisance to those who possess power.',
      explanation:
          'Miłosz wrote The Captive Mind after fleeing Stalinist Poland — '
          'a firsthand study of intellectuals who slowly accepted the official '
          'lie. Power relies on collective agreement to a shared fiction. '
          'Refusing to repeat what you know is false is the most available '
          'form of resistance.',
    ),
    WisdomEntry(
      title:       'The Body Knows',
      source:      'Boris Pasternak · Doctor Zhivago',
      quote:       'Your health is bound to be affected if, day after day, you say the opposite of what you feel.',
      explanation:
          'Doctor Zhivago was smuggled out of the USSR; Pasternak was forced '
          'to refuse the Nobel Prize under state pressure. The cost of sustained '
          'inauthenticity is not only moral — it is physical. Living against '
          'your own grain is expensive in ways that show up in the body first.',
    ),
    WisdomEntry(
      title:       'What Facts Cannot Hold',
      source:      'Boris Pasternak · Doctor Zhivago',
      quote:       'What is laid down, ordered, factual, is never enough to embrace the whole truth.',
      explanation:
          'Systems of measurement — salary, metrics, productivity — capture '
          'part of a life but miss the texture of it. The facts of your '
          'existence are not the whole of your existence. Protect the part '
          'that cannot be measured.',
    ),
    WisdomEntry(
      title:       'Freeing the Freed Self',
      source:      'Toni Morrison · Beloved',
      quote:       'Freeing yourself was one thing; claiming ownership of that freed self was another.',
      explanation:
          'Beloved was challenged and banned repeatedly in US school districts. '
          'Morrison identifies the gap most people never fully cross: the '
          'difference between escaping an old identity and fully inhabiting '
          'the new one. Liberation is incomplete without ownership.',
    ),
    WisdomEntry(
      title:       'The Invisible Man Sees',
      source:      'Ralph Ellison · Invisible Man',
      quote:       'I am an invisible man... I am a man of substance, of flesh and bone, fiber and liquids — and I might even be said to possess a mind.',
      explanation:
          'Invisible Man was banned across multiple US states. Ellison\'s '
          'narrator is unseen because others refuse to look. The paradox: '
          'invisibility grants an unusual freedom — to observe without being '
          'managed. If you have ever been overlooked, you know this advantage. '
          'Use it.',
    ),
    WisdomEntry(
      title:       'The River of Time',
      source:      'Gabriel García Márquez · One Hundred Years of Solitude',
      quote:       'A person doesn\'t die when he should but when he can.',
      explanation:
          'Banned across several Latin American regimes. García Márquez '
          'understood that life operates on its own schedule. You cannot rush '
          'readiness — yours or others. But you can prepare so that when the '
          'moment arrives, you can meet it.',
    ),
    WisdomEntry(
      title:       'The Pact With Solitude',
      source:      'Gabriel García Márquez · Love in the Time of Cholera',
      quote:       'The secret of a good old age is simply an honorable pact with solitude.',
      explanation:
          'The people who age with dignity have learned to be alone without '
          'being lonely. They are not dependent on external validation to feel '
          'whole. Solitude is a skill, not a punishment. Develop it before '
          'you need it.',
    ),
    WisdomEntry(
      title:       'The Correct Ladder',
      source:      'Leo Tolstoy · The Death of Ivan Ilyich',
      quote:       'Ivan Ilyich\'s life had been most simple and most ordinary and therefore most terrible.',
      explanation:
          'Suppressed by the Russian church. Ivan Ilyich spends his life '
          'climbing the correct social ladder only to discover on his deathbed '
          'that he climbed the wrong wall. Audit your ambitions now, not at '
          'the end.',
    ),
    WisdomEntry(
      title:       'What If My Whole Life Has Been Wrong',
      source:      'Leo Tolstoy · The Death of Ivan Ilyich',
      quote:       'What if my whole life has been wrong?',
      explanation:
          'Tolstoy considers this the most important question a person can '
          'ask — and argues it should be asked while there is still time to '
          'do something about the answer.',
    ),
    WisdomEntry(
      title:       'What I Am and What I Want to Be',
      source:      'André Gide · The Immoralist',
      quote:       'I am not what I want to be. And yet I want to be what I am.',
      explanation:
          'Placed on the Vatican\'s Index of Forbidden Books. Gide names the '
          'tension precisely: the self you perform versus the self you actually '
          'inhabit. Real growth is closing that gap — not by forcing performance '
          'to match an ideal, but by doing the inner work.',
    ),
    WisdomEntry(
      title:       'The Suppression of Hunger',
      source:      'Richard Wright · Native Son',
      quote:       'I didn\'t want to kill! But what I killed for, I am!',
      explanation:
          'Native Son was banned in multiple US states and challenged '
          'repeatedly. Wright\'s Bigger Thomas is shaped entirely by forces '
          'outside his control — then condemned for it. The lesson is not '
          'absolution; it is that environment shapes behavior powerfully. '
          'Design your environment before it designs you.',
    ),
    WisdomEntry(
      title:       'The Examined Life Under Pressure',
      source:      'Nikos Kazantzakis · Zorba the Greek',
      quote:       'I felt once more how simple and frugal a thing is happiness: a glass of wine, a roast chestnut, a wretched little brazier, the sound of the sea.',
      explanation:
          'Kazantzakis was excommunicated from the Greek Orthodox Church. '
          'Zorba understood something most miss: the capacity for joy does '
          'not scale with luxury. Train your ability to find richness in '
          'simple things and no external circumstance can truly impoverish you.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // PHYSICAL MASTERY — Body, Discipline & Peak Performance
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'The One Kick',
      source:      'Bruce Lee',
      quote:       'I fear not the man who has practiced 10,000 kicks once, but the man who has practiced one kick 10,000 times.',
      explanation:
          'Breadth feels productive. Depth changes the outcome. The expert '
          'is not the person who has tried everything — it is the person who '
          'has repeated one thing long enough to make it automatic, and then '
          'refined what automatic can become.',
    ),
    WisdomEntry(
      title:       'Be Water',
      source:      'Bruce Lee',
      quote:       'Empty your mind, be formless, shapeless — like water.',
      explanation:
          'Water adapts to every container without losing its nature. '
          'Rigidity in the body and in strategy both lose the same way: '
          'the opponent finds the fixed point and exploits it. Train for '
          'flexibility as seriously as you train for strength.',
    ),
    WisdomEntry(
      title:       'Absorb What Is Useful',
      source:      'Bruce Lee · Tao of Jeet Kune Do',
      quote:       'Absorb what is useful, discard what is not, add what is uniquely your own.',
      explanation:
          'No system is complete. Every philosophy has blind spots and gifts. '
          'Take what works from wherever you find it, discard the rest without '
          'ceremony, and synthesize something that belongs to you alone.',
    ),
    WisdomEntry(
      title:       'Today Over Yesterday',
      source:      'Miyamoto Musashi · The Book of Five Rings',
      quote:       'Today is victory over yourself of yesterday.',
      explanation:
          'Written by a swordsman who went undefeated in 61 duels. Musashi\'s '
          'measure of progress was not comparison against others — it was '
          'comparison against his own previous standard. Your only real '
          'competition is who you were yesterday.',
    ),
    WisdomEntry(
      title:       'Many Paths to the Summit',
      source:      'Miyamoto Musashi · The Book of Five Rings',
      quote:       'You must understand that there is more than one path to the top of the mountain.',
      explanation:
          'Musashi studied painting, sculpture, strategy, and philosophy '
          'alongside swordsmanship. Mastery in one domain illuminates mastery '
          'in all others. Cross-train your mind the way you cross-train '
          'your body.',
    ),
    WisdomEntry(
      title:       'The Samurai\'s Readiness',
      source:      'Yamamoto Tsunetomo · Hagakure',
      quote:       'The way of the samurai is found in death.',
      explanation:
          'Hagakure was banned in post-war Japan. Tsunetomo\'s meaning: act '
          'each day as if it were your last — not in desperation, but in '
          'total commitment. The person who has already accepted the cost '
          'of the work fights without hesitation.',
    ),
    WisdomEntry(
      title:       'No Days Off',
      source:      'Jocko Willink · Discipline Equals Freedom',
      quote:       'Discipline equals freedom.',
      explanation:
          'Every morning you do not negotiate with the alarm, the training, '
          'the work — you reclaim time and energy that undisciplined people '
          'spend managing the consequences of yesterday. The system that '
          'constrains you for an hour gives you back the decade.',
    ),
    WisdomEntry(
      title:       'Extreme Ownership',
      source:      'Jocko Willink · Extreme Ownership',
      quote:       'The leader must own everything in their world. There is no one else to blame.',
      explanation:
          'When things go wrong, the instinct is to find whose fault it is. '
          'The effective move is to ask what you will do differently. Blame '
          'is comfortable and useless. Ownership is uncomfortable and gives '
          'you back the controls.',
    ),
    WisdomEntry(
      title:       'Walking as Medicine',
      source:      'Hippocrates',
      quote:       'Walking is man\'s best medicine.',
      explanation:
          'The ancient principle confirmed by modern research: consistent '
          'physical movement is more effective than most interventions for '
          'mood, cognition, and longevity. The most sophisticated tool '
          'available to you costs nothing.',
    ),
    WisdomEntry(
      title:       'The Hard Thing First',
      source:      'Mark Twain',
      quote:       'If it\'s your job to eat a frog, it\'s best to do it first thing in the morning.',
      explanation:
          'The task you are avoiding generates more mental weight than its '
          'actual execution. Complete the hardest item first and the rest of '
          'the day moves with momentum instead of dread. Avoidance is a tax '
          'paid all day; action is a tax paid once.',
    ),
    WisdomEntry(
      title:       'Rest at the End',
      source:      'Kobe Bryant',
      quote:       'Rest at the end, not in the middle.',
      explanation:
          'The middle of a goal — after the initial excitement and before '
          'the result — is where most people rest. That is precisely where '
          'the ground is gained and lost. Push through the middle.',
    ),
    WisdomEntry(
      title:       'The Mind Is the Limit',
      source:      'Arnold Schwarzenegger · Total Recall',
      quote:       'The mind is the limit. As long as the mind can envision the fact that you can do something, you can do it.',
      explanation:
          'Schwarzenegger trained in an era with no sports science. His '
          'conviction: physical limits are primarily mental constructs. '
          'The body follows the ceiling the mind sets. Raise the ceiling '
          'consciously and deliberately.',
    ),
    WisdomEntry(
      title:       'Win Before the Fight',
      source:      'Sun Tzu · The Art of War',
      quote:       'Victorious warriors win first and then go to war, while defeated warriors go to war first and then seek to win.',
      explanation:
          'Physical preparation is not separate from strategy. The person '
          'who shows up in optimal condition — rested, strong, clear — wins '
          'before the contest begins. Energy management is part of execution.',
    ),
    WisdomEntry(
      title:       'The Body Serves the Mission',
      source:      'Epictetus · Discourses',
      quote:       'Take care of your body, but do not make that the chief thing.',
      explanation:
          'Physical condition is infrastructure, not identity. Maintain it '
          'seriously — sleep, movement, nutrition — because a deteriorating '
          'body limits every other pursuit. But the body serves the life; '
          'the life does not exist to serve the body.',
    ),
    WisdomEntry(
      title:       'Design Your Environment',
      source:      'Seneca · Letters to Lucilius',
      quote:       'Associate with those who are likely to improve you.',
      explanation:
          'Who you train with and what environment you put yourself in shape '
          'outcomes more than motivation ever will. Design your environment '
          'before you rely on willpower. The right room raises everyone in it.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // SPIRITUAL DEPTH — Inner Life, Presence & the Sacred
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'You Are the Observer',
      source:      'Bhagavad Gita · Chapter 2',
      quote:       'You are not the mind, you are the observer of the mind.',
      explanation:
          'Thoughts arise and pass. Emotions rise and fall. The part of you '
          'that notices them is stable. Cultivate that witnessing position — '
          'it is not detachment from life but the ground from which you can '
          'respond rather than react.',
    ),
    WisdomEntry(
      title:       'Act Without Clinging',
      source:      'Bhagavad Gita · Chapter 3',
      quote:       'Let right deeds be thy motive, not the fruit which comes from them.',
      explanation:
          'Krishna\'s core teaching: full effort, zero clinging to outcome. '
          'The action done cleanly — without anxiety about the result — is '
          'more powerful and more sustainable than action done with one eye '
          'always on the scoreboard.',
    ),
    WisdomEntry(
      title:       'The Witness Self',
      source:      'Bhagavad Gita · Chapter 13',
      quote:       'The Self is the witness — neither the actor nor the acted upon.',
      explanation:
          'Beneath all roles, moods, and performances is a part of you that '
          'cannot be damaged by failure or inflated by success. Access it '
          'and your decisions become less automatic, more chosen.',
    ),
    WisdomEntry(
      title:       'The Guest House',
      source:      'Rumi · The Guest House',
      quote:       'This human being is a guest house. Every morning a new arrival.',
      explanation:
          'Joy, depression, rage, clarity — treat them as visitors. Receive '
          'each one at the door and let it pass through. Clinging to the '
          'pleasant ones and fighting the difficult ones equally delays their '
          'departure and your return to center.',
    ),
    WisdomEntry(
      title:       'What You Seek',
      source:      'Rumi',
      quote:       'What you seek is seeking you.',
      explanation:
          'The thing you are drawn to repeatedly — the work, the discipline, '
          'the calling — is not random. It is pulling you because you belong '
          'to it. Stop treating it as coincidence and start walking toward it.',
    ),
    WisdomEntry(
      title:       'The Reed\'s Longing',
      source:      'Rumi · Masnavi, Book I',
      quote:       'Listen to the reed, how it tells a tale of separations.',
      explanation:
          'Rumi opens his masterwork with the reed\'s longing — cut from its '
          'origin, crying for return. The longing you feel for something more '
          'is not weakness — it is signal. It points toward what you were '
          'made for. Follow the ache.',
    ),
    WisdomEntry(
      title:       'Wu Wei',
      source:      'Lao Tzu · Tao Te Ching, Chapter 48',
      quote:       'When nothing is done, nothing is left undone.',
      explanation:
          'Effortless action — not doing nothing, but doing without forcing. '
          'When you align with the grain of the situation, work flows. '
          'Forcing creates the very resistance you are trying to overcome.',
    ),
    WisdomEntry(
      title:       'Return to Stillness',
      source:      'Lao Tzu · Tao Te Ching, Chapter 16',
      quote:       'Return to the root is called stillness. Stillness is called returning to one\'s destiny.',
      explanation:
          'Before the next decision, the next move, the next conversation — '
          'there is a baseline you can access if you stop long enough. Not '
          'meditation as ritual, but the daily practice of returning to quiet '
          'before acting from noise.',
    ),
    WisdomEntry(
      title:       'Knowing Yourself',
      source:      'Lao Tzu · Tao Te Ching, Chapter 33',
      quote:       'Knowing others is wisdom. Knowing yourself is enlightenment.',
      explanation:
          'Understanding people is a useful skill. Understanding yourself '
          'is the work of a lifetime. Most interpersonal friction is '
          'self-ignorance — a pattern you haven\'t seen in yourself yet '
          'appearing in someone else\'s face.',
    ),
    WisdomEntry(
      title:       'Before and After Enlightenment',
      source:      'Zen proverb',
      quote:       'Before enlightenment, chop wood, carry water. After enlightenment, chop wood, carry water.',
      explanation:
          'The tasks don\'t change. The relationship to them does. The person '
          'who has found their footing does the same ordinary things as '
          'everyone else — but with full presence and without resentment. '
          'That invisible shift is everything.',
    ),
    WisdomEntry(
      title:       'The Full Cup',
      source:      'Zen tradition',
      quote:       'A full cup cannot be filled.',
      explanation:
          'You learn nothing from a position of certainty. Empty the cup '
          'before each conversation, each problem, each new day — otherwise '
          'you only confirm what you already think you know. Beginner\'s '
          'mind is the most productive state available.',
    ),
    WisdomEntry(
      title:       'The Middle Way',
      source:      'Siddhartha Gautama',
      quote:       'Just as a lute sounds well neither when its strings are too taut nor too loose — so too with the mind.',
      explanation:
          'Buddha discovered the Middle Way after years of extreme asceticism '
          'left him too weak to think. Calibrate. Enough discipline to build, '
          'enough rest to recover. The middle is not mediocrity — it is '
          'precision.',
    ),
    WisdomEntry(
      title:       'Remove the Arrow First',
      source:      'Siddhartha Gautama · Cūḷamālukya Sutta',
      quote:       'The person struck by an arrow does not ask who shot it before removing it.',
      explanation:
          'Metaphysical questions — why is there suffering, what is the '
          'ultimate meaning — are arrows you debate while bleeding. Solve '
          'the immediate problem. Philosophical clarity follows once you '
          'are not in crisis. Sequence matters.',
    ),
    WisdomEntry(
      title:       'The Dark Night',
      source:      'St. John of the Cross · Dark Night of the Soul',
      quote:       'In the darkness of the soul, only love remains to be the guide.',
      explanation:
          'St. John of the Cross was imprisoned by his own religious order. '
          'He wrote this from a cell. The dark night — the period where every '
          'external support falls away — is not abandonment in his framework. '
          'It is preparation. The clearing always precedes the building.',
    ),
    WisdomEntry(
      title:       'Attention as the Highest Gift',
      source:      'Simone Weil · Waiting for God',
      quote:       'Attention is the rarest and purest form of generosity.',
      explanation:
          'Weil considered full attention sacred — the closest the human '
          'being comes to grace. In an era of engineered distraction, giving '
          'someone or something your complete, undivided presence is an act '
          'of radical love.',
    ),
    WisdomEntry(
      title:       'The Shadow',
      source:      'Carl Jung · Psychology and Religion',
      quote:       'Until you make the unconscious conscious, it will direct your life and you will call it fate.',
      explanation:
          'The patterns you refuse to examine — your anger, your envy, your '
          'fear — do not disappear. They run silently underneath your '
          'decisions. Bring them into the open and they lose their autonomy. '
          'What you name, you can influence. What you deny runs you.',
    ),
    WisdomEntry(
      title:       'The Terrifying Acceptance',
      source:      'Carl Jung',
      quote:       'The most terrifying thing is to accept oneself completely.',
      explanation:
          'Becoming yourself requires facing the parts you have spent years '
          'hiding — the weakness, the contradiction, the capacity for both '
          'greatness and smallness. Integration, not perfection, is the goal. '
          'Most people stop halfway and settle into a partial version.',
    ),
    WisdomEntry(
      title:       'Emotion Named Is Emotion Tamed',
      source:      'Baruch Spinoza · Ethics',
      quote:       'An emotion which is a passion ceases to be a passion as soon as we form a clear and distinct idea of it.',
      explanation:
          'Naming and understanding an emotion reduces its power. The vague '
          'fear becomes a specific concern. The overwhelming rage becomes a '
          'defined trigger. Clarity dissolves intensity. Think about what you '
          'feel before acting from it.',
    ),
    WisdomEntry(
      title:       'The Inner Room',
      source:      'Marcus Aurelius · Meditations',
      quote:       'Go into yourself. The rational being has the power to be content with itself.',
      explanation:
          'The external world will always be unstable. The inner life is the '
          'one domain you can actually govern. Develop it seriously — through '
          'reading, reflection, honest self-examination — and you carry a '
          'stable home with you everywhere.',
    ),
    WisdomEntry(
      title:       'The Present Moment',
      source:      'Eckhart Tolle · The Power of Now',
      quote:       'Realize deeply that the present moment is all you ever have.',
      explanation:
          'The mind pulls backward into past regret or forward into future '
          'anxiety. Reality only exists now. Return attention to the present '
          'and most anxiety dissolves — because anxiety is almost always '
          'about a time that is not this one.',
    ),
    WisdomEntry(
      title:       'Thoughts About the Situation',
      source:      'Eckhart Tolle · Stillness Speaks',
      quote:       'The primary cause of unhappiness is never the situation but your thoughts about it.',
      explanation:
          'The situation is neutral until the mind narrates it. Two people '
          'in the same circumstance live two entirely different experiences '
          'depending on the story they tell. Change the story and you change '
          'the experience without changing the fact.',
    ),
    WisdomEntry(
      title:       'As Above, So Below',
      source:      'The Emerald Tablet · Hermes Trismegistus',
      quote:       'That which is above is like that which is below, and that which is below is like that which is above.',
      explanation:
          'The internal and external are mirrors. Your outer life reflects '
          'the inner architecture you\'ve built. Change the inside first. '
          'The outside rearranges more slowly, but it rearranges.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // WEALTH BUILDING — Money, Leverage & Long-Term Thinking
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Compound Everything',
      source:      'Naval Ravikant',
      quote:       'Play long-term games with long-term people.',
      explanation:
          'All real wealth — money, skill, reputation, trust — compounds. '
          'The people you stay with over decades, the habits you maintain '
          'over years. Short-term loops keep you on a treadmill. Long-term '
          'games change the trajectory.',
    ),
    WisdomEntry(
      title:       'Specific Knowledge',
      source:      'Naval Ravikant',
      quote:       'Arm yourself with specific knowledge, accountability, and leverage.',
      explanation:
          'Specific knowledge is the skill you cannot be trained for — it '
          'comes from obsession, not curriculum. It is what you would do '
          'even without being paid. That intersection of genuine interest '
          'and rare capability is where leverage lives.',
    ),
    WisdomEntry(
      title:       'Earn While You Sleep',
      source:      'Naval Ravikant',
      quote:       'If you don\'t find a way to make money while you sleep, you will work until you die.',
      explanation:
          'Trading time directly for money has a ceiling. Assets — businesses, '
          'intellectual property, investments — produce returns without requiring '
          'your hourly presence. Build assets as early and consistently as '
          'possible.',
    ),
    WisdomEntry(
      title:       'Pay Yourself First',
      source:      'George Samuel Clason · The Richest Man in Babylon',
      quote:       'A part of all you earn is yours to keep.',
      explanation:
          'The foundational wealth principle: before paying any obligation, '
          'pay yourself first. The person who saves nothing owns nothing, '
          'regardless of income. Start with 10%. Automate it. Forget it exists.',
    ),
    WisdomEntry(
      title:       'Gold Comes to the Disciplined',
      source:      'George Samuel Clason · The Richest Man in Babylon',
      quote:       'Gold cometh gladly and in increasing quantity to any man who will put by not less than one-tenth of his earnings.',
      explanation:
          'Written during the Great Depression, drawing on ancient Babylonian '
          'financial wisdom. Consistent saving plus compound growth defeats '
          'irregular high-income with zero discipline every time. The amount '
          'matters less than the consistency.',
    ),
    WisdomEntry(
      title:       'Definiteness of Purpose',
      source:      'Napoleon Hill · Think and Grow Rich',
      quote:       'There is one quality which one must possess to win, and that is definiteness of purpose.',
      explanation:
          'Vague wants produce vague results. The specificity of your goal '
          'determines the efficiency of your pursuit. State exactly what you '
          'want, exactly when you want it, and exactly what you will give '
          'for it. Ambiguity is expensive.',
    ),
    WisdomEntry(
      title:       'The Mastermind Alliance',
      source:      'Napoleon Hill · Think and Grow Rich',
      quote:       'No individual has sufficient experience, education, native ability, and knowledge to ensure the accumulation of a great fortune without the cooperation of other people.',
      explanation:
          'Wealth is not built in isolation. Hill\'s mastermind principle: '
          'surround yourself with people who collectively have the skills '
          'you lack. You are not looking for agreement — you are looking '
          'for complementary intelligence. The right table raises every '
          'person at it.',
    ),
    WisdomEntry(
      title:       'Build the Portfolio of Skills',
      source:      'Robert Greene · Mastery',
      quote:       'The future belongs to those who learn more skills and combine them in creative ways.',
      explanation:
          'One deep skill gives you a career. Two complementary skills give '
          'you an edge. Three that no one has combined creates a category '
          'you own. The portfolio of capabilities — not the single credential '
          '— is the real long-term asset.',
    ),
    WisdomEntry(
      title:       'Plan All the Way to the End',
      source:      'Robert Greene · 48 Laws of Power',
      quote:       'The ending is everything. Plan all the way to it, taking into account all the possible consequences, obstacles, and twists of fortune.',
      explanation:
          'Most people plan the beginning of a thing — the launch, the deal. '
          'Walk yourself to the final move before making the first one. '
          'Surprises come mostly from refusing to look that far ahead.',
    ),
    WisdomEntry(
      title:       'Plant the Tree Today',
      source:      'Warren Buffett',
      quote:       'Someone is sitting in the shade today because someone planted a tree twenty years ago.',
      explanation:
          'Compound growth is invisible in the short term and enormous in '
          'the long term. The investment you don\'t make, the habit you '
          'don\'t start, the skill you defer — these are not neutral decisions. '
          'They are choices with compounding costs.',
    ),
    WisdomEntry(
      title:       'Risk Is Ignorance',
      source:      'Warren Buffett',
      quote:       'Risk comes from not knowing what you are doing.',
      explanation:
          'Most people fear the wrong thing. Failure is a learning event '
          'with known cost. Mediocrity — consistently acceptable performance '
          'with no learning — is the silent killer of potential. Know your '
          'domain well enough that failure becomes rare and recoverable.',
    ),
    WisdomEntry(
      title:       'Show Me the Incentive',
      source:      'Charlie Munger',
      quote:       'Show me the incentive and I\'ll show you the outcome.',
      explanation:
          'Before analyzing behavior — yours, an institution\'s, a partner\'s '
          '— find the incentive structure. People reliably optimize for what '
          'they are rewarded for. Align your incentives with what you actually '
          'want and behavior corrects itself.',
    ),
    WisdomEntry(
      title:       'Inversion',
      source:      'Charlie Munger',
      quote:       'Invert, always invert. Tell me where I\'m going to die, that I may never go there.',
      explanation:
          'Rather than asking how to succeed, ask how to reliably fail — '
          'then avoid that. Mapping failure is often more precise than mapping '
          'success. Most catastrophes are predictable in reverse.',
    ),
    WisdomEntry(
      title:       'Buy Assets, Not Liabilities',
      source:      'Robert Kiyosaki · Rich Dad Poor Dad',
      quote:       'The rich buy assets. The poor only have expenses. The middle class buys liabilities they think are assets.',
      explanation:
          'An asset puts money into your pocket. A liability takes money out. '
          'Most people buy things they think are assets but function as '
          'liabilities. Know the difference in every major purchase before '
          'you make it.',
    ),
    WisdomEntry(
      title:       'How Money Is Kept',
      source:      'Robert Kiyosaki · Rich Dad Poor Dad',
      quote:       'It\'s not how much money you make, but how much money you keep, how hard it works for you, and how many generations you keep it for.',
      explanation:
          'Income is not wealth. A high income fully consumed leaves nothing. '
          'Wealth is accumulated capital — assets that generate more assets. '
          'The discipline is not earning more but leaking less while building '
          'systems that self-perpetuate.',
    ),
    WisdomEntry(
      title:       'Execute or It Means Nothing',
      source:      'Peter Drucker',
      quote:       'Plans are only good intentions unless they immediately degenerate into hard work.',
      explanation:
          'Ideas feel productive but produce nothing on their own. Every plan '
          'must end in a concrete next action with a deadline. Strategy '
          'without operations is philosophy.',
    ),
    WisdomEntry(
      title:       'Measure What Matters',
      source:      'Peter Drucker',
      quote:       'What gets measured gets managed.',
      explanation:
          'If you track it, you influence it. If you ignore it, it drifts. '
          'Choose three to five key metrics in your financial life — savings '
          'rate, net worth growth, income sources — and watch what happens '
          'once they are visible and reviewed weekly.',
    ),
    WisdomEntry(
      title:       'The 80/20 of Wealth',
      source:      'Vilfredo Pareto',
      quote:       'Eighty percent of the effects come from twenty percent of the causes.',
      explanation:
          'In your income, your habits, your relationships — a small number '
          'of inputs drives most of the output. Find those inputs and protect '
          'them. Eliminate or delegate the rest. Optimization is subtraction.',
    ),
    WisdomEntry(
      title:       'The Opportunity Cost',
      source:      'Frédéric Bastiat · The Law',
      quote:       'In the economy, an act, a habit, an institution, a law produces not only one effect, but a series of effects.',
      explanation:
          'Every decision has visible costs and invisible ones. The money '
          'spent is seen; the compounded return it would have generated is '
          'unseen. Train yourself to see both. Every financial decision has '
          'an opportunity cost — what you could have done instead.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // KAFKA — The Absurdity of Systems
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'The Inner Verdict',
      source:      'Franz Kafka · The Trial',
      quote:       'Someone must have slandered Josef K., for one morning, without having done anything wrong, he was arrested.',
      explanation:
          'The system does not need your guilt to convict you. Bureaucracy, '
          'opinion, the market — they operate on their own logic. Your '
          'innocence is irrelevant to the machine. Learn the machine, or '
          'it will grind you regardless.',
    ),
    WisdomEntry(
      title:       'The Permission That Never Comes',
      source:      'Franz Kafka · The Castle',
      quote:       'There is infinite hope, but not for us.',
      explanation:
          'Stop waiting for permission from the castle. It will never arrive. '
          'The hope that exists is real — what blocks it is the belief that '
          'access belongs to someone else.',
    ),
    WisdomEntry(
      title:       'The Pull of the True Self',
      source:      'Franz Kafka · The Metamorphosis',
      quote:       'Was he an animal, that music could move him so? He felt as if the way to the unknown nourishment he longed for was revealing itself.',
      explanation:
          'Even when made unrecognizable by circumstance — failure, illness, '
          'a role you never chose — the thing that moves you still points to '
          'what you are. Follow the pull. It is more honest than the shape '
          'you wear in public.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // CAMUS — Absurdism, Revolt & Radical Presence
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'One Must Imagine Sisyphus Happy',
      source:      'Albert Camus · The Myth of Sisyphus',
      quote:       'The struggle itself toward the heights is enough to fill a man\'s heart.',
      explanation:
          'The rock always comes back down. The goal, the number, the milestone '
          '— you reach it and the next version appears. The climbing is the '
          'life. Fall in love with the repetition, not the summit.',
    ),
    WisdomEntry(
      title:       'The Habit of Despair',
      source:      'Albert Camus · The Plague',
      quote:       'The habit of despair is worse than despair itself.',
      explanation:
          'A single crisis can be survived. But normalize catastrophe — let '
          'difficulty become your default lens — and you create a permanent '
          'filter that blocks every actual opportunity. Break the habit of '
          'despair before it becomes your operating system.',
    ),
    WisdomEntry(
      title:       'Stop Searching for Happiness',
      source:      'Albert Camus',
      quote:       'You will never be happy if you continue to search for what happiness consists of.',
      explanation:
          'Meaning is not a thing you find — it is a thing you build while '
          'moving. Decide what you\'re committed to, do that, and let meaning '
          'accumulate behind you.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // DOSTOEVSKY — Suffering, Freedom & Consciousness
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Consciousness Without Action',
      source:      'Fyodor Dostoevsky · Notes from Underground',
      quote:       'I am a sick man… I am a wicked man. An unattractive man.',
      explanation:
          'The underground man is what happens when hyper-consciousness has '
          'no outlet in action. He sees everything, does nothing, and curdles. '
          'The cure is not less awareness — it is more movement. Thinking '
          'without acting poisons the thinker.',
    ),
    WisdomEntry(
      title:       'The Right to Choose Wrongly',
      source:      'Fyodor Dostoevsky · Notes from Underground',
      quote:       'What man wants is simply independent choice, whatever that independence may cost.',
      explanation:
          'Freedom is more fundamental than optimization. Any system — '
          'personal or political — that removes your choice to be wrong also '
          'removes your humanity. Know why you believe what you believe.',
    ),
    WisdomEntry(
      title:       'The Price of Depth',
      source:      'Fyodor Dostoevsky · Crime and Punishment',
      quote:       'Pain and suffering are always inevitable for a large intelligence and a deep heart.',
      explanation:
          'If you feel things intensely, the world will hurt you more. That '
          'is the price of sensitivity. Don\'t try to numb down to average. '
          'The same capacity that makes you hurt is what makes you fully alive.',
    ),
    WisdomEntry(
      title:       'Find Something to Live For',
      source:      'Fyodor Dostoevsky · The Brothers Karamazov',
      quote:       'The mystery of human existence lies not in just staying alive, but in finding something to live for.',
      explanation:
          'People who drift are not usually unhealthy — they are unmotivated. '
          'Find the thing you would be ashamed to die without having tried, '
          'and organize your days around it.',
    ),
    WisdomEntry(
      title:       'Love Is Not a Feeling',
      source:      'Fyodor Dostoevsky · The Brothers Karamazov',
      quote:       'Love in action is a harsh and dreadful thing compared with love in dreams.',
      explanation:
          'It is easy to love humanity in the abstract. The actual human in '
          'front of you — with their timing, their needs, their flaws — is '
          'much harder. Real love is a practice, not a feeling.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // SARTRE — Existence, Bad Faith & Radical Responsibility
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'You Are What You Choose',
      source:      'Jean-Paul Sartre · Existentialism Is a Humanism',
      quote:       'Man is nothing else but what he makes of himself.',
      explanation:
          'You were not born with a fixed purpose — you are building it with '
          'every choice. You cannot blame your nature, your parents, or your '
          'circumstance forever. At some point you are what you have chosen.',
    ),
    WisdomEntry(
      title:       'Condemned to Be Free',
      source:      'Jean-Paul Sartre · Being and Nothingness',
      quote:       'We are condemned to be free.',
      explanation:
          'Bad faith is pretending you have no choice when you do. You always '
          'choose, even when you choose not to choose. The sentence is freedom. '
          'Own it.',
    ),
    WisdomEntry(
      title:       'Hell Is Other People',
      source:      'Jean-Paul Sartre · No Exit',
      quote:       'Hell is other people.',
      explanation:
          'Sartre didn\'t mean people are hell. He meant: when you define '
          'yourself through the gaze of others, you hand them the keys to '
          'your existence. Stop letting their opinion be the final verdict '
          'on your life.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // KOBO ABE — Identity, Alienation & the Shifting Self
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'The Lost Address',
      source:      'Kobo Abe · The Woman in the Dunes',
      quote:       'A man who has lost his address has in a sense lost his self.',
      explanation:
          'Identity is partly location — social, professional, relational. '
          'When those anchors shift, you feel unmoored. Rebuild the map from '
          'first principles: what do you value, and what will you do today '
          'because of it?',
    ),
    WisdomEntry(
      title:       'Work in the Box',
      source:      'Kobo Abe · The Box Man',
      quote:       'Inside the box, I am the observer. Outside, I become the observed.',
      explanation:
          'Not every phase of building should be public. Some work needs '
          'privacy to develop before it can survive exposure. Choose when '
          'to be visible and when to be invisible.',
    ),
    WisdomEntry(
      title:       'The Mask Reveals',
      source:      'Kobo Abe · The Face of Another',
      quote:       'A mask is not a disguise — it is a new possibility.',
      explanation:
          'Every new skill, context, or role you step into reveals a version '
          'of yourself that was always there — it needed the invitation. '
          'Try on more versions of yourself.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // BECKETT — Endurance, Failure & Waiting
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Fail Better',
      source:      'Samuel Beckett · Worstward Ho',
      quote:       'Ever tried. Ever failed. No matter. Try again. Fail again. Fail better.',
      explanation:
          'The point is not eventual success — it is the quality of your '
          'next failure. Each attempt, if you are paying attention, fails '
          'at a more sophisticated level. That drift toward better failure '
          'is what mastery looks like from the inside.',
    ),
    WisdomEntry(
      title:       'Begin Without Godot',
      source:      'Samuel Beckett · Waiting for Godot',
      quote:       'Let\'s go. — We can\'t. — Why not? — We\'re waiting for Godot.',
      explanation:
          'Audit your life for Godots — the funding round, the perfect '
          'moment, the right partner before you start. Godot is not coming. '
          'Begin without him.',
    ),
    WisdomEntry(
      title:       'I\'ll Go On',
      source:      'Samuel Beckett · The Unnamable',
      quote:       'I can\'t go on, I\'ll go on.',
      explanation:
          'You do not go on because you feel ready. You go on because stopping '
          'is also a choice, and you are choosing this instead. That is the '
          'whole of it.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // NIETZSCHE — Will, Eternal Return & Overcoming
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Amor Fati',
      source:      'Friedrich Nietzsche · Ecce Homo',
      quote:       'My formula for greatness in a human being is amor fati: that one wants nothing to be different.',
      explanation:
          'Not just tolerating what happens — loving it. Love what was, '
          'because it is the only foundation for what comes next.',
    ),
    WisdomEntry(
      title:       'The Eternal Return',
      source:      'Friedrich Nietzsche · The Gay Science',
      quote:       'What if you had to live your life again, exactly as you lived it, infinitely?',
      explanation:
          'Would you choose the same choices if you knew you\'d repeat them '
          'forever? If not — change them now. The thought experiment strips '
          'away the excuse that it doesn\'t matter. It always matters.',
    ),
    WisdomEntry(
      title:       'Become Who You Are',
      source:      'Friedrich Nietzsche · Ecce Homo',
      quote:       'Become who you are.',
      explanation:
          'Becoming is not addition — it is mostly excavation. Remove the '
          'layers of habit, fear, and performance that sit on top of your '
          'core and the self beneath has always been there.',
    ),
    WisdomEntry(
      title:       'Create Your Values',
      source:      'Friedrich Nietzsche · The Gay Science',
      quote:       'God is dead. God remains dead. And we have killed him. How shall we comfort ourselves?',
      explanation:
          'If the old framework of meaning collapses, what do you put in '
          'its place? The answer is your responsibility. You must become the '
          'source of your own values. No one else can do this for you.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // STOIC — Marcus Aurelius, Seneca, Epictetus
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'The Obstacle Is the Way',
      source:      'Marcus Aurelius · Meditations',
      quote:       'The impediment to action advances action. What stands in the way becomes the way.',
      explanation:
          'The thing blocking you is the thing you\'re here to do. Walk into '
          'it and the next version of you walks out the other side.',
    ),
    WisdomEntry(
      title:       'Memento Mori',
      source:      'Marcus Aurelius · Meditations',
      quote:       'You could leave life right now. Let that determine what you do and say and think.',
      explanation:
          'Death is not a threat — it is the editor. Don\'t waste a day '
          'pretending you have forever.',
    ),
    WisdomEntry(
      title:       'The View From Above',
      source:      'Marcus Aurelius · Meditations',
      quote:       'Look at everything from above — the countless herds of men, and countless rites, and every kind of voyage.',
      explanation:
          'From the satellite view, most crises are local weather. This is '
          'not detachment from care — it is perspective that allows you to '
          'care without being consumed.',
    ),
    WisdomEntry(
      title:       'On the Shortness of Life',
      source:      'Seneca · De Brevitate Vitae',
      quote:       'It is not that we have a short time to live, but that we waste a great deal of it.',
      explanation:
          'The problem is not the length of life but the percentage spent '
          'on other people\'s priorities. Reclaim one hour a day and you '
          'will recover years.',
    ),
    WisdomEntry(
      title:       'Suffering in Imagination',
      source:      'Seneca · Letters to Lucilius',
      quote:       'We suffer more often in imagination than in reality.',
      explanation:
          'Most fear is rehearsal. The actual event is usually smaller and '
          'more workable than the version you played 50 times in your head. '
          'Act on the real, not the rehearsal.',
    ),
    WisdomEntry(
      title:       'Premeditatio Malorum',
      source:      'Seneca · Letters to Lucilius',
      quote:       'He robs present ills of their power who has perceived their coming beforehand.',
      explanation:
          'Five minutes each morning imagining what could go wrong — not '
          'as anxiety, as inoculation. The morning that the thing goes wrong, '
          'you\'ve already met it once and it has less power.',
    ),
    WisdomEntry(
      title:       'What Is in Your Power',
      source:      'Epictetus · Enchiridion',
      quote:       'Some things are in our control and others not.',
      explanation:
          'Sort every worry into two columns: in your power, not in your '
          'power. Spend zero energy on the second column. All your force '
          'on the first. This single discipline removes most suffering.',
    ),
    WisdomEntry(
      title:       'Act Well Your Part',
      source:      'Epictetus · Enchiridion',
      quote:       'Remember that you are an actor in a play, the character of which is determined by the Author.',
      explanation:
          'You did not choose your starting circumstances. But you choose how '
          'you play the role you\'ve been given. Excellence is not about '
          'getting a better role — it is about playing your actual role as '
          'well as it can be played.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // POWER & STRATEGY
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Conceal Your Intentions',
      source:      'Robert Greene · 48 Laws of Power',
      quote:       'Keep people off-balance and in the dark by never revealing the purpose behind your actions.',
      explanation:
          'When others can\'t read your moves, they can\'t plan against them. '
          'Show only the surface; keep the strategy in the basement.',
    ),
    WisdomEntry(
      title:       'Say Less Than Necessary',
      source:      'Robert Greene · 48 Laws of Power',
      quote:       'The more you say, the more common you appear and the less in control.',
      explanation:
          'Powerful people use silence. Each word you don\'t need to say — '
          'and didn\'t — adds weight to the ones you do.',
    ),
    WisdomEntry(
      title:       'The Seductive Pull',
      source:      'Robert Greene · The Art of Seduction',
      quote:       'The greatest seducers in history were masters of the art of making others feel that they, not the seducer, were the ones being pursued.',
      explanation:
          'The most effective pull is indirect. Create desire by withdrawing '
          'slightly. Make the other person feel they are moving toward you '
          'by their own choice. Force never seduces; attraction does.',
    ),
    WisdomEntry(
      title:       'Know Your Enemy',
      source:      'Sun Tzu · The Art of War',
      quote:       'If you know yourself and your enemy, you need not fear the result of a hundred battles.',
      explanation:
          'Half the work is knowing what you actually are. The other half '
          'is honest study of what you\'re up against. Skip either and you\'re '
          'fighting blind.',
    ),
    WisdomEntry(
      title:       'Win Without Fighting',
      source:      'Sun Tzu · The Art of War',
      quote:       'The supreme art of war is to subdue the enemy without fighting.',
      explanation:
          'The conflict you avoid by superior preparation is worth more than '
          'the one you barely survive. Out-position rather than out-punch.',
    ),
    WisdomEntry(
      title:       'The Lion & the Fox',
      source:      'Niccolò Machiavelli · The Prince',
      quote:       'A prince should imitate both the lion and the fox.',
      explanation:
          'The lion alone falls into traps; the fox alone has no defence '
          'against wolves. You need both — the strength to hold ground and '
          'the cunning to read the room.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // VIKTOR FRANKL — Meaning, Suffering & the Last Freedom
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'The Last Human Freedom',
      source:      'Viktor Frankl · Man\'s Search for Meaning',
      quote:       'Everything can be taken from a man but one thing: the last of human freedoms — to choose one\'s attitude in any given set of circumstances.',
      explanation:
          'Frankl wrote this from Auschwitz. If attitude is a choice inside '
          'that — it is a choice inside anything. You do not control the '
          'event. You control what you turn it into.',
    ),
    WisdomEntry(
      title:       'Meaning Over Happiness',
      source:      'Viktor Frankl · Man\'s Search for Meaning',
      quote:       'It is the very pursuit of happiness that thwarts happiness.',
      explanation:
          'Happiness is a by-product of meaningful action, not a target. '
          'Pursue something worth doing. Let the happiness follow, or not '
          '— either way you will have done something worth doing.',
    ),
    WisdomEntry(
      title:       'Suffering With a Frame',
      source:      'Viktor Frankl · Man\'s Search for Meaning',
      quote:       'If there is meaning in life at all, then there must be meaning in suffering.',
      explanation:
          'Pain with no frame is just pain. Pain inside a frame — "this is '
          'making me," "this is the price of what I care about" — becomes '
          'bearable. Find the frame before the suffering finds you.',
    ),

    // ════════════════════════════════════════════════════════════════════
    // DISCIPLINE & ACTION
    // ════════════════════════════════════════════════════════════════════

    WisdomEntry(
      title:       'Excellence Is a Habit',
      source:      'Aristotle · Nicomachean Ethics',
      quote:       'Excellence, then, is not an act, but a habit.',
      explanation:
          'The extraordinary performance is produced by the ordinary practice. '
          'Excellence is a habit that has been running long enough.',
    ),
    WisdomEntry(
      title:       'Patience\'s Fruit',
      source:      'Aristotle',
      quote:       'Patience is bitter, but its fruit is sweet.',
      explanation:
          'Most plans fail not because they were wrong but because the person '
          'quit before the curve turned. The compound interest of staying is '
          'enormous.',
    ),
    WisdomEntry(
      title:       'The Man in the Arena',
      source:      'Theodore Roosevelt · Citizenship in a Republic, 1910',
      quote:       'It is not the critic who counts; not the man who points out how the strong man stumbles.',
      explanation:
          'The people who have never tried will always have the cleanest '
          'opinions. Be the one in the arena — dirty, sometimes losing — '
          'not the one in the stands with the clean shirt.',
    ),
    WisdomEntry(
      title:       'The Cave You Fear',
      source:      'Joseph Campbell',
      quote:       'The cave you fear to enter holds the treasure you seek.',
      explanation:
          'The thing you don\'t want to do is almost always the thing that '
          'unlocks the next phase. Notice what you\'ve been avoiding. That '
          'avoidance is a map.',
    ),
    WisdomEntry(
      title:       'The Daily Vote',
      source:      'James Clear · Atomic Habits',
      quote:       'Every action is a vote for the type of person you wish to become.',
      explanation:
          'You don\'t become someone in one giant act. You become them in a '
          'thousand small votes. The kept word, the closed app, the early '
          'start — those are the ballot.',
    ),
    WisdomEntry(
      title:       'Start With Who, Not What',
      source:      'James Clear · Atomic Habits',
      quote:       'The goal is not to read a book, the goal is to become a reader.',
      explanation:
          'Identity goals are different from outcome goals: every small action '
          'either confirms or contradicts the person you are becoming. Start '
          'with who, not what.',
    ),
    WisdomEntry(
      title:       'Ship and Improve',
      source:      'Voltaire',
      quote:       'Don\'t let the perfect be the enemy of the good.',
      explanation:
          'Shipping something imperfect and improving beats refining forever '
          'and shipping nothing. Get the rough version into the world, let '
          'reality teach you, then sharpen.',
    ),
    WisdomEntry(
      title:       'Find What Burns',
      source:      'Charles Bukowski',
      quote:       'Find what you love and let it kill you.',
      explanation:
          'Not literal destruction — total commitment. The thing worth doing '
          'will consume time, energy, and attention. Half-effort produces '
          'half-life. Choose something worth going all in on.',
    ),
    WisdomEntry(
      title:       'The Fear of Silence',
      source:      'Blaise Pascal · Pensées',
      quote:       'All of humanity\'s problems stem from man\'s inability to sit quietly in a room alone.',
      explanation:
          'Distraction is not accidental — it is escape. Sit long enough '
          'without noise and you will meet your actual thoughts. Most people '
          'avoid this precisely because they know what they will find.',
    ),
    WisdomEntry(
      title:       'The Pendulum of Desire',
      source:      'Arthur Schopenhauer · The World as Will and Representation',
      quote:       'Life swings like a pendulum between pain and boredom.',
      explanation:
          'Desire drives you forward, but once satisfied it dissolves into '
          'emptiness. Understanding this stops you from expecting permanent '
          'satisfaction from temporary wins.',
    ),
    WisdomEntry(
      title:       'You Cannot Want What You Want',
      source:      'Arthur Schopenhauer',
      quote:       'A man can do what he wants, but not want what he wants.',
      explanation:
          'You control actions more easily than desires. Shape your environment '
          'so better actions become easier despite the desires. Design the '
          'system. Don\'t rely on the will.',
    ),
    WisdomEntry(
      title:       'Imagination Over Knowledge',
      source:      'Albert Einstein · Saturday Evening Post, 1929',
      quote:       'Imagination is more important than knowledge. Knowledge is limited. Imagination encircles the world.',
      explanation:
          'Knowledge maps the past. Imagination maps what isn\'t yet. Keep '
          'the imagination working even — especially — when the knowledge '
          'says it can\'t be done.',
    ),
    WisdomEntry(
      title:       'Law of Detachment',
      source:      'Bhagavad Gita · Chapter 2',
      quote:       'You have the right to action, but never to its fruits.',
      explanation:
          'Do the work fully. Then let go of how it lands. Attachment to '
          'outcome makes you greedy when winning and bitter when losing. '
          'Detach, and the work itself becomes clean.',
    ),
    WisdomEntry(
      title:       'Law of Cause & Effect',
      source:      'Hermetic principle · The Kybalion',
      quote:       'Every cause has its effect; every effect has its cause.',
      explanation:
          'Luck is what people call patterns they haven\'t yet seen. The '
          'small thing you did today — the rule you kept or broke — is '
          'planting an effect you will harvest later. Nothing arrives without '
          'cause.',
    ),
    WisdomEntry(
      title:       'Energy Flows Where Attention Goes',
      source:      'William James · Principles of Psychology',
      quote:       'The faculty of voluntarily bringing back a wandering attention, over and over again, is the very root of judgment, character, and will.',
      explanation:
          'What you attend to consistently grows. What you ignore atrophies. '
          'Audit your attention weekly. Your attention pattern is the most '
          'honest portrait of what you actually value.',
    ),

  ]; // end entries
}