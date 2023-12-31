import './quiz_screen.dart';

List<QuizQuestion> questionList = [
  QuizQuestion(
    question:
        'באיור שלהלן מתואר סכמתית קומפלקס של מבני מגורים שהוקמו על גבי חניון משותף .כל אחד מהמבנים מקבל הזנה נפרדת במתח נמוך מתחנת טרנספורמציה של חברת החשמל. תחנת הטרנספורמציה הוקמה בתוך בניין מספר 1 . השוואת הפוטנציאלים במבנים אלה מיושמת באמצעות פסי השוואת פוטנציאלים נפרדים בכל אחד מהמבנים איזה מבין האפשרויות הבאות היא הנכונה ביותר מבחינת שיטת הגנה בפני חשמול במבנים ?',
    answers: [
      QuizAnswer(
          answer:
              'לאור העובדה שכל מבנה מקבל הזנה בנפרד, אפשר לבצע חיבור בין פס אפס לבין פס השוואת פוטנציאלים בכל אחד מהמבנים'),
      QuizAnswer(
          answer:
              'אפשר לבצע חיבור בין פס אפס לבין פס השוואת פוטנציאלים של אחד מהמבנים בלבד. הפס לביצוע האיפוס ייבחר על ידי המתכנן'),
      QuizAnswer(
          answer:
              'החיבור היחיד בין נקודת האפס לפהפ יבוצע רק במבנה שבו מותקן השנאי'),
      QuizAnswer(
          answer:
              'אסור במקרה זה להשתמש באיפוס כשיטת הגנה מפני חשמול. יש להשתמש רק בשיטת הארקת הגנה ( TT).'),
    ],
    correctAnswerIndex: 2,
  ),
  //more 699 questions. due to copyright reasons, cannot be shared.
];
