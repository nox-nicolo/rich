// lib/feature/trading/service/news_analysis_engine.dart
//
// Gold-focused news analysis. Takes a raw economic calendar event and
// matches it against a curated knowledge base of how each event type
// typically moves gold (XAUUSD) and WHY.
//
// The engine is deliberately offline + rule-based: no API keys, no
// network calls, deterministic output, and every explanation was hand-
// written so the user can LEARN from it over time rather than just see
// a bull/bear sticker.
//
// To add a new asset later (e.g. NAS100 or EURUSD), copy the _goldRules
// block, swap out the takeaway/why text, and add a new `analyzeFor<X>()`
// method that dispatches off event.headline / event.currency.

import '../model/news_event.dart';
import '../model/news_analysis.dart';

class _Rule {
  /// Lowercase substrings to match against the event headline.
  /// Any match triggers the rule, so keep patterns specific.
  final List<String> patterns;

  /// If non-empty, the event's currency code must be one of these.
  /// (ForexFactory uses 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'NZD', 'CHF', 'CNY'.)
  final List<String> currencies;

  final NewsAnalysis analysis;

  const _Rule({
    required this.patterns,
    this.currencies = const [],
    required this.analysis,
  });
}

class NewsAnalysisEngine {
  NewsAnalysisEngine._();

  /// Returns a gold-specific analysis for the given event, or `null`
  /// if no rule in the knowledge base applies.
  static NewsAnalysis? analyzeForGold(NewsEvent event) {
    final title = event.headline.toLowerCase();
    final cur   = (event.currency ?? '').toUpperCase();

    for (final rule in _goldRules) {
      if (rule.currencies.isNotEmpty && !rule.currencies.contains(cur)) {
        continue;
      }
      for (final p in rule.patterns) {
        if (title.contains(p)) return rule.analysis;
      }
    }
    return null;
  }

  // ── Knowledge base ──────────────────────────────────────────────────────
  //
  // Rules are evaluated top-to-bottom. More specific rules first, so that
  // e.g. "Fed Chair Powell Speaks" matches the Chair rule before the
  // generic FOMC member rule.

  static final List<_Rule> _goldRules = [
    // ── Fed policy — the biggest single driver of gold ──────────────────

    _Rule(
      patterns: [
        'federal funds rate',
        'fomc statement',
        'fomc economic projections',
        'fomc press conference',
      ],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Fed rate decision — the single biggest driver of gold.',
        why:
            'The Federal Reserve sets US interest rates, which directly set '
            'the opportunity cost of holding gold. Gold pays no yield, so when '
            'real rates (nominal rate minus inflation) rise, gold becomes less '
            'attractive vs Treasuries — money rotates out, price falls. A '
            'hawkish Fed (hike, or hold with tough language) typically sinks '
            'gold. A dovish Fed (cut, pause, or soft language about growth) '
            'lifts it. Rate days produce the biggest intraday moves of the '
            'month — 1–2% is normal, bigger on surprise.',
        beatScenario:
            'Hike or hawkish hold → USD up, real yields up → GOLD DOWN',
        missScenario:
            'Cut or dovish tone → USD down, real yields down → GOLD UP',
        whatToWatch:
            'The dot plot (future rate projections), Powell\'s tone in the '
            'press conference, and the 2-year Treasury yield. Gold moves '
            'almost perfectly inverse to the 2-year on Fed days.',
      ),
    ),

    _Rule(
      patterns: ['fomc meeting minutes', 'fomc minutes'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Minutes reveal how hawkish/dovish the Fed REALLY is.',
        why:
            'Released 3 weeks after each FOMC meeting. Traders comb the text '
            'for language that shifts expectations about the next rate move. '
            'Minutes that sound more hawkish than the meeting itself (more '
            'worry about inflation, more willingness to hold rates) knock gold '
            'down. Minutes that sound softer (worry about growth or banks) '
            'push gold up. Often a 0.3–0.8% move on release.',
        whatToWatch:
            'Count mentions of "persistent inflation" vs "downside risks to '
            'growth". The balance of language is what moves price.',
      ),
    ),

    _Rule(
      patterns: ['fed chair', 'chair powell', 'powell speaks', 'powell testimony'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Powell speeches routinely swing gold \$15–30/oz in minutes.',
        why:
            'The Fed Chair is the single most-watched voice in markets. Any '
            'phrase that shifts the market\'s view on the next rate move hits '
            'gold instantly. Dovish phrases ("data dependent", "getting '
            'closer to neutral", "progress on inflation") rally gold. Hawkish '
            'phrases ("more work to do", "higher for longer", "not yet '
            'confident") sink it. The market reacts to CHANGES in tone from '
            'his previous appearance, not the absolute hawkishness level.',
        whatToWatch:
            'Compare his wording to his previous speech — does he sound more '
            'worried about inflation, or more worried about jobs/growth? '
            'That delta is the trade.',
      ),
    ),

    _Rule(
      patterns: ['fomc member', 'fed governor', 'fed\'s '],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Non-Chair Fed speakers move gold less, but still move it.',
        why:
            'Regional Fed presidents and governors give speeches that hint '
            'at the direction of rate policy. Well-known hawks (Bullard, '
            'Kashkari, Mester historically) pushing tough language → small '
            'gold sell-off. Known doves (Brainard, Bostic, Evans) sounding '
            'soft → small gold rally. Less weight than Powell, but enough '
            'to matter when gold is sitting near a technical level.',
      ),
    ),

    // ── Jobs data ─────────────────────────────────────────────────────────

    _Rule(
      patterns: [
        'non-farm employment change',
        'non-farm payrolls',
        'nonfarm payrolls',
        'non farm payrolls',
        'nfp',
      ],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'NFP beat → gold down. NFP miss → gold up.',
        why:
            'Non-Farm Payrolls is the most-watched US jobs report. A strong '
            'print tells the market the economy is hot enough that the Fed '
            'can keep rates high (or hike further) without causing a '
            'recession. That strengthens the dollar and pushes gold down. A '
            'weak print flips the story — the Fed will have to cut sooner, '
            'real yields fall, and gold rallies. NFP Friday usually produces '
            'the single biggest gold move of the first week of each month.',
        beatScenario: 'Payrolls > forecast → USD up → GOLD DOWN',
        missScenario: 'Payrolls < forecast → USD down → GOLD UP',
        whatToWatch:
            'Also watch Average Hourly Earnings in the same release — hot '
            'wages = hot inflation expectations = bearish gold, even if the '
            'headline payroll number is in line.',
      ),
    ),

    _Rule(
      patterns: ['unemployment rate'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Lower unemployment = strong economy = gold down.',
        why:
            'Unemployment is the cleanest single number on US labor-market '
            'health. Lower-than-expected unemployment says the economy is '
            'still hot enough to handle Fed tightening — dollar up, gold '
            'down. Higher unemployment tells the market the Fed has over-'
            'tightened and will have to cut — dollar down, gold up.',
        beatScenario:
            'Unemployment LOWER than forecast → USD up → GOLD DOWN',
        missScenario:
            'Unemployment HIGHER than forecast → USD down → GOLD UP',
      ),
    ),

    _Rule(
      patterns: ['adp non-farm', 'adp employment', 'adp payroll'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'ADP is NFP\'s warm-up — same direction, smaller impact.',
        why:
            'ADP Employment Change is released two days before NFP and '
            'measures US private-sector payrolls. Same logic as NFP: beat = '
            'hawkish Fed narrative = gold down; miss = dovish Fed narrative = '
            'gold up. ADP has only a loose correlation with the official NFP '
            'number, so a big ADP surprise can move gold \$5–15/oz, but the '
            'move often gets faded before Friday.',
      ),
    ),

    _Rule(
      patterns: ['jolts job openings', 'job openings'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Too many job openings = hot labor = hawkish Fed = gold down.',
        why:
            'JOLTS (Job Openings and Labor Turnover Survey) measures the '
            'number of unfilled US jobs. The Fed watches this closely because '
            'lots of openings means labor demand > labor supply, which keeps '
            'wage growth hot, which keeps core inflation sticky. A hot JOLTS '
            'print is a green light for the Fed to stay tight — bearish for '
            'gold. A cool JOLTS print signals the labor market is softening '
            '— bullish for gold.',
        beatScenario: 'Openings > forecast → Fed stays hawkish → GOLD DOWN',
        missScenario: 'Openings < forecast → Labor softening → GOLD UP',
      ),
    ),

    _Rule(
      patterns: ['unemployment claims', 'jobless claims', 'initial claims'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Weekly jobless claims — rising = recession fear = gold up.',
        why:
            'Weekly initial jobless claims are the highest-frequency jobs '
            'indicator. Rising claims → labor market cracking → Fed cuts '
            'sooner → gold up. Falling claims → labor market hot → Fed stays '
            'tight → gold down. Small weekly moves are noise; trend matters '
            'more than any single print.',
      ),
    ),

    // ── Inflation ─────────────────────────────────────────────────────────

    _Rule(
      patterns: [
        'core cpi',
        'cpi m/m',
        'cpi y/y',
        'consumer price index',
      ],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Hot CPI = hawkish Fed = gold down (short term).',
        why:
            'CPI measures US inflation. In classical theory, inflation is '
            'BULLISH for gold because gold is an inflation hedge. In today\'s '
            'market, though, CPI trades as a "Fed reaction" event: hot CPI → '
            'Fed hikes or stays tight → real rates rise → gold falls. Cooler '
            'CPI → Fed can pause or cut → real rates fall → gold rallies. '
            'The Fed-reaction channel has dominated gold flows since 2022.',
        beatScenario: 'CPI HOTTER than forecast → Fed hawkish → GOLD DOWN',
        missScenario: 'CPI COOLER than forecast → Fed dovish → GOLD UP',
        whatToWatch:
            'Core CPI (ex food & energy) matters more than headline because '
            'the Fed targets core. Month-over-month is what they watch '
            'closest — annualized m/m is the key number.',
      ),
    ),

    _Rule(
      patterns: ['core pce', 'pce price index', 'pce m/m', 'pce y/y'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'PCE is the Fed\'s PREFERRED inflation gauge.',
        why:
            'The Fed targets 2% inflation using PCE, not CPI — so PCE '
            'surprises move rate expectations directly. Same logic as CPI: '
            'hotter PCE → hawkish Fed → gold down; cooler PCE → dovish Fed → '
            'gold up. Core PCE (ex food & energy) is the single most '
            'important inflation number the Fed watches.',
        beatScenario: 'PCE HOTTER than forecast → GOLD DOWN',
        missScenario: 'PCE COOLER than forecast → GOLD UP',
      ),
    ),

    _Rule(
      patterns: ['ppi m/m', 'ppi y/y', 'producer price', 'core ppi'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'PPI previews next month\'s CPI — smaller but same direction.',
        why:
            'Producer Price Index measures wholesale prices at the factory '
            'gate, before they reach consumers. Hot PPI often leaks into CPI '
            'a month later, so traders front-run the Fed reaction. Same '
            'direction as CPI: hot PPI → gold down; soft PPI → gold up. '
            'Smaller impact than CPI itself.',
      ),
    ),

    // ── Growth / activity ─────────────────────────────────────────────────

    _Rule(
      patterns: [
        'gdp m/m',
        'gdp q/q',
        'advance gdp',
        'gross domestic product',
        'gdp price',
      ],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Strong US growth = strong USD = gold down.',
        why:
            'GDP is the broadest measure of US economic activity. A strong '
            'print confirms the Fed has room to keep rates restrictive — USD '
            'up, gold down. A weak print raises recession fears — Fed cut '
            'bets rise, gold up. GDP matters less intraday than jobs and '
            'inflation, but it sets the medium-term trend for the dollar '
            'and therefore for gold.',
      ),
    ),

    _Rule(
      patterns: ['retail sales', 'core retail sales'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Strong consumer = strong economy = gold down.',
        why:
            'Retail Sales measures US consumer spending, which is ~70% of '
            'GDP. A hot print means the consumer is still healthy and the '
            'Fed can keep fighting inflation → dollar up → gold down. A weak '
            'print means demand is breaking → Fed cuts sooner → gold up. '
            'Moderate impact — usually a \$5–15/oz move.',
        beatScenario: 'Retail Sales BEAT → GOLD DOWN',
        missScenario: 'Retail Sales MISS → GOLD UP',
      ),
    ),

    _Rule(
      patterns: [
        'ism manufacturing',
        'ism services',
        'ism non-manufacturing',
        'ism composite',
      ],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'ISM > 50 = expansion = gold down | < 50 = contraction = gold up.',
        why:
            'ISM Purchasing Managers Indexes are survey-based forward '
            'indicators of US manufacturing and services activity. The 50 '
            'line separates expansion from contraction. A big beat deeper '
            'into expansion = hawkish Fed narrative = gold down. A miss '
            'slipping into contraction = recession fear = Fed cuts = gold '
            'up. The Prices-Paid sub-index is also a CPI leading indicator '
            'and moves gold on its own.',
      ),
    ),

    _Rule(
      patterns: ['consumer confidence', 'consumer sentiment', 'umich'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Confident consumers keep spending = Fed hawkish = gold down.',
        why:
            'Consumer confidence surveys (Conference Board, University of '
            'Michigan) signal future spending intent. High confidence '
            'supports the "strong US economy" narrative — dollar up, gold '
            'down. Low confidence hints at upcoming spending weakness — '
            'gold up. Moderate impact, but the UMich survey also publishes '
            'inflation expectations, which the Fed explicitly watches.',
      ),
    ),

    _Rule(
      patterns: ['durable goods orders', 'core durable goods'],
      currencies: ['USD'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Durable goods = business investment pulse.',
        why:
            'Durable Goods Orders track big-ticket manufacturing orders '
            '(machinery, vehicles, aircraft). A strong print means businesses '
            'are confident enough to invest — supports hawkish Fed narrative '
            '→ gold down. A weak print flags slowing investment → dovish Fed '
            '→ gold up. Small impact unless a big surprise.',
      ),
    ),

    // ── Non-US events that still move gold via DXY ─────────────────────────

    _Rule(
      patterns: [
        'main refinancing rate',
        'ecb press conference',
        'ecb monetary policy',
        'ecb interest rate',
      ],
      currencies: ['EUR'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'Hawkish ECB weakens DXY → gold usually up.',
        why:
            'Gold is priced in USD, so anything that moves the Dollar Index '
            '(DXY) moves gold. The Euro is ~57% of DXY, so the ECB rate '
            'decision is the single biggest non-Fed event for gold. Hawkish '
            'ECB → EUR rallies → DXY falls → gold rises. Dovish ECB → EUR '
            'falls → DXY rises → gold falls. Expect a 0.3–0.8% gold swing '
            'in the first hour.',
      ),
    ),

    _Rule(
      patterns: ['bank of england', 'official bank rate', 'boe monetary', 'mpc official'],
      currencies: ['GBP'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'BoE moves GBP → small indirect effect on gold via DXY.',
        why:
            'Bank of England rate decisions. GBP is ~12% of the Dollar '
            'Index, so BoE surprises nudge DXY and therefore gold. Smaller '
            'effect than the ECB, but on a big surprise it\'s enough to '
            'kick gold \$5–10/oz in the first minutes.',
      ),
    ),

    _Rule(
      patterns: ['boj', 'bank of japan', 'monetary policy statement'],
      currencies: ['JPY'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'BoJ surprises spike JPY → risk-off = gold up.',
        why:
            'The Bank of Japan is the world\'s biggest dove — any step toward '
            'normalizing rates is a genuine surprise and triggers a global '
            'unwind of yen carry trades. JPY spikes, risk assets wobble, and '
            'gold usually benefits from the risk-off flow plus the indirect '
            'DXY weakening.',
      ),
    ),

    _Rule(
      patterns: ['china cpi', 'china gdp', 'china manufacturing pmi', 'china pmi'],
      analysis: NewsAnalysis(
        asset: 'XAUUSD',
        assetDisplay: 'GOLD',
        direction: AnalysisDirection.volatile,
        takeaway: 'China is the biggest physical gold buyer — its data matters.',
        why:
            'China and India together account for ~50% of global physical '
            'gold demand. Strong China data = strong demand narrative for '
            'commodities including gold → mildly bullish. Weak China data → '
            'demand worry → mildly bearish. Smaller immediate reaction than '
            'US data, but shapes the multi-week trend.',
      ),
    ),
  ];
}
