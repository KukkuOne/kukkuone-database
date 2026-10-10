/**
 * The broiler disease catalogue.
 *
 * Seeded rather than typed so that a finding, a diagnosis and eventually a
 * model's output all name the same thing. Two vets spelling Gumboro
 * differently would otherwise become two diseases, and a dataset split across
 * both is a dataset that cannot be trained on.
 *
 * `notifiable` is not decoration. Newcastle disease and avian influenza must
 * be reported to the authorities in India; an app that files a confirmed case
 * quietly is part of the problem, so the flag is here to make the duty
 * visible at the point it is diagnosed.
 *
 * Telugu names are the ones farmers actually use where they exist. Where a
 * disease is only ever called by its English name in the field, nameTe is
 * null rather than a literal translation nobody would say out loud.
 */
export const DISEASES: Array<{
  code: string;
  name: string;
  nameTe?: string;
  summary?: string;
  summaryTe?: string;
  notifiable?: boolean;
}> = [
  {
    code: 'NEWCASTLE',
    name: 'Newcastle disease (Ranikhet)',
    nameTe: 'కొక్కెర వ్యాధి (రాణిఖేత్)',
    summary:
      'Sudden deaths, greenish droppings, gasping, twisted neck in survivors. '
      + 'Spreads fast through a shed and between farms.',
    summaryTe:
      'అకస్మాత్తుగా చనిపోవడం, ఆకుపచ్చ రెట్టలు, ఊపిరి తీసుకోవడంలో ఇబ్బంది, మెడ వంకరపోవడం. '
      + 'షెడ్‌లో వేగంగా వ్యాపిస్తుంది.',
    notifiable: true,
  },
  {
    code: 'AVIAN_INFLUENZA',
    name: 'Avian influenza',
    nameTe: 'బర్డ్ ఫ్లూ',
    summary:
      'Very high sudden mortality, swollen blue combs and wattles, severe drop '
      + 'in feed and water. Report immediately.',
    summaryTe:
      'ఒక్కసారిగా చాలా ఎక్కువ మరణాలు, కొమ్ము నీలంగా వాపు, దాణా నీరు బాగా తగ్గడం. '
      + 'వెంటనే తెలియజేయాలి.',
    notifiable: true,
  },
  {
    code: 'GUMBORO',
    name: 'Infectious bursal disease (Gumboro)',
    nameTe: 'గంబోరో',
    summary:
      'Hits around three weeks. Watery droppings, huddling, swollen then '
      + 'shrunken bursa. Leaves birds open to everything else.',
    summaryTe:
      'సుమారు మూడు వారాల వయసులో వస్తుంది. నీటి రెట్టలు, గుంపుగా చేరడం, బర్సా వాపు. '
      + 'తరువాత ఇతర వ్యాధులు సులభంగా సోకుతాయి.',
  },
  {
    code: 'COCCIDIOSIS',
    name: 'Coccidiosis',
    nameTe: 'రక్త విరేచనాలు',
    summary:
      'Blood or orange mucus in droppings, ruffled birds, poor weight. Comes '
      + 'with wet litter.',
    summaryTe:
      'రెట్టలలో రక్తం లేదా నారింజ రంగు జిగురు, ఈకలు చెదరడం, బరువు తగ్గడం. '
      + 'తడి లిట్టర్‌తో వస్తుంది.',
  },
  {
    code: 'CRD',
    name: 'Chronic respiratory disease (Mycoplasma)',
    nameTe: 'శ్వాసకోశ వ్యాధి',
    summary:
      'Rattling breath, nasal discharge, swollen face. Worse in dusty sheds '
      + 'and with poor ventilation.',
    summaryTe:
      'ఊపిరిలో గరగర శబ్దం, ముక్కు కారడం, ముఖం వాపు. దుమ్ము, గాలి ఆడని షెడ్‌లో ఎక్కువ.',
  },
  {
    code: 'COLIBACILLOSIS',
    name: 'Colibacillosis (E. coli)',
    nameTe: 'ఈ-కొలై ఇన్ఫెక్షన్',
    summary:
      'Follows other infections or bad litter. Fibrin over heart and liver on '
      + 'post-mortem, air sacs cloudy.',
    summaryTe:
      'ఇతర ఇన్ఫెక్షన్ల తరువాత లేదా చెడ్డ లిట్టర్‌తో వస్తుంది. గుండె కాలేయంపై పొర, '
      + 'గాలి సంచులు మబ్బుగా.',
  },
  {
    code: 'SALMONELLOSIS',
    name: 'Salmonellosis',
    nameTe: 'సాల్మొనెల్లా',
    summary:
      'Chick mortality in the first fortnight, white pasty vents, unabsorbed '
      + 'yolk sacs.',
    summaryTe:
      'మొదటి రెండు వారాలలో పిల్లల మరణాలు, తెల్లని అంటుకునే రెట్టలు, '
      + 'పచ్చసొన ఇంకిపోకపోవడం.',
  },
  {
    code: 'MAREKS',
    name: "Marek's disease",
    summary:
      'Older birds, leg or wing paralysis, enlarged nerves, tumours on organs. '
      + 'Vaccine failure at the hatchery is the usual story.',
  },
  {
    code: 'IB',
    name: 'Infectious bronchitis',
    summary: 'Gasping and sneezing, kidney damage in some strains, wet litter.',
  },
  {
    code: 'ASCITES',
    name: 'Ascites (water belly)',
    nameTe: 'పొట్టలో నీరు',
    summary:
      'Fast-growing birds, swollen abdomen full of fluid, right heart enlarged. '
      + 'A growth-rate and oxygen problem rather than an infection.',
    summaryTe:
      'వేగంగా పెరిగే కోళ్లలో, పొట్టలో నీరు చేరి ఉబ్బడం. ఇది ఇన్ఫెక్షన్ కాదు.',
  },
  {
    code: 'NECROTIC_ENTERITIS',
    name: 'Necrotic enteritis',
    summary:
      'Often rides on coccidiosis. Dark droppings, ballooned gut with a rough '
      + 'lining on post-mortem.',
  },
  {
    code: 'AFLATOXICOSIS',
    name: 'Aflatoxicosis',
    nameTe: 'బూజు దాణా విషం',
    summary:
      'Mouldy feed. Pale enlarged liver, poor growth across the whole batch '
      + 'rather than scattered birds.',
    summaryTe:
      'బూజు పట్టిన దాణా వల్ల. కాలేయం పాలిపోయి ఉబ్బడం, బ్యాచ్ మొత్తం పెరుగుదల తగ్గడం.',
  },
  {
    code: 'HEAT_STRESS',
    name: 'Heat stress',
    nameTe: 'వేడి ఒత్తిడి',
    summary:
      'Panting, wings held out, crowding at the drinkers, deaths in the hottest '
      + 'hours. Not an infection — a shed problem.',
    summaryTe:
      'ఎగశ్వాస, రెక్కలు విప్పడం, నీటి దగ్గర గుమిగూడటం, మధ్యాహ్నం మరణాలు. '
      + 'ఇది ఇన్ఫెక్షన్ కాదు, షెడ్ సమస్య.',
  },
  {
    code: 'OTHER',
    name: 'Something else',
    summary:
      'Kept deliberately. A vet who cannot name it must still be able to '
      + 'record what they saw, and a pile of these is how the catalogue learns '
      + 'what it is missing.',
  },
];
