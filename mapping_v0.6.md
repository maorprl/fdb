# Finder / FDB — נקודת המשך לצ׳אט חדש: Key Audit הושלם, ERD טרם נבנה

**גרסה 0.6, 19.11.2026.** מסמך זה משלב את גרסה 0.5 המקורית ואת כל הממצאים שנוספו מאז. **כאשר יש סתירה בין הנספח המעודכן שמופיע כאן ראשונה לבין גרסה 0.5 המובאת בהמשך — העדכון הזה גובר.** לא בוצעו שינויים בנתוני BigQuery במסגרת מיפוי המפתחות. המשתמש מדגיש: לא לקבוע כללים עסקיים נורמטיביים, לא לנחש קשרים, לא לחקור מחדש בדיקות שכבר הושלמו.

## מצב עדכני — מה לעשות בצ׳אט החדש

- המטרה: **להפיק ERD תיאורי ראשון ומדויק של 16 טבלאות הליבה** בפרויקט BigQuery `fdb-sql-lab`, dataset `fdb`, עם PK לוגי, קשרי FK לוגיים, כיווניות/קרדינליות שנצפו, חריגות שלמות הפניה וסימון רמת אימות לכל קשר.
- **Key Audit סגור בהיקף שנקבע**: בכל 16 הטבלאות `id` ייחודי, ללא NULL וללא כפילויות, על סמך שאילתות שנסרקו. זהו PK *מועמד לוגי*, **לא אילוץ DB**. השאילתה על `INFORMATION_SCHEMA.TABLE_CONSTRAINTS` החזירה **אפס שורות**: אין אילוצי PK/FK שהוגדרו במפורש ב־dataset הנוכחי (אין בכך מסקנה על מערכת Finder המקורית).
- **לא הושלם ERD עדיין**. צריך להמיר את הממצאים לקשרי דיאגרמה. לא לייצר FK מלאכותיים בין שני מודלי הגיוסים (`BaseEvent`/`New_Funding_Round`) או בין מודלי החדשות.
- `Tag_Relations` **מחוץ לתרשים המרכזי לפי החלטת המשתמש**. יתר ארבע טבלאות העזר של תגיות ו־`Events` העצמאית אינן חלק מ־16 הליבה כרגע. טבלת המשתמשים שבבסיס `New_Member.user` אינה קיימת בהיקף הנוכחי. סיווג Public/Private Funding נדחה לפוסט־סיווג. אין צורך לחקור שוב את Visibility/Exit אלא לתעד מסקנות והסתייגויות.

## 16 טבלאות הליבה

`New_Company`, `New_Member`, `News`, `CompanyNews`, `New_Company_news`, `BaseClassificationModel`, `BaseClassificationRelationModel`, `BaseClassificationCompanyModel`, `New_Tag`, `New_Company_Tag`, `BaseEvent`, `BaseEvent_investors`, `BaseEvent_grantors`, `New_Funding_Round`, `New_Funding_Round_known_investors`, `New_Funding_Round_unknown_investors`.

## השלמת Key Audit מאז גרסה 0.5

### ייחודיות `id`

- 15 הטבלאות המקוריות: **15/15 PASS**; דוח של 15 שורות, לכל טבלה `null_ids=0`, `duplicated_id_values=0`, `extra_duplicate_rows=0`.
- `New_Member` נטענה על ידי המשתמש ואומתה ב־BigQuery: **64,224 רשומות, 27 עמודות, 64,224 מזהי `id` שונים, 0 מזהי `id` חסרים**. אין טבלה דרוסה לפי דיווח המשתמש.
- סך הכול **16/16 PK לוגיים מועמדים**.

### ייחודיות זוגות שדות בטבלאות קישור

| טבלה | סה״כ רשומות | זוגות חסרים רכיב | זוגות שונים | צמדים כפולים | רשומות עודפות |
|---|---:|---:|---:|---:|---:|
| `CompanyNews` | 94,854 | 0 | 94,854 | 0 | 0 |
| `BaseEvent_grantors` | 1,859 | 68 | 1,790 | 1 | 1 |
| `BaseEvent_investors` | 32,988 | 32 | 32,941 | 14 | 15 |
| `New_Company_news` | 57,097 | 9,494 | 47,482 | 120 | 121 |
| `New_Funding_Round_known_investors` | 11,610 | 0 | 11,603 | 7 | 7 |
| `New_Funding_Round_unknown_investors` | 11,499 | 0 | 11,485 | 12 | 14 |

- `BaseEvent_grantors`: הצמד היחיד הכפול הוא **שתי רשומות זהות בכל העמודות מלבד `id`** (`records=2`, `distinct_versions_without_id=1`).
- `BaseEvent_investors`: 14 צמדים כפולים; בתוכן של חלקם הבדלים בסכומי השקעה, `follow_on` וכדומה. **אין להסיק grain ייחודי ברמת אירוע+משקיע או למחוק כפילויות.**
- `New_Funding_Round_known_investors`: כל **7** הצמדים הכפולים זהים במלוא התוכן פרט ל־`id`.
- `New_Funding_Round_unknown_investors`: כל **12** הצמדים הכפולים זהים במלוא התוכן פרט ל־`id` (14 רשומות עודפות).
- `New_Company_news`: מתוך 120 צמדים כפולים, **9** זהים מלבד `id`, **111** מכילים הבדלי תוכן; שדות משתנים לפי מספר צמדים: `source` ב־103, `author` ב־90, `news_url` ב־1; `news_date`, `news_summary`, `news_description`, `visible` — 0. הספירות חופפות.
- `New_Member`: שני השדות `company`+`user` מאוכלסים יחד ב־63,985 רשומות, 62,266 צמדים שונים, 940 צמדים כפולים, 1,719 רשומות עודפות. לכן **הצמד אינו מפתח ייחודי**.

### FK מועמדים נוספים שנבדקו

| מקור | יעד מועמד | מאוכלס | תואם | לא תואם | מסקנה נתונית |
|---|---|---:|---:|---:|---|
| `BaseEvent.acquired_company_entity_key` | `New_Company.id` | 67 | 67 | 0 | בשימוש בעיקר `ReverseMergerEvent` (63), `SpacEvent` (3), `POEvent` (1) |
| `BaseEvent.institution_entity_key` | `New_Company.id` | 4,417 | 4,217 | 200 | רק `GraduationEvent` |
| `BaseEvent.merged_with_entity_key` | `New_Company.id` | 23 | 23 | 0 | רק `SpacEvent` |
| `New_Company.acquired_by_key` | `New_Company.id` | 796 | 788 | 8 | הפניה עצמית מועמדת |
| `New_Company.primary_sector_key` | `BaseClassificationModel.id` | 14,182 | 14,182 | 0 | התאמה מלאה של מאוכלסים |
| `New_Company.tto_key` | `New_Company.id` | 1,904 | 1,904 | 0 | הפניה עצמית מועמדת |
| `BaseEvent.community_key` | `New_Company.id` | 202 | 199 | 3 | רק `CommunityInvolvementEvent`; יעד מסוגים `Community`, `Accelerator`, `Corporate Accelerator`, `Entrepreneurship Program`, `Co-Working Space`; 128 מזהים שונים |
| `New_Company.r_d_due_to_acquisition_key` | `New_Company.id` | 96 | 87 | 9 | כל 87 היעדים שהתאימו הם `type=Startup`; 96 מזהים שונים |
| `New_Member.company` | `New_Company.id` | 64,010 | 62,727 | 1,283 | 214 NULL; 938 מזהים שונים שלא נמצאו; 0 מחרוזות ריקות; קשר לוגי N:1 |

- שלושה קשרים מועמדים **שלא נמצאה להם אף התאמה ל־`New_Member.id`**: `New_Company.member_verified_data_id` (44 מאוכלסים, 0 התאמות), `New_Company.register_id` (12,884, 0), `New_Company.user_key` (173, 0).
- `New_Member.user`: 64,199 מאוכלסים, 59,145 ערכים שונים. המשתמש הסביר שזה מתייחס **לטבלת משתמשים חיצונית לסכמה**, ולכן לא מציגים FK ל־`New_Member` עצמו.
- קיימת חפיפה *במרחב המזהים* בין `New_Member.user` לבין שדות יוצר/מעדכן: `BaseEvent.creator_key` 17,770 התאמות מתוך 37,185, `BaseEvent.updator_key` 19,585/37,210, `New_Company.creator_id` 14,346/27,654, `New_Company.last_modifier_id` 12,789/21,698, `New_Company.updator_id` 8,914/16,524, `New_Company.user_key` 118/173, `New_Company.member_verified_data_id` 30/44. זו **לא הוכחת FK** כי `New_Member.user` אינו מפתח ייחודי. `register_id` ו־`investors_lead_partner_key` לא התאימו. `BaseEvent_grantors.grantors_lead_partner_key` ריק לחלוטין.

### מזהים היסטוריים וחיצוניים

| שדה | מאוכלס | distinct_nonempty | duplicate_excess |
|---|---:|---:|---:|
| `New_Company.crunchbase_id` | 9,865 | 9,845 | 20 |
| `New_Company.old_key` | 41 | 41 | 0 |
| `New_Company_Tag.old_key` | 23,796 | 23,796 | 0 |
| `New_Funding_Round.old_key` | 0 | 0 | 0 |
| `New_Tag.old_key` | 882 | 882 | 0 |

אלה אינם FK מוכחים רק משום שהם ייחודיים. `New_Funding_Round.joint_companies`: 11,716 רשומות, רק **10** לא ריקות, 10 ערכים שונים, דוגמאות הן שמות חברות בטקסט חופשי, לעתים כמה באותו ערך. **לא אותר FK**.

### אילוצים פיזיים

השאילתה `fdb-sql-lab.fdb.INFORMATION_SCHEMA.TABLE_CONSTRAINTS` עם `KEY_COLUMN_USAGE` החזירה **There is no data to display** (אפס שורות). **אין אילוצי PK/FK מוצהרים** במאגר BigQuery הנוכחי. כל הקשרים המתועדים מבוססים על בדיקות התאמה לוגיות, לא על אילוץ DB, ואינם מבטיחים אכיפת referential integrity.

### סטטוס מיפוי Events / Funding

- כל סוגי האירועים ממופים ברמת **רשימת event_type**, אבל **לא כל שדה עסקי** של כל אירוע הוסבר. אין להציג זאת כהוכחה להבנה מלאה של משמעות האירועים.
- Funding: שני מודלים מקבילים. `New_Funding_Round` ו־`BaseEvent` **אין ביניהם FK מאומת**; 6,858 התאמות חד־חד־ערכיות לפי חברה/תאריך/סכום במחקר מוקדם בלבד, לא כלל join אוניברסלי.
- Visibility: זוהו שדות והרכבי הרשאות באירוע/סכום/סוג מימון/זהות משקיע/סכום משקיע; קדימות הרשאות ומשמעות NULL לא הוכחו.
- `is_exit`: 2,979 אירועים עם ערך 1; כולם באחד מארבעת הסוגים `MNAEvent`, `POEvent`, `ReverseMergerEvent`, `SpacEvent`. 2,975 מדורגים ראשונים ו־4 חולקים תאריך מדויק עם אירוע מוקדם באותו יום (ולכן ה־ROW_NUMBER לא מוכיח סדר עסקי). 143 אירועים מתועדים ראשונים מסומנים 0, כך שלא לגזור `is_exit` באופן אוטומטי מן המיקום הכרונולוגי.
- `New_Funding_Round` **סוגי גיוס** נשמרים ב־`type_`, `BaseEvent` ב־`funding_type_funding_type`. Public/Private Funding **אינו עמודה מאומתת** ונדחה לפוסט־סיווג.

## אופן העבודה הבא

ליצור **מטריצת קשרים ו־ERD של 16 טבלאות**, תחילה קשרים מאומתים וחלקיים בלבד. לציין בשדה נפרד כל קשר משוער/מותנה ב־event_type, כל ספירת FK שלא התאימה, grain וטבלאות bridge עם כפילויות עסקיות. לא להציג `New_Member.user` כמפתח ישיר ל־`New_Member.id`; לא לבצע UNION ALL של שני מודלי funding כאילו הם לא חופפים; לא לשנות BigQuery או ליצור אילוצים פיזיים. **אין צורך לחזור על Key Audit** שהושלם אלא אם מתגלה סתירה ממוקדת.

---

# נספח מקור — מסמך גרסה 0.5 לפני השלמת Key Audit והוספת `New_Member`

# Finder / FDB — מיפוי מסד נתונים: מסמך מצב תיאורי ומבוסס בדיקות

**גרסה:** 0.5 — 19 בנובמבר 2026  
**היסטוריה מגרסה 0.3:** הוגדר ההבדל בין מלאי 21 הטבלאות לבין היקף ה־ERD המרכזי; הוחרגה `Tag_Relations` מן התרשים המרכזי בהתאם להחלטה בשיחה; שאר טבלאות העזר נותרו לבחינת רלוונטיות, ללא קביעה שהן מיותרות.  
**סביבת נתונים:** BigQuery, `fdb-sql-lab.fdb`  
**בסיס ראייתי:** תוצאות שאילתות SQL שהורצו על ידי המשתמש במהלך השיחה; מבנה העמודות מקובץ `INFORMATION_SCHEMA.COLUMNS`.  
**מטרה:** לשמר ממצאי מדידות ל־ERD תיאורי ולהבחין בין קשרי נתונים שנבדקו, פרשנויות שטרם הוכחו ותחומים שלא מופו.  
**היקף:** זוהו בסכמה 21 טבלאות ו־342 עמודות. זהו מלאי המקור, **לא יעד מחייב להכללה ב־ERD**. התרשים המרכזי צריך לשקף את הטבלאות והקשרים הרלוונטיים למודל שהוגדר; לא כל טבלת עזר חייבת להופיע בו.  
**אין בקובץ זה שינוי נתונים או המלצה למחוק רשומות.**

## מצב כולל

**מיפוי חלקי מתקדם — לא ERD סופי.** הבדיקות האחרונות משלימות את *התיאור הנתוני* של Visibility ושל דפוסי `is_exit`, אך לא מאמתות את הלוגיקה העסקית/ההרשאתית של המוצר. Public/Private Funding נשאר סיווג נגזר אפשרי **שלא הוגדר כעת**.

## היקף ה־ERD — מיפוי המרכז מול טבלאות העזר (עדכון 0.4)

הטבלאות חולקו לצורך ניהול המיפוי, **לא** כטענה שהטבלאות שאינן בליבה חסרות ערך או שאין בהן מידע רלוונטי לשימושים אחרים.

- **15 טבלאות שנכללות כרגע במיפוי הליבה:** `New_Company`; `News`, `CompanyNews`, `New_Company_news`; `BaseClassificationModel`, `BaseClassificationRelationModel`, `BaseClassificationCompanyModel`; `New_Tag`, `New_Company_Tag`; `BaseEvent`, `BaseEvent_investors`, `BaseEvent_grantors`; `New_Funding_Round`, `New_Funding_Round_known_investors`, `New_Funding_Round_unknown_investors`. נוכחותן ברשימה אינה אומרת שכל פרט בהן הושלם.
- **טבלה נוספת שטרם הוכרע אם היא בתחום התרשים המרכזי:** `Events` — טבלת אירועים עצמאית, עם `entity_id`, `title`, `start_date`, `end_date`, ועוד; אין לבלבל בינה לבין `BaseEvent`. הקישור הלוגי של `Events.entity_id` טרם נבדק.
- **טבלת עזר שהוחרגה בהסכמה מן ה־ERD המרכזי:** `Tag_Relations`. ידוע שקיימים בה 418 קשרי parent/child וחלקם מצביעים ל־`New_Tag`, אבל אין הכרח להראות אותם במפת הנתונים המרכזית.
- **ארבע טבלאות עזר שטרם הוכרעה רלוונטיותן:** `New_Source_Tag`, `New_Source_Tag_alternatives`, `New_Tag_Merged`, `New_Tag_reports_tags`. השמות והעמודות ידועים מתוך הסכמה; לא נבדק כאן תפקידן ביחס ל־ERD הנדרש.

**קריטריון הסיום:** כיסוי הטבלאות והקשרים **שבתחום המודל הנבחר**, כולל מפתחות ו־grain, חריגות ידועות והבחנה בין קשר מאומת לקשר משוער. אין דרישה לתאר כל אחת מ־342 העמודות, ואין להסיק שעבודה על כל 21 הטבלאות היא תנאי ל־ERD שימושי.

### מה נותר להשלמה כדי להפיק ERD מרכזי

1. לציין במפורש את קבוצת הטבלאות הנכללת בתרשים ואת הטבלאות שמחוץ לתחום; לגבי ארבע טבלאות העזר לעיל אפשר להשאיר **'לא הוכרע'** בלי לחקור אותן כעת.
2. עבור הקשרים בליבה שכבר נבדקו, להמיר את הממצאים לטבלת ERD מסודרת: מפתח מקור, מפתח יעד, סוג הקשר המשוער/שנצפה, `grain`, כמות חריגות, ורמת ודאות.
3. להבחין בתרשים בין שני מודלי הגיוס ובין שני מודלי החדשות, בלי ליצור קישורי FK שלא אומתו.
4. להחליט האם `Events` העצמאית נמצאת בתחום; רק אם כן, לבדוק את הקישור של `entity_id` ולכלול אותה.
5. להפיק את הדיאגרמה. חקירה עסקית מלאה של כל סוגי האירועים ושל כל 179 שדות `New_Company` **אינה תנאי מבני** ליצירתה.

## מקרא ודאות

- **אומת** — נתמך במדידות SQL על הקשרים/המפתחות.
- **חלקי** — קשר או פרשנות תקינים ברוב המקרים, עם חריגות ידועות.
- **פתוח** — טרם הוכרע באמצעות הנתונים.
- **מופה ברמת שדות וערכים** — הוכחו מבנה, ערכים ושילובים שנצפו; אין בכך הוכחה ללוגיקת האפליקציה.
- `FK` בהקשר זה פירושו *קשר לוגי שנבדק*, לא בהכרח אילוץ FOREIGN KEY שהוגדר פיזית ב־BigQuery.

## 1. טבלת הישויות המרכזית — New_Company

- **אומת:** `New_Company` מכילה 29,795 רשומות, `id` ייחודי ולא NULL (כפי שנבדק).
- **אומת:** אינה רק טבלת סטארטאפים; מייצגת גם משקיעים, בורסות, חברות, מאיצים, ישויות ציבוריות ועוד.
- **אומת:** `type` ו־`sub_type` מבחינים בין סוגי ישויות; השדה `category` היה NULL בכל 7,305 ישויות המשקיע שנבדקו, ולכן אינו כלי טוב לזיהוי אוכלוסיית משקיעים.
- **אומת:** אוכלוסיית הישויות שמופיעות בתפקיד משקיע במודלי הגיוס: 7,305 ישויות תואמות ל־`New_Company`; מתוכן 5,606 מסווגות `type = 'Investor'`, ו־1,699 תחת סוגים אחרים. דוגמאות `sub_type` למשקיעים: `VC and Private Equity`, `Angel`, `Corporate VC`, `Institutional Investor`, `Angel Group`, `Incubator`.
- **כלל אנליטי:** סוג הישות (`type`) אינו תפקידה בעסקה. אין לסנן רק `type='Investor'` אם רוצים את *כל* הישויות שהשקיעו בפועל.

## 2. News — קשרים נבדקו, עם חריגות מתועדות

- `News`: 92,546 רשומות; `id` ייחודי. `news_id` לא ייחודי, כולל 21,428 ערכי NULL וכפילויות.
- **אומת:** `CompanyNews.company_id → New_Company.id`: 94,818 התאמות ו־36 לא נמצאו מתוך 94,854.
- **אומת:** `CompanyNews.news_id → News.id`: 94,830 התאמות ו־24 לא נמצאו מתוך 94,854. זהו המפתח הנכון למסלול הראשי; *לא* `News.news_id`.
- `New_Company_news`: 57,097 רשומות, כולל העתקי תוכן חדשות.
- **חלקי:** `New_Company_news.origin_entity_id → New_Company.id`: 57,092 התאמות, 5 חריגות.
- **חלקי:** `New_Company_news.news_id → News.news_id`: 47,013 התאמות, 590 ערכים לא נמצאו, 9,494 NULL; שדה היעד `News.news_id` אינו ייחודי.
- **חפיפה:** 46,884 צירופי חברה–`news_id` משותפים לשני המודלים (בבדיקת DISTINCT של מזהי חדשות לא־ריקים); לא נכון להניח שהטבלאות זרות זו לזו.
- **בדיקת URL:** מבין 10,084 רשומות בהן `news_id` חסר או אינו נמצא, התאמה לפי *אותה חברה + URL* הניבה 9,764 רשומות עם מועמד חד־משמעי, 8 עם שני מועמדים, ו־312 ללא מועמד. התאמת URL אינה הוכחת זהות.
- **החלטה:** ל־JOIN סטנדרטי של חברה–חדשות, להשתמש במסלול `New_Company → CompanyNews → News` בכפוף לחריגות. לשמר `New_Company_news` כמקור מקביל/מועשר ולא למחוק אותו.

## 3. Classification — קשרים והיררכיות נבדקו

- `BaseClassificationModel`: **500 סיווגים** בשלוש היררכיות נפרדות:

  | סוג | Depth 0 | Depth 1 | Depth 2 | סך |
  |---|---:|---:|---:|---:|
  | Industry | 17 | 81 | 175 | 273 |
  | Sector | 13 | 54 | 64 | 131 |
  | Technology | 13 | 83 | 0 | 96 |
  | **סה״כ** | **43** | **218** | **239** | **500** |

- **אומת:** `BaseClassificationRelationModel` מחזיקה 457 קשרים הורה–ילד; כולם נמצאו, כולם באותה קטגוריה, הילד בעומק גדול ב־1, להורה ולילד אותו `root_key`; לכל ילד הורה אחד. מבנה זה הוא יער של 43 עצים.
- **אומת:** `BaseClassificationModel.root_key → BaseClassificationModel.id`: לכל 500 הסיווגים שורש קיים בעומק 0; שורשי עומק 0 מפנים לעצמם.
- `BaseClassificationCompanyModel`: 161,373 שיוכי חברה–סיווג.
- **חלקי:** `classification_key → BaseClassificationModel.id`: 153,322 נמצאו, **8,051** לא נמצאו; החריגות מתרכזות ב־**53 מזהי Sector** (7,851 שיוכים) וב־**9 מזהי Industry** (200 שיוכים). ב־Technology אין הפניות חסרות.
- **חלקי:** `company_key → New_Company.id`: 158,370 התאמות, 1,804 לא נמצאו, 1,199 NULL.
- **אומת:** 4,891 רשומות עודפות לפי צירוף `(company_type, classification_category, company_key, classification_key)` כאשר שני המפתחות לא־ריקים; רובן הגדול ב־Sector. לא הוכח שכל אלה מצביעות לטבלאות אב קיימות; דוגמאות ב־JOIN הוכיחו שגם צירופים תקינים משוכפלים.
- **אומת:** `company_type` (`New_Startup`, `Startup`, `startup` וכו׳) אינו חלוקה בלעדית; למשל 10,092 חברות משותפות ל־`New_Startup` ו־`startup`.
- **החלטה:** הגרעין העסקי המשוער הוא שיוך *חברה–סיווג–קטגוריה–סוג חברה*, אך אינו ייחודי בפועל. להגדיר grain לפני כל ספירה, לטפל ב־fan-out.

## 4. Tags — קשרים נבדקו; Tag_Relations משנית

- **קשר מרכזי:** `New_Company ← New_Company_Tag → New_Tag` (M:N לוגי).
- `New_Company_Tag`: 171,082 רשומות.
- **חלקי:** `company → New_Company.id`: 168,608 נמצאו, 2,474 לא נמצאו.
- **חלקי:** `tag → New_Tag.id`: 149,338 נמצאו, 130 לא נמצאו; 21,614 `tag IS NULL` ו־`tag_name IS NULL` גם יחד.
- **אומת:** 147,704 רשומות שבהן החברה והתגית שתיהן נמצאו; 23,378 רשומות שבהן לפחות צד אחד חסר. הספירות של חריגות עשויות לחפוף.
- **אומת:** 273 רשומות עודפות לפי `(company,tag,company_type)` ברשומות שבהן שני המפתחות לא־ריקים; לא בהכרח כפילות של כל עמודות הרשומה.
- **טבלת צד:** `Tag_Relations` מכילה 418 זוגות `parent`–`child`: 169 שני הצדדים נמצאים ב־`New_Tag.id`, 38 הורה בלבד, 21 ילד בלבד, 190 אף צד. `New_Tag.old_key` לא פתר את החסרים. דוגמאות `marketing → customer-retention` מאשרות את משמעות קשרי הורה–ילד. **Legacy candidate בלבד — גיל היסטורי לא הוכח.** מחוץ ל־ERD המרכזי כרגע, אך לא להתעלם ממנה אם אנליזה דורשת היררכיית תגיות.

## 5. מימון — New_Funding_Round ומודל המשקיעים

- `New_Funding_Round`: 11,716 סבבים. `startup → New_Company.id`: 11,639 התאמות במדידות קודמות; יש חריגות.
- **אומת:** `New_Funding_Round_known_investors.origin_entity_id → New_Funding_Round.id`: 11,610/11,610 התאמות.
- **חלקי:** `known_investors → New_Company.id`: 11,547/11,610 נמצאו; 63 רשומות מתייחסות ל־10 מזהים לא מוכרים.
- `New_Funding_Round_unknown_investors`: 11,499 רשומות. `origin_entity_id → New_Funding_Round.id`: 11,499/11,499 התאמות. `unknown_investors` הוא **שם/תיאור בטקסט חופשי**, לא FK למשקיע.
- בהתאמת שמות מנורמלים ל־`New_Company.name`: 8,502 רשומות עם התאמת שם יחידה; 1,249 עמומות; 1,748 לא נמצאו. **אין להמיר התאמות שם אוטומטית ל־FK.**
- השדה `New_Funding_Round.old_key` הוא NULL בכל 11,716 הרשומות שנבדקו; לא מספק קישור ל־BaseEvent.

## 6. BaseEvent ו־BaseEvent_investors

- `BaseEvent`: 37,408 אירועים מכל הסוגים, `id` ייחודי.
- **חלקי:** `BaseEvent.company_key → New_Company.id`: 36,951 התאמות, 456 לא נמצאו, 1 NULL.
- **אומת:** `BaseEvent_investors.origin_entity_id → BaseEvent.id`: 32,988/32,988 התאמות.
- `BaseEvent_investors`: 32,988 רשומות — 32,967 `FundingRoundEvent`, 17 `ICOEvent`, 4 `GrantEvent`.
- **חלקי:** `investors_entity_entity_key → New_Company.id`: 32,899 התאמות; 32 NULL ו־57 לא נמצאו.
- בטבלת המשקיעים יש גם פרטים ברמת השתתפות: `investors_amount_amount`, `investors_is_lead`, `investors_is_follow_on`, `investors_first_investment` ושדות visibility נפרדים.
- משקיעים מזוהים באמצעות מזהים משותפים: 979 מזהים שונים במודל New_Funding_Round, 7,296 במודל FundingRoundEvent, ומתוכם 952 משותפים. **זו חפיפה בין משקיעים, לא ראיה לאותו סבב.**
- נמצאו 15 קבוצות חזרה של זוג `(event_id, investor_key)`, 31 רשומות, 16 עודפות; בחלקן ערכי סכומים/דגלים שונים — לא לבצע DISTINCT עיוור.

## 7. חפיפה בין מודלי הגיוס — התאמות מדודות, איחוד לא הוכרע

- `BaseEvent` עם `event_type='FundingRoundEvent'`: 15,963 רשומות.
- `New_Funding_Round`: 11,716 רשומות.
- **אין FK ישיר מאומת ביניהם.** `old_key` אינו מספק התאמות.
- מדידה של התאמה אחד־לאחד לפי `(company_id, date, amount)` ושובר שוויון בסדר רשומות:

  | סיווג | סבבים במודל New |
  |---|---:|
  | התאמה מלאה | 6,858 |
  | אותה חברה, תאריך שונה | 2,291 |
  | סכום חסר | 1,764 |
  | אותה חברה ותאריך, סכום שונה | 287 |
  | תאריך חסר/לא תקין | 276 |
  | אין FundingRoundEvent לאותה חברה | 239 |
  | עודף כפילות על מפתח תואם | 1 |
  | **סה״כ** | **11,716** |

- **פרשנות זהירה:** 6,858 הן התאמות עסקיות חזקות לפי שלושה מאפיינים, לא הוכחת זהות באמצעות מזהה. 4,858 שאינן בהתאמה מלאה אינן בהכרח גיוסים ייחודיים.
- **כלל אנליטי:** לא לבצע `UNION ALL` של שני המודלים לצורך ספירת גיוסים ללא דה־דופליקציה ייעודית. גם JOIN ישיר למשקיעים עלול לנפח סכומים.

## 8. מענקים — Grants

- `BaseEvent` עם `event_type='GrantEvent'`: 2,118 אירועים.
- **חלקי:** `BaseEvent_grantors.origin_entity_id → BaseEvent.id`: 1,853 רשומות מקושרות לאירוע, 6 הפניות לאירוע שאינו קיים (סך 1,859).
- מתוך 1,853 רשומות האירוע התקינות: 1,621 מעניקים ב־`New_Company`, 164 מפתחות לא נמצאו, 68 מפתחות NULL; הן מכסות 1,760 אירועי Grant שונים. מכאן 358 GrantEvents ללא רשומת Grantor תואמת.
- **הקשר הלוגי:** מענק/אירוע ← טבלת מעניקים → ישות מעניקה ב־New_Company. יש חריגות.

## 9. רכישות/מיזוגים — MNAEvent

- `BaseEvent` עם `event_type='MNAEvent'`: 2,591 אירועים.
- `company_key`: מאוכלס בכולם, 2,541 התאמות ל־New_Company, 50 לא נמצאו.
- `other_party_entity_key`: מאוכלס ב־2,578, מתוכם 2,570 נמצאו, 8 לא נמצאו; 13 NULL.
- `was_acquired=1` ב־2,529 אירועים, `was_acquired=0` ב־62 אירועים. אלה **אינם** ספירות `is_exit`.
- **הגדרת עבודה מאומתת בדוגמאות:** אם `was_acquired=1`, `company_key` הוא הצד שנרכש ו־`other_party_entity_key` הצד הרוכש; אם `was_acquired=0`, הכיוון מתהפך. עבור `Merger` משתמשים באותה מוסכמה אנליטית בהסכמת המשתמש, ללא טענה משפטית שכל מיזוג הוא רכישה.
- סוגי `mna_type`: Acquisition, Merger, Buyout.
- **עדכון:** הקשר בין `was_acquired`, `mna_type` ו־`is_exit` נבדק בהמשך (סעיף 16). זהו שדה נפרד; לא ניתן להסיק אותו רק מ־`was_acquired`.

## 10. הנפקות/כניסה למסחר ובורסות

### POEvent
- 1,043 אירועי `POEvent`.
- **אומת:** `BaseEvent.stock_exchange_key → New_Company.id`, כאשר `New_Company.type='Stock Exchange'`: 1,039 קשרים תקינים, 4 מפתחות חסרים, 44 מזהי בורסות שונים.
- `ticker` לא ריק ב־1,029 אירועים; יש בו גם טקסטים לא תקינים, ולכן אין להתייחס אליו כאל מזהה מובטח.
- `is_exit`: 715 ערך 1, 296 ערך 0, 32 NULL.
- בדיקת הסדר הכרונולוגי של PO לכל חברה (לפי תאריך מתועד):
  - אירוע ראשון: 713 Exit=1; 54 Exit=0; 2 NULL.
  - אירוע נוסף: 2 Exit=1; 242 Exit=0; 30 NULL.
- **הבהרת היקף:** נתונים אלה סודרו בתוך POEvent בלבד. סעיף 16 מציג דירוג משותף לכל ארבעת סוגי האירועים הרלוונטיים. מדובר במתאם במדידות, לא בהוכחה להגדרה העסקית של Exit.

### ReverseMergerEvent
- 65 אירועים; `is_exit=1` ב־51, `0` ב־10, NULL ב־4.
- 64 קישורי בורסה תקינים לישויות מסוג `Stock Exchange`; 60 עם ticker; שדות `other_party_entity_key` ו־`merged_with_entity_key` ריקים באירועים שנבדקו.
- 27 מתוך 65 אירועים שייכים לחברות שמופיע עבורן גם `POEvent` (חפיפה ברמת חברה, לא בהכרח אותו אירוע).
- **תיאור מבני:** באירועי ReverseMergerEvent שנבדקו נמצאו שדות חברה, בורסה ו־ticker; שדות הצד השני לעסקה היו ריקים במדגם שנבדק.

## 11. מצב המיפוי — הבחנה בין מה שנבדק למה שעדיין פתוח

| תחום | מה נבדק | מה לא הוכח או לא הושלם |
|---|---|---|
| `New_Company` | מפתח, מספר ישויות, סוגים ותפקידים במספר קשרים | מלוא 179 העמודות ומשמעות כולן |
| חדשות | `News`, `CompanyNews`, `New_Company_news` וההתאמות ביניהן | שקילות מלאה של שני מודלי החדשות |
| Classification | 500 סיווגים, 457 קשרי עץ, קישורי חברות וחריגות | פירוש כל קוד וסיבת ההפניות החסרות |
| Tags | תגיות, שיוכי חברות, חריגות ו־`Tag_Relations` | סטטוס מקור/גרסה של הקשרים המשניים |
| Funding & Investors | שני מודלי גיוסים, משקיעים מוכרים/לא־מוכרים, התאמות וחריגות | מפתח ישיר בין שני המודלים ושקילות עסקית מלאה |
| Grants | קשרים בין אירועים, מעניקים וישויות | התאמה למענקים שנרשמו ב־`New_Funding_Round` |
| M&A, PO, Reverse Merger | שדות עיקריים, תפקידי צדדים ובורסות, חריגות | לוגיקת האפליקציה המקורית בכל מקרה |
| Funding Type | כל הערכים וההתפלגויות בשני המודלים | סיווג Public/Private כשדה נתונים — לא אותר; סיווג נגזר נדחה |
| Visibility | ערכים, התפלגויות ושילובים ברמת אירוע, סכום, סוג מימון ומשקיע | משמעות NULL, קדימות הרשאות וההתנהגות במוצר |
| `is_exit` | ארבעת סוגי האירועים שבהם נצפה 1, תפקיד החברה, סדר תאריכים וארבעה חריגי דירוג | הגדרה עסקית מלאה וטיפול בתאריכים חסרים/זהים |
| יתר סוגי האירועים | התפלגות סוגים ומספרי רשומות | מיפוי שדות וקשרים פרטני, לרבות `Events` הנפרדת |
| ERD בתחום שהוגדר | שלד קשרים לוגיים (סעיף 12) | דיאגרמה עם הטבלאות הרלוונטיות, ה־grains וקשרים מסומנים ברמת ודאות מתאימה |

**כלל תיעודי:** "נבדק" אינו "הושלם במלואו". מיפוי שדות אינו שקול לשחזור כללי החשיפה או החלטות המערכת. סדר ההמשך אינו מוכרע במסמך זה.

## 12. קשרים לוגיים מרכזיים — טבלת שלד

| Parent / target | Child / source field | סטטוס |
|---|---|---|
| `New_Company.id` | `CompanyNews.company_id` | מאומת חלקית — 36 חריגות |
| `News.id` | `CompanyNews.news_id` | מאומת חלקית — 24 חריגות |
| `New_Company.id` | `New_Company_news.origin_entity_id` | מאומת חלקית — 5 חריגות |
| `News.news_id` | `New_Company_news.news_id` | לא ייחודי וחלקי; אינו PK בטוח |
| `BaseClassificationModel.id` | `BaseClassificationRelationModel.parent_key/child_key` | 457/457 שניהם תקינים |
| `BaseClassificationModel.id` | `BaseClassificationModel.root_key` | 500/500 שורשים תקינים |
| `BaseClassificationModel.id` | `BaseClassificationCompanyModel.classification_key` | 8,051 חריגות |
| `New_Company.id` | `BaseClassificationCompanyModel.company_key` | 1,804 חסרים + 1,199 NULL |
| `New_Company.id` | `New_Company_Tag.company` | 2,474 חריגות |
| `New_Tag.id` | `New_Company_Tag.tag` | 130 חסרים + 21,614 NULL |
| `New_Company.id` | `New_Funding_Round.startup` | 11,639 התאמות; חריגות |
| `New_Funding_Round.id` | `New_Funding_Round_known_investors.origin_entity_id` | 11,610/11,610 |
| `New_Company.id` | `New_Funding_Round_known_investors.known_investors` | 63 חריגות |
| `New_Funding_Round.id` | `New_Funding_Round_unknown_investors.origin_entity_id` | 11,499/11,499 |
| `New_Company.id` | `BaseEvent.company_key` | 456 חסרים + 1 NULL |
| `BaseEvent.id` | `BaseEvent_investors.origin_entity_id` | 32,988/32,988 |
| `New_Company.id` | `BaseEvent_investors.investors_entity_entity_key` | 57 חסרים + 32 NULL |
| `BaseEvent.id` | `BaseEvent_grantors.origin_entity_id` | 6 חריגות |
| `New_Company.id` | `BaseEvent_grantors.grantors_entity_entity_key` | 164 חסרים + 68 NULL בקרב אירועים תקינים |
| `New_Company.id` | `BaseEvent.other_party_entity_key` (MNA בלבד) | 8 חסרים + 13 NULL |
| `New_Company.id` (`type='Stock Exchange'`) | `BaseEvent.stock_exchange_key` (PO/ReverseMerger) | 1,039/1,043 PO; 64/65 ReverseMerger |
| `BaseEvent.id` ↔ `New_Funding_Round.id` | **אין קשר ישיר מאומת** | התאמה עסקית בלבד ל־6,858 מקרים |

## 13. הערות טכניות על Grain ו־JOIN

- להתחיל מכל שאילתה עם **Unit of Analysis / Grain**: חברה, סבב, אירוע, השתתפות משקיע או שיוך לתגית/סיווג.
- לספור חברות `COUNT(DISTINCT company_id)` כאשר טבלת הקישור עשויה להכיל כמה רשומות לחברה; להיזהר מ־fan-out.
- לא לסכום סכום סבב אחרי JOIN של סבב למשקיעים ללא התאמת Grain.
- לא להתייחס ל־`unknown_investors` כ־FK, ל־`News.news_id` כ־PK, ל־`company_type` כמחלקה בלעדית או ל־`was_acquired` כ־`is_exit`.
- לא לערבב **Private Funding** עם **Private Visibility**.
- נתונים עם תאריכים כגון `YYYY-MM-01` עשויים לשקף דיוק חודשי בלבד; יש לאמת לפני ניתוח של יום מדויק.

## הערה על השלמות

זה **מסמך מצב לתחומים שנותחו**, לא ERD סופי של התחום שנבחר ולא תיעוד מלא של כל 342 העמודות. אין צורך לכלול את כל 21 הטבלאות בתרשים המרכזי. כל מסקנה עתידית צריכה להתבסס על שאילתות/תוצאות, ולהתווסף למסמך עם ציון מה נבדק בפועל.


## 14. Funding Type — התפלגות ערכים בפועל (עדכון 19.11.2026)

**נבדק בפועל:** `BaseEvent.funding_type_funding_type` על `FundingRoundEvent` (15,963 רשומות), ו־`New_Funding_Round.type_` (11,716 רשומות). הנתונים נספרו ללא ניסיון ליישב אירועים בין הטבלאות.

| מקור | ערך כפי שנשמר | רשומות |
|---|---|---:|
| `BaseEvent` | `Seed` | 4,937 |
| `BaseEvent` | `A Round` | 2,513 |
| `BaseEvent` | `Undisclosed Round` | 2,396 |
| `BaseEvent` | `Pre-Seed` | 1,424 |
| `BaseEvent` | `B Round` | 1,286 |
| `BaseEvent` | `C Round` | 654 |
| `BaseEvent` | `PIPE` | 530 |
| `BaseEvent` | `NULL` | 354 |
| `BaseEvent` | `Convertible Debt` | 328 |
| `BaseEvent` | `D Round` | 319 |
| `BaseEvent` | `SAFE` | 315 |
| `BaseEvent` | `Debt Financing` | 229 |
| `BaseEvent` | `Equity crowdfunding` | 183 |
| `BaseEvent` | `Crowdfunding` | 159 |
| `BaseEvent` | `E Round` | 151 |
| `BaseEvent` | `F Round` | 67 |
| `BaseEvent` | `Secondary Round` | 59 |
| `BaseEvent` | `Convertible Bond` | 34 |
| `BaseEvent` | `G Round` | 25 |
| `New_Funding_Round` | `Seed` | 3,534 |
| `New_Funding_Round` | `A Round` | 1,792 |
| `New_Funding_Round` | `Grant` | 1,312 |
| `New_Funding_Round` | `Undisclosed Round` | 1,169 |
| `New_Funding_Round` | `B Round` | 961 |
| `New_Funding_Round` | `Pre-Seed` | 713 |
| `New_Funding_Round` | `C Round` | 499 |
| `New_Funding_Round` | `Post-IPO Equity Funding` | 275 |
| `New_Funding_Round` | `NULL` | 272 |
| `New_Funding_Round` | `Convertible Debt` | 262 |
| `New_Funding_Round` | `D Round` | 247 |
| `New_Funding_Round` | `Crowdfunding` | 163 |
| `New_Funding_Round` | `Debt Financing` | 119 |
| `New_Funding_Round` | `E Round` | 112 |
| `New_Funding_Round` | `Equity crowdfunding` | 76 |
| `New_Funding_Round` | `F Round` | 52 |
| `New_Funding_Round` | `Joint Project Grant` | 36 |
| `New_Funding_Round` | `Initial Coin Offering` | 29 |
| `New_Funding_Round` | `Private Equity` | 28 |
| `New_Funding_Round` | `Angel` | 24 |
| `New_Funding_Round` | `Private_equity` | 12 |
| `New_Funding_Round` | `Undisclosed` | 12 |
| `New_Funding_Round` | `G Round` | 12 |
| `New_Funding_Round` | `Post-equity funding` | 3 |
| `New_Funding_Round` | `Convertible_note` | 1 |
| `New_Funding_Round` | `Product_crowdfunding` | 1 |

### ממצאים ודאיים

- שתי הטבלאות משתמשות ברשימות **לא זהות** של סוגי מימון: 19 ערכים נבדלים (כולל NULL) ב־BaseEvent, ו־26 ב־New_Funding_Round.
- ב־New_Funding_Round יש `Grant` (1,312) ו־`Joint Project Grant` (36); ב־BaseEvent מענקים מיוצגים גם כאירועי `GrantEvent` נפרדים. כלומר, לא נכון להשוות ספירת *כל* New_Funding_Round רק ל־`FundingRoundEvent`.
- ב־New_Funding_Round מופיע `Initial Coin Offering` (29), בעוד שב־BaseEvent קיים `ICOEvent` כסוג אירוע נפרד.
- `PIPE` מופיע ב־BaseEvent (530) ו־`Post-IPO Equity Funding` ב־New_Funding_Round (275); **לא הוכח** שהשדות מתארים אותו סוג מימון.
- יש ערכים בעלי דמיון מילולי כגון `Private Equity` / `Private_equity`, `Convertible Debt` / `Convertible_note` ו־`Crowdfunding` / `Product_crowdfunding`; שקילותם לא אומתה.
- `Secondary Round` (59) מופיע כערך עצמאי. משמעותו המעשית והשימוש בו לספירות הון חדש לא נבדקו.

### מה ידוע על סיווג Public/Private

- `PIPE` מופיע ב־`BaseEvent` (530) ו־`Post-IPO Equity Funding` מופיע ב־`New_Funding_Round` (275). המשתמש תיאר את שניהם כדוגמאות ל־**Public Funding** בהקשר העסקי הרלוונטי.
- **אין בשדות שנבדקו עמודת `funding_category` מפורשת או מקבילה שאותרה, שמכילה סיווג Public Funding / Private Funding.** השדות `funding_type_funding_type` ו־`type_` שומרים את סוג המימון, ושדות Visibility מתארים נראות/חשיפה.
- סיווג נגזר לאחר טעינה (*post-classification*) הוזכר כאפשרות, אך **העיסוק בו נדחה במפורש**. לא הוחלט על מיפוי של שאר הסוגים ולא נוספה עמודה.
- אין להסיק שיש שני סוגי מימון זהים רק משום שהם מופיעים בשתי הטבלאות או שהם קרובים מבחינה מילולית.

### נושאים שעדיין פתוחים בתחום הגיוסים

- התאמת אירועי `Grant`/`Joint Project Grant`/`Initial Coin Offering` בטבלת `New_Funding_Round` לסוגי האירועים `GrantEvent`/`ICOEvent` ב־`BaseEvent` טרם נבדקה במסגרת ההמשך המתועד כאן.
- המשמעות המדויקת של סוגים בעלי שמות קרובים, והכללים העסקיים ששימשו את Finder למיון סוגי המימון, אינם מוכחים מן הסכמה בלבד.

## 15. Visibility — התפלגויות ושילובים שנמדדו (עדכון 19.11.2026)

**מה נבדק:** ערכי חשיפה ב־`BaseEvent` (37,408 אירועים), ב־`BaseEvent_investors` (32,988 רשומות) וב־`New_Funding_Round.visible` (11,716 סבבים). בנוסף נמדדו שילובים רק ב־15,963 `FundingRoundEvent`, ושילובי אירוע–משקיע ב־32,967 קישורי משקיעים לאירועי גיוס.

### 15.1 ערכים לכל שדה

| טבלה | רכיב | עמודה | Public | Private | Internal | NULL | סה״כ |
|---|---|---|---:|---:|---:|---:|---:|
| `BaseEvent` | האירוע | `visibility_visibility_type` | 31,620 | 735 | 439 | 4,614 | 37,408 |
| `BaseEvent` | הסכום | `amount_visibility_visibility_type` | 19,709 | 537 | 21 | 17,141 | 37,408 |
| `BaseEvent` | סוג המימון | `funding_type_visibility_visibility_type` | 15,893 | 121 | 1 | 21,393 | 37,408 |
| `BaseEvent_investors` | זהות המשקיע | `investors_entity_visibility_visibility_type` | 28,441 | 210 | 62 | 4,275 | 32,988 |
| `BaseEvent_investors` | סכום השתתפות | `investors_amount_visibility_visibility_type` | 31,641 | 229 | 0 | 1,118 | 32,988 |

`New_Funding_Round.visible`: ערך `1` ב־10,605 רשומות; `0` ב־1,111. אין בתוצאות אלה הוכחה ששדה זה שקול לאחד משדות ה־Visibility ב־`BaseEvent`.

### 15.2 שילובים ברמת FundingRoundEvent

כל 15,963 הרשומות נכללו, ב־26 צירופים שונים. שמות `event`, `amount`, `funding_type` מתארים שלושה שדות נפרדים באותה רשומת `BaseEvent`.

| Event | Amount | Funding Type | סבבים |
|---|---|---|---:|
| Public | Public | Public | 13,380 |
| Public | NULL | Public | 1,249 |
| Internal | Public | Public | 383 |
| Private | Public | Public | 355 |
| Public | Private | Public | 229 |
| Private | NULL | Public | 114 |
| Private | Private | Public | 50 |
| Private | Private | Private | 40 |
| Internal | NULL | Public | 28 |
| Public | Private | Private | 24 |
| Public | Public | Private | 23 |
| Public | Public | NULL | 17 |
| Public | NULL | Private | 16 |
| Private | Public | NULL | 15 |
| NULL | Public | NULL | 8 |
| Internal | Private | Public | 7 |
| Private | NULL | Private | 5 |
| Internal | Private | Private | 5 |
| Private | Public | Private | 5 |
| Public | Internal | Public | 3 |
| Internal | Public | Private | 2 |
| Internal | NULL | Private | 1 |
| Public | Private | NULL | 1 |
| Internal | Internal | Public | 1 |
| Internal | Internal | Internal | 1 |
| NULL | Private | NULL | 1 |
| **סה״כ** | | | **15,963** |

**תצפית:** קיימים אירועים שסומנו Public, ובתוכם סכום או סוג מימון Private; וקיימים אירועים Private/Internal עם רכיבים שסומנו Public. זה מאמת קיום **ערכים נפרדים** ברשומה, אך לא את כללי פרשנותם במערכת.

### 15.3 שילובים ברמת השתתפות משקיע באירוע גיוס

לאחר JOIN של `BaseEvent_investors.origin_entity_id` ל־`BaseEvent.id` וסינון `event_type='FundingRoundEvent'`: 32,967 רשומות משקיע, 28 צירופים. `funding_rounds` בתוצאות המקוריות היה `COUNT(DISTINCT e.id)` לכל צירוף, ולכן אינו מדד שניתן לסכום בין שורות.

| Event | Investor Identity | Investor Amount | רשומות משקיע | סבבים שונים בצירוף |
|---|---|---|---:|---:|
| Public | Public | Public | 27,556 | 12,345 |
| Public | NULL | Public | 3,090 | 1,009 |
| Public | NULL | NULL | 1,081 | 383 |
| Private | Public | Public | 357 | 279 |
| Internal | Public | Public | 328 | 255 |
| Public | Public | Private | 115 | 74 |
| Public | Private | Public | 108 | 88 |
| Private | Private | Public | 70 | 64 |
| Private | Public | Private | 51 | 29 |
| Public | Internal | Public | 34 | 32 |
| Private | NULL | Public | 31 | 16 |
| Public | NULL | Private | 21 | 16 |
| Internal | NULL | Public | 20 | 16 |
| Internal | NULL | NULL | 19 | 17 |
| Internal | Internal | Public | 19 | 18 |
| Private | Private | Private | 15 | 10 |
| Public | Private | Private | 13 | 7 |
| Internal | Public | Private | 8 | 7 |
| Private | NULL | NULL | 8 | 7 |
| NULL | Public | Public | 4 | 4 |
| Public | Public | NULL | 4 | 4 |
| NULL | Internal | Public | 4 | 4 |
| Internal | Private | Public | 3 | 3 |
| Internal | Internal | NULL | 2 | 2 |
| Private | NULL | Private | 2 | 2 |
| Public | Internal | Private | 2 | 2 |
| Public | Private | NULL | 1 | 1 |
| Internal | Internal | Private | 1 | 1 |
| **סה״כ** | | | **32,967** | — |

**תצפית:** 27,556/32,967 (83.6%) הן רשומות שבהן כל שלושת הערכים שנבדקו Public. בשאר מופיעים שילובים אחרים לרבות אירוע Public וזהות משקיע Private, או אירוע Private וזהות משקיע Public. 21 רשומות המשקיע שמחוץ ל־FundingRoundEvent אינן חלק מטבלת שילובים זו.

### 15.4 גבולות הידיעה

- `Public`, `Private`, `Internal` ו־`NULL` הם ערכים שנצפו; אין מהם לבדם ראיה להגדרת קבוצות משתמשים או הרשאות אפקטיביות באפליקציה.
- משמעות `NULL` אינה ידועה, ולא נבדקה קדימות בין Visibility של האירוע לבין Visibility של רכיביו.
- ההשוואה בין Visibility של שני מודלי הגיוס לא נבדקה במפתח סבב חד־חד־ערכי.
- **סטטוס:** מיפוי שדות/ערכים/צירופים — בוצע; לוגיקת הצגה/חשיפה במוצר — פתוחה.

## 16. `is_exit` — פיזור, צד העסקה ורצף אירועים (עדכון 19.11.2026)

### 16.1 אילו סוגי אירועים מכילים ערך `is_exit=1`?

| `event_type` | סך אירועים | Exit = 1 | Exit = 0 | NULL |
|---|---:|---:|---:|---:|
| `MNAEvent` | 2,591 | 2,201 | 294 | 96 |
| `POEvent` | 1,043 | 715 | 296 | 32 |
| `ReverseMergerEvent` | 65 | 51 | 10 | 4 |
| `SpacEvent` | 23 | 12 | 10 | 1 |
| **סה״כ ארבעת הסוגים** | **3,722** | **2,979** | **610** | **133** |

באף אחד מסוגי `BaseEvent` האחרים שנכללו בהתפלגות הכוללת לא נצפה `is_exit=1` (רק `0` או `NULL`). זהו תיאור של נתוני הסכמה שנדגמו, ולא קביעה מהו Exit מבחינה עסקית/משפטית.

### 16.2 `MNAEvent`: `mna_type`, `was_acquired` ו־`is_exit`

| `mna_type` | `was_acquired` | סה״כ | 1 | 0 | NULL |
|---|---:|---:|---:|---:|---:|
| Acquisition | 0 | 57 | 0 | 41 | 16 |
| Acquisition | 1 | 2,412 | 2,126 | 218 | 68 |
| Buyout | 0 | 1 | 0 | 0 | 1 |
| Buyout | 1 | 23 | 14 | 6 | 3 |
| Merger | 0 | 4 | 0 | 2 | 2 |
| Merger | 1 | 94 | 61 | 27 | 6 |
| **סה״כ** | | **2,591** | **2,201** | **294** | **96** |

במדידה זו, כל 2,201 המקרים שבהם `is_exit=1` היו עם `was_acquired=1`; לא נצפה `is_exit=1` כשהערך `was_acquired=0`. מתוך 2,529 אירועים שבהם `was_acquired=1`, היו 251 עם `is_exit=0` ו־77 עם `NULL`.

### 16.3 דירוג בתוך כל חברה על פני ארבעת סוגי האירועים

**שיטת הבדיקה:** מתוך `MNAEvent`, `POEvent`, `ReverseMergerEvent` ו־`SpacEvent` נשמרו אירועים עם `company_key` מאוכלס; ל־MNA נכללו רק `was_acquired=1` (לכן 62 אירועי MNA עם `was_acquired=0` אינם בטבלת דירוג זו). לכל חברה דורגו אירועים עם `ROW_NUMBER()` לפי `event_date ASC NULLS LAST, id`. ערכי תאריך נותחו באמצעות `SAFE_CAST(SUBSTR(TRIM(date),1,10) AS DATE)`.

| מיקום בדירוג | סוג | is_exit = 1 | is_exit = 0 | NULL | תאריך חסר בקרב Exit=1 |
|---|---|---:|---:|---:|---:|
| ראשון | MNAEvent | 2,200 | 111 | 0 | 12 |
| ראשון | POEvent | 712 | 25 | 0 | 3 |
| ראשון | ReverseMergerEvent | 51 | 2 | 0 | 0 |
| ראשון | SpacEvent | 12 | 5 | 0 | 0 |
| מאוחר | MNAEvent | 1 | 140 | 77 | 0 |
| מאוחר | POEvent | 3 | 271 | 32 | 0 |
| מאוחר | ReverseMergerEvent | 0 | 8 | 4 | 0 |
| מאוחר | SpacEvent | 0 | 5 | 1 | 0 |
| **סה״כ** | | **2,979** | **567** | **114** | **15** |

**פרשנות המספרים:** מבין 2,979 רשומות `is_exit=1`, 2,975 קיבלו דירוג ראשון ו־4 דירוג מאוחר; מתוך הראשונות, 15 רשומות Exit עם תאריך חסר, ולכן אין לגביהן הוכחה לסדר כרונולוגי. יש 143 אירועים שקיבלו דירוג ראשון ו־`is_exit=0`; חלקם נמצאים באותו תאריך לצד אירוע Exit.

### 16.4 ארבעת אירועי ה־Exit שקיבלו דירוג מאוחר

| חברה | אירוע שקיבל דירוג ראשון (`is_exit=0`) | אירוע בדירוג מאוחר (`is_exit=1`) | התאריך המשותף |
|---|---|---|---|
| Alcon Pharmaceuticals | POEvent | POEvent | 2019-04-01 |
| Intec Pharma | POEvent | POEvent | 2015-08-01 |
| Nostromo Energy | ReverseMergerEvent | POEvent | 2021-06-01 |
| TSG IT Advanced Systems | MNAEvent | MNAEvent | 2016-01-01 |

לכל הארבעה אותו תאריך בשני האירועים. הסדר ביניהם נקבע על ידי `id` כמפתח מיון משני, ולא על ידי שעה עסקית מאומתת. לכן תיאורם כ־"אירוע Exit מאוחר בזמן" **אינו נתמך** בתאריך השמור.

### 16.5 גבולות הידיעה

- יש התאמה חזקה בין הופעת `is_exit=1` לבין אירוע המדורג ראשון לפי השדות הזמינים, עם ארבעה צירופי אירועים באותו יום, אך זה **אינו מוכיח** שהגדרת Finder לשדה היא "ה־Exit הראשון".
- אירועים ראשונים עם `is_exit=0`, תאריכים חסרים או תאריכים באותה רזולוציה מגבילים את ההסקה.
- הוכח איזה ערך **שמור** ב־`is_exit`; טרם הוכחו כל התנאים העסקיים שבהם ערך זה נקבע.
- **סטטוס:** פיזור `is_exit`, קשר לכיוון M&A ובדיקת דירוג אירועים — בוצעו; הכלל העסקי המקורי — פתוח.



---

## 17. הרחבת היקף והשלמת Key Audit (עדכון גרסה 0.5)

**היקף עבודה מעודכן:** נוספה `New_Member`, כך שהליבה הנבדקת כוללת **16 טבלאות**. הטבלה `Events` אינה כלולה בהיקף הנוכחי, וכך גם `Tag_Relations` וטבלאות עזר נוספות כמפורט בתחילת המסמך. אין להסיק מן הכותרות הישנות שעדיין מדובר ב־15 טבלאות.

### 17.1 ייחודיות `id` — הושלמה

- ב־15 הטבלאות המקוריות נבדקו כל ערכי `id`: **15/15 PASS**, אפס NULL, אפס מזהים כפולים.
- `New_Member`: לפי תוצאת אימות ב־BigQuery שהמשתמש מסר, **64,224 רשומות, 27 עמודות, 64,224 מזהי `id` ייחודיים, אפס NULL**.
- אלה **מפתחות ראשיים מועמדים המאומתים לפי הנתונים בפועל**, לא אישור לקיומו של אילוץ PK פיזי.

### 17.2 זוגות שדות בטבלאות הקישור — ביקורת ייחודיות

| טבלה | סך שורות | זוגות חסרים | זוגות כפולים | רשומות עודפות יחסית לזוג | תוצאת השוואת תוכן |
|---|---:|---:|---:|---:|---|
| `CompanyNews` | 94,854 | 0 | 0 | 0 | הצמד `(company_id,news_id)` ייחודי בפועל |
| `BaseEvent_grantors` | 1,859 | 68 | 1 | 1 | הצמד הכפול זהה לחלוטין למעט `id` |
| `BaseEvent_investors` | 32,988 | 32 | 14 | 15 | חלק מהצמדים מכילים תוכן שונה; לא להניח שהצמד מפתח |
| `New_Company_news` | 57,097 | 9,494 | 120 | 121 | 9 צמדים זהים למעט `id`; 111 צמדים בעלי תוכן שונה |
| `New_Funding_Round_known_investors` | 11,610 | 0 | 7 | 7 | כל 7 הצמדים זהים למעט `id` |
| `New_Funding_Round_unknown_investors` | 11,499 | 0 | 12 | 14 | כל 12 הצמדים זהים למעט `id` |

ב־`New_Company_news`, מבין 120 צמדים כפולים, ב־103 יש הבדל ב־`source`, ב־90 ב־`author`, וב־1 ב־`news_url`; לא נמצאו הבדלים ב־`news_date`, `news_summary`, `news_description`, `visible`. המדדים חופפים בין צמדים.

**תיקון ביחס לסעיף 6 הישן:** בדיקת זוגות עדכנית נתנה 14 צמדים כפולים ו־15 רשומות עודפות ב־`BaseEvent_investors`; אין להשתמש בספירה הישנה של 15 קבוצות / 16 עודפות.

### 17.3 קשרים נוספים שנבדקו

| שדה מקור | יעד שנבדק | מאוכלסים | התאמות | חסרים ביעד | הערה |
|---|---|---:|---:|---:|---|
| `BaseEvent.acquired_company_entity_key` | `New_Company.id` | 67 | 67 | 0 | 63 ReverseMerger, 3 SPAC, 1 PO |
| `BaseEvent.institution_entity_key` | `New_Company.id` | 4,417 | 4,217 | 200 | רק GraduationEvent |
| `BaseEvent.merged_with_entity_key` | `New_Company.id` | 23 | 23 | 0 | רק SpacEvent |
| `BaseEvent.community_key` | `New_Company.id` | 202 | 199 | 3 | רק CommunityInvolvementEvent; 128 מזהים ייחודיים |
| `New_Company.acquired_by_key` | `New_Company.id` | 796 | 788 | 8 | קשר עצמי מועמד |
| `New_Company.primary_sector_key` | `BaseClassificationModel.id` | 14,182 | 14,182 | 0 | קשר מסווג, לא מפתח ייחודי במקור |
| `New_Company.tto_key` | `New_Company.id` | 1,904 | 1,904 | 0 | קשר עצמי מועמד |
| `New_Company.r_d_due_to_acquisition_key` | `New_Company.id` | 96 | 87 | 9 | 87 יעדים תואמים עם `type=Startup` |
| `New_Member.company` | `New_Company.id` | 64,010 | 62,727 | 1,283 | 214 NULL, 0 מחרוזות ריקות, 938 מזהים חסרים שונים |

`New_Member.company` חוזר ברשומות שונות, ולכן הקשר הנצפה הוא many-to-one מ־Member אל Company. `New_Member.user` מפנה לפי הקשר שהמשתמש מסר לטבלת משתמשים **שאינה בתחום ה־ERD**; היעד לא אומת במסגרת המודל. `(company,user)` אינו ייחודי: 63,985 צמדים מלאים, 62,266 זוגות שונים, 940 זוגות כפולים, 1,719 רשומות עודפות.

### 17.4 שדות משתמשים/מזהים מחוץ לתחום

**שדות שלא התאימו ל־`New_Company.id` או `BaseEvent.id` בבדיקה שנערכה:**

| שדה מקור | ערכים מאוכלסים | התאמות ל־`New_Member.user` | מסקנה מוגבלת |
|---|---:|---:|---|
| `BaseEvent.creator_key` | 37,185 | 17,770 | חפיפה במרחב מזהי משתמשים, לא FK מאומת ל־`New_Member.id` |
| `BaseEvent.updator_key` | 37,210 | 19,585 | כנ״ל |
| `New_Company.creator_id` | 27,654 | 14,346 | כנ״ל |
| `New_Company.updator_id` | 16,524 | 8,914 | כנ״ל |
| `New_Company.last_modifier_id` | 21,698 | 12,789 | כנ״ל |
| `New_Company.user_key` | 173 | 118 | כנ״ל |
| `New_Company.member_verified_data_id` | 44 | 30 | חפיפה חלקית בלבד; אין הוכחת יעד FK |
| `New_Company.register_id` | 12,884 | 0 | יעד לא מאומת |
| `BaseEvent_investors.investors_lead_partner_key` | 182 | 0 | יעד לא מאומת |
| `BaseEvent_grantors.grantors_lead_partner_key` | 0 | — | כל הערכים NULL |

שלושה שדות ב־`New_Company` (`member_verified_data_id`, `register_id`, `user_key`) נבדקו גם מול `New_Member.id` והניבו **0 התאמות**. אין לצייר בינם לבין `New_Member.id` קשרים מאומתים.

### 17.5 מזהים חלופיים והיסטוריים

| שדה | מאוכלסים | ייחודיים לא־ריקים | עודף כפילויות |
|---|---:|---:|---:|
| `New_Company.crunchbase_id` | 9,865 | 9,845 | 20 |
| `New_Company.old_key` | 41 | 41 | 0 |
| `New_Company_Tag.old_key` | 23,796 | 23,796 | 0 |
| `New_Funding_Round.old_key` | 0 | 0 | 0 |
| `New_Tag.old_key` | 882 | 882 | 0 |

אין להציג מזהים אלה כ־FK או כ־PK אם לא נבדקה סמנטיקת היעד; חלקם ייחודיים רק על אוכלוסיית הערכים המאוכלסים.

### 17.6 גבולות ההשלמה — Events ו־Funding

**מספיק לשרטוט ERD בתחום הנבחר:** כבר ידועות טבלאות הבסיס, המפתחות הראשיים המועמדים, טבלאות ההשתתפות של משקיעים ומעניקים, וקשרים לוגיים רבים (עם חריגות). אין FK מפורש מאומת המקשר `BaseEvent.FundingRoundEvent` ל־`New_Funding_Round`; התאמה אנליטית אינה הופכת לקשר ERD.

**שני פריטים שנותרו לבירור ממוקד:**

1. `New_Funding_Round.joint_companies` — תוכנו ויכולתו לשאת מזהי חברה נוספים טרם נבדקו. אין לשער שהוא FK לפני בדיקת ערכים.
2. אילוצי PK/FK פיזיים ב־`INFORMATION_SCHEMA.TABLE_CONSTRAINTS` ו־`KEY_COLUMN_USAGE` טרם נבדקו; `id` אומת לפי הנתונים ולא בהכרח הוגדר כאילוץ.

**לא תנאי לסגירת ERD המבני:** כללי Visibility באפליקציה; סמנטיקת כל 37,408 האירועים; Post-classification של Public/Private Funding; שיוך מושלם בין שני מודלי Funding; טבלת משתמשים מחוץ להיקף. כל אלה יירשמו כהסתייגויות ולא ייוצגו כקשרים ודאיים.

**מצב כולל בגרסה 0.5:** ביקורת ייחודיות `id` הושלמה ב־16/16 טבלאות; ביקורת הצמדים בוצעה בשש טבלאות הקישור; קשרי FK מרכזיים ומזהים חיצוניים תועדו. נותרו שני פריטי אימות ממוקדים לעיל, לאחריהם ניתן לערוך טבלת כיסוי סופית ולהפיק ERD מבני מתועד.