# Finder — ERD navigation

תרשים ניווט מצומצם לכל **16 טבלאות הליבה**. הקווים מציגים רק הפניות עיקריות שנבדקו; פירוט ה־31 צמדים, התנאים, ה־NULL והחריגות מופיע ב־[Relationship Matrix](relationships.md). תרשים Graphviz מלא בקובץ [Finder_ERD_Overview.dot](Finder_ERD_Overview.dot).

**A** = התאמה מלאה של הערכים שנבדקו; **B** = התאמה חלקית/חריגות/תחולה מוגבלת. שני הסיווגים **אינם אילוצים פיזיים**. בכל קשר כזה, כאשר ערך המקור מתאים ל־`id` ביעד, ההתאמה לכל היותר לרשומת יעד אחת (N:1).

```mermaid
flowchart LR
    NC["New_Company"]
    NM["New_Member"]
    NEWS["News"]
    CN["CompanyNews"]
    NCN["New_Company_news"]
    CL["BaseClassificationModel"]
    CLR["BaseClassificationRelationModel"]
    CLC["BaseClassificationCompanyModel"]
    TAG["New_Tag"]
    NCT["New_Company_Tag"]
    BE["BaseEvent"]
    BEI["BaseEvent_investors"]
    BEG["BaseEvent_grantors"]
    FR["New_Funding_Round"]
    FRI["New_Funding_Round_known_investors"]
    FRU["New_Funding_Round_unknown_investors"]

    CN -->|"company_id B"| NC
    CN -->|"news_id B"| NEWS
    NCN -->|"origin_entity_id B"| NC
    NM -->|"company B"| NC

    CLR -->|"parent_key A"| CL
    CLR -->|"child_key A"| CL
    CLC -->|"company_key B"| NC
    CLC -->|"classification_key B"| CL
    NC -->|"primary_sector_key A"| CL

    NCT -->|"company B"| NC
    NCT -->|"tag B"| TAG

    BE -->|"company_key B + other roles"| NC
    BEI -->|"origin_entity_id A"| BE
    BEI -->|"investors_entity_entity_key B"| NC
    BEG -->|"origin_entity_id B"| BE
    BEG -->|"grantors_entity_entity_key B"| NC

    FR -->|"startup B"| NC
    FRI -->|"origin_entity_id A"| FR
    FRI -->|"known_investors B"| NC
    FRU -->|"origin_entity_id A"| FR

    classDef hub fill:#E5EFFB,stroke:#40678A,color:#18314D;
    class NC,NEWS,CL,TAG,BE,FR hub;
```

הערות: `New_Company_news.news_id → News.news_id` **לא צויר** משום שמפתח היעד לא ייחודי. אין קו בין `BaseEvent` ל־`New_Funding_Round`. הפניות עצמיות (`New_Company.acquired_by_key`, `tto_key`, `r_d_due_to_acquisition_key`, `BaseClassificationModel.root_key`) והפניות תלויות־`event_type` מתועדות במטריצה ובתרשים DOT, ולא כולן מוצגות במפת הניווט כדי לשמור על קריאות.
