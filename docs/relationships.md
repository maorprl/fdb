# Finder — Relationship evidence matrix

**מקור:** [מיפוי v0.6](finder_erd_checkpoint_v0.6.md), [ה־ERD](Finder_ERD_Overview.dot). נוצר מתוך גיליון Relationship Matrix v0.1 ללא הרצת בדיקות BigQuery חדשות.

- 16 טבלאות; 32 שורות בדיקה; 31 צמדי שדות שונים. `BaseEvent.stock_exchange_key` נמדד בנפרד ב־`POEvent` וב־`ReverseMergerEvent`.
- A: כל ערכי המפתח שנבדקו תואמים ליעד ייחודי — **לא** אילוץ DB. B: חריגות או חוסר בפירוט הבדיקה. C: התאמה בשדה יעד לא ייחודי, **לא** FK.
- המדדים "התאמות / אוכלוסייה" מתייחסים לתחולה בעמודה האחרונה; לעיתים כל הרשומות ולעיתים רק ערכים מאוכלסים.
- תא ריק במקור מסומן "—": משמעו **לא דווח**, ולא אפס. טווחי החריגות אינם תמיד בני סכימה כשיש חפיפה.
- N:1 מתאר את ההתאמה דרך `id` ייחודי; אינו מוכיח שכל מקורות המידע תקינים, שהקשר מחייב או את מספר ההורים בפועל.

| שדה מקור | שדה יעד | התאמות / נבדקו | חסרים ביעד | NULL במקור | רמה | תחולה |
| --- | --- | ---: | ---: | ---: | --- | --- |
| `CompanyNews.company_id` | `New_Company.id` | 94818 / 94854 | 36.0 | 0.0 | B \| חריגות | כל הרשומות |
| `CompanyNews.news_id` | `News.id` | 94830 / 94854 | 24.0 | 0.0 | B \| חריגות | כל הרשומות |
| `New_Company_news.origin_entity_id` | `New_Company.id` | 57092 / 57097 | 5.0 | 0.0 | B \| חריגות | כל הרשומות |
| `New_Company_news.news_id` | `News.news_id` | 47013 / 57097 | 590.0 | 9494.0 | C \| לא FK | כל הרשומות |
| `BaseClassificationModel.root_key` | `BaseClassificationModel.id` | 500 / 500 | 0.0 | 0.0 | A \| התאמה מלאה | 500 סיווגים |
| `BaseClassificationRelationModel.parent_key` | `BaseClassificationModel.id` | 457 / 457 | 0.0 | 0.0 | A \| התאמה מלאה | 457 קשרי היררכיה |
| `BaseClassificationRelationModel.child_key` | `BaseClassificationModel.id` | 457 / 457 | 0.0 | 0.0 | A \| התאמה מלאה | 457 קשרי היררכיה |
| `BaseClassificationCompanyModel.classification_key` | `BaseClassificationModel.id` | 153322 / 161373 | 8051.0 | 0.0 | B \| חריגות | כל הרשומות |
| `BaseClassificationCompanyModel.company_key` | `New_Company.id` | 158370 / 161373 | 1804.0 | 1199.0 | B \| חריגות | כל הרשומות |
| `New_Company.primary_sector_key` | `BaseClassificationModel.id` | 14182 / 14182 | 0.0 | — | A \| התאמה מלאה | מאוכלסים בלבד |
| `New_Company_Tag.company` | `New_Company.id` | 168608 / 171082 | 2474.0 | 0.0 | B \| חריגות | כל הרשומות |
| `New_Company_Tag.tag` | `New_Tag.id` | 149338 / 171082 | 130.0 | 21614.0 | B \| חריגות | כל הרשומות |
| `New_Member.company` | `New_Company.id` | 62727 / 64224 | 1283.0 | 214.0 | B \| חריגות | כל הרשומות |
| `BaseEvent.company_key` | `New_Company.id` | 36951 / 37408 | 456.0 | 1.0 | B \| חריגות | כל סוגי האירועים |
| `BaseEvent.other_party_entity_key` | `New_Company.id` | 2570 / 2591 | 8.0 | 13.0 | B \| חריגות | MNAEvent בלבד |
| `BaseEvent.stock_exchange_key` | `New_Company.id` | 1039 / 1043 | 4.0 | — | B \| חריגות | POEvent; יעד type='Stock Exchange' |
| `BaseEvent.stock_exchange_key` | `New_Company.id` | 64 / 65 | — | — | B \| חסר פירוט | ReverseMergerEvent; יעד type='Stock Exchange' |
| `BaseEvent.acquired_company_entity_key` | `New_Company.id` | 67 / 67 | 0.0 | — | A \| התאמה מלאה | 63 ReverseMerger, 3 Spac, 1 PO |
| `BaseEvent.institution_entity_key` | `New_Company.id` | 4217 / 4417 | 200.0 | — | B \| חריגות | GraduationEvent בלבד |
| `BaseEvent.merged_with_entity_key` | `New_Company.id` | 23 / 23 | 0.0 | — | A \| התאמה מלאה | SpacEvent בלבד |
| `BaseEvent.community_key` | `New_Company.id` | 199 / 202 | 3.0 | — | B \| חריגות | CommunityInvolvementEvent בלבד |
| `BaseEvent_investors.origin_entity_id` | `BaseEvent.id` | 32988 / 32988 | 0.0 | 0.0 | A \| התאמה מלאה | כל הרשומות |
| `BaseEvent_investors.investors_entity_entity_key` | `New_Company.id` | 32899 / 32988 | 57.0 | 32.0 | B \| חריגות | כל הרשומות |
| `BaseEvent_grantors.origin_entity_id` | `BaseEvent.id` | 1853 / 1859 | 6.0 | 0.0 | B \| חריגות | כל הרשומות |
| `BaseEvent_grantors.grantors_entity_entity_key` | `New_Company.id` | 1621 / 1853 | 164.0 | 68.0 | B \| חריגות | רק 1853 רשומות עם אירוע תקין |
| `New_Funding_Round.startup` | `New_Company.id` | 11639 / 11716 | — | — | B \| חסר פירוט | כל הסבבים |
| `New_Funding_Round_known_investors.origin_entity_id` | `New_Funding_Round.id` | 11610 / 11610 | 0.0 | 0.0 | A \| התאמה מלאה | כל הרשומות |
| `New_Funding_Round_known_investors.known_investors` | `New_Company.id` | 11547 / 11610 | 63.0 | 0.0 | B \| חריגות | כל הרשומות |
| `New_Funding_Round_unknown_investors.origin_entity_id` | `New_Funding_Round.id` | 11499 / 11499 | 0.0 | 0.0 | A \| התאמה מלאה | כל הרשומות |
| `New_Company.acquired_by_key` | `New_Company.id` | 788 / 796 | 8.0 | — | B \| חריגות | מאוכלסים בלבד |
| `New_Company.tto_key` | `New_Company.id` | 1904 / 1904 | 0.0 | — | A \| התאמה מלאה | מאוכלסים בלבד |
| `New_Company.r_d_due_to_acquisition_key` | `New_Company.id` | 87 / 96 | 9.0 | — | B \| חריגות | מאוכלסים בלבד |

## הבדלים שאסור לטשטש

- `New_Company_news.news_id → News.news_id` אינו FK תקין: `News.news_id` אינו ייחודי. המסלול הראשי הוא `CompanyNews.news_id → News.id` (עם חריגות מתועדות).
- אין FK ישיר בין `BaseEvent` ו־`New_Funding_Round`. 6,858 התאמות לפי חברה/תאריך/סכום אינן זהות מפתח.
- אין FK מאומת בין מודלי החדשות, אף שהם חופפים.
- `New_Member.user` פונה לפי הקשר המשתמש לטבלת משתמשים מחוץ ל־16 הטבלאות; **אינו** FK ל־`New_Member.id`.
- `New_Funding_Round_unknown_investors.unknown_investors` הוא טקסט חופשי, לא מזהה משקיע.
- `Tag_Relations`, `Events` וטבלאות עזר נוספות הוחרגו במפורש מן ה־ERD המרכזי.

## Grain וכפילויות

- `CompanyNews(company_id,news_id)`: ייחודי בפועל.
- `BaseEvent_investors`: 14 צמדים כפולים, 15 עודפות; חלקם שונים בסכומים/דגלים.
- `New_Company_news`: 120 צמדים כפולים, 121 עודפות; ב־111 קבוצות יש הבדלי תוכן.
- `BaseEvent_grantors`: צמד כפול אחד, תוכן זהה מלבד `id`.
- `New_Funding_Round_known_investors`: 7 צמדים כפולים, זהים מלבד `id`.
- `New_Funding_Round_unknown_investors`: 12 צמדים כפולים, 14 רשומות עודפות, זהים מלבד `id`.
- `New_Member(company,user)`: 940 צמדים כפולים, 1,719 עודפות; אינו מפתח.
- `BaseClassificationCompanyModel`: 4,891 רשומות עודפות לפי הצירוף המרובע שנבדק.
- `New_Company_Tag`: 273 עודפות לפי `(company, tag, company_type)`.

לבדיקות המלאות ולהקשרים העסקיים ראה את המסמך v0.6.
