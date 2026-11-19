# Finder / FDB — SQL Learning & Data Model

תיעוד עבודה של 16 טבלאות הליבה של Finder ב־BigQuery, המשמש ללימוד SQL מקצועי (ובפרט Window Functions) על סכמה אמיתית.

> **סטטוס:** מיפוי תיאורי ולא סכמת מקור מלאה או הגדרת מודל עסקי סופית. המסמך `v0.6` גובר על ההערות ההיסטוריות בנספח שלו. **לא הועלו נתונים גולמיים.**

## סביבת נתונים

- BigQuery project: `fdb-sql-lab`
- Dataset: `fdb`
- Scope: **16 טבלאות ליבה** בלבד
- Key Audit: **16/16 מזהי `id` ייחודיים ולא NULL** במדידות המתועדות
- מפתחות וקשרים **לוגיים**: לא הוגדרו אילוצי PK/FK פיזיים ב־dataset שנבדק
- אין לטעון ש־`BaseEvent` ו־`New_Funding_Round` קשורות באמצעות FK ישיר

## מסמכים

| נתיב | שימוש |
| --- | --- |
| [docs/finder_erd_checkpoint_v0.6.md](docs/finder_erd_checkpoint_v0.6.md) | מקור האמת לממצאי המיפוי, החריגות, ה־Key Audit וההסתייגויות |
| [docs/Finder_ERD_Overview.dot](docs/Finder_ERD_Overview.dot) | מקור Graphviz של ה־ERD הלוגי (16 טבלאות) |
| [docs/relationships.md](docs/relationships.md) | אינדקס קשרים מרכזיים, רמות אימות ונקודות כשל |
| [learning/window-functions.md](learning/window-functions.md) | מסלול לימוד פונקציות חלון עם דוגמאות מתוך Finder |
| [learning/teacher-instructions.md](learning/teacher-instructions.md) | הוראות למורה SQL בצ'אט חדש / ChatGPT Project |
| [sql/export_columns.sql](sql/export_columns.sql) | שאילתת **קריאה בלבד** לייצוא שמות העמודות והטיפוסים של 16 הטבלאות |

## התחלת לימוד Window Functions

1. פתח צ'אט בפרויקט הלמידה, הפנה לקבצי `docs/` ו־`learning/`.
2. בקש **שאלה אחת בכל פעם** על טבלאות ושדות קיימים בלבד; ללא פתרון לפני ניסיון עצמאי.
3. התחלה מומלצת: `New_Funding_Round` עם `id`, `startup`, `type_` ו־`COUNT(*) OVER(PARTITION BY startup)`.
4. לפני תרגול שדורש עמודות נוספות, הרץ את `sql/export_columns.sql` והוסף את הפלט לפרויקט; אין להמציא שמות שדות.

## כללי איכות ופרטיות

- אין להעלות CSVים של נתוני המקור, dump של Finder, מידע אישי, מפתחות גישה או קובצי credentials.
- אין לשנות טבלאות ב־BigQuery לצורך התרגול: SELECT בלבד.
- אין להמיר התאמות שם או חפיפות בין מודלים ל־FK.
- יש להגדיר Grain לפני JOIN / GROUP BY / Window Function, ולבדוק השלכות fan-out.
- התרשים מתאר **התאמות שנצפו**, לא אכיפת שלמות הפניה או כללים עסקיים מאומתים.

המאגר **ציבורי**. לפני הוספת נתונים או תיעוד נוסף, בדוק שהחומר מתאים לפרסום.
